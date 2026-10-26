import 'dart:async';

import 'package:bracket/core/constants.dart';
import 'package:bracket/data/auth/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Supabase-backed auth. Selected by the providers once
/// `AppConstants.hasSupabase` is true.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  /// Sticky while a password-recovery session is open. The token refresh
  /// (and `initialSession` on restore) re-emit the same session afterwards;
  /// the hold on /reset-password must survive those events, so it only
  /// clears at [updatePassword], a fresh sign-in/sign-up, or sign-out.
  bool _recovering = false;

  @override
  AuthSession? get currentSession => _sessionOf(_client.auth.currentSession);

  @override
  Stream<AuthSession?> get stateChanges =>
      _client.auth.onAuthStateChange.map((state) {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          _recovering = true;
        }
        return _sessionOf(state.session);
      });

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session == null) {
        throw const AuthFailure(
          'No se pudo iniciar sesión.',
          code: 'signInFailed',
        );
      }
      _recovering = false;
      return _sessionOf(response.session)!;
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<AuthSession?> signUp({
    required String email,
    required String password,
    String fullName = '',
    String username = '',
    DateTime? birthDate,
    String gender = '',
    List<String> sports = const [],
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        // Back into the app, not the Site URL: the confirm link opens the
        // same deep link OAuth uses (allow-listed in the dashboard), so a
        // first sign-in lands in the app instead of a web page.
        emailRedirectTo: AppConstants.oauthRedirectUrl,
        data: {
          'full_name': fullName,
          // The whole form travels here: with confirmation pending there
          // is no session to save a profile through, so the DB trigger
          // (migration 0007) writes these into profiles at account
          // creation. The keys are sent unconditionally so the confirmed
          // and the pending path stay identical.
          'username': username,
          'birth_date': birthDate?.toIso8601String(),
          'gender': gender,
          'sports': sports,
        },
      );
      // Null session = email confirmation pending (Supabase default): the
      // caller shows an informational message, not an error.
      if (response.session != null) _recovering = false;
      return _sessionOf(response.session);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    // Best effort: `public.email_taken` (migration 0006) reads auth.users
    // with security definer. Any failure (RPC not applied) just skips the
    // live hint — signUp still rejects the duplicate.
    try {
      final taken = await _client.rpc(
        'email_taken',
        params: {'p_email': email.trim()},
      );
      return taken == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AuthSession> signInWithOAuth(SocialProvider provider) async {
    try {
      // Build the provider's page URL (gotrue stores the PKCE code verifier
      // for the deep-link exchange). supabase_flutter captures the redirect
      // deep link (AppConstants.oauthRedirectUrl) on its own, exchanges the
      // code and emits the new session on onAuthStateChange.
      final response = await _client.auth.getOAuthSignInUrl(
        provider: _oauthProvider(provider),
        redirectTo: AppConstants.oauthRedirectUrl,
      );

      // Hand the URL to the system browser.
      final launched = await launchUrl(
        Uri.parse(response.url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const AuthFailure(
          'No se pudo abrir el navegador.',
          code: 'browserFailed',
        );
      }

      final session = await _client.auth.onAuthStateChange
          .map((state) => state.session)
          .firstWhere((s) => s != null)
          .timeout(_oauthTimeout);
      _recovering = false;
      return _sessionOf(session)!;
    } on TimeoutException {
      // The browser was closed without completing the flow.
      throw const AuthFailure(
        'Se canceló el inicio de sesión con el proveedor.',
        code: 'oauthCancelled',
      );
    } on AuthException catch (e) {
      // Raw backend message (English): passes through untranslated.
      throw AuthFailure(e.message);
    }
  }

  /// How long the browser round-trip may take (typing Google/Apple
  /// credentials included) before the flow is treated as cancelled.
  static const _oauthTimeout = Duration(minutes: 2);

  OAuthProvider _oauthProvider(SocialProvider provider) => switch (provider) {
    SocialProvider.google => OAuthProvider.google,
    SocialProvider.apple => OAuthProvider.apple,
  };

  @override
  Future<void> resetPasswordForEmail(String email) async {
    try {
      // Same deep link as OAuth: after the browser verifies the link,
      // supabase_flutter captures it in the app and gotrue emits
      // `passwordRecovery` (PKCE verifier stored under that event name),
      // which the session flags as `recovery`.
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: AppConstants.oauthRedirectUrl,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      // Password set: release the /reset-password hold for the next event.
      _recovering = false;
    } on AuthSessionMissingException {
      // No session (link opened in a cleared app state): surface as an
      // app failure the reset screen can show, not a crash.
      throw const AuthFailure(
        'La sesión de recuperación ya no existe. Pedí un enlace nuevo.',
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      _recovering = false;
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  AuthSession? _sessionOf(Session? session) => session == null
      ? null
      : AuthSession(
          userId: session.user.id,
          email: session.user.email ?? '',
          recovery: _recovering,
        );
}
