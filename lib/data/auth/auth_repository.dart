/// A minimal signed-in session (replaces Supabase's session in the app layer).
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    this.recovery = false,
  });

  final String userId;
  final String email;

  /// True while the session was opened by a password-recovery email link:
  /// the router holds the user on /reset-password until the password is
  /// changed (see `_redirect`), and [AuthController.updatePassword]
  /// releases the hold by re-emitting the session without this flag.
  final bool recovery;

  @override
  bool operator ==(Object other) =>
      other is AuthSession &&
      other.userId == userId &&
      other.email == email &&
      other.recovery == recovery;

  @override
  int get hashCode => Object.hash(userId, email, recovery);

  @override
  String toString() =>
      'AuthSession($userId, $email${recovery ? ', recovery' : ''})';
}

/// User-facing auth error (invalid credentials, duplicate email, ...).
///
/// [message] is the debugging/fallback text; [code] is the stable key the
/// UI translates (see `authErrorMessage`). Raw backend failures carry no
/// code and are shown as-is.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  final String message;

  /// Stable, language-neutral error key, e.g. `emailTaken`.
  final String? code;

  @override
  String toString() => message;
}

/// Social sign-in providers (browser-redirect OAuth via Supabase).
///
/// Adding one = an enum case + a mock account + a Supabase dashboard
/// enablement (see README).
enum SocialProvider {
  google('Google'),
  apple('Apple');

  const SocialProvider(this.label);

  /// Label for the sign-in buttons.
  final String label;
}

/// Sign-up/sign-in/sign-out and auth state.
///
/// Supabase implementation: `SupabaseAuthRepository`; mock: `MockAuthRepository`.
abstract class AuthRepository {
  /// The current session, if any (synchronous read at app start).
  AuthSession? get currentSession;

  /// Fires whenever the session changes (sign in, sign out, token refresh).
  Stream<AuthSession?> get stateChanges;

  Future<AuthSession> signIn({required String email, required String password});

  /// Signs in through [provider]'s browser OAuth flow (redirects back into
  /// the app). First-time users get an account automatically — their
  /// profile still needs completion, like after sign-up.
  Future<AuthSession> signInWithOAuth(SocialProvider provider);

  /// Creates an account and signs in.
  ///
  /// The whole sign-up form travels as account metadata ([username],
  /// [birthDate], [gender], [sports], [fullName]): with email
  /// confirmation on (Supabase's default) there is no session to save a
  /// profile through, so the `handle_new_user()` trigger (migration 0007)
  /// copies the metadata into `profiles` at account creation. Without it
  /// the user would retype everything after confirming the email.
  ///
  /// The confirmation link returns into the app (`emailRedirectTo`, see
  /// `AppConstants.oauthRedirectUrl`) instead of the project's Site URL.
  ///
  /// Returns `null` when the backend requires email confirmation first:
  /// the account exists (profile included) but there is no session yet.
  Future<AuthSession?> signUp({
    required String email,
    required String password,
    String fullName = '',
    String username = '',
    DateTime? birthDate,
    String gender = '',
    List<String> sports = const [],
  });

  /// Best-effort duplicate-email check for the sign-up form's live hint
  /// (250 ms debounce). The real constraint runs at [signUp].
  Future<bool> isEmailRegistered(String email);

  /// Emails a password-reset link that returns into the app (the
  /// `emailRedirectTo` deep link), where it opens a session flagged
  /// [AuthSession.recovery].
  ///
  /// Resolves even for an unknown address — the backend doesn't reveal
  /// whether the account exists (anti-enumeration), so the UI always shows
  /// a hedged "if an account exists…" confirmation.
  Future<void> resetPasswordForEmail(String email);

  /// Sets the new password on the recovery session (or the signed-in one).
  /// Releasing the [AuthSession.recovery] hold is the controller's job.
  Future<void> updatePassword(String newPassword);

  /// Permanently deletes the signed-in account and all of its data —
  /// the in-app deletion flow both stores require (App Store guideline
  /// 5.1.1(v), Play's account-deletion policy). See migration 0012: the
  /// backend cascades profiles, tournaments and inscriptions.
  ///
  /// The caller drops the session state afterwards (the repository only
  /// clears its own local copy of the session).
  Future<void> deleteAccount();

  Future<void> signOut();
}
