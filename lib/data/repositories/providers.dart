import 'package:tande/core/constants.dart';
import 'package:tande/core/utils/banner_picker.dart';
import 'package:tande/data/auth/auth_repository.dart';
import 'package:tande/data/auth/mock_auth_repository.dart';
import 'package:tande/data/auth/supabase_auth_repository.dart';
import 'package:tande/data/billing/billing_service.dart';
import 'package:tande/data/billing/mock_billing_service.dart';
import 'package:tande/data/billing/play_billing_service.dart';
import 'package:tande/data/repositories/inscription_repository.dart';
import 'package:tande/data/repositories/mock/mock_inscription_repository.dart';
import 'package:tande/data/repositories/mock/mock_profile_repository.dart';
import 'package:tande/data/repositories/mock/mock_tournament_repository.dart';
import 'package:tande/data/repositories/profile_repository.dart';
import 'package:tande/data/repositories/supabase/supabase_inscription_repository.dart';
import 'package:tande/data/repositories/supabase/supabase_profile_repository.dart';
import 'package:tande/data/repositories/supabase/supabase_tournament_repository.dart';
import 'package:tande/data/repositories/tournament_repository.dart';
import 'package:tande/data/storage/banner_storage.dart';
import 'package:tande/data/storage/mock_banner_storage.dart';
import 'package:tande/models/user_model.dart';
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

/// Optional tournament banners: Supabase Storage (public bucket) on real
/// builds, [MockStore.banners] in memory otherwise. The tournament
/// repositories and the card/detail displays share this instance.
final bannerStorageProvider = Provider<BannerStorage>((ref) {
  if (AppConstants.hasSupabase) {
    return SupabaseBannerStorage(Supabase.instance.client);
  }
  return MockBannerStorage();
});

/// The gallery picker behind the event form's "Agregar imagen" (overridden
/// in tests so the platform image channel is never hit).
final bannerPickerProvider = Provider<BannerPicker>(
  (ref) => const GalleryBannerPicker(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConstants.hasSupabase) {
    return SupabaseAuthRepository(Supabase.instance.client);
  }
  return MockAuthRepository();
});

/// Play Billing (Tande Pro). Real on release builds (the Supabase
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
  /// the account exists (profile included, via the signup metadata) but
  /// is not signed in yet.
  Future<AuthSession?> signUp({
    required String email,
    required String password,
    String fullName = '',
    String username = '',
    DateTime? birthDate,
    String gender = '',
    List<String> sports = const [],
  }) async {
    final session = await ref
        .read(authRepositoryProvider)
        .signUp(
          email: email,
          password: password,
          fullName: fullName,
          username: username,
          birthDate: birthDate,
          gender: gender,
          sports: sports,
        );
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

  /// Sends the password-reset email; its link returns into the app with a
  /// session flagged [AuthSession.recovery], which the router holds on
  /// /reset-password until [updatePassword].
  Future<void> resetPasswordForEmail(String email) =>
      ref.read(authRepositoryProvider).resetPasswordForEmail(email);

  /// Sets the new password and releases the recovery hold: the session is
  /// re-emitted without the flag, so the router stops pinning the screen
  /// (the screen itself navigates on to Explore).
  Future<void> updatePassword(String newPassword) async {
    final session = state;
    await ref.read(authRepositoryProvider).updatePassword(newPassword);
    if (session != null) {
      state = AuthSession(userId: session.userId, email: session.email);
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = null;
  }

  /// Permanently deletes the signed-in account (Profile → "Eliminar
  /// cuenta"; App Store 5.1.1(v) / Play account-deletion policy). The
  /// repository runs the cascade (migration 0012) and clears its local
  /// session; dropping the state here is what takes the router to /login
  /// and invalidates every session-derived provider.
  Future<void> deleteAccount() async {
    await ref.read(authRepositoryProvider).deleteAccount();
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
