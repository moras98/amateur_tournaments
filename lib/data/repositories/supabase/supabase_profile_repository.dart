import 'package:tande/data/repositories/profile_repository.dart';
import 'package:tande/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-backed profiles (`public.profiles` table).
/// Selected by the providers once `AppConstants.hasSupabase` is true.
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
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
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
