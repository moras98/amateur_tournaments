import 'package:bracket/data/repositories/inscription_repository.dart';
import 'package:bracket/data/repositories/mock/mock_store.dart';
import 'package:bracket/data/repositories/mock/mock_tournament_repository.dart';
import 'package:bracket/models/inscription_model.dart';

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
  }) async {
    final existingIndex = _store.inscriptions.indexWhere(
      (i) => i.playerId == playerId && i.tournamentId == tournamentId,
    );
    if (existingIndex >= 0) {
      final existing = _store.inscriptions[existingIndex];
      if (existing.status == InscriptionStatus.pending ||
          existing.status == InscriptionStatus.confirmed) {
        return _withPlayer(existing);
      }
      // Rejected or cancelled: the player may request again — the row is
      // reactivated (mirrors the unique tournament/player constraint).
      final reactivated = InscriptionModel(
        id: existing.id,
        tournamentId: tournamentId,
        playerId: playerId,
        status: InscriptionStatus.pending,
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
      status: InscriptionStatus.pending,
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
