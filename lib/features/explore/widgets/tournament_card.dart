import 'package:tande/core/sports.dart';
import 'package:tande/core/utils/format.dart';
import 'package:tande/core/widgets/tournament_banner.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/l10n/labels.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Event card shared by the list view and the map's marker sheet.
class TournamentCard extends StatelessWidget {
  const TournamentCard({
    super.key,
    required this.tournament,
    this.distanceKm,
    this.onTap,
  });

  final TournamentModel tournament;

  /// Distance from the user, shown top-right when known.
  final double? distanceKm;

  /// Defaults to opening the tournament detail screen.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = tournament;
    final accent = sportColor(t.sport);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push('/tournament/${t.id}'),
        child: Column(
          children: [
            // Full-bleed banner strip when the organizer uploaded one
            // (the Card's Clip.antiAlias rounds it); without it the card
            // is exactly the old single-row layout.
            if (t.bannerPath != null) TournamentBanner(tournament: t),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'sport-${t.id}',
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(sportIcon(t.sport), color: accent, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                t.title,
                                style: theme.textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (distanceKm != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                formatDistanceKm(distanceKm!),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                formatEventDate(t.startTime, end: t.endTime),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                t.venueName.isEmpty
                                    ? t.city
                                    : '${t.venueName} • ${t.city}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _SpotsBadge(tournament: t),
                            const SizedBox(width: 8),
                            Text(
                              formatCost(
                                t.inscriptionCost,
                                freeLabel: l10n.free,
                                currency: t.currency,
                              ),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

/// "4 lugares libres" / "Completo" / "Cerrado".
class _SpotsBadge extends StatelessWidget {
  const _SpotsBadge({required this.tournament});

  final TournamentModel tournament;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = tournament;

    final (
      Color background,
      Color foreground,
      String label,
    ) = t.status == TournamentStatus.closed
        ? (
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.onSurfaceVariant,
            l10n.tournamentStatus(TournamentStatus.closed),
          )
        : t.isFull
        ? (
            theme.colorScheme.errorContainer,
            theme.colorScheme.onErrorContainer,
            l10n.tournamentStatus(TournamentStatus.full),
          )
        : t.spotsLeft <= 3
        ? (
            theme.colorScheme.tertiaryContainer,
            theme.colorScheme.onTertiaryContainer,
            l10n.spotsLeft(t.spotsLeft),
          )
        : (
            theme.colorScheme.primaryContainer,
            theme.colorScheme.onPrimaryContainer,
            l10n.spotsLeft(t.spotsLeft),
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
