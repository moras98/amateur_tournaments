import 'package:tande/core/map/tile_provider.dart';
import 'package:tande/core/sports.dart';
import 'package:tande/core/theme/adaptive.dart';
import 'package:tande/core/utils/contact.dart';
import 'package:tande/core/utils/format.dart';
import 'package:tande/core/widgets/tournament_banner.dart';
import 'package:tande/data/auth/auth_repository.dart';
import 'package:tande/data/repositories/providers.dart';
import 'package:tande/features/explore/explore_providers.dart';
import 'package:tande/features/inscriptions/inscriptions_providers.dart';
import 'package:tande/features/organizer/organizer_providers.dart';
import 'package:tande/features/tournament/tournament_providers.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/l10n/labels.dart';
import 'package:tande/models/inscription_model.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:tande/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  Future<void> _register({
    required TournamentModel tournament,
    UserModel? organizer,
    UserModel? player,
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
            teamName: player?.fullName ?? '',
          );
      container
        ..invalidate(myInscriptionProvider(tournament.id))
        // The list tab caches its result — refresh it or a previously
        // visited "Mis inscripciones" keeps showing the pre-signup state.
        ..invalidate(myInscriptionsProvider)
        // The organizer's event card shows a pending-requests badge.
        ..invalidate(tournamentInscriptionsProvider(tournament.id));

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.registerError(error))));
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
      container
        ..invalidate(myInscriptionProvider(widget.tournamentId))
        ..invalidate(tournamentProvider(widget.tournamentId))
        ..invalidate(myInscriptionsProvider)
        ..invalidate(tournamentInscriptionsProvider(widget.tournamentId))
        ..invalidate(exploreResultsProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.registrationCancelled)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.cancelError(error))));
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
    final opened = await openWhatsApp(
      phone: organizer.phone,
      message: '¡Hola! Tengo una consulta sobre "${tournament.title}".',
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.whatsappOpenFailed(organizer.phone))),
      );
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

    return Scaffold(
      appBar: AppBar(),
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
              // Banner (when the organizer uploaded one): flies in from
              // the Explore card's strip through the shared Hero tag.
              if (tournament.bannerPath != null) ...[
                TournamentBanner(
                  tournament: tournament,
                  height: 160,
                  radius: 16,
                ),
                const SizedBox(height: 16),
              ],

              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'sport-${tournament.id}',
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sportColor(
                          tournament.sport,
                        ).withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        sportIcon(tournament.sport),
                        color: sportColor(tournament.sport),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.title,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _Tag(label: l10n.sportLabel(tournament.sport)),
                            _Tag(label: l10n.kindLabel(tournament.kind)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Key facts
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: l10n.dateLabel,
                        value: formatEventDate(
                          tournament.startTime,
                          end: tournament.endTime,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: l10n.venueLabelShort,
                        value: tournament.venueName.isEmpty
                            ? tournament.city
                            : '${tournament.venueName}\n'
                                  '${tournament.address}, ${tournament.city}',
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.payments_outlined,
                        label: l10n.costLabel,
                        value: formatCost(
                          tournament.inscriptionCost,
                          freeLabel: l10n.free,
                          currency: tournament.currency,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.emoji_events_outlined,
                        label: l10n.prizesLabelShort,
                        value: tournament.prizes.isEmpty
                            ? '—'
                            : tournament.prizes,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.groups_outlined,
                        label: l10n.formatLabel,
                        value:
                            '${l10n.kindLabel(tournament.kind)} • '
                            '${l10n.teamsCount(tournament.totalTeams)}',
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
                            TileLayer(
                              urlTemplate: osmTileUrl,
                              userAgentPackageName: 'com.tande.app',
                              tileProvider: ref.watch(tileProviderProvider),
                            ),
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
                            '© OpenStreetMap',
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
                    child: FilledButton.tonalIcon(
                      onPressed: (organizer != null && organizer.canBeContacted)
                          ? () => _contactOrganizer(
                              tournament: tournament,
                              organizer: organizer,
                            )
                          : null,
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('WhatsApp'),
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
    } else if (tournament.status == TournamentStatus.closed) {
      button = FilledButton(
        onPressed: null,
        child: Text(l10n.registrationsClosedButton),
      );
    } else if (tournament.isFull) {
      button = FilledButton(onPressed: null, child: Text(l10n.tournamentFull));
    } else {
      button = FilledButton(
        onPressed: _registering
            ? null
            : () => _register(
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
                !(inscription?.isPending ?? false)) ...[
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
                (inscription?.isConfirmed ?? false)) ...[
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}
