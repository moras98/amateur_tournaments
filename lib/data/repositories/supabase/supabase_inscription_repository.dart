import 'package:bracket/data/repositories/inscription_repository.dart';
import 'package:bracket/models/inscription_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-backed inscriptions (`public.inscriptions`). Selected by the
/// providers once `AppConstants.hasSupabase` is true.
///
/// Confirm/reject decisions update the row; the `sync_tournament_status`
/// trigger keeps the event's status (`full`/`open`) in sync.
class SupabaseInscriptionRepository implements InscriptionRepository {
  SupabaseInscriptionRepository(this._client);

  final SupabaseClient _client;

  /// Every column plus the player profile (public under profiles RLS).
  static const _select = '*, player:profiles(*)';

  @override
  Future<List<InscriptionModel>> fetchForPlayer(String playerId) async {
    final rows = await _client
        .from('inscriptions')
        .select(_select)
        .eq('player_id', playerId)
        .order('created_at', ascending: false);
    return rows.map(InscriptionModel.fromJson).toList();
  }

  @override
  Future<List<InscriptionModel>> fetchForTournament(String tournamentId) async {
    final rows = await _client
        .from('inscriptions')
        .select(_select)
        .eq('tournament_id', tournamentId)
        .order('created_at');
    return rows.map(InscriptionModel.fromJson).toList();
  }

  @override
  Future<InscriptionModel?> fetchForPlayerAndTournament({
    required String playerId,
    required String tournamentId,
  }) async {
    final row = await _client
        .from('inscriptions')
        .select(_select)
        .eq('player_id', playerId)
        .eq('tournament_id', tournamentId)
        .maybeSingle();
    if (row == null) return null;
    return InscriptionModel.fromJson(row);
  }

  @override
  Future<InscriptionModel> create({
    required String tournamentId,
    required String playerId,
    String teamName = '',
    String note = '',
  }) async {
    final existing = await fetchForPlayerAndTournament(
      playerId: playerId,
      tournamentId: tournamentId,
    );
    if (existing != null) {
      if (existing.status == InscriptionStatus.pending ||
          existing.status == InscriptionStatus.confirmed) {
        return existing;
      }
      // Rejected or cancelled: the player may request again — the row is
      // reactivated (mirrors the unique tournament/player constraint).
      final row = await _client
          .from('inscriptions')
          .update({
            'status': InscriptionStatus.pending.value,
            'team_name': teamName,
            'note': note,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', existing.id)
          .select(_select)
          .single();
      return InscriptionModel.fromJson(row);
    }

    try {
      final row = await _client
          .from('inscriptions')
          .insert({
            'tournament_id': tournamentId,
            'player_id': playerId,
            'team_name': teamName,
            'note': note,
          })
          .select(_select)
          .single();
      return InscriptionModel.fromJson(row);
    } on PostgrestException catch (error) {
      // 23505 = unique (tournament_id, player_id): a concurrent request won
      // the race — return that inscription.
      if (error.code == '23505') {
        final raced = await fetchForPlayerAndTournament(
          playerId: playerId,
          tournamentId: tournamentId,
        );
        if (raced != null) return raced;
      }
      rethrow;
    }
  }

  @override
  Future<void> cancel({required String inscriptionId}) async {
    // RLS only lets a player update their own row to 'cancelled'.
    await _client
        .from('inscriptions')
        .update({
          'status': InscriptionStatus.cancelled.value,
          'confirmed_at': null,
        })
        .eq('id', inscriptionId);
  }

  @override
  Future<InscriptionModel> decide({
    required String inscriptionId,
    required InscriptionStatus status,
  }) async {
    final row = await _client
        .from('inscriptions')
        .update({
          'status': status.value,
          'confirmed_at': status == InscriptionStatus.confirmed
              ? DateTime.now().toUtc().toIso8601String()
              : null,
        })
        .eq('id', inscriptionId)
        .select(_select)
        .single();
    return InscriptionModel.fromJson(row);
  }

  @override
  Future<int> countConfirmed(String tournamentId) async {
    final row = await _client
        .from('spots_left')
        .select('confirmed_teams')
        .eq('tournament_id', tournamentId)
        .maybeSingle();
    final appRows = (row?['confirmed_teams'] as num?)?.toInt() ?? 0;
    // The view counts app rows only: parity with the mock (and the
    // model's totalConfirmed) needs the off-app manual count too.
    final tournament = await _client
        .from('tournaments')
        .select('manual_confirmed')
        .eq('id', tournamentId)
        .maybeSingle();
    final manual = (tournament?['manual_confirmed'] as num?)?.toInt() ?? 0;
    return appRows + manual;
  }
}
