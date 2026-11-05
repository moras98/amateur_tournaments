import 'package:tande/core/constants.dart';
import 'package:tande/core/map/basemap.dart';
import 'package:tande/core/map/basemap_layer.dart';
import 'package:tande/core/observability/analytics.dart';
import 'package:tande/core/theme/app_gradients.dart';
import 'package:tande/core/widgets/sport_sticker.dart';
import 'package:tande/core/theme/adaptive.dart';
import 'package:tande/core/utils/contact.dart';
import 'package:tande/core/widgets/contact_sheet.dart';
import 'package:tande/models/contact_channel.dart';
import 'package:tande/core/utils/format.dart';
import 'package:tande/core/widgets/tournament_banner.dart';
import 'package:tande/data/auth/auth_repository.dart';
import 'package:tande/data/repositories/providers.dart';
import 'package:tande/features/explore/explore_providers.dart';
import 'package:tande/features/inscriptions/inscriptions_providers.dart';
import 'package:tande/features/organizer/organizer_providers.dart';
import 'package:tande/features/tournament/tournament_providers.dart';
import 'package:tande/features/tournament/widgets/team_name_dialog.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/l10n/labels.dart';
import 'package:tande/models/inscription_model.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:tande/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tande/core/widgets/tande_toast.dart';

/// Full event information, spots-left progress, organizer contact and the
/// registration action (pending → organizer confirms off-app via WhatsApp).
class TournamentDetailScreen extends ConsumerStatefulWidget {
  const TournamentDetailScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState
    extends ConsumerState<TournamentDetailScreen> {
  bool _registering = false;
  bool _cancelling = false;

  /// Asks for the team name (pre-filled with the player's) and then creates
  /// the inscription. The name is what the organizer sees in their list and
  /// what the CSV export carries — a person's name where a team belongs makes
  /// both of those useless.
  Future<void> _startRegistration({
    required TournamentModel tournament,
    UserModel? organizer,
    UserModel? player,
    bool waitlist = false,
  }) async {
    if (_registering) return;
    final teamName = await askTeamName(
      context,
      initial: player?.fullName ?? '',
    );
    if (teamName == null || !mounted) return;
    await _register(
      tournament: tournament,
      organizer: organizer,
      player: player,
      teamName: teamName,
      waitlist: waitlist,
    );
  }

  Future<void> _register({
    required TournamentModel tournament,
    UserModel? organizer,
    UserModel? player,
    required String teamName,
    bool waitlist = false,
  }) async {
    if (_registering) return; // Same-frame double tap protection.
    final l10n = AppLocalizations.of(context)!;
    final session = ref.read(authStateProvider);
    if (session == null) return;

    // Captured before the awaits: `ref` throws once the widget is disposed,
    // and the caches must refresh even if the user navigates away while the
    // write is in flight.
    final container = ProviderScope.containerOf(context, listen: false);

    setState(() => _registering = true);
    try {
      await ref
          .read(inscriptionRepositoryProvider)
          .create(
            tournamentId: tournament.id,
            playerId: session.userId,
            teamName: teamName,
            waitlist: waitlist,
          );
      container.read(analyticsProvider).track('inscription_requested', {
        'tournament_id': tournament.id,
        'waitlist': waitlist,
      });
      container
        ..invalidate(myInscriptionProvider(tournament.id))
        // The list tab caches its result — refresh it or a previously
        // visited "Mis inscripciones" keeps showing the pre-signup state.
        ..invalidate(myInscriptionsProvider)
        // The organizer's event card shows a pending-requests badge.
        ..invalidate(tournamentInscriptionsProvider(tournament.id));

      if (waitlist) {
        // No payment to coordinate yet: the spot isn't theirs until one
        // frees up, so opening WhatsApp here would be premature.
        if (mounted) {
          showTandeToast(
            context,
            l10n.waitlistSuccess,
            kind: ToastKind.success,
          );
        }
        return;
      }

      // Payment is coordinated off-app: open WhatsApp with a pre-filled
      // message to the organizer.
      final contactable = organizer != null && organizer.canBeContacted;
      var opened = false;
      if (contactable) {
        opened = await openWhatsApp(
          phone: organizer.phone,
          message: _registrationMessage(tournament, player),
        );
      }

      if (!mounted) return;
      final String message;
      if (!contactable) {
        message = l10n.registerSuccessNoContact;
      } else if (opened) {
        message = l10n.registerSuccessWhatsApp;
      } else {
        message = l10n.registerSuccessFallback;
      }
      showTandeToast(context, message);
    } catch (error) {
      if (mounted) {
        showTandeToast(
          context,
          l10n.registerError(error),
          kind: ToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  Future<void> _cancel(InscriptionModel inscription) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.cancelConfirmTitle,
      message: l10n.cancelConfirmMessage,
      confirmLabel: l10n.cancelRegistration,
      destructive: true,
      icon: Icons.event_busy,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    // Captured before the await: `ref` throws once disposed, and freeing a
    // spot must refresh Explore (full → open) even mid-navigation.
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await ref
          .read(inscriptionRepositoryProvider)
          .cancel(inscriptionId: inscription.id);
      container.read(analyticsProvider).track('inscription_cancelled', {
        'tournament_id': widget.tournamentId,
      });
      container
        ..invalidate(myInscriptionProvider(widget.tournamentId))
        ..invalidate(tournamentProvider(widget.tournamentId))
        ..invalidate(myInscriptionsProvider)
        ..invalidate(tournamentInscriptionsProvider(widget.tournamentId))
        ..invalidate(exploreResultsProvider);

      if (mounted) {
        showTandeToast(
          context,
          l10n.registrationCancelled,
          kind: ToastKind.success,
        );
      }
    } catch (error) {
      if (mounted) {
        showTandeToast(context, l10n.cancelError(error), kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _contactOrganizer({
    required TournamentModel tournament,
    required UserModel organizer,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final message = '¡Hola! Tengo una consulta sobre "${tournament.title}".';

    // A phone on its own keeps the old one-tap path: WhatsApp. The chooser
    // only appears when the organizer actually published another channel,
    // because "which app?" is a question worth asking only when there is a
    // different answer.
    if (!organizer.hasExtraContactChannels) {
      final opened = await openWhatsApp(
        phone: organizer.phone,
        message: message,
      );
      if (opened || !mounted) return;
      // WhatsApp didn't open (not installed / no handler): fall back to
      // the channels sheet instead of a dead-end notice — it carries
      // "Llamar" with the same number, so the only conversion path of the
      // product never becomes a wall (§4.10-b).
      final result = await showContactSheet(
        context: context,
        title: l10n.contactSheetTitle(
          organizer.fullName.isNotEmpty
              ? organizer.fullName
              : organizer.username,
        ),
        channels: contactChannelsOf(
          organizer,
          linkLabel: l10n.contactLinkDefault,
        ),
        message: message,
      );
      if (result == false && mounted) {
        showTandeToast(context, l10n.contactOpenFailed, kind: ToastKind.error);
      }
      return;
    }

    final opened = await showContactSheet(
      context: context,
      title: l10n.contactSheetTitle(
        organizer.fullName.isNotEmpty ? organizer.fullName : organizer.username,
      ),
      channels: contactChannelsOf(
        organizer,
        linkLabel: l10n.contactLinkDefault,
      ),
      message: message,
    );
    if (opened == false && mounted) {
      showTandeToast(context, l10n.contactOpenFailed, kind: ToastKind.error);
    }
  }

  /// Sends the event to the team's group chat — the growth loop of a
  /// marketplace that people find through other people (§4.10-c). The text
  /// links to this platform's store listing ([AppConstants.storeListingUrl]);
  /// iOS shares the text without a link until the App Store id exists.
  Future<void> _share(TournamentModel tournament) async {
    final l10n = AppLocalizations.of(context)!;
    final link = AppConstants.storeListingUrl;
    final date = formatEventDate(tournament.startTime);
    final venue = tournament.venueName.isNotEmpty
        ? tournament.venueName
        : (tournament.city.isNotEmpty ? tournament.city : '—');
    final teams = l10n.teamsCount(tournament.totalTeams);
    final text = link.isEmpty
        ? l10n.shareEventText(tournament.title, date, venue, teams)
        : l10n.shareEventTextLink(tournament.title, date, venue, teams, link);

    final result = await SharePlus.instance.share(ShareParams(text: text));
    if (result.status == ShareResultStatus.unavailable && mounted) {
      showTandeToast(context, l10n.shareFailed, kind: ToastKind.error);
    }
  }

  String _registrationMessage(TournamentModel tournament, UserModel? player) {
    final name = player?.fullName.isNotEmpty == true
        ? player!.fullName
        : (player?.username ?? '');
    return '¡Hola! Me acabo de inscribir en "${tournament.title}" el '
        '${formatEventDate(tournament.startTime)}'
        '${name.isEmpty ? '' : ' ($name)'}. ¿Cómo coordino el pago?';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));
    final tournament = tournamentAsync.valueOrNull;

    return Scaffold(
      // Share sits in the app bar: sending an event to the team's group
      // chat is the product's growth loop (§4.10-c) — everyone in that
      // chat already has the problem the app solves.
      appBar: AppBar(
        actions: [
          if (tournament != null)
            IconButton(
              onPressed: () => _share(tournament),
              tooltip: l10n.shareEvent,
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: tournamentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.tournamentLoadError(error))),
        data: (tournament) {
          if (tournament == null) {
            return Center(child: Text(l10n.tournamentNotFound));
          }
          return _buildDetail(tournament);
        },
      ),
    );
  }

  Widget _buildDetail(TournamentModel tournament) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final organizer = ref
        .watch(organizerProvider(tournament.ownerId))
        .valueOrNull;
    final inscriptionAsync = ref.watch(myInscriptionProvider(tournament.id));
    final inscription = inscriptionAsync.valueOrNull;
    final session = ref.watch(authStateProvider);
    final player = ref.watch(currentProfileProvider).valueOrNull;

    final takenRatio = tournament.totalTeams <= 0
        ? 0.0
        : (tournament.totalConfirmed / tournament.totalTeams).clamp(0.0, 1.0);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero: one branded block instead of "banner + white header".
              // With a banner it is the photo under a scrim; without one it is
              // the brand gradient — never an empty green rectangle. The title
              // lives inside it, which is what makes the screen feel designed
              // rather than assembled from a stack of rows.
              _TournamentHero(
                tournament: tournament,
                sportLabel: l10n.sportLabel(tournament.sport),
                kindLabel: l10n.kindLabel(tournament.kind),
              ),
              const SizedBox(height: 16),

              // Key facts — two columns. Five stacked label/value rows read
              // like a settings screen; pairing them (fecha/formato,
              // costo/premios) halves the height and gives the block a
              // rhythm. Sede stays full width: it is the one value that wraps.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _InfoCell(
                                icon: Icons.calendar_today_outlined,
                                label: l10n.dateLabel,
                                value: formatEventDate(
                                  tournament.startTime,
                                  end: tournament.endTime,
                                ),
                              ),
                            ),
                            const _CellDivider(),
                            Expanded(
                              child: _InfoCell(
                                icon: Icons.groups_outlined,
                                label: l10n.formatLabel,
                                value:
                                    '${l10n.kindLabel(tournament.kind)} • '
                                    '${l10n.teamsCount(tournament.totalTeams)}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _RowDivider(),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _InfoCell(
                                icon: Icons.payments_outlined,
                                label: l10n.costLabel,
                                value: formatCost(
                                  tournament.inscriptionCost,
                                  freeLabel: l10n.free,
                                  currency: tournament.currency,
                                ),
                              ),
                            ),
                            const _CellDivider(),
                            Expanded(
                              child: _InfoCell(
                                icon: Icons.emoji_events_outlined,
                                label: l10n.prizesLabelShort,
                                value: tournament.prizes.isEmpty
                                    ? '—'
                                    : tournament.prizes,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _RowDivider(),
                      _InfoCell(
                        icon: Icons.location_on_outlined,
                        label: l10n.venueLabelShort,
                        value: tournament.venueName.isEmpty
                            ? tournament.city
                            : '${tournament.venueName}\n'
                                  '${tournament.address}, ${tournament.city}',
                      ),
                    ],
                  ),
                ),
              ),

              // Location preview
              if (tournament.location != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 160,
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: tournament.location!,
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            const BasemapLayer(),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: tournament.location!,
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.location_pin,
                                    size: 40,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          left: 6,
                          bottom: 4,
                          child: Text(
                            ref.watch(
                              mapAttributionProvider(
                                styleAssetFor(Theme.of(context).brightness),
                              ),
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Spots progress
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            tournament.isFull
                                ? l10n.tournamentStatus(TournamentStatus.full)
                                : l10n.spotsLeft(tournament.spotsLeft),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: tournament.isFull
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
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
                    ],
                  ),
                ),
              ),

              // About
              if (tournament.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.aboutTournament, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  tournament.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              // Organizer
              const SizedBox(height: 16),
              Text(l10n.organizerTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: Text(
                    organizer?.fullName.isNotEmpty == true
                        ? organizer!.fullName
                        : (organizer?.username ?? '…'),
                  ),
                  subtitle: Text(l10n.organizerTitle),
                  // The theme's FilledButton stretches to the full available
                  // width (Size.fromHeight) — constrain it inside the tile.
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: _contactAction(
                      tournament: tournament,
                      organizer: organizer,
                      session: session,
                      l10n: l10n,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        _bottomBar(
          tournament: tournament,
          session: session,
          inscription: inscription,
          inscriptionLoading: inscriptionAsync.isLoading,
          organizer: organizer,
          player: player,
        ),
      ],
    );
  }

  /// The organizer card's action, three states (§4.10-a):
  /// - a channel exists → contact (WhatsApp, or the sheet with the extras);
  /// - this is the owner without any channel → an *enabled* shortcut to
  ///   add one — a grey button with no explanation reads as a bug, and
  ///   the owner is the only one who can fix it;
  /// - a visitor with nothing to open → disabled, same as always.
  Widget _contactAction({
    required TournamentModel tournament,
    required UserModel? organizer,
    required AuthSession? session,
    required AppLocalizations l10n,
  }) {
    if (organizer != null && organizer.hasContactChannels) {
      return FilledButton.tonalIcon(
        onPressed: () =>
            _contactOrganizer(tournament: tournament, organizer: organizer),
        icon: Icon(
          organizer.hasExtraContactChannels
              ? Icons.forum_outlined
              : Icons.chat_bubble_outline,
          size: 18,
        ),
        label: Text(
          organizer.hasExtraContactChannels
              ? l10n.contactAction
              : l10n.contactWhatsApp,
        ),
      );
    }

    if (session?.userId == tournament.ownerId) {
      return FilledButton.tonalIcon(
        onPressed: () => context.push('/complete-profile'),
        icon: const Icon(Icons.add_ic_call_outlined, size: 18),
        label: Text(l10n.addContact),
      );
    }

    return FilledButton.tonalIcon(
      onPressed: null,
      icon: const Icon(Icons.chat_bubble_outline, size: 18),
      label: Text(l10n.contactWhatsApp),
    );
  }

  Widget _bottomBar({
    required TournamentModel tournament,
    required AuthSession? session,
    required InscriptionModel? inscription,
    required bool inscriptionLoading,
    required UserModel? organizer,
    required UserModel? player,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final Widget button;
    if (session == null) {
      button = FilledButton(
        onPressed: () => context.go('/login?from=/tournament/${tournament.id}'),
        child: Text(l10n.signInToRegister),
      );
    } else if (inscriptionLoading) {
      // Don't flash "Inscribirme" while the player's state resolves — a
      // confirmed player would see the register button flip instantly.
      button = FilledButton(
        onPressed: null,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (inscription?.isConfirmed ?? false) {
      button = FilledButton.tonalIcon(
        onPressed: null,
        icon: const Icon(Icons.check_circle),
        label: Text(l10n.registeredTitle),
      );
    } else if (inscription?.isPending ?? false) {
      button = OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_top),
        label: Text(l10n.awaitingConfirmation),
      );
    } else if (inscription?.isWaitlisted ?? false) {
      button = OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.people_outline),
        label: Text(l10n.waitlistedTitle),
      );
    } else if (tournament.status == TournamentStatus.closed) {
      button = FilledButton(
        onPressed: null,
        child: Text(l10n.registrationsClosedButton),
      );
    } else if (tournament.isFull) {
      // Full is no longer a dead end: the player can hold a place in line and
      // the oldest waitlisted row is promoted automatically when a spot frees.
      button = FilledButton.tonal(
        onPressed: _registering
            ? null
            : () => _startRegistration(
                tournament: tournament,
                organizer: organizer,
                player: player,
                waitlist: true,
              ),
        child: _registering
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l10n.joinWaitlist),
      );
    } else {
      button = FilledButton(
        onPressed: _registering
            ? null
            : () => _startRegistration(
                tournament: tournament,
                organizer: organizer,
                player: player,
              ),
        child: _registering
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l10n.registerButton),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (session != null &&
                !(inscription?.isConfirmed ?? false) &&
                !(inscription?.isPending ?? false) &&
                !(inscription?.isWaitlisted ?? false)) ...[
              Text(
                tournament.isFull ||
                        tournament.status == TournamentStatus.closed
                    ? l10n.noSpotsAvailable
                    : l10n.spotsLeft(tournament.spotsLeft),
                style: theme.textTheme.labelLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            button,
            if ((inscription?.isPending ?? false) ||
                (inscription?.isConfirmed ?? false) ||
                (inscription?.isWaitlisted ?? false)) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: _cancelling ? null : () => _cancel(inscription!),
                icon: _cancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.block, size: 18),
                label: Text(l10n.cancelRegistration),
              ),
            ],
            if (inscription?.isPending ?? false) ...[
              const SizedBox(height: 8),
              Text(
                l10n.paymentHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One fact in the grid: icon + label on the first line, value below.
///
/// The icon is small and quiet (`onSurfaceVariant`, 16) — in the old stacked
/// row it was 20 and `primary`, which made five primary-colored icons compete
/// with the one primary action on the screen.
class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(height: 1.3)),
      ],
    );
  }
}

/// Hairline between the grid's columns, stretching to the taller cell.
class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.6),
    );
  }
}

/// Hairline between the grid's rows.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
    );
  }
}

class _TournamentHero extends StatelessWidget {
  const _TournamentHero({
    required this.tournament,
    required this.sportLabel,
    required this.kindLabel,
  });

  final TournamentModel tournament;
  final String sportLabel;
  final String kindLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final banner = tournament.bannerPath;
    final hasBanner = banner != null && banner.isNotEmpty;
    const height = 208.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasBanner)
              TournamentBanner(
                tournament: tournament,
                height: height,
                radius: 0,
              )
            else ...[
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.brand),
              ),
              // Signature: the pitch drawn on the brand block — a centre
              // circle and the halfway line at 7% white, cropped by the card.
              // Without it the gradient reads as a flat dark rectangle.
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _PitchLines()),
                ),
              ),
            ],
            // Scrim only over a photo: the brand gradient is already dark
            // enough for white text, and a scrim on top of it flattens the
            // one brand asset the screen has.
            if (hasBanner)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x8A000000)],
                    stops: [0.30, 1.0],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Hero(
                    tag: 'sport-${tournament.id}',
                    child: SportSticker(
                      sport: tournament.sport,
                      size: 46,
                      onBrand: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Scoreboard: identity on the left, the one number that
                  // decides a tap on the right. A plain title block left the
                  // right half of the hero empty, which is what made it read
                  // as a decorative rectangle.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tournament.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _BrandTag(label: sportLabel),
                                _BrandTag(label: kindLabel),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _HeroStat(tournament: tournament),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small translucent pill for content sitting on the hero. Never a scheme
/// role: on a photo or the brand gradient those either disappear or clash.
class _BrandTag extends StatelessWidget {
  const _BrandTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Halfway line + centre circle, huge and cropped, at 7% white. Drawn instead
/// of an image so it scales with the hero and costs nothing.
class _PitchLines extends CustomPainter {
  const _PitchLines();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    // Halfway line off-centre to the right, so the block never looks split.
    final x = size.width * 0.62;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    canvas.drawCircle(Offset(x, size.height * 0.5), size.height * 0.55, paint);
    canvas.drawCircle(
      Offset(x, size.height * 0.5),
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The hero's right-hand number: spots left when open, otherwise the status
/// word. Reads like a scoreboard, which is the app's subject matter.
class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.tournament});

  final TournamentModel tournament;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = tournament;

    final isNumber = t.status != TournamentStatus.closed && !t.isFull;
    final value = t.status == TournamentStatus.closed
        ? l10n.tournamentStatus(TournamentStatus.closed)
        : t.isFull
        ? l10n.tournamentStatus(TournamentStatus.full)
        : '${t.spotsLeft}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style:
              (isNumber
                      ? theme.textTheme.displaySmall
                      : theme.textTheme.titleLarge)
                  ?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
          maxLines: 1,
        ),
        if (isNumber) ...[
          const SizedBox(height: 2),
          Text(
            l10n.spotsLeftLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ],
    );
  }
}
