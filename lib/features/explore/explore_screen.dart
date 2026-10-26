import 'package:tande/core/utils/nav_geometry.dart';
import 'package:tande/core/widgets/search_capsule.dart';
import 'package:tande/features/explore/explore_providers.dart';
import 'package:tande/features/explore/widgets/filter_sheet.dart';
import 'package:tande/features/explore/widgets/tournament_list.dart';
import 'package:tande/features/explore/widgets/tournament_map.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Discovery screen: map with all events, toggleable list view,
/// debounced search and filters.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  /// Same window for the body's inset animation, so the list slides under
  /// the (stationary) capsule as the views swap.
  static const _rowTransition = Duration(milliseconds: 260);

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filter (with its badge) and the map/list toggle — the capsule's
  /// trailing controls in both views.
  List<Widget> _rowActions({
    required ExploreView view,
    required int filterCount,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return [
      IconButton(
        tooltip: l10n.filters,
        onPressed: () => showExploreFilters(context),
        icon: Badge(
          isLabelVisible: filterCount > 0,
          label: Text('$filterCount'),
          child: const Icon(Icons.tune),
        ),
      ),
      IconButton(
        tooltip: view == ExploreView.map ? l10n.switchToList : l10n.switchToMap,
        onPressed: () => ref.read(exploreViewProvider.notifier).state =
            view == ExploreView.map ? ExploreView.list : ExploreView.map,
        icon: Icon(
          view == ExploreView.map ? Icons.view_list : Icons.map_outlined,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Keeps the field in sync when filters are cleared elsewhere
    // (e.g. the empty state's "Borrar filtros"). While typing, the debounced
    // value always ends up equal to the field text, so this is a no-op.
    ref.listen(exploreFiltersProvider, (previous, next) {
      if (next.text != _searchController.text) {
        _searchController.text = next.text;
      }
    });

    final view = ref.watch(exploreViewProvider);
    final results = ref.watch(exploreResultsProvider);
    final location = ref.watch(userLocationProvider);
    final filterCount = ref.watch(exploreFilterCountProvider);
    final filtersNotifier = ref.read(exploreFiltersProvider.notifier);
    // System inset from *above* the Scaffold: the body has no app bar to
    // absorb it (the capsule paints/pads itself instead).
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      // No app bar in either view: the search row is always the same
      // rounded capsule (design.md §7) floating at the top. Map view is
      // full-bleed behind it; list view's content slides under it, clearing
      // the capsule's region.
      body: Stack(
        children: [
          AnimatedPadding(
            duration: _rowTransition,
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(
              top: view == ExploreView.list
                  ? topInset + kNavCapsuleRegionHeight
                  : 0,
            ),
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.exploreLoadError),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.invalidate(exploreResultsProvider),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
              data: (tournaments) {
                // Map states: wait for the device location (the map never
                // preloads a hardcoded city), then frame the user or, without
                // one, the pins themselves — and ask to retry when there is
                // nothing at all to frame.
                final Widget mapChild;
                final user = location.valueOrNull;
                if (location.isLoading && !location.hasValue) {
                  mapChild = const Center(
                    key: ValueKey('map-loading'),
                    child: CircularProgressIndicator(),
                  );
                } else if (user == null &&
                    !tournaments.any((t) => t.location != null)) {
                  mapChild = _NoLocationPrompt(
                    key: const ValueKey('map-no-location'),
                    onRetry: () => ref.invalidate(userLocationProvider),
                  );
                } else {
                  mapChild = TournamentMap(
                    key: const ValueKey('map'),
                    tournaments: tournaments,
                    userLocation: user,
                  );
                }
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.025),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: view == ExploreView.map
                      ? mapChild
                      : TournamentList(
                          key: const ValueKey('list'),
                          tournaments: tournaments,
                          userLocation: user,
                        ),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SearchCapsule(
              key: const ValueKey('search-capsule'),
              controller: _searchController,
              hintText: l10n.searchHint,
              onChanged: filtersNotifier.search,
              onSubmitted: filtersNotifier.searchNow,
              actions: _rowActions(view: view, filterCount: filterCount),
            ),
          ),
        ],
      ),
    );
  }
}

/// Map placeholder when the device location is unavailable and there are no
/// pins to frame: asking for the permission again is the only way to a map,
/// so none is mounted (and no tiles are wasted).
class _NoLocationPrompt extends StatelessWidget {
  const _NoLocationPrompt({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noLocationTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noLocationBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.my_location),
              label: Text(l10n.useMyLocation),
            ),
          ],
        ),
      ),
    );
  }
}
