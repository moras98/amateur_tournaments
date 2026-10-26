import 'package:tande/models/user_model.dart';

/// Player/organizer profiles.
///
/// Supabase implementation: `SupabaseProfileRepository`;
/// mock: `MockProfileRepository`.
abstract class ProfileRepository {
  /// The signed-in user's profile.
  Future<UserModel> fetchCurrent();

  Future<UserModel?> fetchById(String id);

  /// Inserts or updates the current user's profile.
  Future<UserModel> save(UserModel profile);

  /// Whether [username] belongs to another profile (live sign-up/profile
  /// hint; [save] enforces the real constraint).
  Future<bool> isUsernameTaken(String username, {String? excludingId});
}
