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

  static const appName = 'Bracket';

  /// Where Supabase sends the user back after the browser OAuth flow
  /// (Google, Apple). Registered as a deep-link scheme in AndroidManifest.xml
  /// and Info.plist, and allow-listed in each provider's dashboard settings.
  static const oauthRedirectUrl =
      'io.supabase.amateurtournaments://login-callback';

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
