import 'package:tande/data/repositories/inscription_repository.dart';
import 'package:tande/data/repositories/mock/mock_store.dart';
import 'package:tande/data/repositories/mock/mock_tournament_repository.dart';
import 'package:tande/models/inscription_model.dart';
import 'package:tande/models/tournament_model.dart';

/// In-memory [InscriptionRepository] backed by [MockStore].
///
/// Note: the seeded inscriptions are only a recent sample. The authoritative
/// confirmed count lives on the tournament (mirrors the `spots_left` view),
/// so [countConfirmed] reads from there.
class MockInscriptionRepository implements InscriptionRepository {
  MockInscriptionRepository([MockStore? store]) : _store = store ?? MockStore();

  final MockStore _store;

  @override
  Future<List<InscriptionModel>> fetchForPlayer(String playerId) async {
    final results =
        _store.inscriptions.where((i) => i.playerId == playerId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Future<List<InscriptionModel>> fetchForTournament(String tournamentId) async {
    final results =
        _store.inscriptions
            .where((i) => i.tournamentId == tournamentId)
            .map((i) => _withPlayer(i))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return results;
  }

  @override
  Future<InscriptionModel?> fetchForPlayerAndTournament({
    required String playerId,
    required String tournamentId,
  }) async {
    for (final inscription in _store.inscriptions) {
      if (inscription.playerId == playerId &&
          inscription.tournamentId == tournamentId) {
        return _withPlayer(inscription);
      }
    }
    return null;
  }

  @override
  Future<InscriptionModel> create({
    required String tournamentId,
    required String playerId,
    String teamName = '',
    String note = '',
    bool waitlist = false,
  }) async {
    final target = waitlist
        ? InscriptionStatus.waitlisted
        : InscriptionStatus.pending;
    final existingIndex = _store.inscriptions.indexWhere(
      (i) => i.playerId == playerId && i.tournamentId == tournamentId,
    );
    if (existingIndex >= 0) {
      final existing = _store.inscriptions[existingIndex];
      if (existing.status == InscriptionStatus.pending ||
          existing.status == InscriptionStatus.confirmed ||
          existing.status == InscriptionStatus.waitlisted) {
        return _withPlayer(existing);
      }
      // Rejected or cancelled: the player may request again — the row is
      // reactivated (mirrors the unique tournament/player constraint).
      final reactivated = InscriptionModel(
        id: existing.id,
        tournamentId: tournamentId,
        playerId: playerId,
        status: target,
        teamName: teamName,
        note: note,
        createdAt: DateTime.now(),
        player: existing.player,
      );
      _store.inscriptions[existingIndex] = reactivated;
      _store.bump();
      return _withPlayer(reactivated);
    }

    final inscription = InscriptionModel(
      // Collision-guarded by MockStore (a private counter would restart at
      // 'i-100' per instance and duplicate seeded-runtime ids).
      id: _store.nextId('i'),
      tournamentId: tournamentId,
      playerId: playerId,
      status: target,
      teamName: teamName,
      note: note,
      createdAt: DateTime.now(),
    );
    _store.inscriptions.add(inscription);
    _store.bump();
    return inscription;
  }

  @override
  Future<InscriptionModel> decide({
    required String inscriptionId,
    required InscriptionStatus status,
  }) async {
    InscriptionModel? updated;
    for (var i = 0; i < _store.inscriptions.length; i++) {
      final inscription = _store.inscriptions[i];
      if (inscription.id != inscriptionId) continue;

      final wasConfirmed = inscription.isConfirmed;
      final willConfirm = status == InscriptionStatus.confirmed;

      updated = InscriptionModel(
        id: inscription.id,
        tournamentId: inscription.tournamentId,
        playerId: inscription.playerId,
        status: status,
        teamName: inscription.teamName,
        note: inscription.note,
        createdAt: inscription.createdAt,
        confirmedAt: willConfirm
            ? (inscription.confirmedAt ?? DateTime.now())
            : null,
        player: inscription.player,
      );
      _store.inscriptions[i] = updated;

      if (!wasConfirmed && willConfirm) {
        applyConfirmedDelta(_store, inscription.tournamentId, 1);
      } else if (wasConfirmed && !willConfirm) {
        applyConfirmedDelta(_store, inscription.tournamentId, -1);
        // Mirror of the DB trigger: a freed confirmed spot goes to the
        // oldest waitlisted row, unless the organizer closed inscriptions.
        _promoteFromWaitlist(inscription.tournamentId);
      }
      break;
    }

    _store.bump();
    if (updated == null) {
      throw StateError('Inscription $inscriptionId not found');
    }
    return _withPlayer(updated);
  }

  @override
  Future<void> cancel({required String inscriptionId}) async {
    // Same mechanics as an organizer decision (frees a confirmed spot).
    await decide(
      inscriptionId: inscriptionId,
      status: InscriptionStatus.cancelled,
    );
  }

  @override
  Future<int> countConfirmed(String tournamentId) async =>
      // Parity with the spots_left view: app rows + off-app manual count.
      _store.tournamentById(tournamentId)?.totalConfirmed ?? 0;

  /// Moves the oldest `waitlisted` inscription of [tournamentId] to
  /// `confirmed`. No-op when there is nobody waiting or the tournament is
  /// closed (parity with `promote_from_waitlist` in migration 0007).
  void _promoteFromWaitlist(String tournamentId) {
    final tournament = _store.tournamentById(tournamentId);
    if (tournament == null || tournament.status == TournamentStatus.closed) {
      return;
    }
    final candidates =
        _store.inscriptions
            .where(
              (i) =>
                  i.tournamentId == tournamentId &&
                  i.status == InscriptionStatus.waitlisted,
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (candidates.isEmpty) return;

    final first = candidates.first;
    final index = _store.inscriptions.indexWhere((i) => i.id == first.id);
    if (index < 0) return;
    _store.inscriptions[index] = InscriptionModel(
      id: first.id,
      tournamentId: first.tournamentId,
      playerId: first.playerId,
      status: InscriptionStatus.confirmed,
      teamName: first.teamName,
      note: first.note,
      createdAt: first.createdAt,
      confirmedAt: DateTime.now(),
      player: first.player,
    );
    applyConfirmedDelta(_store, tournamentId, 1);
  }

  InscriptionModel _withPlayer(InscriptionModel inscription) =>
      InscriptionModel(
        id: inscription.id,
        tournamentId: inscription.tournamentId,
        playerId: inscription.playerId,
        status: inscription.status,
        teamName: inscription.teamName,
        note: inscription.note,
        createdAt: inscription.createdAt,
        confirmedAt: inscription.confirmedAt,
        player: _store.profileById(inscription.playerId),
      );
}
