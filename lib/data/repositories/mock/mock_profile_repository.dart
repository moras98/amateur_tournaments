import 'package:tande/data/repositories/mock/mock_store.dart';
import 'package:tande/data/repositories/profile_repository.dart';
import 'package:tande/models/user_model.dart';

/// In-memory [ProfileRepository] backed by [MockStore].
class MockProfileRepository implements ProfileRepository {
  MockProfileRepository([MockStore? store]) : _store = store ?? MockStore();

  final MockStore _store;

  @override
  Future<UserModel> fetchCurrent() async {
    final profile = _store.profileById(_store.currentUserId);
    if (profile == null) {
      throw StateError('No current profile in mock store');
    }
    return profile;
  }

  @override
  Future<UserModel?> fetchById(String id) async => _store.profileById(id);

  @override
  Future<UserModel> save(UserModel profile) async {
    // Mirror the DB's `username unique` constraint: the mock would
    // otherwise let two profiles share a handle (and the app would treat
    // them as interchangeable).
    final taken = _store.profiles.any(
      (p) => p.id != profile.id && p.username == profile.username,
    );
    if (taken) {
      throw StateError('Ese nombre de usuario ya está en uso.');
    }

    final index = _store.profiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      _store.profiles[index] = profile;
    } else {
      _store.profiles.add(profile);
    }
    _store.bump();
    return profile;
  }

  @override
  Future<bool> isUsernameTaken(String username, {String? excludingId}) async {
    // Mirrors the unique-username guard in [save].
    return _store.profiles.any(
      (p) => p.id != excludingId && p.username == username,
    );
  }
}
