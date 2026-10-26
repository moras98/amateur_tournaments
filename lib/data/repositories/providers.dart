import 'package:bracket/core/constants.dart';
import 'package:bracket/data/auth/auth_repository.dart';
import 'package:bracket/data/auth/mock_auth_repository.dart';
import 'package:bracket/data/auth/supabase_auth_repository.dart';
import 'package:bracket/data/billing/billing_service.dart';
import 'package:bracket/data/billing/mock_billing_service.dart';
import 'package:bracket/data/billing/play_billing_service.dart';
import 'package:bracket/data/repositories/inscription_repository.dart';
import 'package:bracket/data/repositories/mock/mock_inscription_repository.dart';
import 'package:bracket/data/repositories/mock/mock_profile_repository.dart';
import 'package:bracket/data/repositories/mock/mock_tournament_repository.dart';
import 'package:bracket/data/repositories/profile_repository.dart';
import 'package:bracket/data/repositories/supabase/supabase_inscription_repository.dart';
import 'package:bracket/data/repositories/supabase/supabase_profile_repository.dart';
import 'package:bracket/data/repositories/supabase/supabase_tournament_repository.dart';
import 'package:bracket/data/repositories/tournament_repository.dart';
import 'package:bracket/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository wiring.
///
/// Mock implementations until `SUPABASE_URL`/`SUPABASE_ANON_KEY` are provided
/// via `--dart-define`; call sites only depend on the abstract types.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (AppConstants.hasSupabase) {
    return SupabaseProfileRepository(Supabase.instance.client);
  }
  return MockProfileRepository();
});

final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  if (AppConstants.hasSupabase) {
    return SupabaseTournamentRepository(Supabase.instance.client);
  }
  return MockTournamentRepository();
});

final inscriptionRepositoryProvider = Provider<InscriptionRepository>((ref) {
  if (AppConstants.hasSupabase) {
    return SupabaseInscriptionRepository(Supabase.instance.client);
  }
  return MockInscriptionRepository();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConstants.hasSupabase) {
    return SupabaseAuthRepository(Supabase.instance.client);
  }
  return MockAuthRepository();
});

/// Play Billing (Bracket Pro). Real on release builds (the Supabase
/// defines are the release marker — same switch as the repositories),
/// mock otherwise: tests and dev builds never touch the billing channel.
final billingServiceProvider = Provider<BillingService>((ref) {
  if (AppConstants.hasSupabase) {
    return PlayBillingService();
  }
  return MockBillingService();
});

/// The signed-in session, or `null`.
///
/// Synchronous initial value (from `AuthRepository.currentSession`) so the
/// router can redirect before the first frame without a login flash.
class AuthController extends Notifier<AuthSession?> {
  @override
  AuthSession? build() {
    final repository = ref.read(authRepositoryProvider);
    final subscription = repository.stateChanges.listen((session) {
      // Covers changes that don't go through this controller
      // (token refresh, sign-out elsewhere).
      if (state != session) state = session;
    });
    ref.onDispose(subscription.cancel);
    return repository.currentSession;
  }

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final session = await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);
    state = session;
    return session;
  }

  /// Returns `null` when the backend requires email confirmation first —
  /// the account exists but is not signed in yet.
  Future<AuthSession?> signUp({
    required String email,
    required String password,
    String fullName = '',
  }) async {
    final session = await ref
        .read(authRepositoryProvider)
        .signUp(email: email, password: password, fullName: fullName);
    // Null keeps the user signed out (no state change needed).
    if (session != null) state = session;
    return session;
  }

  /// Browser-redirect OAuth sign-in (Google, Apple). The profile still
  /// needs completion on a first sign-in — the login screen routes through
  /// /complete-profile.
  Future<AuthSession> signInWithOAuth(SocialProvider provider) async {
    final session = await ref
        .read(authRepositoryProvider)
        .signInWithOAuth(provider);
    state = session;
    return session;
  }

  /// Live "email already in use" hint for the sign-up form (the account
  /// itself is checked again at [signUp]).
  Future<bool> isEmailRegistered(String email) =>
      ref.read(authRepositoryProvider).isEmailRegistered(email);

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = null;
  }
}

final authStateProvider = NotifierProvider<AuthController, AuthSession?>(
  AuthController.new,
);

/// The signed-in user's profile, or `null` when signed out.
///
/// Invalidate after saving a profile so dependent screens refresh.
final currentProfileProvider = FutureProvider<UserModel?>((ref) {
  final session = ref.watch(authStateProvider);
  if (session == null) return null;
  return ref.watch(profileRepositoryProvider).fetchById(session.userId);
});
