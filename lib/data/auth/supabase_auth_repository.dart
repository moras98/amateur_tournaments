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

  @override
  AuthSession? get currentSession => _sessionOf(_client.auth.currentSession);

  @override
  Stream<AuthSession?> get stateChanges =>
      _client.auth.onAuthStateChange.map((state) => _sessionOf(state.session));

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
      final session = _sessionOf(response.session);
      if (session == null) {
        throw const AuthFailure(
          'No se pudo iniciar sesión.',
          code: 'signInFailed',
        );
      }
      return session;
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
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  AuthSession? _sessionOf(Session? session) => session == null
      ? null
      : AuthSession(userId: session.user.id, email: session.user.email ?? '');
}
