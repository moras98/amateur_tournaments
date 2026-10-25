import 'dart:async';

import 'package:bracket/data/auth/auth_repository.dart';
import 'package:bracket/data/repositories/mock/mock_store.dart';
import 'package:bracket/models/user_model.dart';

/// In-memory auth for local development and tests.
///
/// Accounts map an email to a mock profile via `MockStore.accountEmails`
/// (like Supabase's `auth.users`): signing in never depends on the current
/// username, so renaming it can't lock you out.
///
/// Demo logins: `nico@demo.app` (player), `el_turco@demo.app` (organizer),
/// `mariano@demo.app` (organizer 2), `lucia@demo.app` (player 2) — any
/// password of 6+ characters.
///
/// [MockAuthRepository.new] starts signed in as the demo player unless
/// `signedIn: false` is passed; `userId` picks a different seeded account
/// (e.g. `u-org-1` for organizer flows).
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({MockStore? store, bool signedIn = true, String? userId})
    : _store = store ?? MockStore() {
    if (signedIn) {
      final id = userId ?? _store.currentUserId;
      final email =
          _store.accountEmails[id] ??
          '${_store.profileById(id)?.username ?? 'user'}@demo.app';
      _session = _sessionFor(id, email);
    }
  }

  final MockStore _store;
  final StreamController<AuthSession?> _controller =
      StreamController<AuthSession?>.broadcast();

  AuthSession? _session;

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> get stateChanges => _controller.stream;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    _validate(email, password);

    final profile = _profileForEmail(email);
    if (profile == null) {
      throw const AuthFailure(
        'Cuenta desconocida. Login demo: nico@demo.app / password123',
        code: 'unknownAccount',
      );
    }

    return _keep(_sessionFor(profile.id, email));
  }

  @override
  Future<AuthSession?> signUp({
    required String email,
    required String password,
    String fullName = '',
  }) async {
    _validate(email, password);

    if (_profileForEmail(email) != null) {
      throw const AuthFailure(
        'Ya existe una cuenta con ese email.',
        code: 'emailTaken',
      );
    }

    final profile = UserModel(
      id: _store.nextId('u'),
      username: _usernameFromEmail(email),
      fullName: fullName,
      gender: '',
      // Starts incomplete: the completion screen fills the rest.
      phone: '',
      sports: const ['football'],
    );
    _store.profiles.add(profile);
    _store.registerAccountEmail(profile.id, email);
    _store.bump();

    return _keep(_sessionFor(profile.id, email));
  }

  @override
  Future<bool> isEmailRegistered(String email) async =>
      _store.profileIdForEmail(email) != null;

  @override
  Future<AuthSession> signInWithOAuth(SocialProvider provider) async {
    // Simulates the browser round-trip by signing in the provider's seeded
    // demo account (see MockStore's social profiles).
    final profileId = switch (provider) {
      SocialProvider.google => MockStore.socialGoogleId,
      SocialProvider.apple => MockStore.socialAppleId,
    };
    final profile = _store.profileById(profileId);
    if (profile == null) {
      throw const AuthFailure(
        'Cuenta social demo no encontrada.',
        code: 'socialMissing',
      );
    }
    final email =
        _store.accountEmails[profileId] ?? '${profile.username}@demo.app';
    return _keep(_sessionFor(profile.id, email));
  }

  @override
  Future<void> signOut() async {
    _setSession(null);
  }

  void _validate(String email, String password) {
    final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!emailOk) {
      throw const AuthFailure('Ingresá un email válido.', code: 'invalidEmail');
    }
    if (password.length < 6) {
      throw const AuthFailure(
        'La contraseña debe tener al menos 6 caracteres.',
        code: 'passwordShort',
      );
    }
  }

  UserModel? _profileForEmail(String email) {
    // Match by registered account email, not by username: renaming a
    // profile's handle must never lock the account out of sign-in.
    final id = _store.profileIdForEmail(email);
    if (id == null) return null;
    return _store.profileById(id);
  }

  String _usernameFromEmail(String email) => email
      .split('@')
      .first
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_.]'), '');

  AuthSession _sessionFor(String userId, String email) =>
      AuthSession(userId: userId, email: email);

  AuthSession? _setSession(AuthSession? session) {
    _session = session;
    _controller.add(session);
    return session;
  }

  /// [signIn]/[signUp] guarantees a non-null session.
  AuthSession _keep(AuthSession session) {
    _setSession(session);
    return session;
  }
}
