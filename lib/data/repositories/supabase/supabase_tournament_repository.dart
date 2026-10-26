import 'dart:math';
import 'dart:typed_data';

import 'package:tande/data/repositories/tournament_repository.dart';
import 'package:tande/data/storage/banner_storage.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-backed tournaments (`public.tournaments` + the `spots_left`
/// view). Selected by the providers once `AppConstants.hasSupabase` is true.
class SupabaseTournamentRepository implements TournamentRepository {
  SupabaseTournamentRepository(this._client, {BannerStorage? banners})
    : _banners = banners ?? SupabaseBannerStorage(_client);

  final SupabaseClient _client;
  final BannerStorage _banners;

  /// Plain tournament columns. The confirmed count comes from the
  /// `spots_left` view in a separate query ([_confirmedCounts]) — never
  /// embedded as `spots_left(confirmed_teams)`: PostgREST only embeds a
  /// *view* through schema-cache foreign-key inference, which fails live
  /// with PGRST200 ("Could not find a relationship between 'tournaments'
  /// and 'spots_left'"). An explicit query is deterministic.
  static const _select = '*';

  /// Cap for one Explore fetch. PostgREST cuts any response at 1000 rows,
  /// and the distance filter/sort runs client-side: without an explicit
  /// limit, a growing table hands each user an arbitrary slice ordered by
  /// date — never the nearby events the screen promises, and with no error
  /// to say so. 200 rows by start_time (indexed since 0002) keeps the page
  /// bounded; a PostGIS `order by location <->` RPC remains the upgrade
  /// path for true distance ordering.
  static const exploreLimit = 200;

  @override
  Future<List<TournamentModel>> fetchTournaments(TournamentQuery query) async {
    // Only what's still running or upcoming: past events drop out of
    // Explore. `fetchByOwner` deliberately doesn't filter — the organizer
    // keeps their history.
    var request = _client
        .from('tournaments')
        .select(_select)
        .gte('end_time', DateTime.now().toUtc().toIso8601String());

    final sports = query.sports;
    if (sports.isNotEmpty) {
      request = request.inFilter('sport', sports);
    }
    final city = query.city;
    if (city != null && city.isNotEmpty) {
      request = request.ilike('city', _escapeLike(city));
    }
    final text = query.text?.trim();
    if (text != null && text.isNotEmpty) {
      final pattern = _escapeLike(text);
      request = request.or(
        'title.ilike.%$pattern%,'
        'venue_name.ilike.%$pattern%,'
        'city.ilike.%$pattern%',
      );
    }

    // Radius search → server-side bounding box circumscribing the radius
    // ([boundingBox]): the rows that arrive are the ones that *can* be in
    // range (indexes in migration 0008), instead of an arbitrary table
    // slice. Only when a radius is actually set — with "any distance" a
    // box would hide the city/text searches that legitimately reach far.
    // The exact circle still filters client-side (mock parity), so the
    // box only has to contain it, never match it.
    final near = query.near;
    final maxKm = query.maxDistanceKm;
    if (near != null && maxKm != null) {
      final box = boundingBox(near, maxKm);
      request = request
          .gte('latitude', box.latMin)
          .lte('latitude', box.latMax)
          .gte('longitude', box.lonMin)
          .lte('longitude', box.lonMax);
    }

    final rows = await request.order('start_time').limit(exploreLimit);
    final counts = await _confirmedCounts(
      rows.map((row) => row['id'] as String),
    );
    var results = rows.map((row) => _fromRow(row, counts)).toList();

    // Distance sorting/filtering happens client-side (mock parity) on top
    // of the server-side box above; a PostGIS `order by location <->` RPC
    // is the upgrade path.
    if (near != null) {
      results =
          results.where((t) {
            final distance = t.distanceKmFrom(near);
            final max = query.maxDistanceKm;
            // Location-less events only survive the "any distance" filter —
            // otherwise they'd sneak past the radius with no distance shown.
            if (distance == null) return max == null;
            return max == null || distance <= max;
          }).toList()..sort(
            (a, b) => (a.distanceKmFrom(near) ?? double.infinity).compareTo(
              b.distanceKmFrom(near) ?? double.infinity,
            ),
          );
    }

    if (query.onlyOpen) {
      results = results.where((t) => t.isOpen).toList();
    }
    return results;
  }

  /// Axis-aligned lat/lon box that fully contains the circle of
  /// [radiusKm] around [center] — the server-side pre-filter for a radius
  /// search (see [fetchTournaments]).
  ///
  /// Latitude uses a deliberately conservative km-per-degree (the real
  /// figure wobbles around 111.3): a box even slightly too small would
  /// drop in-range events before the client-side circle filter could keep
  /// them. The longitude half-width divides by cos of the *poleward* edge
  /// latitude, where a degree of longitude is shortest — that's where the
  /// circle bulges widest in longitude.
  static ({double latMin, double latMax, double lonMin, double lonMax})
  boundingBox(LatLng center, double radiusKm) {
    const kmPerDegree = 110.5;
    final dLat = radiusKm / kmPerDegree;
    final edgeCos = cos(
      (center.latitude.abs() + dLat) * pi / 180,
    ).clamp(0.05, 1.0);
    final dLon = radiusKm / (kmPerDegree * edgeCos);
    return (
      latMin: center.latitude - dLat,
      latMax: center.latitude + dLat,
      lonMin: center.longitude - dLon,
      lonMax: center.longitude + dLon,
    );
  }

  @override
  Future<TournamentModel?> fetchById(String id) async {
    final row = await _client
        .from('tournaments')
        .select(_select)
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return _fromSingle(row);
  }

  @override
  Future<List<TournamentModel>> fetchByOwner(String ownerId) async {
    final rows = await _client
        .from('tournaments')
        .select(_select)
        .eq('owner_id', ownerId)
        .order('start_time');
    final counts = await _confirmedCounts(
      rows.map((row) => row['id'] as String),
    );
    return rows.map((row) => _fromRow(row, counts)).toList();
  }

  @override
  Future<TournamentModel> create(TournamentModel tournament) async {
    final json = _payload(tournament);
    if (tournament.id.isEmpty) json.remove('id');
    final row = await _client
        .from('tournaments')
        .insert(json)
        .select(_select)
        .single();
    return _fromSingle(row);
  }

  @override
  Future<TournamentModel> update(TournamentModel tournament) async {
    final json = _payload(tournament)
      // Ownership, creation time and the off-app manual count never
      // change through the generic update: only setManualConfirmed
      // writes it (a stale screen can't clobber newer taps).
      ..remove('id')
      ..remove('owner_id')
      ..remove('manual_confirmed');
    final row = await _client
        .from('tournaments')
        .update(json)
        .eq('id', tournament.id)
        .select(_select)
        .single();
    return _fromSingle(row);
  }

  @override
  Future<void> setManualConfirmed(
    TournamentModel tournament,
    int amount,
  ) async {
    // Only the manual column: the app-confirmed count is derived (the
    // spots_left view) and the update RLS policy scopes this to the owner.
    // The DB trigger re-syncs open/full from inscriptions + manual count.
    await _client
        .from('tournaments')
        .update({'manual_confirmed': amount < 0 ? 0 : amount})
        .eq('id', tournament.id)
        .eq('owner_id', tournament.ownerId);
  }

  @override
  Future<void> delete(String id) async {
    final row = await _client
        .from('tournaments')
        .select('banner_path')
        .eq('id', id)
        .maybeSingle();
    // The banner object goes before the row: the storage delete policy
    // checks the caller owns the tournament by folder id, which stops
    // holding the moment the row is gone.
    final bannerPath = row?['banner_path'] as String?;
    if (bannerPath != null) await _banners.remove(bannerPath);
    // RLS restricts this to the owner; inscriptions cascade in the DB.
    await _client.from('tournaments').delete().eq('id', id);
  }

  @override
  Future<String> uploadBanner(String tournamentId, Uint8List bytes) =>
      _banners.upload(tournamentId: tournamentId, bytes: bytes);

  @override
  Future<void> removeBanner(String path) => _banners.remove(path);

  Map<String, dynamic> _payload(TournamentModel tournament) {
    // Plain `latitude`/`longitude` columns (no PostGIS dependency);
    // `created_at` is managed by the database.
    return tournament.toJson()..remove('created_at');
  }

  /// Confirmed inscription rows per tournament, straight from the view —
  /// one batched query per fetch. The view counts *app rows only*;
  /// `manualConfirmed` rides along in the `*` columns and the model sums
  /// both into `totalConfirmed`.
  Future<Map<String, int>> _confirmedCounts(Iterable<String> ids) async {
    final idList = ids.toList();
    if (idList.isEmpty) return const {};
    final rows = await _client
        .from('spots_left')
        .select('tournament_id, confirmed_teams')
        .inFilter('tournament_id', idList);
    return {
      for (final row in rows)
        row['tournament_id'] as String:
            (row['confirmed_teams'] as num?)?.toInt() ?? 0,
    };
  }

  Future<TournamentModel> _fromSingle(Map<String, dynamic> row) async {
    final counts = await _confirmedCounts([row['id'] as String]);
    return _fromRow(row, counts);
  }

  TournamentModel _fromRow(Map<String, dynamic> row, Map<String, int> counts) {
    final tournament = TournamentModel.fromJson(row);
    return tournament.copyWith(confirmedTeams: counts[tournament.id] ?? 0);
  }

  String _escapeLike(String value) {
    // PostgREST uses `,` `(` `)` as `or=` grammar and `:` as a filter
    // separator: strip them or a search like "Copa (7v7)" fails the whole
    // query with a 400 (PGRST102).
    final sanitized = value.replaceAll(RegExp(r'[,():]'), ' ');
    return sanitized.replaceAll('%', r'\%').replaceAll('_', r'\_');
  }
}
