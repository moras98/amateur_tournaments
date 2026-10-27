import 'package:tande/data/auth/auth_repository.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/models/inscription_model.dart';
import 'package:tande/models/tournament_model.dart';

/// Localized vocabulary lookups keyed by the values the app stores.
///
/// The stored values (`football`, `elimination`, `male`, ISO-3166 codes,
/// status enums) stay language-neutral in models and repositories; the
/// human label always comes from [AppLocalizations] so it follows the
/// phone's locale.
extension SportLabels on AppLocalizations {
  /// Sport label for a stored `tournaments.sport` value.
  String sportLabel(String sport) => switch (sport) {
    'football' => sportFootball,
    'padel' => sportPadel,
    'tennis' => sportTennis,
    'basketball' => sportBasketball,
    _ => sport,
  };

  /// Format label for a stored `tournaments.kind` value.
  String kindLabel(String kind) => switch (kind) {
    'elimination' => kindElimination,
    'league' => kindLeague,
    _ => kind,
  };

  /// Gender label for a stored `profiles.gender` value.
  String genderLabel(String gender) => switch (gender) {
    'male' => genderMale,
    'female' => genderFemale,
    'other' => genderOther,
    _ => gender,
  };

  /// Country name for an ISO-3166 alpha-2 code (unknown codes pass
  /// through, like the stored dial code does).
  String countryName(String iso) => switch (iso.toUpperCase()) {
    'AR' => countryAR,
    'BO' => countryBO,
    'BR' => countryBR,
    'CL' => countryCL,
    'CO' => countryCO,
    'EC' => countryEC,
    'ES' => countryES,
    'US' => countryUS,
    'FR' => countryFR,
    'IT' => countryIT,
    'MX' => countryMX,
    'PY' => countryPY,
    'PE' => countryPE,
    'PT' => countryPT,
    'GB' => countryGB,
    'UY' => countryUY,
    'VE' => countryVE,
    _ => iso,
  };
}

/// Status labels moved out of the models (models stay UI-free).
extension StatusLabels on AppLocalizations {
  String tournamentStatus(TournamentStatus status) => switch (status) {
    TournamentStatus.open => statusOpen,
    TournamentStatus.full => statusFull,
    TournamentStatus.closed => statusClosed,
  };

  String inscriptionStatus(InscriptionStatus status) => switch (status) {
    InscriptionStatus.pending => inscriptionPending,
    InscriptionStatus.confirmed => inscriptionConfirmed,
    InscriptionStatus.rejected => inscriptionRejected,
    InscriptionStatus.cancelled => inscriptionCancelled,
    InscriptionStatus.waitlisted => inscriptionWaitlisted,
  };
}

/// Maps an [AuthFailure] to the current language.
///
/// Failures raised by the app carry a `code` and get localized copy;
/// raw backend messages (no code) pass through untranslated — they come
/// from Supabase in whatever language the service returns.
String authErrorMessage(AuthFailure failure, AppLocalizations l10n) {
  return switch (failure.code) {
    'unknownAccount' => l10n.authUnknownAccount,
    'emailTaken' => l10n.authEmailTaken,
    'socialMissing' => l10n.authSocialMissing,
    'invalidEmail' => l10n.authInvalidEmail,
    'passwordShort' => l10n.authPasswordShort,
    'signInFailed' => l10n.authSignInFailed,
    'browserFailed' => l10n.authBrowserFailed,
    'oauthCancelled' => l10n.authOAuthCancelled,
    _ => failure.message,
  };
}
