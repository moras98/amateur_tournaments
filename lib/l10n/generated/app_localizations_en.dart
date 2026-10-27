// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navExplore => 'Explore';

  @override
  String get navInscriptions => 'Sign-ups';

  @override
  String get navOrganize => 'Organize';

  @override
  String get navProfile => 'Profile';

  @override
  String get errorScreenTitle => 'We couldn\'t find that screen';

  @override
  String get errorScreenBody =>
      'The event may no longer exist or the link may be broken.';

  @override
  String get errorScreenBack => 'Back to Explore';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get free => 'Free';

  @override
  String get retry => 'Try again';

  @override
  String get save => 'Save';

  @override
  String get apply => 'Apply';

  @override
  String get reset => 'Reset';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String loadError(Object error) {
    return 'Error: $error';
  }

  @override
  String get sportFootball => 'Football';

  @override
  String get sportPadel => 'Padel';

  @override
  String get sportTennis => 'Tennis';

  @override
  String get sportBasketball => 'Basketball';

  @override
  String get kindElimination => 'Elimination';

  @override
  String get kindLeague => 'League';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get countryAR => 'Argentina';

  @override
  String get countryBO => 'Bolivia';

  @override
  String get countryBR => 'Brazil';

  @override
  String get countryCL => 'Chile';

  @override
  String get countryCO => 'Colombia';

  @override
  String get countryEC => 'Ecuador';

  @override
  String get countryES => 'Spain';

  @override
  String get countryUS => 'United States';

  @override
  String get countryFR => 'France';

  @override
  String get countryIT => 'Italy';

  @override
  String get countryMX => 'Mexico';

  @override
  String get countryPY => 'Paraguay';

  @override
  String get countryPE => 'Peru';

  @override
  String get countryPT => 'Portugal';

  @override
  String get countryGB => 'United Kingdom';

  @override
  String get countryUY => 'Uruguay';

  @override
  String get countryVE => 'Venezuela';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusFull => 'Full';

  @override
  String get statusClosed => 'Closed';

  @override
  String get inscriptionPending => 'Pending';

  @override
  String get inscriptionConfirmed => 'Confirmed';

  @override
  String get inscriptionRejected => 'Rejected';

  @override
  String get inscriptionCancelled => 'Cancelled';

  @override
  String get loginTagline => 'Your tournament starts here';

  @override
  String get emailLabel => 'Email';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordTooShort => 'The password must be at least 6 characters';

  @override
  String get signIn => 'Sign in';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String continueWith(Object provider) {
    return 'Continue with $provider';
  }

  @override
  String get noAccountSignup => 'Don\'t have an account? Sign up';

  @override
  String get browseAsGuest => 'Browse events without an account';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get forgotPasswordTitle => 'Reset your password';

  @override
  String get forgotPasswordBody =>
      'Enter your email and we\'ll send you a link to set a new password.';

  @override
  String get sendResetLink => 'Send link';

  @override
  String get resetEmailSent =>
      'If an account exists for that email, we sent you a link to reset the password.';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get newPassword => 'New password';

  @override
  String get resetPasswordBody => 'Choose a new password for your account.';

  @override
  String get savePassword => 'Save password';

  @override
  String get passwordUpdated => 'Password updated.';

  @override
  String get authUnknownAccount =>
      'Unknown account. Demo login: nico@demo.app / password123';

  @override
  String get authEmailTaken => 'An account already exists with that email.';

  @override
  String get authSocialMissing => 'Demo social account not found.';

  @override
  String get authInvalidEmail => 'Enter a valid email.';

  @override
  String get authPasswordShort => 'The password must be at least 6 characters.';

  @override
  String get authSignInFailed => 'Couldn\'t sign in.';

  @override
  String get authBrowserFailed => 'Couldn\'t open the browser.';

  @override
  String get authOAuthCancelled => 'Sign-in with the provider was cancelled.';

  @override
  String get signupHeroTitle => 'Join Tande';

  @override
  String get signupHeroSubtitle =>
      'Sign up to register for events and organize your own.';

  @override
  String get fullName => 'Full name';

  @override
  String get enterName => 'Enter your name';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get aboutYou => 'About you';

  @override
  String get gender => 'Gender';

  @override
  String get whatDoYouPlay => 'What do you play?';

  @override
  String get sportsFilterHint =>
      'Your sports filter the events you see in Explore.';

  @override
  String get createAccount => 'Create account';

  @override
  String get chooseBirthDate => 'Choose your date of birth';

  @override
  String get mustBe18 => 'You must be 18 or older to use Tande.';

  @override
  String get chooseSport => 'Choose at least one sport';

  @override
  String get bannerSectionLabel => 'Tournament image';

  @override
  String get bannerHint => 'Optional. Shown in Explore and on the event page.';

  @override
  String get bannerAdd => 'Add image';

  @override
  String get bannerChange => 'Change image';

  @override
  String get bannerRemove => 'Remove image';

  @override
  String get bannerSaveFailed =>
      'The event was saved, but the image couldn\'t be uploaded. Try again from Edit.';

  @override
  String get acceptTermsPrefix => 'I accept the ';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get acceptTermsError =>
      'Accept the Terms and Conditions to create your account.';

  @override
  String get socialTermsPrefix => 'By continuing you accept the ';

  @override
  String get proTitle => 'Tande Pro';

  @override
  String get proProfileHint => 'Unlimited tournaments for organizers';

  @override
  String get proChoosePlan => 'Choose your plan';

  @override
  String get proBenefit1 => 'Unlimited active tournaments';

  @override
  String get proBenefit2 => 'Export registrations to CSV (spreadsheet-ready)';

  @override
  String get proMonthly => 'Monthly';

  @override
  String get proYearly => 'Yearly';

  @override
  String get proBestValue => 'Best value';

  @override
  String get proTrialCta => 'Try for free';

  @override
  String get proSubscribeCta => 'Subscribe';

  @override
  String proTrialNotice(Object days) {
    return 'Free $days-day trial. After that the subscription is charged unless you cancel before it ends.';
  }

  @override
  String get proDisclosure =>
      'Billed to your Google Play account. Renews automatically until you cancel; you can cancel anytime in Google Play.';

  @override
  String get proRestore => 'Restore purchases';

  @override
  String get proRestoreMissing => 'No purchases found to restore.';

  @override
  String get proComingSoon => 'Coming soon';

  @override
  String get proComingSoonBody => 'Tande Pro is launching soon. Check back!';

  @override
  String get proAlready => 'You already have Tande Pro';

  @override
  String get proAlreadyBody => 'Your active tournaments have no limit.';

  @override
  String get proPurchaseError =>
      'The purchase couldn\'t be completed. Try again.';

  @override
  String get proLegalPrefix => 'Read the ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get accountCreatedConfirmEmail =>
      'Account created. Check your email to confirm it, then sign in.';

  @override
  String get pwUseAtLeast8 => 'Use at least 8 characters';

  @override
  String get pwAddUppercase => 'Add an uppercase letter';

  @override
  String get pwAddLowercase => 'Add a lowercase letter';

  @override
  String get pwAddNumber => 'Add a number';

  @override
  String get pwCheckAtLeast8 => 'At least 8 characters';

  @override
  String get pwCheckUppercase => 'One uppercase';

  @override
  String get pwCheckLowercase => 'One lowercase';

  @override
  String get pwCheckNumber => 'One number';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameHelp => 'Letters, numbers, dots and underscores';

  @override
  String get usernameRequired => 'Choose a username';

  @override
  String get usernameFormat => 'Only letters, numbers, . and _';

  @override
  String get usernameTaken => 'That username is already in use.';

  @override
  String get birthDate => 'Date of birth';

  @override
  String get tapToChoose => 'Tap to choose';

  @override
  String get noSession => 'No signed-in session';

  @override
  String saveFailed(Object error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String get sportsYouPlay => 'Sports you play';

  @override
  String get country => 'Country';

  @override
  String get phoneOptional => 'Phone / WhatsApp (optional)';

  @override
  String get phoneHelp => 'Without the country code, e.g.: 911 2233-4455';

  @override
  String get phoneInvalid => 'Enter a valid number';

  @override
  String get organizerMode => 'I organize tournaments';

  @override
  String get organizerModeHint => 'Shows the Organize tab to create events';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get startButton => 'Get started';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmMessage =>
      'You can sign in again whenever you want.';

  @override
  String get signOut => 'Sign out';

  @override
  String get notSignedIn => 'You\'re not signed in.';

  @override
  String get incompleteProfile => 'Your profile is incomplete';

  @override
  String get completeProfileHint => 'Complete it to register for events.';

  @override
  String get phoneLabel => 'Phone / WhatsApp';

  @override
  String get role => 'Role';

  @override
  String get organizer => 'Organizer';

  @override
  String get player => 'Player';

  @override
  String get sportsTitle => 'Sports';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get filters => 'Filters';

  @override
  String get switchToList => 'Switch to list';

  @override
  String get switchToMap => 'Switch to map';

  @override
  String get exploreLoadError => 'Something went wrong loading the events.';

  @override
  String get searchHint => 'Search events, courts, cities';

  @override
  String get noLocationTitle => 'We couldn\'t find your location';

  @override
  String get noLocationBody => 'Turn on location to see tournaments near you.';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get sport => 'Sport';

  @override
  String get all => 'All';

  @override
  String get distanceFrom => 'Distance from my location';

  @override
  String get any => 'Any';

  @override
  String get updateLocation => 'Update location';

  @override
  String get onlyAvailable => 'Only events with spots available';

  @override
  String spotsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spots free',
      one: '$count spot free',
    );
    return '$_temp0';
  }

  @override
  String get noTournaments => 'No tournaments found';

  @override
  String get noTournamentsBody => 'Try another search or clear the filters.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String eventsInArea(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events in this area',
      one: '$count event in this area',
    );
    return '$_temp0';
  }

  @override
  String get centerOnMe => 'Center on my location';

  @override
  String get viewDetails => 'View details';

  @override
  String get filterAll => 'All';

  @override
  String get filterPending => 'Pending';

  @override
  String get filterConfirmed => 'Confirmed';

  @override
  String get filterRejected => 'Rejected';

  @override
  String get filterWaitlist => 'Waitlisted';

  @override
  String get emptyRequestsWaitlist => 'Nobody on the waitlist yet.';

  @override
  String get joinWaitlist => 'Join the waitlist';

  @override
  String get waitlistSuccess =>
      'You\'re on the waitlist. If a spot frees up we confirm you and the organizer lets you know.';

  @override
  String get waitlistedTitle => 'On the waitlist';

  @override
  String get waitlistedHint =>
      'The tournament is full. We\'ll let you know if a spot frees up.';

  @override
  String get inscriptionWaitlisted => 'Waitlisted';

  @override
  String get exportCsv => 'Export registrations (CSV)';

  @override
  String get exportCsvEmpty => 'No registrations to export yet.';

  @override
  String get exportCsvFailed => 'Couldn\'t build the spreadsheet. Try again.';

  @override
  String get duplicateEvent => 'Duplicate tournament';

  @override
  String myLoadError(Object error) {
    return 'Couldn\'t load your sign-ups: $error';
  }

  @override
  String get emptyInscriptionsAll => 'No sign-ups yet';

  @override
  String get emptyInscriptionsPending => 'No pending sign-ups';

  @override
  String get emptyInscriptionsConfirmed => 'No confirmed sign-ups';

  @override
  String searchNoResults(Object query) {
    return 'We couldn\'t find events matching \"$query\".';
  }

  @override
  String get searchMyInscriptions => 'Search my sign-ups';

  @override
  String get fallbackTitle => 'Tournament';

  @override
  String get noInscriptionsTitle => 'You don\'t have any sign-ups yet';

  @override
  String get noInscriptionsBody =>
      'Find a tournament near you — payment is arranged directly with the organizer.';

  @override
  String get exploreEvents => 'Explore events';

  @override
  String get sortSoonest => 'Soonest';

  @override
  String get sortCreated => 'Recently created';

  @override
  String get sortTitleAZ => 'Title (A–Z)';

  @override
  String get sortMenu => 'Sort';

  @override
  String organizerLoadError(Object error) {
    return 'Couldn\'t load your events: $error';
  }

  @override
  String get searchMyEvents => 'Search my events';

  @override
  String get createEvent => 'Create event';

  @override
  String get organizerGateTitle => 'Organizer mode is off';

  @override
  String get organizerGateBody =>
      'Turn it on from your profile to create events and confirm players once they pay you directly.';

  @override
  String get goToProfile => 'Go to profile';

  @override
  String get noEventsTitle => 'No events yet';

  @override
  String get noEventsBody =>
      'Create your first event. Players sign up here and pay you directly — you confirm each spot.';

  @override
  String get pastEvents => 'Past events';

  @override
  String spotsOf(int confirmed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total spots',
      one: '$total spot',
    );
    return '$confirmed of $_temp0';
  }

  @override
  String requestsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requests',
      one: '$count request',
    );
    return '$_temp0';
  }

  @override
  String eventLoadError(Object error) {
    return 'Couldn\'t load the event: $error';
  }

  @override
  String get formatLabel => 'Format';

  @override
  String get titleLabel => 'Title';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get prizesLabel => 'Prizes (optional)';

  @override
  String get startsLabel => 'Starts';

  @override
  String get endsLabel => 'Ends';

  @override
  String get teamsLabel => 'Teams';

  @override
  String get spotsTotal => 'Total spots available';

  @override
  String get costLabel => 'Entry cost';

  @override
  String get costFreeHint => 'Leave it empty if the event is free';

  @override
  String get venueLabel => 'Venue name';

  @override
  String get addressLabel => 'Address';

  @override
  String get cityLabel => 'City';

  @override
  String get locationLabel => 'Location';

  @override
  String get locationHint =>
      'Tap the map to place the venue pin. Use your current location to fill in the address.';

  @override
  String pinPlaced(Object lat, Object lng) {
    return 'Pin placed at $lat, $lng';
  }

  @override
  String get publishEvent => 'Publish event';

  @override
  String get locationDenied =>
      'Couldn\'t get your location. Check the app\'s permissions.';

  @override
  String get locationNoAddress =>
      'Location updated. The address couldn\'t be completed.';

  @override
  String get addressFilled => 'Address filled in from your location.';

  @override
  String get locationUpdated => 'Location updated.';

  @override
  String get addressFailed =>
      'Couldn\'t complete the address from the chosen point. Type it manually.';

  @override
  String get required => 'Required';

  @override
  String get minOneTeam => 'Enter a number of 1 or more';

  @override
  String get invalidAmount => 'Enter a valid amount';

  @override
  String get endDateBeforeStart => 'The end date must be after the start date.';

  @override
  String get eventNotFound => 'Event not found';

  @override
  String capBelowConfirmed(Object confirmed) {
    return 'You can\'t lower the cap below the confirmed teams ($confirmed).';
  }

  @override
  String get eventSaved => 'Event saved';

  @override
  String get eventPublished => 'Event published';

  @override
  String eventSaveError(Object error) {
    return 'Couldn\'t save the event: $error';
  }

  @override
  String get editEvent => 'Edit event';

  @override
  String get moreActions => 'More actions';

  @override
  String get closeRegistrations => 'Close sign-ups';

  @override
  String get reopenRegistrations => 'Reopen sign-ups';

  @override
  String get deleteEvent => 'Delete event';

  @override
  String get registrationsClosed => 'Sign-ups closed';

  @override
  String get registrationsReopened => 'Sign-ups reopened';

  @override
  String requestsLoadError(Object error) {
    return 'Couldn\'t load the requests: $error';
  }

  @override
  String get emptyRequestsPending => 'No pending requests';

  @override
  String get emptyRequestsConfirmed => 'No confirmed requests';

  @override
  String get emptyRequestsRejected => 'No rejected requests';

  @override
  String updateEventError(Object error) {
    return 'Couldn\'t update the event: $error';
  }

  @override
  String get outsideUpdated => 'Off-app confirmations updated';

  @override
  String updateError(Object error) {
    return 'Couldn\'t update: $error';
  }

  @override
  String get deleteConfirmTitle => 'Delete event?';

  @override
  String get deleteConfirmMessage =>
      'This deletes the event and all of its sign-ups. This can\'t be undone.';

  @override
  String deleteError(Object error) {
    return 'Couldn\'t delete the event: $error';
  }

  @override
  String get registrationConfirmed => 'Sign-up confirmed';

  @override
  String get registrationRejected => 'Sign-up rejected';

  @override
  String get notifyWhatsApp => 'Notify on WhatsApp';

  @override
  String whatsappOpenFailed(Object phone) {
    return 'Couldn\'t open WhatsApp. Call $phone.';
  }

  @override
  String requestedOn(Object date) {
    return 'Requested on $date';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get reject => 'Reject';

  @override
  String get outsideTitle => 'Confirmed off-app';

  @override
  String get outsideShortTitle => 'Off-app';

  @override
  String get outsideHelp =>
      'Teams you confirmed yourself (cash, in person, WhatsApp).';

  @override
  String get decreaseOne => 'Remove one';

  @override
  String get increaseOne => 'Add one';

  @override
  String outsideFull(Object confirmed) {
    return 'The $confirmed confirmed in the app already fill the cap.';
  }

  @override
  String outsideMax(Object confirmed, Object total) {
    return 'The app has $confirmed confirmed. The total can\'t exceed $total.';
  }

  @override
  String get registerSuccessNoContact =>
      'Sign-up requested. Arrange payment directly with the organizer.';

  @override
  String get registerSuccessWhatsApp =>
      'Sign-up requested. Arrange payment on WhatsApp — the organizer confirms your spot.';

  @override
  String get registerSuccessFallback =>
      'Sign-up requested. Message the organizer on WhatsApp to arrange payment.';

  @override
  String registerError(Object error) {
    return 'Couldn\'t register: $error';
  }

  @override
  String get cancelConfirmTitle => 'Cancel sign-up?';

  @override
  String get cancelConfirmMessage =>
      'Your spot will be freed. You can sign up again later, subject to availability.';

  @override
  String get cancelRegistration => 'Cancel sign-up';

  @override
  String get registrationCancelled => 'Sign-up cancelled';

  @override
  String cancelError(Object error) {
    return 'Couldn\'t cancel: $error';
  }

  @override
  String tournamentLoadError(Object error) {
    return 'Couldn\'t load the tournament: $error';
  }

  @override
  String get tournamentNotFound => 'Tournament not found';

  @override
  String get dateLabel => 'Date';

  @override
  String get venueLabelShort => 'Venue';

  @override
  String get prizesLabelShort => 'Prizes';

  @override
  String teamsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count teams',
      one: '$count team',
    );
    return '$_temp0';
  }

  @override
  String spotsTaken(int confirmed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total spots taken',
      one: '$total spot taken',
    );
    return '$confirmed of $_temp0';
  }

  @override
  String get aboutTournament => 'About the tournament';

  @override
  String get organizerTitle => 'Organizer';

  @override
  String get signInToRegister => 'Sign in to register';

  @override
  String get registeredTitle => 'You\'re signed up';

  @override
  String get awaitingConfirmation => 'Awaiting confirmation';

  @override
  String get registrationsClosedButton => 'Sign-ups closed';

  @override
  String get tournamentFull => 'Tournament full';

  @override
  String get registerButton => 'Sign up';

  @override
  String get teamNameTitle => 'What team are you signing up with?';

  @override
  String get teamNameBody =>
      'This is the name the organizer sees in their list, and what goes into the spreadsheet.';

  @override
  String get teamNameLabel => 'Team name';

  @override
  String get teamNameRequired =>
      'Add a name so the organizer can identify you.';

  @override
  String get spotsLeftLabel => 'spots left';

  @override
  String get noSpotsAvailable => 'No spots available';

  @override
  String get paymentHint =>
      'Arrange payment with the organizer on WhatsApp; your spot is confirmed once they approve.';
}
