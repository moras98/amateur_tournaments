import 'package:tande/data/repositories/inscription_repository.dart';
import 'package:tande/models/inscription_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-backed inscriptions (`public.inscriptions`). Selected by the
/// providers once `AppConstants.hasSupabase` is true.
///
/// Confirm/reject decisions update the row; the `sync_tournament_status`
/// trigger keeps the event's status (`full`/`open`) in sync.
///
/// Player profiles are **not** embedded with `profiles(*)`: since migration
/// 0014 that table is owner-only and the anon key can no longer read every
/// player's phone. The organizer gets the contact channels of their own
/// tournament's players through `inscription_player_contacts(tournament_id)`.
class SupabaseInscriptionRepository implements InscriptionRepository {
  SupabaseInscriptionRepository(this._client);

  final SupabaseClient _client;

  static const _select = '*';

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
    final players = await _playerContacts(tournamentId);
    return rows.map((row) {
      final player = players[row['player_id']];
      final json = <String, dynamic>{...row};
      if (player != null) json['player'] = player;
      return InscriptionModel.fromJson(json);
    }).toList();
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

  /// Contact channels of the players registered in [tournamentId], keyed by
  /// player id. Empty when the RPC is not deployed yet or the caller does
  /// not own the tournament — the request list still renders, just without
  /// the contact buttons.
  Future<Map<String, Map<String, dynamic>>> _playerContacts(
    String tournamentId,
  ) async {
    try {
      final response = await _client.rpc(
        'inscription_player_contacts',
        params: {'p_tournament_id': tournamentId},
      );
      final rows = (response as List).cast<Map<String, dynamic>>();
      return {
        for (final row in rows)
          if (row['player_id'] != null)
            row['player_id'] as String: {
              'id': row['player_id'],
              'username': row['username'] ?? '',
              'full_name': row['full_name'] ?? '',
              'avatar_url': row['avatar_url'],
              'phone': row['phone'] ?? '',
              'instagram': row['instagram'] ?? '',
              'telegram': row['telegram'] ?? '',
              'contact_url': row['contact_url'] ?? '',
              'sports': row['sports'] ?? const <String>[],
            },
      };
    } catch (_) {
      return const {};
    }
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
    final existing = await fetchForPlayerAndTournament(
      playerId: playerId,
      tournamentId: tournamentId,
    );
    if (existing != null) {
      if (existing.status == InscriptionStatus.pending ||
          existing.status == InscriptionStatus.confirmed ||
          existing.status == InscriptionStatus.waitlisted) {
        return existing;
      }
      // Rejected or cancelled: the player may request again — the row is
      // reactivated (mirrors the unique tournament/player constraint).
      final row = await _client
          .from('inscriptions')
          .update({
            'status': target.value,
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
            'status': target.value,
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
