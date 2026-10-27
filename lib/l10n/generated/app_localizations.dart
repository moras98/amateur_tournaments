import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('es', 'UY'),
  ];

  /// No description provided for @navExplore.
  ///
  /// In es_UY, this message translates to:
  /// **'Explorar'**
  String get navExplore;

  /// No description provided for @navInscriptions.
  ///
  /// In es_UY, this message translates to:
  /// **'Inscripciones'**
  String get navInscriptions;

  /// No description provided for @navOrganize.
  ///
  /// In es_UY, this message translates to:
  /// **'Organizar'**
  String get navOrganize;

  /// No description provided for @navProfile.
  ///
  /// In es_UY, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @errorScreenTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'No encontramos esa pantalla'**
  String get errorScreenTitle;

  /// No description provided for @errorScreenBody.
  ///
  /// In es_UY, this message translates to:
  /// **'Puede que el evento ya no exista o el enlace esté roto.'**
  String get errorScreenBody;

  /// No description provided for @errorScreenBack.
  ///
  /// In es_UY, this message translates to:
  /// **'Volver a Explorar'**
  String get errorScreenBack;

  /// No description provided for @clearSearch.
  ///
  /// In es_UY, this message translates to:
  /// **'Borrar búsqueda'**
  String get clearSearch;

  /// No description provided for @cancel.
  ///
  /// In es_UY, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In es_UY, this message translates to:
  /// **'Listo'**
  String get done;

  /// No description provided for @free.
  ///
  /// In es_UY, this message translates to:
  /// **'Gratis'**
  String get free;

  /// No description provided for @retry.
  ///
  /// In es_UY, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In es_UY, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @apply.
  ///
  /// In es_UY, this message translates to:
  /// **'Aplicar'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In es_UY, this message translates to:
  /// **'Restablecer'**
  String get reset;

  /// No description provided for @back.
  ///
  /// In es_UY, this message translates to:
  /// **'Atrás'**
  String get back;

  /// No description provided for @next.
  ///
  /// In es_UY, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @loadError.
  ///
  /// In es_UY, this message translates to:
  /// **'Error: {error}'**
  String loadError(Object error);

  /// No description provided for @sportFootball.
  ///
  /// In es_UY, this message translates to:
  /// **'Fútbol'**
  String get sportFootball;

  /// No description provided for @sportPadel.
  ///
  /// In es_UY, this message translates to:
  /// **'Pádel'**
  String get sportPadel;

  /// No description provided for @sportTennis.
  ///
  /// In es_UY, this message translates to:
  /// **'Tenis'**
  String get sportTennis;

  /// No description provided for @sportBasketball.
  ///
  /// In es_UY, this message translates to:
  /// **'Básquet'**
  String get sportBasketball;

  /// No description provided for @kindElimination.
  ///
  /// In es_UY, this message translates to:
  /// **'Eliminación'**
  String get kindElimination;

  /// No description provided for @kindLeague.
  ///
  /// In es_UY, this message translates to:
  /// **'Liga'**
  String get kindLeague;

  /// No description provided for @genderMale.
  ///
  /// In es_UY, this message translates to:
  /// **'Hombre'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In es_UY, this message translates to:
  /// **'Mujer'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In es_UY, this message translates to:
  /// **'Otro'**
  String get genderOther;

  /// No description provided for @countryAR.
  ///
  /// In es_UY, this message translates to:
  /// **'Argentina'**
  String get countryAR;

  /// No description provided for @countryBO.
  ///
  /// In es_UY, this message translates to:
  /// **'Bolivia'**
  String get countryBO;

  /// No description provided for @countryBR.
  ///
  /// In es_UY, this message translates to:
  /// **'Brasil'**
  String get countryBR;

  /// No description provided for @countryCL.
  ///
  /// In es_UY, this message translates to:
  /// **'Chile'**
  String get countryCL;

  /// No description provided for @countryCO.
  ///
  /// In es_UY, this message translates to:
  /// **'Colombia'**
  String get countryCO;

  /// No description provided for @countryEC.
  ///
  /// In es_UY, this message translates to:
  /// **'Ecuador'**
  String get countryEC;

  /// No description provided for @countryES.
  ///
  /// In es_UY, this message translates to:
  /// **'España'**
  String get countryES;

  /// No description provided for @countryUS.
  ///
  /// In es_UY, this message translates to:
  /// **'Estados Unidos'**
  String get countryUS;

  /// No description provided for @countryFR.
  ///
  /// In es_UY, this message translates to:
  /// **'Francia'**
  String get countryFR;

  /// No description provided for @countryIT.
  ///
  /// In es_UY, this message translates to:
  /// **'Italia'**
  String get countryIT;

  /// No description provided for @countryMX.
  ///
  /// In es_UY, this message translates to:
  /// **'México'**
  String get countryMX;

  /// No description provided for @countryPY.
  ///
  /// In es_UY, this message translates to:
  /// **'Paraguay'**
  String get countryPY;

  /// No description provided for @countryPE.
  ///
  /// In es_UY, this message translates to:
  /// **'Perú'**
  String get countryPE;

  /// No description provided for @countryPT.
  ///
  /// In es_UY, this message translates to:
  /// **'Portugal'**
  String get countryPT;

  /// No description provided for @countryGB.
  ///
  /// In es_UY, this message translates to:
  /// **'Reino Unido'**
  String get countryGB;

  /// No description provided for @countryUY.
  ///
  /// In es_UY, this message translates to:
  /// **'Uruguay'**
  String get countryUY;

  /// No description provided for @countryVE.
  ///
  /// In es_UY, this message translates to:
  /// **'Venezuela'**
  String get countryVE;

  /// No description provided for @statusOpen.
  ///
  /// In es_UY, this message translates to:
  /// **'Abierto'**
  String get statusOpen;

  /// No description provided for @statusFull.
  ///
  /// In es_UY, this message translates to:
  /// **'Completo'**
  String get statusFull;

  /// No description provided for @statusClosed.
  ///
  /// In es_UY, this message translates to:
  /// **'Cerrado'**
  String get statusClosed;

  /// No description provided for @inscriptionPending.
  ///
  /// In es_UY, this message translates to:
  /// **'Pendiente'**
  String get inscriptionPending;

  /// No description provided for @inscriptionConfirmed.
  ///
  /// In es_UY, this message translates to:
  /// **'Confirmada'**
  String get inscriptionConfirmed;

  /// No description provided for @inscriptionRejected.
  ///
  /// In es_UY, this message translates to:
  /// **'Rechazada'**
  String get inscriptionRejected;

  /// No description provided for @inscriptionCancelled.
  ///
  /// In es_UY, this message translates to:
  /// **'Cancelada'**
  String get inscriptionCancelled;

  /// No description provided for @loginTagline.
  ///
  /// In es_UY, this message translates to:
  /// **'Tu torneo empieza acá'**
  String get loginTagline;

  /// No description provided for @emailLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @invalidEmail.
  ///
  /// In es_UY, this message translates to:
  /// **'Ingresá un email válido'**
  String get invalidEmail;

  /// No description provided for @passwordLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @passwordTooShort.
  ///
  /// In es_UY, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get passwordTooShort;

  /// No description provided for @signIn.
  ///
  /// In es_UY, this message translates to:
  /// **'Iniciar sesión'**
  String get signIn;

  /// No description provided for @orContinueWith.
  ///
  /// In es_UY, this message translates to:
  /// **'o continuá con'**
  String get orContinueWith;

  /// No description provided for @continueWith.
  ///
  /// In es_UY, this message translates to:
  /// **'Continuar con {provider}'**
  String continueWith(Object provider);

  /// No description provided for @noAccountSignup.
  ///
  /// In es_UY, this message translates to:
  /// **'¿No tenés cuenta? Registrate'**
  String get noAccountSignup;

  /// No description provided for @browseAsGuest.
  ///
  /// In es_UY, this message translates to:
  /// **'Explorar eventos sin cuenta'**
  String get browseAsGuest;

  /// No description provided for @currencyLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Moneda'**
  String get currencyLabel;

  /// No description provided for @forgotPassword.
  ///
  /// In es_UY, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'Recuperar contraseña'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordBody.
  ///
  /// In es_UY, this message translates to:
  /// **'Ingresá tu email y te mandamos un enlace para elegir una contraseña nueva.'**
  String get forgotPasswordBody;

  /// No description provided for @sendResetLink.
  ///
  /// In es_UY, this message translates to:
  /// **'Enviar enlace'**
  String get sendResetLink;

  /// No description provided for @resetEmailSent.
  ///
  /// In es_UY, this message translates to:
  /// **'Si existe una cuenta con ese email, te enviamos un enlace para restablecer la contraseña.'**
  String get resetEmailSent;

  /// No description provided for @backToSignIn.
  ///
  /// In es_UY, this message translates to:
  /// **'Volver a iniciar sesión'**
  String get backToSignIn;

  /// No description provided for @newPassword.
  ///
  /// In es_UY, this message translates to:
  /// **'Contraseña nueva'**
  String get newPassword;

  /// No description provided for @resetPasswordBody.
  ///
  /// In es_UY, this message translates to:
  /// **'Elegí una contraseña nueva para tu cuenta.'**
  String get resetPasswordBody;

  /// No description provided for @savePassword.
  ///
  /// In es_UY, this message translates to:
  /// **'Guardar contraseña'**
  String get savePassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In es_UY, this message translates to:
  /// **'Contraseña actualizada.'**
  String get passwordUpdated;

  /// No description provided for @authUnknownAccount.
  ///
  /// In es_UY, this message translates to:
  /// **'Cuenta desconocida. Login demo: nico@demo.app / password123'**
  String get authUnknownAccount;

  /// No description provided for @authEmailTaken.
  ///
  /// In es_UY, this message translates to:
  /// **'Ya existe una cuenta con ese email.'**
  String get authEmailTaken;

  /// No description provided for @authSocialMissing.
  ///
  /// In es_UY, this message translates to:
  /// **'Cuenta social demo no encontrada.'**
  String get authSocialMissing;

  /// No description provided for @authInvalidEmail.
  ///
  /// In es_UY, this message translates to:
  /// **'Ingresá un email válido.'**
  String get authInvalidEmail;

  /// No description provided for @authPasswordShort.
  ///
  /// In es_UY, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres.'**
  String get authPasswordShort;

  /// No description provided for @authSignInFailed.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo iniciar sesión.'**
  String get authSignInFailed;

  /// No description provided for @authBrowserFailed.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo abrir el navegador.'**
  String get authBrowserFailed;

  /// No description provided for @authOAuthCancelled.
  ///
  /// In es_UY, this message translates to:
  /// **'Se canceló el inicio de sesión con el proveedor.'**
  String get authOAuthCancelled;

  /// No description provided for @signupHeroTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'Unite a Tande'**
  String get signupHeroTitle;

  /// No description provided for @signupHeroSubtitle.
  ///
  /// In es_UY, this message translates to:
  /// **'Registrate para inscribirte a eventos y organizar los tuyos.'**
  String get signupHeroSubtitle;

  /// No description provided for @fullName.
  ///
  /// In es_UY, this message translates to:
  /// **'Nombre completo'**
  String get fullName;

  /// No description provided for @enterName.
  ///
  /// In es_UY, this message translates to:
  /// **'Ingresá tu nombre'**
  String get enterName;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In es_UY, this message translates to:
  /// **'¿Ya tenés cuenta? Iniciá sesión'**
  String get alreadyHaveAccount;

  /// No description provided for @aboutYou.
  ///
  /// In es_UY, this message translates to:
  /// **'Sobre vos'**
  String get aboutYou;

  /// No description provided for @gender.
  ///
  /// In es_UY, this message translates to:
  /// **'Género'**
  String get gender;

  /// No description provided for @whatDoYouPlay.
  ///
  /// In es_UY, this message translates to:
  /// **'¿Qué jugás?'**
  String get whatDoYouPlay;

  /// No description provided for @sportsFilterHint.
  ///
  /// In es_UY, this message translates to:
  /// **'Tus deportes filtran los eventos que ves en Explorar.'**
  String get sportsFilterHint;

  /// No description provided for @createAccount.
  ///
  /// In es_UY, this message translates to:
  /// **'Crear cuenta'**
  String get createAccount;

  /// No description provided for @chooseBirthDate.
  ///
  /// In es_UY, this message translates to:
  /// **'Elegí tu fecha de nacimiento'**
  String get chooseBirthDate;

  /// No description provided for @mustBe18.
  ///
  /// In es_UY, this message translates to:
  /// **'Tenés que tener 18 años o más para usar Tande.'**
  String get mustBe18;

  /// No description provided for @chooseSport.
  ///
  /// In es_UY, this message translates to:
  /// **'Elegí al menos un deporte'**
  String get chooseSport;

  /// No description provided for @bannerSectionLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Imagen del torneo'**
  String get bannerSectionLabel;

  /// No description provided for @bannerHint.
  ///
  /// In es_UY, this message translates to:
  /// **'Opcional. Se muestra en Explorar y en la ficha del torneo.'**
  String get bannerHint;

  /// No description provided for @bannerAdd.
  ///
  /// In es_UY, this message translates to:
  /// **'Agregar imagen'**
  String get bannerAdd;

  /// No description provided for @bannerChange.
  ///
  /// In es_UY, this message translates to:
  /// **'Cambiar imagen'**
  String get bannerChange;

  /// No description provided for @bannerRemove.
  ///
  /// In es_UY, this message translates to:
  /// **'Quitar imagen'**
  String get bannerRemove;

  /// No description provided for @bannerSaveFailed.
  ///
  /// In es_UY, this message translates to:
  /// **'Se guardó el evento, pero la imagen no se pudo subir. Probá de nuevo desde Editar.'**
  String get bannerSaveFailed;

  /// No description provided for @acceptTermsPrefix.
  ///
  /// In es_UY, this message translates to:
  /// **'Acepto los '**
  String get acceptTermsPrefix;

  /// No description provided for @termsAndConditions.
  ///
  /// In es_UY, this message translates to:
  /// **'Términos y condiciones'**
  String get termsAndConditions;

  /// No description provided for @acceptTermsError.
  ///
  /// In es_UY, this message translates to:
  /// **'Para crear la cuenta, aceptá los Términos y condiciones.'**
  String get acceptTermsError;

  /// No description provided for @socialTermsPrefix.
  ///
  /// In es_UY, this message translates to:
  /// **'Al continuar, aceptás los '**
  String get socialTermsPrefix;

  /// No description provided for @proTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'Tande Pro'**
  String get proTitle;

  /// No description provided for @proProfileHint.
  ///
  /// In es_UY, this message translates to:
  /// **'Torneos sin límites para organizadores'**
  String get proProfileHint;

  /// No description provided for @proChoosePlan.
  ///
  /// In es_UY, this message translates to:
  /// **'Elegí tu plan'**
  String get proChoosePlan;

  /// No description provided for @proBenefit1.
  ///
  /// In es_UY, this message translates to:
  /// **'Torneos activos ilimitados'**
  String get proBenefit1;

  /// No description provided for @proBenefit2.
  ///
  /// In es_UY, this message translates to:
  /// **'Exportar inscripciones a CSV (planilla lista para Excel)'**
  String get proBenefit2;

  /// No description provided for @proMonthly.
  ///
  /// In es_UY, this message translates to:
  /// **'Mensual'**
  String get proMonthly;

  /// No description provided for @proYearly.
  ///
  /// In es_UY, this message translates to:
  /// **'Anual'**
  String get proYearly;

  /// No description provided for @proBestValue.
  ///
  /// In es_UY, this message translates to:
  /// **'Mejor valor'**
  String get proBestValue;

  /// No description provided for @proTrialCta.
  ///
  /// In es_UY, this message translates to:
  /// **'Probar gratis'**
  String get proTrialCta;

  /// No description provided for @proSubscribeCta.
  ///
  /// In es_UY, this message translates to:
  /// **'Suscribirme'**
  String get proSubscribeCta;

  /// No description provided for @proTrialNotice.
  ///
  /// In es_UY, this message translates to:
  /// **'Prueba gratis por {days} días. Después se cobra la suscripción, salvo que la canceles antes.'**
  String proTrialNotice(Object days);

  /// No description provided for @proDisclosure.
  ///
  /// In es_UY, this message translates to:
  /// **'Suscripción con cargo a tu cuenta de Google Play. Se renueva automáticamente hasta que la cancelás; podés cancelarla cuando quieras desde Google Play.'**
  String get proDisclosure;

  /// No description provided for @proRestore.
  ///
  /// In es_UY, this message translates to:
  /// **'Restaurar compras'**
  String get proRestore;

  /// No description provided for @proRestoreMissing.
  ///
  /// In es_UY, this message translates to:
  /// **'No encontramos compras para restaurar.'**
  String get proRestoreMissing;

  /// No description provided for @proComingSoon.
  ///
  /// In es_UY, this message translates to:
  /// **'Próximamente'**
  String get proComingSoon;

  /// No description provided for @proComingSoonBody.
  ///
  /// In es_UY, this message translates to:
  /// **'Tande Pro se está por lanzar. ¡Volvé pronto!'**
  String get proComingSoonBody;

  /// No description provided for @proAlready.
  ///
  /// In es_UY, this message translates to:
  /// **'Ya tenés Tande Pro'**
  String get proAlready;

  /// No description provided for @proAlreadyBody.
  ///
  /// In es_UY, this message translates to:
  /// **'Tus torneos activos no tienen límite.'**
  String get proAlreadyBody;

  /// No description provided for @proPurchaseError.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo completar la compra. Intentá de nuevo.'**
  String get proPurchaseError;

  /// No description provided for @proLegalPrefix.
  ///
  /// In es_UY, this message translates to:
  /// **'Leé los '**
  String get proLegalPrefix;

  /// No description provided for @privacyPolicy.
  ///
  /// In es_UY, this message translates to:
  /// **'Política de privacidad'**
  String get privacyPolicy;

  /// No description provided for @accountCreatedConfirmEmail.
  ///
  /// In es_UY, this message translates to:
  /// **'Cuenta creada. Revisá tu email para confirmarla y luego iniciá sesión.'**
  String get accountCreatedConfirmEmail;

  /// No description provided for @pwUseAtLeast8.
  ///
  /// In es_UY, this message translates to:
  /// **'Usá al menos 8 caracteres'**
  String get pwUseAtLeast8;

  /// No description provided for @pwAddUppercase.
  ///
  /// In es_UY, this message translates to:
  /// **'Agregá una letra mayúscula'**
  String get pwAddUppercase;

  /// No description provided for @pwAddLowercase.
  ///
  /// In es_UY, this message translates to:
  /// **'Agregá una letra minúscula'**
  String get pwAddLowercase;

  /// No description provided for @pwAddNumber.
  ///
  /// In es_UY, this message translates to:
  /// **'Agregá un número'**
  String get pwAddNumber;

  /// No description provided for @pwCheckAtLeast8.
  ///
  /// In es_UY, this message translates to:
  /// **'Al menos 8 caracteres'**
  String get pwCheckAtLeast8;

  /// No description provided for @pwCheckUppercase.
  ///
  /// In es_UY, this message translates to:
  /// **'Una mayúscula'**
  String get pwCheckUppercase;

  /// No description provided for @pwCheckLowercase.
  ///
  /// In es_UY, this message translates to:
  /// **'Una minúscula'**
  String get pwCheckLowercase;

  /// No description provided for @pwCheckNumber.
  ///
  /// In es_UY, this message translates to:
  /// **'Un número'**
  String get pwCheckNumber;

  /// No description provided for @usernameLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Nombre de usuario'**
  String get usernameLabel;

  /// No description provided for @usernameHelp.
  ///
  /// In es_UY, this message translates to:
  /// **'Letras, números, puntos y guiones bajos'**
  String get usernameHelp;

  /// No description provided for @usernameRequired.
  ///
  /// In es_UY, this message translates to:
  /// **'Elegí un nombre de usuario'**
  String get usernameRequired;

  /// No description provided for @usernameFormat.
  ///
  /// In es_UY, this message translates to:
  /// **'Solo letras, números, . y _'**
  String get usernameFormat;

  /// No description provided for @usernameTaken.
  ///
  /// In es_UY, this message translates to:
  /// **'Ese nombre de usuario ya está en uso.'**
  String get usernameTaken;

  /// No description provided for @birthDate.
  ///
  /// In es_UY, this message translates to:
  /// **'Fecha de nacimiento'**
  String get birthDate;

  /// No description provided for @tapToChoose.
  ///
  /// In es_UY, this message translates to:
  /// **'Tocá para elegir'**
  String get tapToChoose;

  /// No description provided for @noSession.
  ///
  /// In es_UY, this message translates to:
  /// **'No hay sesión iniciada'**
  String get noSession;

  /// No description provided for @saveFailed.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo guardar: {error}'**
  String saveFailed(Object error);

  /// No description provided for @sportsYouPlay.
  ///
  /// In es_UY, this message translates to:
  /// **'Deportes que jugás'**
  String get sportsYouPlay;

  /// No description provided for @country.
  ///
  /// In es_UY, this message translates to:
  /// **'País'**
  String get country;

  /// No description provided for @phoneOptional.
  ///
  /// In es_UY, this message translates to:
  /// **'Teléfono / WhatsApp (opcional)'**
  String get phoneOptional;

  /// No description provided for @phoneHelp.
  ///
  /// In es_UY, this message translates to:
  /// **'Sin el código de país, ej.: 911 2233-4455'**
  String get phoneHelp;

  /// No description provided for @phoneInvalid.
  ///
  /// In es_UY, this message translates to:
  /// **'Ingresá un número válido'**
  String get phoneInvalid;

  /// No description provided for @organizerMode.
  ///
  /// In es_UY, this message translates to:
  /// **'Organizo torneos'**
  String get organizerMode;

  /// No description provided for @organizerModeHint.
  ///
  /// In es_UY, this message translates to:
  /// **'Muestra la pestaña Organizar para crear eventos'**
  String get organizerModeHint;

  /// No description provided for @saveChanges.
  ///
  /// In es_UY, this message translates to:
  /// **'Guardar cambios'**
  String get saveChanges;

  /// No description provided for @startButton.
  ///
  /// In es_UY, this message translates to:
  /// **'Comenzar'**
  String get startButton;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'¿Cerrar sesión?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmMessage.
  ///
  /// In es_UY, this message translates to:
  /// **'Podés volver a iniciar sesión cuando quieras.'**
  String get signOutConfirmMessage;

  /// No description provided for @signOut.
  ///
  /// In es_UY, this message translates to:
  /// **'Cerrar sesión'**
  String get signOut;

  /// No description provided for @notSignedIn.
  ///
  /// In es_UY, this message translates to:
  /// **'No has iniciado sesión.'**
  String get notSignedIn;

  /// No description provided for @incompleteProfile.
  ///
  /// In es_UY, this message translates to:
  /// **'Tu perfil está incompleto'**
  String get incompleteProfile;

  /// No description provided for @completeProfileHint.
  ///
  /// In es_UY, this message translates to:
  /// **'Completalo para inscribirte a eventos.'**
  String get completeProfileHint;

  /// No description provided for @phoneLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Teléfono / WhatsApp'**
  String get phoneLabel;

  /// No description provided for @role.
  ///
  /// In es_UY, this message translates to:
  /// **'Rol'**
  String get role;

  /// No description provided for @organizer.
  ///
  /// In es_UY, this message translates to:
  /// **'Organizador'**
  String get organizer;

  /// No description provided for @player.
  ///
  /// In es_UY, this message translates to:
  /// **'Jugador'**
  String get player;

  /// No description provided for @sportsTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'Deportes'**
  String get sportsTitle;

  /// No description provided for @editProfile.
  ///
  /// In es_UY, this message translates to:
  /// **'Editar perfil'**
  String get editProfile;

  /// No description provided for @filters.
  ///
  /// In es_UY, this message translates to:
  /// **'Filtros'**
  String get filters;

  /// No description provided for @switchToList.
  ///
  /// In es_UY, this message translates to:
  /// **'Cambiar a lista'**
  String get switchToList;

  /// No description provided for @switchToMap.
  ///
  /// In es_UY, this message translates to:
  /// **'Cambiar a mapa'**
  String get switchToMap;

  /// No description provided for @exploreLoadError.
  ///
  /// In es_UY, this message translates to:
  /// **'Algo salió mal al cargar los eventos.'**
  String get exploreLoadError;

  /// No description provided for @searchHint.
  ///
  /// In es_UY, this message translates to:
  /// **'Buscar eventos, canchas, ciudades'**
  String get searchHint;

  /// No description provided for @noLocationTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'No pudimos encontrar tu ubicación'**
  String get noLocationTitle;

  /// No description provided for @noLocationBody.
  ///
  /// In es_UY, this message translates to:
  /// **'Activá la ubicación para ver los torneos cerca tuyo.'**
  String get noLocationBody;

  /// No description provided for @useMyLocation.
  ///
  /// In es_UY, this message translates to:
  /// **'Usar mi ubicación'**
  String get useMyLocation;

  /// No description provided for @sport.
  ///
  /// In es_UY, this message translates to:
  /// **'Deporte'**
  String get sport;

  /// No description provided for @all.
  ///
  /// In es_UY, this message translates to:
  /// **'Todos'**
  String get all;

  /// No description provided for @distanceFrom.
  ///
  /// In es_UY, this message translates to:
  /// **'Distancia desde mi ubicación'**
  String get distanceFrom;

  /// No description provided for @any.
  ///
  /// In es_UY, this message translates to:
  /// **'Cualquiera'**
  String get any;

  /// No description provided for @updateLocation.
  ///
  /// In es_UY, this message translates to:
  /// **'Actualizar ubicación'**
  String get updateLocation;

  /// No description provided for @onlyAvailable.
  ///
  /// In es_UY, this message translates to:
  /// **'Solo eventos con lugares disponibles'**
  String get onlyAvailable;

  /// No description provided for @spotsLeft.
  ///
  /// In es_UY, this message translates to:
  /// **'{count, plural, =1{{count} lugar libre} other{{count} lugares libres}}'**
  String spotsLeft(int count);

  /// No description provided for @noTournaments.
  ///
  /// In es_UY, this message translates to:
  /// **'No se encontraron torneos'**
  String get noTournaments;

  /// No description provided for @noTournamentsBody.
  ///
  /// In es_UY, this message translates to:
  /// **'Probá con otra búsqueda o borrá los filtros.'**
  String get noTournamentsBody;

  /// No description provided for @clearFilters.
  ///
  /// In es_UY, this message translates to:
  /// **'Borrar filtros'**
  String get clearFilters;

  /// No description provided for @eventsInArea.
  ///
  /// In es_UY, this message translates to:
  /// **'{count, plural, =1{{count} evento en esta zona} other{{count} eventos en esta zona}}'**
  String eventsInArea(int count);

  /// No description provided for @centerOnMe.
  ///
  /// In es_UY, this message translates to:
  /// **'Centrar en mi ubicación'**
  String get centerOnMe;

  /// No description provided for @viewDetails.
  ///
  /// In es_UY, this message translates to:
  /// **'Ver detalle'**
  String get viewDetails;

  /// No description provided for @filterAll.
  ///
  /// In es_UY, this message translates to:
  /// **'Todas'**
  String get filterAll;

  /// No description provided for @filterPending.
  ///
  /// In es_UY, this message translates to:
  /// **'Pendientes'**
  String get filterPending;

  /// No description provided for @filterConfirmed.
  ///
  /// In es_UY, this message translates to:
  /// **'Confirmadas'**
  String get filterConfirmed;

  /// No description provided for @filterRejected.
  ///
  /// In es_UY, this message translates to:
  /// **'Rechazadas'**
  String get filterRejected;

  /// No description provided for @filterWaitlist.
  ///
  /// In es_UY, this message translates to:
  /// **'En espera'**
  String get filterWaitlist;

  /// No description provided for @emptyRequestsWaitlist.
  ///
  /// In es_UY, this message translates to:
  /// **'Nadie en lista de espera todavía.'**
  String get emptyRequestsWaitlist;

  /// No description provided for @joinWaitlist.
  ///
  /// In es_UY, this message translates to:
  /// **'Anotarme en lista de espera'**
  String get joinWaitlist;

  /// No description provided for @waitlistSuccess.
  ///
  /// In es_UY, this message translates to:
  /// **'Quedaste en lista de espera. Si se libera un cupo te confirmamos y el organizador te avisa.'**
  String get waitlistSuccess;

  /// No description provided for @waitlistedTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'En lista de espera'**
  String get waitlistedTitle;

  /// No description provided for @waitlistedHint.
  ///
  /// In es_UY, this message translates to:
  /// **'El torneo está lleno. Te avisamos si se libera un cupo.'**
  String get waitlistedHint;

  /// No description provided for @inscriptionWaitlisted.
  ///
  /// In es_UY, this message translates to:
  /// **'En espera'**
  String get inscriptionWaitlisted;

  /// No description provided for @exportCsv.
  ///
  /// In es_UY, this message translates to:
  /// **'Exportar inscripciones (CSV)'**
  String get exportCsv;

  /// No description provided for @exportCsvEmpty.
  ///
  /// In es_UY, this message translates to:
  /// **'Todavía no hay inscripciones para exportar.'**
  String get exportCsvEmpty;

  /// No description provided for @exportCsvFailed.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo preparar la planilla. Probá de nuevo.'**
  String get exportCsvFailed;

  /// No description provided for @duplicateEvent.
  ///
  /// In es_UY, this message translates to:
  /// **'Duplicar torneo'**
  String get duplicateEvent;

  /// No description provided for @myLoadError.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudieron cargar las inscripciones: {error}'**
  String myLoadError(Object error);

  /// No description provided for @emptyInscriptionsAll.
  ///
  /// In es_UY, this message translates to:
  /// **'No hay inscripciones todavía'**
  String get emptyInscriptionsAll;

  /// No description provided for @emptyInscriptionsPending.
  ///
  /// In es_UY, this message translates to:
  /// **'No hay inscripciones pendientes'**
  String get emptyInscriptionsPending;

  /// No description provided for @emptyInscriptionsConfirmed.
  ///
  /// In es_UY, this message translates to:
  /// **'No hay inscripciones confirmadas'**
  String get emptyInscriptionsConfirmed;

  /// No description provided for @searchNoResults.
  ///
  /// In es_UY, this message translates to:
  /// **'No encontramos eventos que coincidan con \"{query}\".'**
  String searchNoResults(Object query);

  /// No description provided for @searchMyInscriptions.
  ///
  /// In es_UY, this message translates to:
  /// **'Buscar mis inscripciones'**
  String get searchMyInscriptions;

  /// No description provided for @fallbackTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'Torneo'**
  String get fallbackTitle;

  /// No description provided for @noInscriptionsTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'Todavía no tenés inscripciones'**
  String get noInscriptionsTitle;

  /// No description provided for @noInscriptionsBody.
  ///
  /// In es_UY, this message translates to:
  /// **'Encontrá un torneo cerca tuyo — el pago se coordina directamente con el organizador.'**
  String get noInscriptionsBody;

  /// No description provided for @exploreEvents.
  ///
  /// In es_UY, this message translates to:
  /// **'Explorar eventos'**
  String get exploreEvents;

  /// No description provided for @sortSoonest.
  ///
  /// In es_UY, this message translates to:
  /// **'Más próximos'**
  String get sortSoonest;

  /// No description provided for @sortCreated.
  ///
  /// In es_UY, this message translates to:
  /// **'Creados recientemente'**
  String get sortCreated;

  /// No description provided for @sortTitleAZ.
  ///
  /// In es_UY, this message translates to:
  /// **'Título (A–Z)'**
  String get sortTitleAZ;

  /// No description provided for @sortMenu.
  ///
  /// In es_UY, this message translates to:
  /// **'Ordenar'**
  String get sortMenu;

  /// No description provided for @organizerLoadError.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudieron cargar tus eventos: {error}'**
  String organizerLoadError(Object error);

  /// No description provided for @searchMyEvents.
  ///
  /// In es_UY, this message translates to:
  /// **'Buscar mis eventos'**
  String get searchMyEvents;

  /// No description provided for @createEvent.
  ///
  /// In es_UY, this message translates to:
  /// **'Crear evento'**
  String get createEvent;

  /// No description provided for @organizerGateTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'El modo organizador está desactivado'**
  String get organizerGateTitle;

  /// No description provided for @organizerGateBody.
  ///
  /// In es_UY, this message translates to:
  /// **'Activalo desde tu perfil para crear eventos y confirmar a los jugadores después de que te paguen directamente.'**
  String get organizerGateBody;

  /// No description provided for @goToProfile.
  ///
  /// In es_UY, this message translates to:
  /// **'Ir al perfil'**
  String get goToProfile;

  /// No description provided for @noEventsTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'Todavía no hay eventos'**
  String get noEventsTitle;

  /// No description provided for @noEventsBody.
  ///
  /// In es_UY, this message translates to:
  /// **'Creá tu primer evento. Los jugadores se inscriben acá y te pagan directamente — vos confirmás cada lugar.'**
  String get noEventsBody;

  /// No description provided for @pastEvents.
  ///
  /// In es_UY, this message translates to:
  /// **'Eventos pasados'**
  String get pastEvents;

  /// No description provided for @spotsOf.
  ///
  /// In es_UY, this message translates to:
  /// **'{confirmed} de {total, plural, =1{{total} lugar} other{{total} lugares}}'**
  String spotsOf(int confirmed, int total);

  /// No description provided for @requestsCount.
  ///
  /// In es_UY, this message translates to:
  /// **'{count, plural, =1{{count} solicitud} other{{count} solicitudes}}'**
  String requestsCount(int count);

  /// No description provided for @eventLoadError.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo cargar el evento: {error}'**
  String eventLoadError(Object error);

  /// No description provided for @formatLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Formato'**
  String get formatLabel;

  /// No description provided for @titleLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Título'**
  String get titleLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Descripción'**
  String get descriptionLabel;

  /// No description provided for @prizesLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Premios (opcional)'**
  String get prizesLabel;

  /// No description provided for @startsLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Comienza'**
  String get startsLabel;

  /// No description provided for @endsLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Finaliza'**
  String get endsLabel;

  /// No description provided for @teamsLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Equipos'**
  String get teamsLabel;

  /// No description provided for @spotsTotal.
  ///
  /// In es_UY, this message translates to:
  /// **'Lugares disponibles en total'**
  String get spotsTotal;

  /// No description provided for @costLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Costo de inscripción'**
  String get costLabel;

  /// No description provided for @costFreeHint.
  ///
  /// In es_UY, this message translates to:
  /// **'Dejalo vacío si el evento es gratis'**
  String get costFreeHint;

  /// No description provided for @venueLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Nombre de la sede'**
  String get venueLabel;

  /// No description provided for @addressLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Dirección'**
  String get addressLabel;

  /// No description provided for @cityLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Ciudad'**
  String get cityLabel;

  /// No description provided for @locationLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Ubicación'**
  String get locationLabel;

  /// No description provided for @locationHint.
  ///
  /// In es_UY, this message translates to:
  /// **'Tocá el mapa para ubicar el pin de la sede. Usá tu ubicación actual para completar la dirección.'**
  String get locationHint;

  /// No description provided for @pinPlaced.
  ///
  /// In es_UY, this message translates to:
  /// **'Pin ubicado en {lat}, {lng}'**
  String pinPlaced(Object lat, Object lng);

  /// No description provided for @publishEvent.
  ///
  /// In es_UY, this message translates to:
  /// **'Publicar evento'**
  String get publishEvent;

  /// No description provided for @locationDenied.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo obtener tu ubicación. Revisá los permisos de la app.'**
  String get locationDenied;

  /// No description provided for @locationNoAddress.
  ///
  /// In es_UY, this message translates to:
  /// **'Ubicación actualizada. No se pudo completar la dirección.'**
  String get locationNoAddress;

  /// No description provided for @addressFilled.
  ///
  /// In es_UY, this message translates to:
  /// **'Dirección completada con tu ubicación.'**
  String get addressFilled;

  /// No description provided for @locationUpdated.
  ///
  /// In es_UY, this message translates to:
  /// **'Ubicación actualizada.'**
  String get locationUpdated;

  /// No description provided for @addressFailed.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo completar la dirección desde el punto elegido. Escribila a mano.'**
  String get addressFailed;

  /// No description provided for @required.
  ///
  /// In es_UY, this message translates to:
  /// **'Obligatorio'**
  String get required;

  /// No description provided for @minOneTeam.
  ///
  /// In es_UY, this message translates to:
  /// **'Ingresá un número igual o mayor a 1'**
  String get minOneTeam;

  /// No description provided for @invalidAmount.
  ///
  /// In es_UY, this message translates to:
  /// **'Ingresá un monto válido'**
  String get invalidAmount;

  /// No description provided for @endDateBeforeStart.
  ///
  /// In es_UY, this message translates to:
  /// **'La fecha de fin debe ser posterior a la de inicio.'**
  String get endDateBeforeStart;

  /// No description provided for @eventNotFound.
  ///
  /// In es_UY, this message translates to:
  /// **'Evento no encontrado'**
  String get eventNotFound;

  /// No description provided for @capBelowConfirmed.
  ///
  /// In es_UY, this message translates to:
  /// **'No podés bajar el cupo por debajo de los equipos confirmados ({confirmed}).'**
  String capBelowConfirmed(Object confirmed);

  /// No description provided for @eventSaved.
  ///
  /// In es_UY, this message translates to:
  /// **'Evento guardado'**
  String get eventSaved;

  /// No description provided for @eventPublished.
  ///
  /// In es_UY, this message translates to:
  /// **'Evento publicado'**
  String get eventPublished;

  /// No description provided for @eventSaveError.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo guardar el evento: {error}'**
  String eventSaveError(Object error);

  /// No description provided for @editEvent.
  ///
  /// In es_UY, this message translates to:
  /// **'Editar evento'**
  String get editEvent;

  /// No description provided for @moreActions.
  ///
  /// In es_UY, this message translates to:
  /// **'Más acciones'**
  String get moreActions;

  /// No description provided for @closeRegistrations.
  ///
  /// In es_UY, this message translates to:
  /// **'Cerrar inscripciones'**
  String get closeRegistrations;

  /// No description provided for @reopenRegistrations.
  ///
  /// In es_UY, this message translates to:
  /// **'Reabrir inscripciones'**
  String get reopenRegistrations;

  /// No description provided for @deleteEvent.
  ///
  /// In es_UY, this message translates to:
  /// **'Eliminar evento'**
  String get deleteEvent;

  /// No description provided for @registrationsClosed.
  ///
  /// In es_UY, this message translates to:
  /// **'Inscripciones cerradas'**
  String get registrationsClosed;

  /// No description provided for @registrationsReopened.
  ///
  /// In es_UY, this message translates to:
  /// **'Inscripciones reabiertas'**
  String get registrationsReopened;

  /// No description provided for @requestsLoadError.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudieron cargar las solicitudes: {error}'**
  String requestsLoadError(Object error);

  /// No description provided for @emptyRequestsPending.
  ///
  /// In es_UY, this message translates to:
  /// **'No hay solicitudes pendientes'**
  String get emptyRequestsPending;

  /// No description provided for @emptyRequestsConfirmed.
  ///
  /// In es_UY, this message translates to:
  /// **'No hay solicitudes confirmadas'**
  String get emptyRequestsConfirmed;

  /// No description provided for @emptyRequestsRejected.
  ///
  /// In es_UY, this message translates to:
  /// **'No hay solicitudes rechazadas'**
  String get emptyRequestsRejected;

  /// No description provided for @updateEventError.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo actualizar el evento: {error}'**
  String updateEventError(Object error);

  /// No description provided for @outsideUpdated.
  ///
  /// In es_UY, this message translates to:
  /// **'Confirmados fuera de la app actualizados'**
  String get outsideUpdated;

  /// No description provided for @updateError.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo actualizar: {error}'**
  String updateError(Object error);

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'¿Eliminar evento?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In es_UY, this message translates to:
  /// **'Esto elimina el evento y todas sus inscripciones. No se puede deshacer.'**
  String get deleteConfirmMessage;

  /// No description provided for @deleteError.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo eliminar el evento: {error}'**
  String deleteError(Object error);

  /// No description provided for @registrationConfirmed.
  ///
  /// In es_UY, this message translates to:
  /// **'Inscripción confirmada'**
  String get registrationConfirmed;

  /// No description provided for @registrationRejected.
  ///
  /// In es_UY, this message translates to:
  /// **'Inscripción rechazada'**
  String get registrationRejected;

  /// No description provided for @notifyWhatsApp.
  ///
  /// In es_UY, this message translates to:
  /// **'Avisar por WhatsApp'**
  String get notifyWhatsApp;

  /// No description provided for @whatsappOpenFailed.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo abrir WhatsApp. Llamá al {phone}.'**
  String whatsappOpenFailed(Object phone);

  /// No description provided for @requestedOn.
  ///
  /// In es_UY, this message translates to:
  /// **'Solicitada el {date}'**
  String requestedOn(Object date);

  /// No description provided for @confirm.
  ///
  /// In es_UY, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @reject.
  ///
  /// In es_UY, this message translates to:
  /// **'Rechazar'**
  String get reject;

  /// No description provided for @outsideTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'Confirmados fuera de la app'**
  String get outsideTitle;

  /// No description provided for @outsideShortTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'Fuera de la app'**
  String get outsideShortTitle;

  /// No description provided for @outsideHelp.
  ///
  /// In es_UY, this message translates to:
  /// **'Equipos que confirmaron por tu cuenta (efectivo, en persona, WhatsApp).'**
  String get outsideHelp;

  /// No description provided for @contactChannelsTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'Cómo te contactan'**
  String get contactChannelsTitle;

  /// No description provided for @contactChannelsHelp.
  ///
  /// In es_UY, this message translates to:
  /// **'Además del teléfono. Los jugadores las ven al tocar Contactar.'**
  String get contactChannelsHelp;

  /// No description provided for @contactAction.
  ///
  /// In es_UY, this message translates to:
  /// **'Contactar'**
  String get contactAction;

  /// No description provided for @contactSheetTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'Contactar a {name}'**
  String contactSheetTitle(Object name);

  /// No description provided for @contactWhatsApp.
  ///
  /// In es_UY, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsApp;

  /// No description provided for @contactCall.
  ///
  /// In es_UY, this message translates to:
  /// **'Llamar'**
  String get contactCall;

  /// No description provided for @contactInstagram.
  ///
  /// In es_UY, this message translates to:
  /// **'Instagram'**
  String get contactInstagram;

  /// No description provided for @contactTelegram.
  ///
  /// In es_UY, this message translates to:
  /// **'Telegram'**
  String get contactTelegram;

  /// No description provided for @contactLink.
  ///
  /// In es_UY, this message translates to:
  /// **'Ver enlace'**
  String get contactLink;

  /// No description provided for @contactLinkDefault.
  ///
  /// In es_UY, this message translates to:
  /// **'Formulario o enlace'**
  String get contactLinkDefault;

  /// No description provided for @contactOpenFailed.
  ///
  /// In es_UY, this message translates to:
  /// **'No pudimos abrir esa vía. Probá con otra.'**
  String get contactOpenFailed;

  /// No description provided for @instagramOptional.
  ///
  /// In es_UY, this message translates to:
  /// **'Instagram (opcional)'**
  String get instagramOptional;

  /// No description provided for @instagramHint.
  ///
  /// In es_UY, this message translates to:
  /// **'@tuclub'**
  String get instagramHint;

  /// No description provided for @telegramOptional.
  ///
  /// In es_UY, this message translates to:
  /// **'Telegram (opcional)'**
  String get telegramOptional;

  /// No description provided for @telegramHint.
  ///
  /// In es_UY, this message translates to:
  /// **'@tuclub'**
  String get telegramHint;

  /// No description provided for @contactUrlOptional.
  ///
  /// In es_UY, this message translates to:
  /// **'Formulario o enlace (opcional)'**
  String get contactUrlOptional;

  /// No description provided for @contactUrlHelp.
  ///
  /// In es_UY, this message translates to:
  /// **'Un Google Form, una planilla o el sitio del club.'**
  String get contactUrlHelp;

  /// No description provided for @contactUrlInvalid.
  ///
  /// In es_UY, this message translates to:
  /// **'Poné un enlace válido (https://…)'**
  String get contactUrlInvalid;

  /// No description provided for @decreaseOne.
  ///
  /// In es_UY, this message translates to:
  /// **'Quitar uno'**
  String get decreaseOne;

  /// No description provided for @increaseOne.
  ///
  /// In es_UY, this message translates to:
  /// **'Agregar uno'**
  String get increaseOne;

  /// No description provided for @outsideFull.
  ///
  /// In es_UY, this message translates to:
  /// **'Las {confirmed} confirmadas en la app ya llenan el cupo.'**
  String outsideFull(Object confirmed);

  /// No description provided for @outsideMax.
  ///
  /// In es_UY, this message translates to:
  /// **'En la app hay {confirmed} confirmadas. El total no puede superar {total}.'**
  String outsideMax(Object confirmed, Object total);

  /// No description provided for @registerSuccessNoContact.
  ///
  /// In es_UY, this message translates to:
  /// **'Inscripción solicitada. Coordiná el pago directamente con el organizador.'**
  String get registerSuccessNoContact;

  /// No description provided for @registerSuccessWhatsApp.
  ///
  /// In es_UY, this message translates to:
  /// **'Inscripción solicitada. Coordiná el pago por WhatsApp — el organizador confirma tu lugar.'**
  String get registerSuccessWhatsApp;

  /// No description provided for @registerSuccessFallback.
  ///
  /// In es_UY, this message translates to:
  /// **'Inscripción solicitada. Escribile al organizador por WhatsApp para coordinar el pago.'**
  String get registerSuccessFallback;

  /// No description provided for @registerError.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo inscribir: {error}'**
  String registerError(Object error);

  /// No description provided for @cancelConfirmTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'¿Cancelar inscripción?'**
  String get cancelConfirmTitle;

  /// No description provided for @cancelConfirmMessage.
  ///
  /// In es_UY, this message translates to:
  /// **'Se liberará tu lugar. Podés volver a inscribirte después, sujeto a disponibilidad.'**
  String get cancelConfirmMessage;

  /// No description provided for @cancelRegistration.
  ///
  /// In es_UY, this message translates to:
  /// **'Cancelar inscripción'**
  String get cancelRegistration;

  /// No description provided for @registrationCancelled.
  ///
  /// In es_UY, this message translates to:
  /// **'Inscripción cancelada'**
  String get registrationCancelled;

  /// No description provided for @cancelError.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo cancelar: {error}'**
  String cancelError(Object error);

  /// No description provided for @tournamentLoadError.
  ///
  /// In es_UY, this message translates to:
  /// **'No se pudo cargar el torneo: {error}'**
  String tournamentLoadError(Object error);

  /// No description provided for @tournamentNotFound.
  ///
  /// In es_UY, this message translates to:
  /// **'Torneo no encontrado'**
  String get tournamentNotFound;

  /// No description provided for @dateLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Fecha'**
  String get dateLabel;

  /// No description provided for @venueLabelShort.
  ///
  /// In es_UY, this message translates to:
  /// **'Sede'**
  String get venueLabelShort;

  /// No description provided for @prizesLabelShort.
  ///
  /// In es_UY, this message translates to:
  /// **'Premios'**
  String get prizesLabelShort;

  /// No description provided for @teamsCount.
  ///
  /// In es_UY, this message translates to:
  /// **'{count, plural, =1{{count} equipo} other{{count} equipos}}'**
  String teamsCount(int count);

  /// No description provided for @spotsTaken.
  ///
  /// In es_UY, this message translates to:
  /// **'{confirmed} de {total, plural, =1{{total} lugar tomado} other{{total} lugares tomados}}'**
  String spotsTaken(int confirmed, int total);

  /// No description provided for @aboutTournament.
  ///
  /// In es_UY, this message translates to:
  /// **'Acerca del torneo'**
  String get aboutTournament;

  /// No description provided for @organizerTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'Organizador'**
  String get organizerTitle;

  /// No description provided for @signInToRegister.
  ///
  /// In es_UY, this message translates to:
  /// **'Iniciar sesión para inscribirte'**
  String get signInToRegister;

  /// No description provided for @registeredTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'Estás inscripto'**
  String get registeredTitle;

  /// No description provided for @awaitingConfirmation.
  ///
  /// In es_UY, this message translates to:
  /// **'Esperando confirmación'**
  String get awaitingConfirmation;

  /// No description provided for @registrationsClosedButton.
  ///
  /// In es_UY, this message translates to:
  /// **'Inscripciones cerradas'**
  String get registrationsClosedButton;

  /// No description provided for @tournamentFull.
  ///
  /// In es_UY, this message translates to:
  /// **'Torneo completo'**
  String get tournamentFull;

  /// No description provided for @registerButton.
  ///
  /// In es_UY, this message translates to:
  /// **'Inscribirme'**
  String get registerButton;

  /// No description provided for @teamNameTitle.
  ///
  /// In es_UY, this message translates to:
  /// **'¿Con qué equipo te anotás?'**
  String get teamNameTitle;

  /// No description provided for @teamNameBody.
  ///
  /// In es_UY, this message translates to:
  /// **'Es el nombre que va a ver el organizador en su lista, y el que sale en la planilla.'**
  String get teamNameBody;

  /// No description provided for @teamNameLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'Nombre del equipo'**
  String get teamNameLabel;

  /// No description provided for @teamNameRequired.
  ///
  /// In es_UY, this message translates to:
  /// **'Poné un nombre para que el organizador te identifique.'**
  String get teamNameRequired;

  /// No description provided for @spotsLeftLabel.
  ///
  /// In es_UY, this message translates to:
  /// **'lugares libres'**
  String get spotsLeftLabel;

  /// No description provided for @noSpotsAvailable.
  ///
  /// In es_UY, this message translates to:
  /// **'No hay lugares disponibles'**
  String get noSpotsAvailable;

  /// No description provided for @paymentHint.
  ///
  /// In es_UY, this message translates to:
  /// **'Coordiná el pago con el organizador por WhatsApp; tu lugar se confirma cuando lo apruebe.'**
  String get paymentHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'es':
      {
        switch (locale.countryCode) {
          case 'UY':
            return AppLocalizationsEsUy();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
