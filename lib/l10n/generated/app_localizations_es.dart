// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navExplore => 'Explorar';

  @override
  String get navInscriptions => 'Inscripciones';

  @override
  String get navOrganize => 'Organizar';

  @override
  String get navProfile => 'Perfil';

  @override
  String get errorScreenTitle => 'No encontramos esa pantalla';

  @override
  String get errorScreenBody =>
      'Puede que el evento ya no exista o el enlace esté roto.';

  @override
  String get errorScreenBack => 'Volver a Explorar';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String get cancel => 'Cancelar';

  @override
  String get done => 'Listo';

  @override
  String get free => 'Gratis';

  @override
  String get retry => 'Reintentar';

  @override
  String get save => 'Guardar';

  @override
  String get apply => 'Aplicar';

  @override
  String get reset => 'Restablecer';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String loadError(Object error) {
    return 'Error: $error';
  }

  @override
  String get sportFootball => 'Fútbol';

  @override
  String get sportPadel => 'Pádel';

  @override
  String get sportTennis => 'Tenis';

  @override
  String get sportBasketball => 'Básquet';

  @override
  String get kindElimination => 'Eliminación';

  @override
  String get kindLeague => 'Liga';

  @override
  String get genderMale => 'Hombre';

  @override
  String get genderFemale => 'Mujer';

  @override
  String get genderOther => 'Otro';

  @override
  String get countryAR => 'Argentina';

  @override
  String get countryBO => 'Bolivia';

  @override
  String get countryBR => 'Brasil';

  @override
  String get countryCL => 'Chile';

  @override
  String get countryCO => 'Colombia';

  @override
  String get countryEC => 'Ecuador';

  @override
  String get countryES => 'España';

  @override
  String get countryUS => 'Estados Unidos';

  @override
  String get countryFR => 'Francia';

  @override
  String get countryIT => 'Italia';

  @override
  String get countryMX => 'México';

  @override
  String get countryPY => 'Paraguay';

  @override
  String get countryPE => 'Perú';

  @override
  String get countryPT => 'Portugal';

  @override
  String get countryGB => 'Reino Unido';

  @override
  String get countryUY => 'Uruguay';

  @override
  String get countryVE => 'Venezuela';

  @override
  String get statusOpen => 'Abierto';

  @override
  String get statusFull => 'Completo';

  @override
  String get statusClosed => 'Cerrado';

  @override
  String get inscriptionPending => 'Pendiente';

  @override
  String get inscriptionConfirmed => 'Confirmada';

  @override
  String get inscriptionRejected => 'Rechazada';

  @override
  String get inscriptionCancelled => 'Cancelada';

  @override
  String get loginTagline => 'Tu torneo empieza acá';

  @override
  String get emailLabel => 'Email';

  @override
  String get invalidEmail => 'Ingresá un email válido';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get orContinueWith => 'o continuá con';

  @override
  String continueWith(Object provider) {
    return 'Continuar con $provider';
  }

  @override
  String get noAccountSignup => '¿No tenés cuenta? Registrate';

  @override
  String get browseAsGuest => 'Explorar eventos sin cuenta';

  @override
  String get currencyLabel => 'Moneda';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get forgotPasswordTitle => 'Recuperar contraseña';

  @override
  String get forgotPasswordBody =>
      'Ingresá tu email y te mandamos un enlace para elegir una contraseña nueva.';

  @override
  String get sendResetLink => 'Enviar enlace';

  @override
  String get resetEmailSent =>
      'Si existe una cuenta con ese email, te enviamos un enlace para restablecer la contraseña.';

  @override
  String get backToSignIn => 'Volver a iniciar sesión';

  @override
  String get newPassword => 'Contraseña nueva';

  @override
  String get resetPasswordBody => 'Elegí una contraseña nueva para tu cuenta.';

  @override
  String get savePassword => 'Guardar contraseña';

  @override
  String get passwordUpdated => 'Contraseña actualizada.';

  @override
  String get authUnknownAccount =>
      'Cuenta desconocida. Login demo: nico@demo.app / password123';

  @override
  String get authEmailTaken => 'Ya existe una cuenta con ese email.';

  @override
  String get authSocialMissing => 'Cuenta social demo no encontrada.';

  @override
  String get authInvalidEmail => 'Ingresá un email válido.';

  @override
  String get authPasswordShort =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get authSignInFailed => 'No se pudo iniciar sesión.';

  @override
  String get authBrowserFailed => 'No se pudo abrir el navegador.';

  @override
  String get authOAuthCancelled =>
      'Se canceló el inicio de sesión con el proveedor.';

  @override
  String get signupHeroTitle => 'Unite a Bracket';

  @override
  String get signupHeroSubtitle =>
      'Registrate para inscribirte a eventos y organizar los tuyos.';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get enterName => 'Ingresá tu nombre';

  @override
  String get alreadyHaveAccount => '¿Ya tenés cuenta? Iniciá sesión';

  @override
  String get aboutYou => 'Sobre vos';

  @override
  String get gender => 'Género';

  @override
  String get whatDoYouPlay => '¿Qué jugás?';

  @override
  String get sportsFilterHint =>
      'Tus deportes filtran los eventos que ves en Explorar.';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get chooseBirthDate => 'Elegí tu fecha de nacimiento';

  @override
  String get chooseSport => 'Elegí al menos un deporte';

  @override
  String get acceptTermsPrefix => 'Acepto los ';

  @override
  String get termsAndConditions => 'Términos y condiciones';

  @override
  String get acceptTermsError =>
      'Para crear la cuenta, aceptá los Términos y condiciones.';

  @override
  String get socialTermsPrefix => 'Al continuar, aceptás los ';

  @override
  String get proTitle => 'Bracket Pro';

  @override
  String get proProfileHint => 'Torneos sin límites para organizadores';

  @override
  String get proChoosePlan => 'Elegí tu plan';

  @override
  String get proBenefit1 => 'Torneos activos ilimitados';

  @override
  String get proBenefit2 => 'Exportar planillas a PDF y CSV';

  @override
  String get proBenefit3 => 'Listas de espera y suplentes';

  @override
  String get proBenefit4 => 'Estadísticas de tu torneo';

  @override
  String get proBenefit5 => 'Destacado en Explorar';

  @override
  String get proMonthly => 'Mensual';

  @override
  String get proYearly => 'Anual';

  @override
  String get proBestValue => 'Mejor valor';

  @override
  String get proTrialCta => 'Probar gratis';

  @override
  String get proSubscribeCta => 'Suscribirme';

  @override
  String proTrialNotice(Object days) {
    return 'Prueba gratis por $days días. Después se cobra la suscripción, salvo que la canceles antes.';
  }

  @override
  String get proDisclosure =>
      'Suscripción con cargo a tu cuenta de Google Play. Se renueva automáticamente hasta que la cancelás; podés cancelarla cuando quieras desde Google Play.';

  @override
  String get proRestore => 'Restaurar compras';

  @override
  String get proRestoreMissing => 'No encontramos compras para restaurar.';

  @override
  String get proComingSoon => 'Próximamente';

  @override
  String get proComingSoonBody =>
      'Bracket Pro se está por lanzar. ¡Volvé pronto!';

  @override
  String get proAlready => 'Ya tenés Bracket Pro';

  @override
  String get proAlreadyBody => 'Tus torneos activos no tienen límite.';

  @override
  String get proPurchaseError =>
      'No se pudo completar la compra. Intentá de nuevo.';

  @override
  String get proLegalPrefix => 'Leé los ';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get accountCreatedConfirmEmail =>
      'Cuenta creada. Revisá tu email para confirmarla y luego iniciá sesión.';

  @override
  String get pwUseAtLeast8 => 'Usá al menos 8 caracteres';

  @override
  String get pwAddUppercase => 'Agregá una letra mayúscula';

  @override
  String get pwAddLowercase => 'Agregá una letra minúscula';

  @override
  String get pwAddNumber => 'Agregá un número';

  @override
  String get pwCheckAtLeast8 => 'Al menos 8 caracteres';

  @override
  String get pwCheckUppercase => 'Una mayúscula';

  @override
  String get pwCheckLowercase => 'Una minúscula';

  @override
  String get pwCheckNumber => 'Un número';

  @override
  String get usernameLabel => 'Nombre de usuario';

  @override
  String get usernameHelp => 'Letras, números, puntos y guiones bajos';

  @override
  String get usernameRequired => 'Elegí un nombre de usuario';

  @override
  String get usernameFormat => 'Solo letras, números, . y _';

  @override
  String get usernameTaken => 'Ese nombre de usuario ya está en uso.';

  @override
  String get birthDate => 'Fecha de nacimiento';

  @override
  String get tapToChoose => 'Tocá para elegir';

  @override
  String get noSession => 'No hay sesión iniciada';

  @override
  String saveFailed(Object error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String get sportsYouPlay => 'Deportes que jugás';

  @override
  String get country => 'País';

  @override
  String get phoneOptional => 'Teléfono / WhatsApp (opcional)';

  @override
  String get phoneHelp => 'Sin el código de país, ej.: 911 2233-4455';

  @override
  String get phoneInvalid => 'Ingresá un número válido';

  @override
  String get organizerMode => 'Organizo torneos';

  @override
  String get organizerModeHint =>
      'Muestra la pestaña Organizar para crear eventos';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get startButton => 'Comenzar';

  @override
  String get signOutConfirmTitle => '¿Cerrar sesión?';

  @override
  String get signOutConfirmMessage =>
      'Podés volver a iniciar sesión cuando quieras.';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get notSignedIn => 'No has iniciado sesión.';

  @override
  String get incompleteProfile => 'Tu perfil está incompleto';

  @override
  String get completeProfileHint => 'Completalo para inscribirte a eventos.';

  @override
  String get phoneLabel => 'Teléfono / WhatsApp';

  @override
  String get role => 'Rol';

  @override
  String get organizer => 'Organizador';

  @override
  String get player => 'Jugador';

  @override
  String get sportsTitle => 'Deportes';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get filters => 'Filtros';

  @override
  String get switchToList => 'Cambiar a lista';

  @override
  String get switchToMap => 'Cambiar a mapa';

  @override
  String get exploreLoadError => 'Algo salió mal al cargar los eventos.';

  @override
  String get searchHint => 'Buscar eventos, canchas, ciudades';

  @override
  String get noLocationTitle => 'No pudimos encontrar tu ubicación';

  @override
  String get noLocationBody =>
      'Activá la ubicación para ver los torneos cerca tuyo.';

  @override
  String get useMyLocation => 'Usar mi ubicación';

  @override
  String get sport => 'Deporte';

  @override
  String get all => 'Todos';

  @override
  String get distanceFrom => 'Distancia desde mi ubicación';

  @override
  String get any => 'Cualquiera';

  @override
  String get updateLocation => 'Actualizar ubicación';

  @override
  String get onlyAvailable => 'Solo eventos con lugares disponibles';

  @override
  String spotsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lugares libres',
      one: '$count lugar libre',
    );
    return '$_temp0';
  }

  @override
  String get noTournaments => 'No se encontraron torneos';

  @override
  String get noTournamentsBody =>
      'Probá con otra búsqueda o borrá los filtros.';

  @override
  String get clearFilters => 'Borrar filtros';

  @override
  String eventsInArea(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos en esta zona',
      one: '$count evento en esta zona',
    );
    return '$_temp0';
  }

  @override
  String get centerOnMe => 'Centrar en mi ubicación';

  @override
  String get viewDetails => 'Ver detalle';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterPending => 'Pendientes';

  @override
  String get filterConfirmed => 'Confirmadas';

  @override
  String get filterRejected => 'Rechazadas';

  @override
  String myLoadError(Object error) {
    return 'No se pudieron cargar las inscripciones: $error';
  }

  @override
  String get emptyInscriptionsAll => 'No hay inscripciones todavía';

  @override
  String get emptyInscriptionsPending => 'No hay inscripciones pendientes';

  @override
  String get emptyInscriptionsConfirmed => 'No hay inscripciones confirmadas';

  @override
  String searchNoResults(Object query) {
    return 'No encontramos eventos que coincidan con \"$query\".';
  }

  @override
  String get searchMyInscriptions => 'Buscar mis inscripciones';

  @override
  String get fallbackTitle => 'Torneo';

  @override
  String get noInscriptionsTitle => 'Todavía no tenés inscripciones';

  @override
  String get noInscriptionsBody =>
      'Encontrá un torneo cerca tuyo — el pago se coordina directamente con el organizador.';

  @override
  String get exploreEvents => 'Explorar eventos';

  @override
  String get sortSoonest => 'Más próximos';

  @override
  String get sortCreated => 'Creados recientemente';

  @override
  String get sortTitleAZ => 'Título (A–Z)';

  @override
  String get sortMenu => 'Ordenar';

  @override
  String organizerLoadError(Object error) {
    return 'No se pudieron cargar tus eventos: $error';
  }

  @override
  String get searchMyEvents => 'Buscar mis eventos';

  @override
  String get createEvent => 'Crear evento';

  @override
  String get organizerGateTitle => 'El modo organizador está desactivado';

  @override
  String get organizerGateBody =>
      'Activalo desde tu perfil para crear eventos y confirmar a los jugadores después de que te paguen directamente.';

  @override
  String get goToProfile => 'Ir al perfil';

  @override
  String get noEventsTitle => 'Todavía no hay eventos';

  @override
  String get noEventsBody =>
      'Creá tu primer evento. Los jugadores se inscriben acá y te pagan directamente — vos confirmás cada lugar.';

  @override
  String get pastEvents => 'Eventos pasados';

  @override
  String spotsOf(int confirmed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total lugares',
      one: '$total lugar',
    );
    return '$confirmed de $_temp0';
  }

  @override
  String requestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count solicitudes',
      one: '$count solicitud',
    );
    return '$_temp0';
  }

  @override
  String eventLoadError(Object error) {
    return 'No se pudo cargar el evento: $error';
  }

  @override
  String get formatLabel => 'Formato';

  @override
  String get titleLabel => 'Título';

  @override
  String get descriptionLabel => 'Descripción';

  @override
  String get prizesLabel => 'Premios (opcional)';

  @override
  String get startsLabel => 'Comienza';

  @override
  String get endsLabel => 'Finaliza';

  @override
  String get teamsLabel => 'Equipos';

  @override
  String get spotsTotal => 'Lugares disponibles en total';

  @override
  String get costLabel => 'Costo de inscripción';

  @override
  String get costFreeHint => 'Dejalo vacío si el evento es gratis';

  @override
  String get venueLabel => 'Nombre de la sede';

  @override
  String get addressLabel => 'Dirección';

  @override
  String get cityLabel => 'Ciudad';

  @override
  String get locationLabel => 'Ubicación';

  @override
  String get locationHint =>
      'Tocá el mapa para ubicar el pin de la sede. Usá tu ubicación actual para completar la dirección.';

  @override
  String pinPlaced(Object lat, Object lng) {
    return 'Pin ubicado en $lat, $lng';
  }

  @override
  String get publishEvent => 'Publicar evento';

  @override
  String get locationDenied =>
      'No se pudo obtener tu ubicación. Revisá los permisos de la app.';

  @override
  String get locationNoAddress =>
      'Ubicación actualizada. No se pudo completar la dirección.';

  @override
  String get addressFilled => 'Dirección completada con tu ubicación.';

  @override
  String get locationUpdated => 'Ubicación actualizada.';

  @override
  String get addressFailed =>
      'No se pudo completar la dirección desde el punto elegido. Escribila a mano.';

  @override
  String get required => 'Obligatorio';

  @override
  String get minOneTeam => 'Ingresá un número igual o mayor a 1';

  @override
  String get invalidAmount => 'Ingresá un monto válido';

  @override
  String get endDateBeforeStart =>
      'La fecha de fin debe ser posterior a la de inicio.';

  @override
  String get eventNotFound => 'Evento no encontrado';

  @override
  String capBelowConfirmed(Object confirmed) {
    return 'No podés bajar el cupo por debajo de los equipos confirmados ($confirmed).';
  }

  @override
  String get eventSaved => 'Evento guardado';

  @override
  String get eventPublished => 'Evento publicado';

  @override
  String eventSaveError(Object error) {
    return 'No se pudo guardar el evento: $error';
  }

  @override
  String get editEvent => 'Editar evento';

  @override
  String get moreActions => 'Más acciones';

  @override
  String get closeRegistrations => 'Cerrar inscripciones';

  @override
  String get reopenRegistrations => 'Reabrir inscripciones';

  @override
  String get deleteEvent => 'Eliminar evento';

  @override
  String get registrationsClosed => 'Inscripciones cerradas';

  @override
  String get registrationsReopened => 'Inscripciones reabiertas';

  @override
  String requestsLoadError(Object error) {
    return 'No se pudieron cargar las solicitudes: $error';
  }

  @override
  String get emptyRequestsPending => 'No hay solicitudes pendientes';

  @override
  String get emptyRequestsConfirmed => 'No hay solicitudes confirmadas';

  @override
  String get emptyRequestsRejected => 'No hay solicitudes rechazadas';

  @override
  String updateEventError(Object error) {
    return 'No se pudo actualizar el evento: $error';
  }

  @override
  String get outsideUpdated => 'Confirmados fuera de la app actualizados';

  @override
  String updateError(Object error) {
    return 'No se pudo actualizar: $error';
  }

  @override
  String get deleteConfirmTitle => '¿Eliminar evento?';

  @override
  String get deleteConfirmMessage =>
      'Esto elimina el evento y todas sus inscripciones. No se puede deshacer.';

  @override
  String deleteError(Object error) {
    return 'No se pudo eliminar el evento: $error';
  }

  @override
  String get registrationConfirmed => 'Inscripción confirmada';

  @override
  String get registrationRejected => 'Inscripción rechazada';

  @override
  String get notifyWhatsApp => 'Avisar por WhatsApp';

  @override
  String whatsappOpenFailed(Object phone) {
    return 'No se pudo abrir WhatsApp. Llamá al $phone.';
  }

  @override
  String requestedOn(Object date) {
    return 'Solicitada el $date';
  }

  @override
  String get confirm => 'Confirmar';

  @override
  String get reject => 'Rechazar';

  @override
  String get outsideTitle => 'Confirmados fuera de la app';

  @override
  String get outsideHelp =>
      'Equipos que confirmaron por tu cuenta (efectivo, en persona, WhatsApp).';

  @override
  String get decreaseOne => 'Quitar uno';

  @override
  String get increaseOne => 'Agregar uno';

  @override
  String outsideFull(Object confirmed) {
    return 'Las $confirmed confirmadas en la app ya llenan el cupo.';
  }

  @override
  String outsideMax(Object confirmed, Object total) {
    return 'En la app hay $confirmed confirmadas. El total no puede superar $total.';
  }

  @override
  String get registerSuccessNoContact =>
      'Inscripción solicitada. Coordiná el pago directamente con el organizador.';

  @override
  String get registerSuccessWhatsApp =>
      'Inscripción solicitada. Coordiná el pago por WhatsApp — el organizador confirma tu lugar.';

  @override
  String get registerSuccessFallback =>
      'Inscripción solicitada. Escribile al organizador por WhatsApp para coordinar el pago.';

  @override
  String registerError(Object error) {
    return 'No se pudo inscribir: $error';
  }

  @override
  String get cancelConfirmTitle => '¿Cancelar inscripción?';

  @override
  String get cancelConfirmMessage =>
      'Se liberará tu lugar. Podés volver a inscribirte después, sujeto a disponibilidad.';

  @override
  String get cancelRegistration => 'Cancelar inscripción';

  @override
  String get registrationCancelled => 'Inscripción cancelada';

  @override
  String cancelError(Object error) {
    return 'No se pudo cancelar: $error';
  }

  @override
  String tournamentLoadError(Object error) {
    return 'No se pudo cargar el torneo: $error';
  }

  @override
  String get tournamentNotFound => 'Torneo no encontrado';

  @override
  String get dateLabel => 'Fecha';

  @override
  String get venueLabelShort => 'Sede';

  @override
  String get prizesLabelShort => 'Premios';

  @override
  String teamsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count equipos',
      one: '$count equipo',
    );
    return '$_temp0';
  }

  @override
  String spotsTaken(int confirmed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total lugares tomados',
      one: '$total lugar tomado',
    );
    return '$confirmed de $_temp0';
  }

  @override
  String get aboutTournament => 'Acerca del torneo';

  @override
  String get organizerTitle => 'Organizador';

  @override
  String get signInToRegister => 'Iniciar sesión para inscribirte';

  @override
  String get registeredTitle => 'Estás inscripto';

  @override
  String get awaitingConfirmation => 'Esperando confirmación';

  @override
  String get registrationsClosedButton => 'Inscripciones cerradas';

  @override
  String get tournamentFull => 'Torneo completo';

  @override
  String get registerButton => 'Inscribirme';

  @override
  String get noSpotsAvailable => 'No hay lugares disponibles';

  @override
  String get paymentHint =>
      'Coordiná el pago con el organizador por WhatsApp; tu lugar se confirma cuando lo apruebe.';
}

/// The translations for Spanish Castilian, as used in Uruguay (`es_UY`).
class AppLocalizationsEsUy extends AppLocalizationsEs {
  AppLocalizationsEsUy() : super('es_UY');

  @override
  String get navExplore => 'Explorar';

  @override
  String get navInscriptions => 'Inscripciones';

  @override
  String get navOrganize => 'Organizar';

  @override
  String get navProfile => 'Perfil';

  @override
  String get errorScreenTitle => 'No encontramos esa pantalla';

  @override
  String get errorScreenBody =>
      'Puede que el evento ya no exista o el enlace esté roto.';

  @override
  String get errorScreenBack => 'Volver a Explorar';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String get cancel => 'Cancelar';

  @override
  String get done => 'Listo';

  @override
  String get free => 'Gratis';

  @override
  String get retry => 'Reintentar';

  @override
  String get save => 'Guardar';

  @override
  String get apply => 'Aplicar';

  @override
  String get reset => 'Restablecer';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String loadError(Object error) {
    return 'Error: $error';
  }

  @override
  String get sportFootball => 'Fútbol';

  @override
  String get sportPadel => 'Pádel';

  @override
  String get sportTennis => 'Tenis';

  @override
  String get sportBasketball => 'Básquet';

  @override
  String get kindElimination => 'Eliminación';

  @override
  String get kindLeague => 'Liga';

  @override
  String get genderMale => 'Hombre';

  @override
  String get genderFemale => 'Mujer';

  @override
  String get genderOther => 'Otro';

  @override
  String get countryAR => 'Argentina';

  @override
  String get countryBO => 'Bolivia';

  @override
  String get countryBR => 'Brasil';

  @override
  String get countryCL => 'Chile';

  @override
  String get countryCO => 'Colombia';

  @override
  String get countryEC => 'Ecuador';

  @override
  String get countryES => 'España';

  @override
  String get countryUS => 'Estados Unidos';

  @override
  String get countryFR => 'Francia';

  @override
  String get countryIT => 'Italia';

  @override
  String get countryMX => 'México';

  @override
  String get countryPY => 'Paraguay';

  @override
  String get countryPE => 'Perú';

  @override
  String get countryPT => 'Portugal';

  @override
  String get countryGB => 'Reino Unido';

  @override
  String get countryUY => 'Uruguay';

  @override
  String get countryVE => 'Venezuela';

  @override
  String get statusOpen => 'Abierto';

  @override
  String get statusFull => 'Completo';

  @override
  String get statusClosed => 'Cerrado';

  @override
  String get inscriptionPending => 'Pendiente';

  @override
  String get inscriptionConfirmed => 'Confirmada';

  @override
  String get inscriptionRejected => 'Rechazada';

  @override
  String get inscriptionCancelled => 'Cancelada';

  @override
  String get loginTagline => 'Tu torneo empieza acá';

  @override
  String get emailLabel => 'Email';

  @override
  String get invalidEmail => 'Ingresá un email válido';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get orContinueWith => 'o continuá con';

  @override
  String continueWith(Object provider) {
    return 'Continuar con $provider';
  }

  @override
  String get noAccountSignup => '¿No tenés cuenta? Registrate';

  @override
  String get browseAsGuest => 'Explorar eventos sin cuenta';

  @override
  String get currencyLabel => 'Moneda';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get forgotPasswordTitle => 'Recuperar contraseña';

  @override
  String get forgotPasswordBody =>
      'Ingresá tu email y te mandamos un enlace para elegir una contraseña nueva.';

  @override
  String get sendResetLink => 'Enviar enlace';

  @override
  String get resetEmailSent =>
      'Si existe una cuenta con ese email, te enviamos un enlace para restablecer la contraseña.';

  @override
  String get backToSignIn => 'Volver a iniciar sesión';

  @override
  String get newPassword => 'Contraseña nueva';

  @override
  String get resetPasswordBody => 'Elegí una contraseña nueva para tu cuenta.';

  @override
  String get savePassword => 'Guardar contraseña';

  @override
  String get passwordUpdated => 'Contraseña actualizada.';

  @override
  String get authUnknownAccount =>
      'Cuenta desconocida. Login demo: nico@demo.app / password123';

  @override
  String get authEmailTaken => 'Ya existe una cuenta con ese email.';

  @override
  String get authSocialMissing => 'Cuenta social demo no encontrada.';

  @override
  String get authInvalidEmail => 'Ingresá un email válido.';

  @override
  String get authPasswordShort =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get authSignInFailed => 'No se pudo iniciar sesión.';

  @override
  String get authBrowserFailed => 'No se pudo abrir el navegador.';

  @override
  String get authOAuthCancelled =>
      'Se canceló el inicio de sesión con el proveedor.';

  @override
  String get signupHeroTitle => 'Unite a Bracket';

  @override
  String get signupHeroSubtitle =>
      'Registrate para inscribirte a eventos y organizar los tuyos.';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get enterName => 'Ingresá tu nombre';

  @override
  String get alreadyHaveAccount => '¿Ya tenés cuenta? Iniciá sesión';

  @override
  String get aboutYou => 'Sobre vos';

  @override
  String get gender => 'Género';

  @override
  String get whatDoYouPlay => '¿Qué jugás?';

  @override
  String get sportsFilterHint =>
      'Tus deportes filtran los eventos que ves en Explorar.';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get chooseBirthDate => 'Elegí tu fecha de nacimiento';

  @override
  String get chooseSport => 'Elegí al menos un deporte';

  @override
  String get acceptTermsPrefix => 'Acepto los ';

  @override
  String get termsAndConditions => 'Términos y condiciones';

  @override
  String get acceptTermsError =>
      'Para crear la cuenta, aceptá los Términos y condiciones.';

  @override
  String get socialTermsPrefix => 'Al continuar, aceptás los ';

  @override
  String get proTitle => 'Bracket Pro';

  @override
  String get proProfileHint => 'Torneos sin límites para organizadores';

  @override
  String get proChoosePlan => 'Elegí tu plan';

  @override
  String get proBenefit1 => 'Torneos activos ilimitados';

  @override
  String get proBenefit2 => 'Exportar planillas a PDF y CSV';

  @override
  String get proBenefit3 => 'Listas de espera y suplentes';

  @override
  String get proBenefit4 => 'Estadísticas de tu torneo';

  @override
  String get proBenefit5 => 'Destacado en Explorar';

  @override
  String get proMonthly => 'Mensual';

  @override
  String get proYearly => 'Anual';

  @override
  String get proBestValue => 'Mejor valor';

  @override
  String get proTrialCta => 'Probar gratis';

  @override
  String get proSubscribeCta => 'Suscribirme';

  @override
  String proTrialNotice(Object days) {
    return 'Prueba gratis por $days días. Después se cobra la suscripción, salvo que la canceles antes.';
  }

  @override
  String get proDisclosure =>
      'Suscripción con cargo a tu cuenta de Google Play. Se renueva automáticamente hasta que la cancelás; podés cancelarla cuando quieras desde Google Play.';

  @override
  String get proRestore => 'Restaurar compras';

  @override
  String get proRestoreMissing => 'No encontramos compras para restaurar.';

  @override
  String get proComingSoon => 'Próximamente';

  @override
  String get proComingSoonBody =>
      'Bracket Pro se está por lanzar. ¡Volvé pronto!';

  @override
  String get proAlready => 'Ya tenés Bracket Pro';

  @override
  String get proAlreadyBody => 'Tus torneos activos no tienen límite.';

  @override
  String get proPurchaseError =>
      'No se pudo completar la compra. Intentá de nuevo.';

  @override
  String get proLegalPrefix => 'Leé los ';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get accountCreatedConfirmEmail =>
      'Cuenta creada. Revisá tu email para confirmarla y luego iniciá sesión.';

  @override
  String get pwUseAtLeast8 => 'Usá al menos 8 caracteres';

  @override
  String get pwAddUppercase => 'Agregá una letra mayúscula';

  @override
  String get pwAddLowercase => 'Agregá una letra minúscula';

  @override
  String get pwAddNumber => 'Agregá un número';

  @override
  String get pwCheckAtLeast8 => 'Al menos 8 caracteres';

  @override
  String get pwCheckUppercase => 'Una mayúscula';

  @override
  String get pwCheckLowercase => 'Una minúscula';

  @override
  String get pwCheckNumber => 'Un número';

  @override
  String get usernameLabel => 'Nombre de usuario';

  @override
  String get usernameHelp => 'Letras, números, puntos y guiones bajos';

  @override
  String get usernameRequired => 'Elegí un nombre de usuario';

  @override
  String get usernameFormat => 'Solo letras, números, . y _';

  @override
  String get usernameTaken => 'Ese nombre de usuario ya está en uso.';

  @override
  String get birthDate => 'Fecha de nacimiento';

  @override
  String get tapToChoose => 'Tocá para elegir';

  @override
  String get noSession => 'No hay sesión iniciada';

  @override
  String saveFailed(Object error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String get sportsYouPlay => 'Deportes que jugás';

  @override
  String get country => 'País';

  @override
  String get phoneOptional => 'Teléfono / WhatsApp (opcional)';

  @override
  String get phoneHelp => 'Sin el código de país, ej.: 911 2233-4455';

  @override
  String get phoneInvalid => 'Ingresá un número válido';

  @override
  String get organizerMode => 'Organizo torneos';

  @override
  String get organizerModeHint =>
      'Muestra la pestaña Organizar para crear eventos';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get startButton => 'Comenzar';

  @override
  String get signOutConfirmTitle => '¿Cerrar sesión?';

  @override
  String get signOutConfirmMessage =>
      'Podés volver a iniciar sesión cuando quieras.';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get notSignedIn => 'No has iniciado sesión.';

  @override
  String get incompleteProfile => 'Tu perfil está incompleto';

  @override
  String get completeProfileHint => 'Completalo para inscribirte a eventos.';

  @override
  String get phoneLabel => 'Teléfono / WhatsApp';

  @override
  String get role => 'Rol';

  @override
  String get organizer => 'Organizador';

  @override
  String get player => 'Jugador';

  @override
  String get sportsTitle => 'Deportes';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get filters => 'Filtros';

  @override
  String get switchToList => 'Cambiar a lista';

  @override
  String get switchToMap => 'Cambiar a mapa';

  @override
  String get exploreLoadError => 'Algo salió mal al cargar los eventos.';

  @override
  String get searchHint => 'Buscar eventos, canchas, ciudades';

  @override
  String get noLocationTitle => 'No pudimos encontrar tu ubicación';

  @override
  String get noLocationBody =>
      'Activá la ubicación para ver los torneos cerca tuyo.';

  @override
  String get useMyLocation => 'Usar mi ubicación';

  @override
  String get sport => 'Deporte';

  @override
  String get all => 'Todos';

  @override
  String get distanceFrom => 'Distancia desde mi ubicación';

  @override
  String get any => 'Cualquiera';

  @override
  String get updateLocation => 'Actualizar ubicación';

  @override
  String get onlyAvailable => 'Solo eventos con lugares disponibles';

  @override
  String spotsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lugares libres',
      one: '$count lugar libre',
    );
    return '$_temp0';
  }

  @override
  String get noTournaments => 'No se encontraron torneos';

  @override
  String get noTournamentsBody =>
      'Probá con otra búsqueda o borrá los filtros.';

  @override
  String get clearFilters => 'Borrar filtros';

  @override
  String eventsInArea(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos en esta zona',
      one: '$count evento en esta zona',
    );
    return '$_temp0';
  }

  @override
  String get centerOnMe => 'Centrar en mi ubicación';

  @override
  String get viewDetails => 'Ver detalle';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterPending => 'Pendientes';

  @override
  String get filterConfirmed => 'Confirmadas';

  @override
  String get filterRejected => 'Rechazadas';

  @override
  String myLoadError(Object error) {
    return 'No se pudieron cargar las inscripciones: $error';
  }

  @override
  String get emptyInscriptionsAll => 'No hay inscripciones todavía';

  @override
  String get emptyInscriptionsPending => 'No hay inscripciones pendientes';

  @override
  String get emptyInscriptionsConfirmed => 'No hay inscripciones confirmadas';

  @override
  String searchNoResults(Object query) {
    return 'No encontramos eventos que coincidan con \"$query\".';
  }

  @override
  String get searchMyInscriptions => 'Buscar mis inscripciones';

  @override
  String get fallbackTitle => 'Torneo';

  @override
  String get noInscriptionsTitle => 'Todavía no tenés inscripciones';

  @override
  String get noInscriptionsBody =>
      'Encontrá un torneo cerca tuyo — el pago se coordina directamente con el organizador.';

  @override
  String get exploreEvents => 'Explorar eventos';

  @override
  String get sortSoonest => 'Más próximos';

  @override
  String get sortCreated => 'Creados recientemente';

  @override
  String get sortTitleAZ => 'Título (A–Z)';

  @override
  String get sortMenu => 'Ordenar';

  @override
  String organizerLoadError(Object error) {
    return 'No se pudieron cargar tus eventos: $error';
  }

  @override
  String get searchMyEvents => 'Buscar mis eventos';

  @override
  String get createEvent => 'Crear evento';

  @override
  String get organizerGateTitle => 'El modo organizador está desactivado';

  @override
  String get organizerGateBody =>
      'Activalo desde tu perfil para crear eventos y confirmar a los jugadores después de que te paguen directamente.';

  @override
  String get goToProfile => 'Ir al perfil';

  @override
  String get noEventsTitle => 'Todavía no hay eventos';

  @override
  String get noEventsBody =>
      'Creá tu primer evento. Los jugadores se inscriben acá y te pagan directamente — vos confirmás cada lugar.';

  @override
  String get pastEvents => 'Eventos pasados';

  @override
  String spotsOf(int confirmed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total lugares',
      one: '$total lugar',
    );
    return '$confirmed de $_temp0';
  }

  @override
  String requestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count solicitudes',
      one: '$count solicitud',
    );
    return '$_temp0';
  }

  @override
  String eventLoadError(Object error) {
    return 'No se pudo cargar el evento: $error';
  }

  @override
  String get formatLabel => 'Formato';

  @override
  String get titleLabel => 'Título';

  @override
  String get descriptionLabel => 'Descripción';

  @override
  String get prizesLabel => 'Premios (opcional)';

  @override
  String get startsLabel => 'Comienza';

  @override
  String get endsLabel => 'Finaliza';

  @override
  String get teamsLabel => 'Equipos';

  @override
  String get spotsTotal => 'Lugares disponibles en total';

  @override
  String get costLabel => 'Costo de inscripción';

  @override
  String get costFreeHint => 'Dejalo vacío si el evento es gratis';

  @override
  String get venueLabel => 'Nombre de la sede';

  @override
  String get addressLabel => 'Dirección';

  @override
  String get cityLabel => 'Ciudad';

  @override
  String get locationLabel => 'Ubicación';

  @override
  String get locationHint =>
      'Tocá el mapa para ubicar el pin de la sede. Usá tu ubicación actual para completar la dirección.';

  @override
  String pinPlaced(Object lat, Object lng) {
    return 'Pin ubicado en $lat, $lng';
  }

  @override
  String get publishEvent => 'Publicar evento';

  @override
  String get locationDenied =>
      'No se pudo obtener tu ubicación. Revisá los permisos de la app.';

  @override
  String get locationNoAddress =>
      'Ubicación actualizada. No se pudo completar la dirección.';

  @override
  String get addressFilled => 'Dirección completada con tu ubicación.';

  @override
  String get locationUpdated => 'Ubicación actualizada.';

  @override
  String get addressFailed =>
      'No se pudo completar la dirección desde el punto elegido. Escribila a mano.';

  @override
  String get required => 'Obligatorio';

  @override
  String get minOneTeam => 'Ingresá un número igual o mayor a 1';

  @override
  String get invalidAmount => 'Ingresá un monto válido';

  @override
  String get endDateBeforeStart =>
      'La fecha de fin debe ser posterior a la de inicio.';

  @override
  String get eventNotFound => 'Evento no encontrado';

  @override
  String capBelowConfirmed(Object confirmed) {
    return 'No podés bajar el cupo por debajo de los equipos confirmados ($confirmed).';
  }

  @override
  String get eventSaved => 'Evento guardado';

  @override
  String get eventPublished => 'Evento publicado';

  @override
  String eventSaveError(Object error) {
    return 'No se pudo guardar el evento: $error';
  }

  @override
  String get editEvent => 'Editar evento';

  @override
  String get moreActions => 'Más acciones';

  @override
  String get closeRegistrations => 'Cerrar inscripciones';

  @override
  String get reopenRegistrations => 'Reabrir inscripciones';

  @override
  String get deleteEvent => 'Eliminar evento';

  @override
  String get registrationsClosed => 'Inscripciones cerradas';

  @override
  String get registrationsReopened => 'Inscripciones reabiertas';

  @override
  String requestsLoadError(Object error) {
    return 'No se pudieron cargar las solicitudes: $error';
  }

  @override
  String get emptyRequestsPending => 'No hay solicitudes pendientes';

  @override
  String get emptyRequestsConfirmed => 'No hay solicitudes confirmadas';

  @override
  String get emptyRequestsRejected => 'No hay solicitudes rechazadas';

  @override
  String updateEventError(Object error) {
    return 'No se pudo actualizar el evento: $error';
  }

  @override
  String get outsideUpdated => 'Confirmados fuera de la app actualizados';

  @override
  String updateError(Object error) {
    return 'No se pudo actualizar: $error';
  }

  @override
  String get deleteConfirmTitle => '¿Eliminar evento?';

  @override
  String get deleteConfirmMessage =>
      'Esto elimina el evento y todas sus inscripciones. No se puede deshacer.';

  @override
  String deleteError(Object error) {
    return 'No se pudo eliminar el evento: $error';
  }

  @override
  String get registrationConfirmed => 'Inscripción confirmada';

  @override
  String get registrationRejected => 'Inscripción rechazada';

  @override
  String get notifyWhatsApp => 'Avisar por WhatsApp';

  @override
  String whatsappOpenFailed(Object phone) {
    return 'No se pudo abrir WhatsApp. Llamá al $phone.';
  }

  @override
  String requestedOn(Object date) {
    return 'Solicitada el $date';
  }

  @override
  String get confirm => 'Confirmar';

  @override
  String get reject => 'Rechazar';

  @override
  String get outsideTitle => 'Confirmados fuera de la app';

  @override
  String get outsideHelp =>
      'Equipos que confirmaron por tu cuenta (efectivo, en persona, WhatsApp).';

  @override
  String get decreaseOne => 'Quitar uno';

  @override
  String get increaseOne => 'Agregar uno';

  @override
  String outsideFull(Object confirmed) {
    return 'Las $confirmed confirmadas en la app ya llenan el cupo.';
  }

  @override
  String outsideMax(Object confirmed, Object total) {
    return 'En la app hay $confirmed confirmadas. El total no puede superar $total.';
  }

  @override
  String get registerSuccessNoContact =>
      'Inscripción solicitada. Coordiná el pago directamente con el organizador.';

  @override
  String get registerSuccessWhatsApp =>
      'Inscripción solicitada. Coordiná el pago por WhatsApp — el organizador confirma tu lugar.';

  @override
  String get registerSuccessFallback =>
      'Inscripción solicitada. Escribile al organizador por WhatsApp para coordinar el pago.';

  @override
  String registerError(Object error) {
    return 'No se pudo inscribir: $error';
  }

  @override
  String get cancelConfirmTitle => '¿Cancelar inscripción?';

  @override
  String get cancelConfirmMessage =>
      'Se liberará tu lugar. Podés volver a inscribirte después, sujeto a disponibilidad.';

  @override
  String get cancelRegistration => 'Cancelar inscripción';

  @override
  String get registrationCancelled => 'Inscripción cancelada';

  @override
  String cancelError(Object error) {
    return 'No se pudo cancelar: $error';
  }

  @override
  String tournamentLoadError(Object error) {
    return 'No se pudo cargar el torneo: $error';
  }

  @override
  String get tournamentNotFound => 'Torneo no encontrado';

  @override
  String get dateLabel => 'Fecha';

  @override
  String get venueLabelShort => 'Sede';

  @override
  String get prizesLabelShort => 'Premios';

  @override
  String teamsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count equipos',
      one: '$count equipo',
    );
    return '$_temp0';
  }

  @override
  String spotsTaken(int confirmed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total lugares tomados',
      one: '$total lugar tomado',
    );
    return '$confirmed de $_temp0';
  }

  @override
  String get aboutTournament => 'Acerca del torneo';

  @override
  String get organizerTitle => 'Organizador';

  @override
  String get signInToRegister => 'Iniciar sesión para inscribirte';

  @override
  String get registeredTitle => 'Estás inscripto';

  @override
  String get awaitingConfirmation => 'Esperando confirmación';

  @override
  String get registrationsClosedButton => 'Inscripciones cerradas';

  @override
  String get tournamentFull => 'Torneo completo';

  @override
  String get registerButton => 'Inscribirme';

  @override
  String get noSpotsAvailable => 'No hay lugares disponibles';

  @override
  String get paymentHint =>
      'Coordiná el pago con el organizador por WhatsApp; tu lugar se confirma cuando lo apruebe.';
}
