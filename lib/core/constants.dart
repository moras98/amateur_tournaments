/// App-wide constants and configuration.
///
/// Supabase credentials are injected at build time:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
abstract class AppConstants {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Until Supabase is configured the app runs on repository mocks.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const appName = 'Tande';

  /// Where Supabase sends the user back after the browser OAuth flow
  /// (Google, Apple). Registered as a deep-link scheme in AndroidManifest.xml
  /// and Info.plist, and allow-listed in each provider's dashboard settings.
  static const oauthRedirectUrl =
      'io.supabase.amateurtournaments://login-callback';

  // --- Tande Pro (LAUNCH.md §7) ------------------------------------

  /// Play Console product ids (one subscription each, base plans on top).
  ///
  /// **Creating these in Play Console switches paying mode ON** for every
  /// user without an entitlement: paywall entry points appear and the
  /// free-tier gate starts enforcing. Do it only when Pro really launches
  /// (after the closed test, once the Pro features ship).
  static const proMonthlyId = 'tande_pro_monthly';
  static const proYearlyId = 'tande_pro_yearly';
  static const proProductIds = [proMonthlyId, proYearlyId];

  /// Free tier: active tournaments an organizer runs without Pro
  /// (active = not closed and not over yet; nothing is blocked until
  /// [proProductIds] exist in Play Console).
  static const freeActiveTournaments = 1;

  /// Mirrors the free-trial length configured on the Play base plan — the
  /// billing plugin can't read it, so keep this in sync. `null` = no
  /// trial: the paywall drops the trial copy entirely.
  // ignore: unnecessary_nullable_for_final_variable_declarations
  static const int? proTrialDays = 7;

  /// Public URLs of the legal documents (hosted — see LAUNCH.md; update
  /// these if the hosting moves). Opened from the registration forms.
  static const termsUrl =
      'https://github.com/moras98/amateur_tournaments/blob/main/store/'
      'terms-and-conditions.md';
  static const privacyUrl =
      'https://github.com/moras98/amateur_tournaments/blob/main/store/'
      'privacy-policy.md';

  /// Supported sports. Values are stored as-is in `tournaments.sport`;
  /// the human labels come from `AppLocalizations.sportLabel`.
  static const sports = ['football', 'padel', 'tennis', 'basketball'];

  /// Tournament formats (labels in `AppLocalizations.kindLabel`).
  static const kinds = ['elimination', 'league'];
}
