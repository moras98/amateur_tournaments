import 'package:tande/core/theme/adaptive.dart';
import 'package:tande/core/utils/contact.dart';
import 'package:tande/core/utils/csv_export.dart';
import 'package:tande/core/utils/format.dart';
import 'package:tande/data/repositories/providers.dart';
import 'package:tande/features/explore/explore_providers.dart';
import 'package:tande/features/inscriptions/inscriptions_providers.dart';
import 'package:tande/features/organizer/organizer_providers.dart';
import 'package:tande/features/pro/pro_providers.dart';
import 'package:tande/features/tournament/tournament_providers.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/l10n/labels.dart';
import 'package:tande/models/inscription_model.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tande/core/widgets/tande_toast.dart';
import 'package:tande/core/widgets/fade_scroll_row.dart';

enum _RequestsView { pending, confirmed, rejected, waitlisted }

enum _EventAction { duplicate, close, reopen, delete }

/// One of the organizer's events: summary + inscription requests to
/// confirm/reject (players coordinate payment off-app first).
class EventRequestsScreen extends ConsumerStatefulWidget {
  const EventRequestsScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<EventRequestsScreen> createState() =>
      _EventRequestsScreenState();
}

class _EventRequestsScreenState extends ConsumerState<EventRequestsScreen> {
  _RequestsView _view = _RequestsView.pending;
  bool _deciding = false;

  /// Off-app count shown while its write is in flight.
  ///
  /// Without this the number only moved after two round trips — the UPDATE,
  /// then the refetch that the invalidation triggers — and the screen blanked
  /// to a spinner in between.
  int? _manualShown;

  /// Latest value asked for but not sent yet.
  int? _manualQueued;
  bool _manualWriting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));

    return tournamentAsync.when(
      // A mutation invalidates this provider: keep the data on screen while it
      // refetches instead of blanking to a spinner. The first load still spins
      // because there is no previous value.
      skipLoadingOnReload: true,
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.eventLoadError(error))),
      ),
      data: (tournament) {
        if (tournament == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.eventNotFound)),
          );
        }
        return _buildBody(tournament);
      },
    );
  }

  Widget _buildBody(TournamentModel stored) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Once the write is done the stored value is the truth: if it caught up,
    // dropping the overlay changes nothing on screen; if it disagrees, the
    // write did not land and the user must see the real number.
    if (_manualShown != null &&
        !_manualWriting &&
        _manualShown != stored.manualConfirmed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _manualShown = null);
      });
    }

    // Everything downstream — the summary total, the progress bar, the status
    // chip and the counter — reads this one value, so the whole card moves
    // together instead of the counter jumping ahead of the total.
    final tournament = _manualShown == null
        ? stored
        : _manualOverride(stored, _manualShown!);
    final inscriptionsAsync = ref.watch(
      tournamentInscriptionsProvider(widget.tournamentId),
    );
    final takenRatio = tournament.totalTeams <= 0
        ? 0.0
        : (tournament.totalConfirmed / tournament.totalTeams).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l10n.exportCsv,
            icon: const Icon(Icons.ios_share),
            onPressed: () => _exportCsv(tournament),
          ),
          IconButton(
            tooltip: l10n.editEvent,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/organize/event/${widget.tournamentId}/edit'),
          ),
          PopupMenuButton<_EventAction>(
            tooltip: l10n.moreActions,
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => switch (action) {
              _EventAction.duplicate => _duplicate(tournament),
              _EventAction.close => _setStatus(
                tournament,
                TournamentStatus.closed,
              ),
              _EventAction.reopen => _reopen(tournament),
              _EventAction.delete => _delete(tournament),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _EventAction.duplicate,
                child: Text(l10n.duplicateEvent),
              ),
              const PopupMenuDivider(),
              if (tournament.status != TournamentStatus.closed)
                PopupMenuItem(
                  value: _EventAction.close,
                  child: Text(l10n.closeRegistrations),
                )
              else
                PopupMenuItem(
                  value: _EventAction.reopen,
                  child: Text(l10n.reopenRegistrations),
                ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _EventAction.delete,
                child: Text(
                  l10n.deleteEvent,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tournament.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      formatEventDate(
                        tournament.startTime,
                        end: tournament.endTime,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.spotsTaken(
                              tournament.totalConfirmed,
                              tournament.totalTeams,
                            ),
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        Text(
                          l10n
                              .tournamentStatus(tournament.status)
                              .toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: takenRatio,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ManualCountTile(
                      tournament: tournament,
                      manual: tournament.manualConfirmed,
                      onChanged: (value) =>
                          _setManualConfirmed(tournament, value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Filters — one scrolling row: a Wrap would stack them into a
          // centered second run on narrow phones.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: FadeScrollRow(
              children: [
                ChoiceChip(
                  label: Text(l10n.filterPending),
                  selected: _view == _RequestsView.pending,
                  onSelected: (_) =>
                      setState(() => _view = _RequestsView.pending),
                ),
                ChoiceChip(
                  label: Text(l10n.filterWaitlist),
                  selected: _view == _RequestsView.waitlisted,
                  onSelected: (_) =>
                      setState(() => _view = _RequestsView.waitlisted),
                ),
                ChoiceChip(
                  label: Text(l10n.filterConfirmed),
                  selected: _view == _RequestsView.confirmed,
                  onSelected: (_) =>
                      setState(() => _view = _RequestsView.confirmed),
                ),
                ChoiceChip(
                  label: Text(l10n.filterRejected),
                  selected: _view == _RequestsView.rejected,
                  onSelected: (_) =>
                      setState(() => _view = _RequestsView.rejected),
                ),
              ],
            ),
          ),
          Expanded(
            child: inscriptionsAsync.when(
              // Same as the tournament above: a reload after a decision keeps
              // the list on screen; only the first load spins.
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text(l10n.requestsLoadError(error))),
              data: (inscriptions) {
                final visible = inscriptions
                    .where((i) => i.status.name == _view.name)
                    .toList();
                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      switch (_view) {
                        _RequestsView.pending => l10n.emptyRequestsPending,
                        _RequestsView.confirmed => l10n.emptyRequestsConfirmed,
                        _RequestsView.rejected => l10n.emptyRequestsRejected,
                        _RequestsView.waitlisted => l10n.emptyRequestsWaitlist,
                      },
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: visible.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) => _RequestCard(
                    inscription: visible[index],
                    eventTitle: tournament.title,
                    deciding: _deciding,
                    onConfirm: () =>
                        _decide(visible[index], InscriptionStatus.confirmed),
                    onReject: () =>
                        _decide(visible[index], InscriptionStatus.rejected),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Duplicate: opens the create form pre-filled from this event (dates moved
  /// a week ahead) so the organizer only adjusts the date. Pro feature.
  Future<void> _duplicate(TournamentModel tournament) async {
    final pro = ref.read(proProvider);
    if (pro.available && !pro.isPro) {
      context.push('/pro');
      return;
    }
    context.push('/organize/duplicate/${tournament.id}');
  }

  /// Exports every registration of this event as a CSV through the system
  /// share sheet (WhatsApp, Drive, mail, Excel). Pro feature.
  Future<void> _exportCsv(TournamentModel tournament) async {
    final l10n = AppLocalizations.of(context)!;
    final pro = ref.read(proProvider);
    if (pro.available && !pro.isPro) {
      context.push('/pro');
      return;
    }

    List<InscriptionModel> inscriptions;
    try {
      inscriptions = await ref.read(
        tournamentInscriptionsProvider(tournament.id).future,
      );
    } catch (_) {
      inscriptions = const [];
    }
    if (!mounted) return;

    if (inscriptions.isEmpty) {
      showTandeToast(context, l10n.exportCsvEmpty);
      return;
    }

    final csv = buildInscriptionsCsv(
      inscriptions: inscriptions,
      statusLabel: l10n.inscriptionStatus,
      dateFormat: formatDateTime,
    );
    final shared = await shareCsv(
      fileName: csvFileName(title: tournament.title, now: DateTime.now()),
      csv: csv,
      subject: tournament.title,
    );
    if (!mounted || shared) return;
    showTandeToast(context, l10n.exportCsvFailed, kind: ToastKind.error);
  }

  /// Close/reopen registrations (manual override; the `sync_tournament_status`
  /// trigger only manages `open`/`full` as inscriptions change).
  Future<void> _setStatus(
    TournamentModel tournament,
    TournamentStatus status,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    // Captured before the await: `ref` throws once disposed, and the caches
    // must refresh even if the user navigates away mid-request.
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await ref
          .read(tournamentRepositoryProvider)
          .update(tournament.copyWith(status: status));
      invalidateOrganizerState(container, tournamentId: tournament.id);
      if (!mounted) return;
      showTandeToast(
        context,
        status == TournamentStatus.closed
            ? l10n.registrationsClosed
            : l10n.registrationsReopened,
        kind: ToastKind.success,
      );
    } catch (error) {
      if (mounted) {
        showTandeToast(
          context,
          l10n.updateEventError(error),
          kind: ToastKind.error,
        );
      }
    }
  }

  Future<void> _reopen(TournamentModel tournament) => _setStatus(
    tournament,
    tournament.totalConfirmed < tournament.totalTeams
        ? TournamentStatus.open
        : TournamentStatus.full,
  );

  /// Persists the off-app confirmed count (teams the organizer confirmed
  /// in person / by WhatsApp, with no inscription row in the app) and
  /// refreshes every cached view of the event.
  /// The tournament as it should look while the off-app write is in flight:
  /// same rule the DB trigger applies (the status follows the total).
  TournamentModel _manualOverride(TournamentModel tournament, int manual) {
    final total = tournament.confirmedTeams + manual;
    final status = tournament.status == TournamentStatus.closed
        ? tournament.status
        : total >= tournament.totalTeams
        ? TournamentStatus.full
        : TournamentStatus.open;
    return tournament.copyWith(manualConfirmed: manual, status: status);
  }

  Future<void> _setManualConfirmed(
    TournamentModel tournament,
    int amount,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    // Captured before the await: `ref` throws once disposed, and these caches
    // must refresh even if the user navigates away mid-request.
    final container = ProviderScope.containerOf(context, listen: false);
    final target = amount < 0 ? 0 : amount;

    // The number moves now; the write and the refetch happen behind it.
    setState(() => _manualShown = target);
    _manualQueued = target;

    // One write at a time, always sending the latest value: five quick taps
    // are two UPDATEs (the one already in flight and the final value), not
    // five racing ones whose replies can land out of order and leave the
    // count at an intermediate number.
    if (_manualWriting) return;
    _manualWriting = true;
    try {
      while (_manualQueued != null) {
        final next = _manualQueued!;
        _manualQueued = null;
        await ref
            .read(tournamentRepositoryProvider)
            .setManualConfirmed(tournament, next);
      }
      // Inscriptions do not change when the off-app count moves, so only the
      // tournament and the lists that show its counts are refreshed.
      container
        ..invalidate(tournamentProvider(tournament.id))
        ..invalidate(myTournamentsProvider)
        ..invalidate(exploreResultsProvider);
      if (!mounted) return;
      showTandeToast(context, l10n.outsideUpdated, kind: ToastKind.success);
    } catch (error) {
      if (!mounted) return;
      // Put the truth back on screen: the overlay goes and the stored value
      // takes over.
      setState(() => _manualShown = null);
      _manualQueued = null;
      showTandeToast(context, l10n.updateError(error), kind: ToastKind.error);
    } finally {
      _manualWriting = false;
    }
  }

  Future<void> _delete(TournamentModel tournament) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteConfirmTitle,
      message: l10n.deleteConfirmMessage,
      confirmLabel: l10n.deleteEvent,
      destructive: true,
      icon: Icons.delete_outline,
    );
    if (confirmed != true || !mounted) return;

    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await ref.read(tournamentRepositoryProvider).delete(tournament.id);
      container
        ..invalidate(myTournamentsProvider)
        ..invalidate(exploreResultsProvider)
        // The event and its inscriptions are gone: drop every cached view
        // of them, including "Mis inscripciones" entries.
        ..invalidate(myInscriptionsProvider)
        ..invalidate(tournamentProvider(tournament.id))
        ..invalidate(tournamentInscriptionsProvider(tournament.id));
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        showTandeToast(context, l10n.deleteError(error), kind: ToastKind.error);
      }
    }
  }

  Future<void> _decide(
    InscriptionModel inscription,
    InscriptionStatus status,
  ) async {
    if (_deciding) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _deciding = true);
    // Captured before the await: `ref` throws once disposed, and the caches
    // must refresh even if the user navigates away mid-request.
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await ref
          .read(inscriptionRepositoryProvider)
          .decide(inscriptionId: inscription.id, status: status);
      invalidateOrganizerState(container, tournamentId: widget.tournamentId);
      if (!mounted) return;
      // Offers to notify the player right away: payment was coordinated
      // off-app, so a WhatsApp ping closes the loop. The action only shows
      // when the player has a contactable number.
      final player = inscription.player;
      final canNotify = player != null && player.canBeContacted;
      showTandeToast(
        context,
        status == InscriptionStatus.confirmed
            ? l10n.registrationConfirmed
            : l10n.registrationRejected,
        kind: ToastKind.success,
        actionLabel: canNotify ? l10n.notifyWhatsApp : null,
        onAction: canNotify ? () => _notifyDecision(inscription, status) : null,
      );
    } catch (error) {
      if (mounted) {
        showTandeToast(context, l10n.updateError(error), kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _deciding = false);
    }
  }

  /// Pre-fills a WhatsApp message with the organizer's decision.
  Future<void> _notifyDecision(
    InscriptionModel inscription,
    InscriptionStatus status,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final player = inscription.player;
    if (player == null || !player.canBeContacted) return;

    final name = player.fullName.isNotEmpty ? player.fullName : player.username;
    final title =
        ref.read(tournamentProvider(widget.tournamentId)).valueOrNull?.title ??
        'el evento';

    final opened = await openWhatsApp(
      phone: player.phone,
      message: status == InscriptionStatus.confirmed
          ? '¡Hola $name! Confirmé tu inscripción para "$title". '
                'Cualquier consulta escribime.'
          : 'Hola $name, tu inscripción para "$title" fue rechazada. '
                'Cualquier consulta escribime.',
    );
    if (!opened && mounted) {
      showTandeToast(
        context,
        l10n.whatsappOpenFailed(player.phone),
        kind: ToastKind.error,
      );
    }
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.inscription,
    required this.eventTitle,
    required this.deciding,
    required this.onConfirm,
    required this.onReject,
  });

  final InscriptionModel inscription;
  final String eventTitle;
  final bool deciding;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  String _playerName(AppLocalizations l10n) {
    final player = inscription.player;
    if (player == null) return l10n.player;
    if (player.fullName.isNotEmpty) return player.fullName;
    return player.username;
  }

  @override
  Widget build(BuildContext context) {
    final player = inscription.player;
    final canContact = player != null && player.canBeContacted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: inscription.isPending
            ? _pendingContent(context, canContact: canContact)
            : _decidedContent(context),
      ),
    );
  }

  Widget _pendingContent(BuildContext context, {required bool canContact}) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final playerName = _playerName(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _avatar(theme, playerName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playerName, style: theme.textTheme.titleMedium),
                  if (inscription.teamName.isNotEmpty)
                    Text(
                      inscription.teamName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (canContact)
              IconButton(
                tooltip: 'WhatsApp',
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => _contactPlayer(context),
              ),
          ],
        ),
        if (inscription.note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '"${inscription.note}"',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          l10n.requestedOn(formatDateTime(inscription.createdAt)),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: deciding ? null : onConfirm,
                icon: const Icon(Icons.check, size: 18),
                label: Text(l10n.confirm),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: deciding ? null : onReject,
                icon: const Icon(Icons.close, size: 18),
                label: Text(l10n.reject),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _decidedContent(BuildContext context) {
    final theme = Theme.of(context);
    final playerName = _playerName(AppLocalizations.of(context)!);

    return Row(
      children: [
        _avatar(theme, playerName),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(playerName, style: theme.textTheme.titleMedium),
              if (inscription.teamName.isNotEmpty)
                Text(
                  inscription.teamName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        _StatusTag(status: inscription.status),
      ],
    );
  }

  /// Squircle, not `CircleAvatar`: the request card sits next to the event
  /// cards, whose sports stickers are rounded squares — a Material circle
  /// there reads as a leftover from another app.
  Widget _avatar(ThemeData theme, String playerName) => Container(
    width: 44,
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      playerName.isEmpty ? '?' : playerName.substring(0, 1).toUpperCase(),
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onSecondaryContainer,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Future<void> _contactPlayer(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final player = inscription.player;
    if (player == null || !player.canBeContacted) return;

    final opened = await openWhatsApp(
      phone: player.phone,
      message:
          'Hola ${_playerName(l10n)}, tengo una novedad sobre tu inscripción '
          'para "$eventTitle".',
    );
    if (!opened && context.mounted) {
      showTandeToast(
        context,
        l10n.whatsappOpenFailed(player.phone),
        kind: ToastKind.error,
      );
    }
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final InscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final (
      Color background,
      Color foreground,
      IconData icon,
    ) = switch (status) {
      InscriptionStatus.confirmed => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
        Icons.check_circle,
      ),
      InscriptionStatus.rejected => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
        Icons.cancel,
      ),
      InscriptionStatus.waitlisted => (
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
        Icons.people_outline,
      ),
      _ => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
        Icons.hourglass_top,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            l10n.inscriptionStatus(status),
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Editor for the off-app confirmed count: teams the organizer confirmed
/// in person / by WhatsApp / cash, which never filed an inscription in
/// the app. Steppers for ±1, tap the number to type an amount.
class _ManualCountTile extends StatelessWidget {
  const _ManualCountTile({
    required this.tournament,
    required this.manual,
    required this.onChanged,
  });

  final TournamentModel tournament;

  /// The value on screen: optimistic while a write is in flight.
  final int manual;
  final ValueChanged<int> onChanged;

  /// Spare capacity beyond the app-confirmed rows: the off-app count can
  /// never push the total past the event's capacity.
  int get _max {
    final spare = tournament.totalTeams - tournament.confirmedTeams;
    return spare < 0 ? 0 : spare;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: scheme.onSurfaceVariant.withValues(alpha: 0.09),
              ),
              child: Icon(
                Icons.person_add_alt_1_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.outsideShortTitle,
                style: theme.textTheme.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _CountStepper(
              value: manual,
              onDecrement: manual <= 0 ? null : () => onChanged(manual - 1),
              onIncrement: manual >= _max ? null : () => onChanged(manual + 1),
              onEdit: () => _editDialog(context),
            ),
          ],
        ),
        Padding(
          // Aligned with the title, past the icon.
          padding: const EdgeInsets.only(left: 44, top: 4),
          child: Text(
            l10n.outsideHelp,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final max = _max;
    final value = await showDialog<int>(
      context: context,
      builder: (context) => _ManualCountDialog(
        initial: tournament.manualConfirmed,
        max: max,
        helper: max <= 0
            ? l10n.outsideFull(tournament.confirmedTeams)
            : l10n.outsideMax(tournament.confirmedTeams, tournament.totalTeams),
      ),
    );
    if (value != null && value != tournament.manualConfirmed) {
      onChanged(value);
    }
  }
}

/// Numeric dialog behind the manual-count tile: clamps to [max] (spare
/// capacity) and returns null on cancel or a non-numeric entry.
/// The ±1 control and the tap-to-type number, grouped as one segmented pill.
///
/// They used to be two bare [IconButton]s and a loose number floating in the
/// tile: three affordances for one value, which is what made the block read
/// as a form dropped into a summary card. In a tinted pill the whole thing is
/// one object you can point at.
class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    required this.onEdit,
  });

  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            buttonKey: const Key('manual-remove'),
            tooltip: l10n.decreaseOne,
            icon: Icons.remove_rounded,
            onPressed: onDecrement,
          ),
          InkWell(
            key: const Key('manual-count'),
            borderRadius: BorderRadius.circular(10),
            onTap: onEdit,
            child: Container(
              constraints: const BoxConstraints(minWidth: 26),
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _StepButton(
            buttonKey: const Key('manual-add'),
            tooltip: l10n.increaseOne,
            icon: Icons.add_rounded,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  /// Lives on the [IconButton] itself: tests and tooling look it up as an
  /// `IconButton` to assert enabled/disabled state.
  final Key buttonKey;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      key: buttonKey,
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      style: IconButton.styleFrom(
        foregroundColor: scheme.onSurface,
        disabledForegroundColor: scheme.onSurfaceVariant.withValues(
          alpha: 0.35,
        ),
      ),
      icon: Icon(icon),
    );
  }
}

class _ManualCountDialog extends StatefulWidget {
  const _ManualCountDialog({
    required this.initial,
    required this.max,
    required this.helper,
  });

  final int initial;
  final int max;
  final String helper;

  @override
  State<_ManualCountDialog> createState() => _ManualCountDialogState();
}

class _ManualCountDialogState extends State<_ManualCountDialog> {
  // Owned here (not in the caller): the route's exit animation still
  // rebuilds the field after `showDialog` returns.
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.initial}',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Clamps the typed amount to the spare capacity (0 floor) and returns
  /// null on a non-numeric entry; cancel returns null too.
  void _save() {
    final parsed = int.tryParse(_controller.text);
    Navigator.of(context).pop(
      parsed == null
          ? null
          : parsed < 0
          ? 0
          : parsed > widget.max
          ? widget.max
          : parsed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Same dialog on both platforms: the shared close-on-top shells —
    // Material's text field, or the native Cupertino field.
    if (isCupertino(context)) {
      return CupertinoCloseAlert(
        title: l10n.outsideTitle,
        confirmLabel: l10n.save,
        onConfirm: _save,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoTextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              placeholder: l10n.teamsLabel,
            ),
            const SizedBox(height: 8),
            Text(widget.helper),
          ],
        ),
      );
    }

    return CloseTopDialog(
      icon: Icons.groups_outlined,
      title: l10n.outsideTitle,
      confirmLabel: l10n.save,
      onConfirm: _save,
      body: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: l10n.teamsLabel,
          helperText: widget.helper,
        ),
      ),
    );
  }
}
