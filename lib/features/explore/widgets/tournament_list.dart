import 'package:tande/core/utils/nav_geometry.dart';
import 'package:tande/core/widgets/animate_in.dart';
import 'package:tande/features/explore/explore_providers.dart';
import 'package:tande/features/explore/widgets/tournament_card.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:tande/core/widgets/tande_empty_state.dart';

/// Search-result list with pull-to-refresh and an empty state.
class TournamentList extends ConsumerWidget {
  const TournamentList({
    super.key,
    required this.tournaments,
    this.userLocation,
  });

  final List<TournamentModel> tournaments;
  final LatLng? userLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tournaments.isEmpty) {
      return _EmptyResults(
        onClearFilters: () =>
            ref.read(exploreFiltersProvider.notifier).clearAll(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // A fresh GPS fix too: the first one may have been denied or stale
        // (e.g. the app was outdoors with the service off).
        ref.invalidate(userLocationProvider);
        await ref.read(userLocationProvider.future);
        ref.invalidate(exploreResultsProvider);
        await ref.read(exploreResultsProvider.future);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        // The list scrolls behind the floating nav capsule on the map tab,
        // so its last card must be able to clear the bar.
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24 + navBarClearanceOf(context),
        ),
        itemCount: tournaments.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tournament = tournaments[index];
          // Staggered fade-in entrance (capped so long lists don't wait).
          return AnimateIn(
            delay: Duration(milliseconds: 50 * index.clamp(0, 6)),
            child: TournamentCard(
              tournament: tournament,
              distanceKm: tournament.distanceKmFrom(userLocation),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.onClearFilters});

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TandeEmptyState(
      icon: Icons.search_off_rounded,
      title: l10n.noTournaments,
      body: l10n.noTournamentsBody,
      action: TextButton(
        onPressed: onClearFilters,
        child: Text(l10n.clearFilters),
      ),
    );
  }
}
