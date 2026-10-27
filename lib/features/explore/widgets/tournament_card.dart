import 'package:tande/core/utils/format.dart';
import 'package:tande/core/widgets/sport_sticker.dart';
import 'package:tande/core/widgets/tournament_banner.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/l10n/labels.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Event card shared by the list view and the map's marker sheet.
///
/// Layout is deliberately **two columns**, not a stack of rows: what the eye
/// needs first is *which* tournament and *how much / how many spots left*, so
/// the left column carries identity (sport sticker + title + when/where) and
/// the right column carries the two numbers that decide a tap. Material's
/// default list item puts everything in one column, which leaves half the card
/// empty and buries the price next to a badge.
class TournamentCard extends StatelessWidget {
  const TournamentCard({
    super.key,
    required this.tournament,
    this.distanceKm,
    this.onTap,
  });

  final TournamentModel tournament;

  /// Distance from the user, folded into the date line when known.
  final double? distanceKm;

  /// Defaults to opening the tournament detail screen.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = tournament;

    final when = formatEventDate(t.startTime, end: t.endTime);
    final whenLine = distanceKm == null
        ? when
        : '$when  •  ${formatDistanceKm(distanceKm!)}';
    // City first: on a narrow card the venue truncates, and for a discovery
    // app the city is the information that must survive.
    final where = t.venueName.isEmpty ? t.city : '${t.city} • ${t.venueName}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push('/tournament/${t.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full-bleed banner strip when the organizer uploaded one (the
            // Card's Clip.antiAlias rounds it). Without one the card starts
            // straight at the content — no placeholder strip.
            if (t.bannerPath != null)
              TournamentBanner(tournament: t, radius: 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'sport-${t.id}',
                    child: SportSticker(sport: t.sport),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        _MetaLine(icon: Icons.schedule_rounded, text: whenLine),
                        if (where.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          _MetaLine(icon: Icons.place_outlined, text: where),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // The decision column: price, then how many spots are left.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCost(
                          t.inscriptionCost,
                          freeLabel: l10n.free,
                          currency: t.currency,
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _SpotsBadge(tournament: t),
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

/// `icon · text` on one line, truncated — the card's only two meta rows.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
