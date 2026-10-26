import 'dart:typed_data';

import 'package:tande/models/tournament_model.dart';
import 'package:latlong2/latlong.dart';

/// Filter/sort options shared by map and list views.
class TournamentQuery {
  const TournamentQuery({
    this.sports = const [],
    this.text,
    this.city,
    this.near,
    this.onlyOpen = false,
    this.maxDistanceKm,
  });

  /// Filter by sport (`football`, `padel`, ...); empty = every sport.
  final List<String> sports;

  /// Free-text search over title, venue and city.
  final String? text;

  /// Exact city filter.
  final String? city;

  /// When set, results are sorted by distance from this point.
  final LatLng? near;

  /// Only tournaments with spots left and status `open`.
  final bool onlyOpen;

  /// Drop results farther than this from [near].
  final double? maxDistanceKm;

  TournamentQuery copyWith({
    List<String>? sports,
    String? Function()? text,
    String? Function()? city,
    LatLng? Function()? near,
    bool? onlyOpen,
    double? Function()? maxDistanceKm,
  }) {
    return TournamentQuery(
      sports: sports ?? this.sports,
      text: text != null ? text() : this.text,
      city: city != null ? city() : this.city,
      near: near != null ? near() : this.near,
      onlyOpen: onlyOpen ?? this.onlyOpen,
      maxDistanceKm: maxDistanceKm != null
          ? maxDistanceKm()
          : this.maxDistanceKm,
    );
  }
}

/// Reads and writes tournaments.
///
/// Supabase implementation: `SupabaseTournamentRepository`;
/// mock: `MockTournamentRepository`.
abstract class TournamentRepository {
  Future<List<TournamentModel>> fetchTournaments(TournamentQuery query);

  Future<TournamentModel?> fetchById(String id);

  /// Tournaments owned by [ownerId] (organizer's "my events").
  Future<List<TournamentModel>> fetchByOwner(String ownerId);

  Future<TournamentModel> create(TournamentModel tournament);

  Future<TournamentModel> update(TournamentModel tournament);

  /// Sets how many teams were confirmed off the app for [tournament]
  /// (players who paid/confirmed outside the platform and never filed an
  /// inscription here). The displayed confirmed total is
  /// `confirmedTeams` (app rows) + this count. Owner-only; the generic
  /// [update] never writes it.
  Future<void> setManualConfirmed(TournamentModel tournament, int amount);

  /// Deletes an event and its inscriptions (owner only; RLS enforces it).
  /// The stored banner object, if any, is removed with it.
  Future<void> delete(String id);

  /// Stores the optional banner image for [tournamentId]; returns the path
  /// for `TournamentModel.bannerPath` (the caller persists it through
  /// [create]/[update]). Replaces any previous banner.
  Future<String> uploadBanner(String tournamentId, Uint8List bytes);

  /// Deletes the banner object at [path] — called once the row stopped
  /// pointing at it ([update] with `bannerPath: () => null`).
  Future<void> removeBanner(String path);
}
