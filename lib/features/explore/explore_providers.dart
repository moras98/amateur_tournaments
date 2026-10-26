import 'dart:async';

import 'package:tande/core/location/location_service.dart';
import 'package:tande/data/repositories/providers.dart';
import 'package:tande/data/repositories/tournament_repository.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Which view the Explore screen is showing.
enum ExploreView { map, list }

final exploreViewProvider = StateProvider<ExploreView>(
  (ref) => ExploreView.map,
);

/// Search text + filter selections for Explore.
class ExploreFilters {
  const ExploreFilters({
    this.text = '',
    this.sports,
    this.maxDistanceKm,
    this.onlyOpen = false,
  });

  /// Debounced search text (title, venue, city).
  final String text;

  /// Sport filter (multi-select).
  ///
  /// `null` = untouched: the signed-in profile's sports drive Explore (what
  /// the player picked at registration/profile edit). An empty list = every
  /// sport (explicit "Todos" / "Borrar filtros"). Anything else = the
  /// user's own selection, which stops the profile default from applying.
  final List<String>? sports;
  final double? maxDistanceKm;
  final bool onlyOpen;

  ExploreFilters copyWith({
    String? text,
    List<String>? sports,
    double? Function()? maxDistanceKm,
    bool? onlyOpen,
  }) {
    return ExploreFilters(
      text: text ?? this.text,
      sports: sports ?? this.sports,
      maxDistanceKm: maxDistanceKm != null
          ? maxDistanceKm()
          : this.maxDistanceKm,
      onlyOpen: onlyOpen ?? this.onlyOpen,
    );
  }
}

class ExploreFiltersController extends Notifier<ExploreFilters> {
  Timer? _debounce;

  @override
  ExploreFilters build() {
    ref.onDispose(() => _debounce?.cancel());
    return const ExploreFilters();
  }

  /// Debounced so typing doesn't refetch on every keystroke.
  void search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(text: value);
    });
  }

  /// Immediate search (keyboard submit, clear button).
  void searchNow(String value) {
    _debounce?.cancel();
    state = state.copyWith(text: value);
  }

  /// Applies the sport selection explicitly (multi-select) — from here on
  /// the profile default no longer drives Explore.
  void setSports(List<String> sports) => state = state.copyWith(sports: sports);

  void setMaxDistance(double? km) =>
      state = state.copyWith(maxDistanceKm: () => km);

  void setOnlyOpen(bool value) => state = state.copyWith(onlyOpen: value);

  /// Clears filters and the search text (empty-state "Borrar filtros").
  /// The sport filter widens to *every* sport: the escape hatch when the
  /// profile default leaves a town with nothing to show.
  void clearAll() {
    _debounce?.cancel();
    state = const ExploreFilters(sports: []);
  }

  /// Clears filters but keeps the search text (it has its own clear button).
  /// Sport-wise it clears to every sport, like [clearAll].
  void reset() {
    _debounce?.cancel();
    state = ExploreFilters(text: state.text, sports: const []);
  }
}

final exploreFiltersProvider =
    NotifierProvider<ExploreFiltersController, ExploreFilters>(
      ExploreFiltersController.new,
    );

/// Device position, or `null` when unavailable (denied, service off, tests).
final userLocationProvider = FutureProvider<LatLng?>((ref) {
  return LocationService().getCurrentLatLng();
});

/// Number of active Explore filters *as applied*, for the filter button's
/// badge: it counts the profile-derived sport default too — the badge has
/// to explain why results are already narrowed on a fresh open.
final exploreFilterCountProvider = Provider<int>((ref) {
  final filters = ref.watch(exploreFiltersProvider);
  final sports =
      filters.sports ??
      ref.watch(currentProfileProvider).valueOrNull?.sports ??
      const <String>[];
  return (sports.isNotEmpty ? 1 : 0) +
      (filters.maxDistanceKm != null ? 1 : 0) +
      (filters.onlyOpen ? 1 : 0);
});

/// The tournaments currently shown on Explore.
///
/// Re-runs when filters change or the device location arrives (which switches
/// sorting from date to distance).
final exploreResultsProvider = FutureProvider<List<TournamentModel>>((
  ref,
) async {
  final filters = ref.watch(exploreFiltersProvider);
  final location = ref.watch(userLocationProvider).valueOrNull;

  // Sport filter: an explicit selection, else the signed-in profile's
  // sports. The profile is awaited only while the default drives the query,
  // so a cold start runs one fetch already filtered (no pin flicker) — and
  // a broken profile degrades to "every sport" instead of erroring.
  var sports = filters.sports;
  if (sports == null) {
    try {
      final profile = await ref.watch(currentProfileProvider.future);
      sports = profile?.sports ?? const [];
    } catch (_) {
      sports = const [];
    }
  }

  return ref
      .watch(tournamentRepositoryProvider)
      .fetchTournaments(
        TournamentQuery(
          sports: sports,
          text: filters.text,
          near: location,
          onlyOpen: filters.onlyOpen,
          maxDistanceKm: filters.maxDistanceKm,
        ),
      );
});
