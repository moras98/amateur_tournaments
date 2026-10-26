import 'package:tande/data/repositories/providers.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The tournament's optional banner image, or nothing when the organizer
/// didn't add one (cards keep their compact sport-icon layout).
///
/// Shared by the Explore card, the map's marker sheet (via that card),
/// the organizer's event list and the detail screen.
class TournamentBanner extends ConsumerWidget {
  const TournamentBanner({
    super.key,
    required this.tournament,
    this.height = 96,
    this.radius = 12,
  });

  final TournamentModel tournament;

  /// Strip height. The detail screen uses a taller one.
  final double height;

  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = tournament.bannerPath;
    if (path == null || path.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final image = ref.watch(bannerStorageProvider).imageFor(path);
    // No Hero here on purpose: the shell keeps every tab alive in one
    // route (StatefulShellRoute.indexedStack), so the same tournament's
    // Explore card and organizer card — both showing the banner — would
    // collide on a shared tag. The sport-icon Hero stays unique to the
    // Explore card.
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image(
        image: image,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        // A deleted/failed object degrades to a neutral strip instead
        // of an error wall — the rest of the card stays usable.
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: SizedBox(height: height, width: double.infinity),
        ),
      ),
    );
  }
}
