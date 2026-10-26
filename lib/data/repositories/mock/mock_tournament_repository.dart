import 'package:bracket/data/repositories/mock/mock_store.dart';
import 'package:bracket/data/repositories/tournament_repository.dart';
import 'package:bracket/models/tournament_model.dart';
import 'package:latlong2/latlong.dart';

/// In-memory [TournamentRepository] backed by [MockStore].
class MockTournamentRepository implements TournamentRepository {
  MockTournamentRepository([MockStore? store]) : _store = store ?? MockStore();

  final MockStore _store;

  @override
  Future<List<TournamentModel>> fetchTournaments(TournamentQuery query) async {
    var results = List<TournamentModel>.of(_store.tournaments);

    // Server parity (audit 4.8): Explore only shows what hasn't ended —
    // `fetchByOwner` keeps the organizer's full history.
    final now = DateTime.now();
    results = results.where((t) => !t.endTime.isBefore(now)).toList();

    final sports = query.sports;
    if (sports.isNotEmpty) {
      results = results.where((t) => sports.contains(t.sport)).toList();
    }

    final city = query.city;
    if (city != null && city.isNotEmpty) {
      results = results
          .where((t) => t.city.toLowerCase() == city.toLowerCase())
          .toList();
    }

    final text = query.text?.trim().toLowerCase();
    if (text != null && text.isNotEmpty) {
      results = results
          .where(
            (t) =>
                t.title.toLowerCase().contains(text) ||
                t.venueName.toLowerCase().contains(text) ||
                t.city.toLowerCase().contains(text),
          )
          .toList();
    }

    if (query.onlyOpen) {
      results = results.where((t) => t.isOpen).toList();
    }

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
          }).toList()..sort((a, b) {
            final da = a.distanceKmFrom(near) ?? double.infinity;
            final db = b.distanceKmFrom(near) ?? double.infinity;
            return da.compareTo(db);
          });
    } else {
      results.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return results;
  }

  @override
  Future<TournamentModel?> fetchById(String id) async =>
      _store.tournamentById(id);

  @override
  Future<List<TournamentModel>> fetchByOwner(String ownerId) async {
    final results =
        _store.tournaments.where((t) => t.ownerId == ownerId).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return results;
  }

  @override
  Future<TournamentModel> create(TournamentModel tournament) async {
    // New events come without an id (the repository assigns it — the mock
    // uses sequential ids, Supabase would use its uuid default).
    final created = tournament.id.isEmpty
        ? tournament.copyWith(
            id: _store.nextId('t'),
            createdAt: () => DateTime.now(),
          )
        : tournament.copyWith(
            createdAt: () => tournament.createdAt ?? DateTime.now(),
          );
    _store.tournaments.add(created);
    _store.bump();
    return created;
  }

  @override
  Future<TournamentModel> update(TournamentModel tournament) async {
    // Callers pass a model fetched earlier: the confirmed count is
    // authoritative on the stored row (Supabase's payload never includes
    // it), so keep it instead of writing back a stale value. The manual
    // off-app count is only written through setManualConfirmed.
    final stored = _store.tournamentById(tournament.id);
    final merged = stored == null
        ? tournament
        : tournament.copyWith(
            confirmedTeams: stored.confirmedTeams,
            manualConfirmed: stored.manualConfirmed,
          );
    _store.replaceTournament(merged);
    return merged;
  }

  @override
  Future<void> setManualConfirmed(
    TournamentModel tournament,
    int amount,
  ) async {
    // Same care as update(): the app-confirmed count is authoritative on
    // the stored row; only the manual slice changes — plus the open/full
    // flip that follows it (mirroring the DB's sync_tournament_status).
    final stored = _store.tournamentById(tournament.id);
    if (stored == null) return;
    final manual = amount < 0 ? 0 : amount;
    final total = stored.confirmedTeams + manual;
    final status = stored.status == TournamentStatus.closed
        ? stored.status
        : total >= stored.totalTeams
        ? TournamentStatus.full
        : TournamentStatus.open;
    _store.replaceTournament(
      stored.copyWith(manualConfirmed: manual, status: status),
    );
    _store.bump();
  }

  @override
  Future<void> delete(String id) async {
    _store.tournaments.removeWhere((t) => t.id == id);
    // Mirrors the FK's `on delete cascade`.
    _store.inscriptions.removeWhere((i) => i.tournamentId == id);
    _store.bump();
  }
}

/// Applies an inscriptions-change to a tournament's confirmed count.
/// Shared by the mock inscription repository.
void applyConfirmedDelta(MockStore store, String tournamentId, int delta) {
  final tournament = store.tournamentById(tournamentId);
  if (tournament == null) return;

  // Lower bound only: clamping to totalTeams would corrupt the count when
  // capacity was lowered below the confirmed rows (Supabase recomputes
  // from rows and never caps).
  var confirmed = tournament.confirmedTeams + delta;
  if (confirmed < 0) confirmed = 0;
  // Capacity counts app rows + the organizer's off-app manual count.
  final total = confirmed + tournament.manualConfirmed;
  var status = tournament.status;
  if (total >= tournament.totalTeams && status == TournamentStatus.open) {
    status = TournamentStatus.full;
  } else if (total < tournament.totalTeams && status == TournamentStatus.full) {
    status = TournamentStatus.open;
  }

  store.replaceTournament(
    tournament.copyWith(confirmedTeams: confirmed, status: status),
  );
}

/// Distance helper reused by explore queries.
double? distanceBetween(LatLng? a, LatLng? b) {
  if (a == null || b == null) return null;
  return const Distance().as(LengthUnit.Kilometer, a, b);
}
