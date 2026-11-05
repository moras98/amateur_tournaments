import 'package:tande/data/repositories/profile_repository.dart';
import 'package:tande/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-backed profiles.
///
/// Two different tables/views, on purpose (migration 0014):
/// - the signed-in user's own row comes from `profiles`, which is
///   owner-only and carries the private fields (birth date, gender, phone);
/// - anybody else's profile comes from `public_profiles`, which only exposes
///   organizers with tournaments and never exposes birth date or gender.
///
/// Before 0014 the whole table was readable with the public anon key, so a
/// signed-out client could harvest every player's phone.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<UserModel> fetchCurrent() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No signed-in user');
    }
    final profile = await fetchById(userId);
    if (profile == null) throw StateError('Profile $userId not found');
    return profile;
  }

  @override
  Future<UserModel?> fetchById(String id) async {
    // Own profile → private table (RLS: auth.uid() = id). Anyone else →
    // public projection. A player who never organizes a tournament is not
    // in `public_profiles`: there is no screen in the app that needs their
    // profile outside the organizer's inscription list (which uses the
    // `inscription_player_contacts` RPC).
    final isSelf = _client.auth.currentUser?.id == id;
    final source = isSelf ? 'profiles' : 'public_profiles';
    final row = await _client.from(source).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return UserModel.fromJson(row);
  }

  @override
  Future<UserModel> save(UserModel profile) async {
    final json = profile.toJson();
    // `birth_date` is a Postgres `date`: send date part only.
    json['birth_date'] = profile.birthDate?.toIso8601String().split('T').first;
    await _client.from('profiles').upsert(json);
    return profile;
  }

  @override
  Future<bool> isUsernameTaken(String username, {String? excludingId}) async {
    // Best effort: `public.username_taken` (migration 0006). Any failure
    // (RPC not applied) just skips the live hint — `save` still enforces
    // uniqueness.
    try {
      final taken = await _client.rpc(
        'username_taken',
        params: {'p_username': username, 'p_excluding': excludingId},
      );
      return taken == true;
    } catch (_) {
      return false;
    }
  }
}
