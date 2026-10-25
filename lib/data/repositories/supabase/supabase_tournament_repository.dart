import 'package:bracket/data/repositories/tournament_repository.dart';
import 'package:bracket/models/tournament_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-backed tournaments (`public.tournaments` + the `spots_left`
/// view). Selected by the providers once `AppConstants.hasSupabase` is true.
class SupabaseTournamentRepository implements TournamentRepository {
  SupabaseTournamentRepository(this._client);

  final SupabaseClient _client;

  /// Plain tournament columns. The confirmed count comes from the
  /// `spots_left` view in a separate query ([_confirmedCounts]) — never
  /// embedded as `spots_left(confirmed_teams)`: PostgREST only embeds a
  /// *view* through schema-cache foreign-key inference, which fails live
  /// with PGRST200 ("Could not find a relationship between 'tournaments'
  /// and 'spots_left'"). An explicit query is deterministic.
  static const _select = '*';

  @override
  Future<List<TournamentModel>> fetchTournaments(TournamentQuery query) async {
    var request = _client.from('tournaments').select(_select);

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

    final rows = await request.order('start_time');
    final counts = await _confirmedCounts(
      rows.map((row) => row['id'] as String),
    );
    var results = rows.map((row) => _fromRow(row, counts)).toList();

    // Distance sorting/filtering happens client-side (mock parity); a
    // PostGIS `order by location <->` RPC is the upgrade path.
    final near = query.near;
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
    // RLS restricts this to the owner; inscriptions cascade in the DB.
    await _client.from('tournaments').delete().eq('id', id);
  }

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
