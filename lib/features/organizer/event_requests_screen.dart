import 'package:tande/core/theme/adaptive.dart';
import 'package:tande/core/utils/contact.dart';
import 'package:tande/core/utils/format.dart';
import 'package:tande/data/repositories/providers.dart';
import 'package:tande/features/explore/explore_providers.dart';
import 'package:tande/features/inscriptions/inscriptions_providers.dart';
import 'package:tande/features/organizer/organizer_providers.dart';
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

enum _RequestsView { pending, confirmed, rejected }

enum _EventAction { close, reopen, delete }

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));

    return tournamentAsync.when(
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

  Widget _buildBody(TournamentModel tournament) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
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
            tooltip: l10n.editEvent,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/organize/event/${widget.tournamentId}/edit'),
          ),
          PopupMenuButton<_EventAction>(
            tooltip: l10n.moreActions,
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => switch (action) {
              _EventAction.close => _setStatus(
                tournament,
                TournamentStatus.closed,
              ),
              _EventAction.reopen => _reopen(tournament),
              _EventAction.delete => _delete(tournament),
            },
            itemBuilder: (context) => [
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.filterPending),
                    selected: _view == _RequestsView.pending,
                    onSelected: (_) =>
                        setState(() => _view = _RequestsView.pending),
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
          ),
          Expanded(
            child: inscriptionsAsync.when(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == TournamentStatus.closed
                ? l10n.registrationsClosed
                : l10n.registrationsReopened,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.updateEventError(error))));
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
  Future<void> _setManualConfirmed(
    TournamentModel tournament,
    int amount,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    // Captured before the await: `ref` throws once disposed, and the caches
    // must refresh even if the user navigates away mid-request.
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await ref
          .read(tournamentRepositoryProvider)
          .setManualConfirmed(tournament, amount);
      invalidateOrganizerState(container, tournamentId: tournament.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.outsideUpdated)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.updateError(error))));
      }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.deleteError(error))));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == InscriptionStatus.confirmed
                ? l10n.registrationConfirmed
                : l10n.registrationRejected,
          ),
          action: canNotify
              ? SnackBarAction(
                  label: l10n.notifyWhatsApp,
                  onPressed: () => _notifyDecision(inscription, status),
                )
              : null,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.updateError(error))));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.whatsappOpenFailed(player.phone))),
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

  Widget _avatar(ThemeData theme, String playerName) => CircleAvatar(
    backgroundColor: theme.colorScheme.secondaryContainer,
    child: Text(
      playerName.isEmpty ? '?' : playerName.substring(0, 1).toUpperCase(),
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onSecondaryContainer,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.whatsappOpenFailed(player.phone))),
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
  const _ManualCountTile({required this.tournament, required this.onChanged});

  final TournamentModel tournament;
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
    final manual = tournament.manualConfirmed;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editDialog(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              Icon(
                Icons.group_add_outlined,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.outsideTitle, style: theme.textTheme.labelLarge),
                    Text(
                      l10n.outsideHelp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('manual-remove'),
                tooltip: l10n.decreaseOne,
                visualDensity: VisualDensity.compact,
                onPressed: manual <= 0 ? null : () => onChanged(manual - 1),
                icon: const Icon(Icons.remove),
              ),
              InkWell(
                key: const Key('manual-count'),
                borderRadius: BorderRadius.circular(8),
                onTap: () => _editDialog(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text('$manual', style: theme.textTheme.titleMedium),
                ),
              ),
              IconButton(
                key: const Key('manual-add'),
                tooltip: l10n.increaseOne,
                visualDensity: VisualDensity.compact,
                onPressed: manual >= _max ? null : () => onChanged(manual + 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
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
