import 'package:bracket/data/auth/auth_repository.dart';
import 'package:bracket/data/auth/mock_auth_repository.dart';
import 'package:bracket/data/repositories/mock/mock_profile_repository.dart';
import 'package:bracket/data/repositories/mock/mock_store.dart';
import 'package:bracket/features/auth/profile_form_screen.dart';
import 'package:bracket/features/auth/signup_screen.dart';
import 'package:bracket/core/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

void main() {
  setUp(MockStore().reset);

  group('MockAuthRepository', () {
    test('starts signed in as the demo player by default', () {
      final auth = MockAuthRepository();
      expect(auth.currentSession, isNotNull);
      expect(auth.currentSession!.userId, 'u-player-1');
    });

    test('signedIn: false starts signed out', () {
      final auth = MockAuthRepository(signedIn: false);
      expect(auth.currentSession, isNull);
    });

    test('signs in with a seeded demo account', () async {
      final auth = MockAuthRepository(signedIn: false);

      final session = await auth.signIn(
        email: 'nico@demo.app',
        password: 'password123',
      );

      expect(session.userId, 'u-player-1');
      expect(auth.currentSession, session);
    });

    test('signing in survives a username rename', () async {
      final store = MockStore();
      final auth = MockAuthRepository(signedIn: false);

      // The player renames their handle: the account email keeps working
      // (sign-in matches emails, not usernames — Supabase parity).
      await MockProfileRepository(
        store,
      ).save(store.player.copyWith(username: 'nicolas_p'));

      final session = await auth.signIn(
        email: 'nico@demo.app',
        password: 'password123',
      );

      expect(session.userId, 'u-player-1');
    });

    test('profile save rejects a username taken by another account', () async {
      final store = MockStore();

      final clash = store.player.copyWith(username: 'el_turco');
      await expectLater(
        MockProfileRepository(store).save(clash),
        throwsStateError,
      );
    });

    test('social sign-in lands on the seeded provider account', () async {
      final auth = MockAuthRepository(signedIn: false);

      final google = await auth.signInWithOAuth(SocialProvider.google);
      expect(google.userId, MockStore.socialGoogleId);
      expect(auth.currentSession, google);

      await auth.signOut();
      final apple = await auth.signInWithOAuth(SocialProvider.apple);
      expect(apple.userId, MockStore.socialAppleId);
      expect(auth.currentSession, apple);
    });

    test('rejects unknown accounts and weak input', () async {
      final auth = MockAuthRepository(signedIn: false);

      await expectLater(
        auth.signIn(email: 'nope@demo.app', password: 'password123'),
        throwsA(isA<AuthFailure>()),
      );
      await expectLater(
        auth.signIn(email: 'not-an-email', password: 'password123'),
        throwsA(isA<AuthFailure>()),
      );
      await expectLater(
        auth.signIn(email: 'nico@demo.app', password: 'short'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('signUp creates an incomplete profile and signs in', () async {
      final auth = MockAuthRepository(signedIn: false);
      final store = MockStore();

      final session = await auth.signUp(
        email: 'newbie@demo.app',
        password: 'password123',
        fullName: 'New Bie',
      );

      expect(session, isNotNull); // Mock mode signs in immediately.
      expect(auth.currentSession, session);
      final profile = store.profileById(session!.userId);
      expect(profile, isNotNull);
      expect(profile!.fullName, 'New Bie');
      expect(profile.isComplete, isFalse);
    });

    test('signUp rejects a duplicate email', () async {
      final auth = MockAuthRepository(signedIn: false);

      await expectLater(
        auth.signUp(email: 'nico@demo.app', password: 'password123'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('signOut clears the session and emits on stateChanges', () async {
      final auth = MockAuthRepository();
      final events = <AuthSession?>[];
      final sub = auth.stateChanges.listen(events.add);

      await auth.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(auth.currentSession, isNull);
      expect(events, [isNull]);
      await sub.cancel();
    });
  });

  /// Taps a bottom-nav destination (icons in screen bodies can collide).
  Finder navIcon(IconData icon) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.byIcon(icon),
  );

  group('Auth flows (widgets)', () {
    Widget app({bool signedIn = true}) => appHarness(signedIn: signedIn);

    testWidgets('protected tabs redirect signed-out users to login', (
      tester,
    ) async {
      await tester.pumpWidget(app(signedIn: false));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.emoji_events_outlined));
      await tester.pumpAndSettle();

      // Login screen (bar carries no title): only the button says this.
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    // Split in two: the signed-out harness carries an extra auth override,
    // and Riverpod forbids re-pumping a scope with a different override
    // count — one signed-in state per test.
    testWidgets('auth screens carry no app bar', (tester) async {
      // Login (reached via a protected tab) is bar-less — an empty AppBar
      // only left a blank strip content scrolled under.
      await tester.pumpWidget(app(signedIn: false));
      await tester.pumpAndSettle();
      await tester.tap(navIcon(Icons.emoji_events_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);

      // ...and signup too (the link sits below the fold).
      final registerLink = find.widgetWithText(
        TextButton,
        '¿No tenés cuenta? Registrate',
      );
      await tester.scrollUntilVisible(
        registerLink,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(registerLink);
      await tester.pumpAndSettle();
      expect(find.text('Unite a Bracket'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('tab screens carry no app bar', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.confirmation_num_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);

      await tester.tap(navIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('signing in returns to the requested tab', (tester) async {
      await tester.pumpWidget(app(signedIn: false));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.emoji_events_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'nico@demo.app');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      // Landed back on the Organize tab (demo player sees the gate).
      expect(find.text('El modo organizador está desactivado'), findsOneWidget);
    });

    testWidgets('profile shows the favorite sports as sport chips', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // The sports section sits below the fold on the profile list.
      await tester.scrollUntilVisible(
        find.text('Deportes'),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      // Nico's favorites: football + padel — each chip carries its sport
      // glyph; the tag is glyph + label with no tinted fill (design §7).
      expect(find.text('Fútbol'), findsOneWidget);
      expect(find.text('Pádel'), findsOneWidget);
      expect(find.byIcon(Icons.sports_soccer), findsOneWidget);
      expect(find.byIcon(Icons.sports_tennis), findsOneWidget);

      // The tag itself — the nearest Container ancestor — is decoration-free.
      final chip = tester.widget<Container>(
        find
            .ancestor(of: find.text('Fútbol'), matching: find.byType(Container))
            .first,
      );
      expect(chip.decoration, isNull);
    });

    testWidgets('profile shows the birth date without the time', (
      tester,
    ) async {
      // Nico has no birth date (—); Sofia's seed does: 12 Apr 1996.
      await tester.pumpWidget(appHarness(signedInAs: MockStore.socialGoogleId));
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      final label = find.text('Fecha de nacimiento');
      await tester.scrollUntilVisible(
        label,
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      // Date only, es_UY — never the event-date pattern with a time.
      expect(find.text('12 abr 1996'), findsOneWidget);
      expect(find.textContaining('• 00:00'), findsNothing);
    });

    /// Login screen → "Registrate" → the sign-up form.
    Future<void> openSignUp(WidgetTester tester) async {
      await tester.tap(navIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      // The social buttons pushed the signup link below the fold.
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text("¿No tenés cuenta? Registrate"));
      await tester.pumpAndSettle();
    }

    /// The sign-up form's own ListView (text fields add nested scrollables).
    Finder signUpScrollable() => find
        .descendant(
          of: find.byType(SignUpScreen),
          matching: find.byType(Scrollable),
        )
        .first;

    testWidgets('signing up creates the account with a complete profile', (
      tester,
    ) async {
      await tester.pumpWidget(app(signedIn: false));
      await tester.pumpAndSettle();
      await openSignUp(tester);

      // Step 1 — the account: name, email, secure password + checklist.
      await tester.enterText(find.byType(TextFormField).at(0), 'New Bie');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'newbie@demo.app',
      );
      await tester.pump(const Duration(milliseconds: 300)); // email check
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.pumpAndSettle();

      final next = find.widgetWithText(FilledButton, 'Siguiente');
      await tester.scrollUntilVisible(
        next,
        300,
        scrollable: signUpScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();

      // Step 2 — "Sobre vos": username, birth date (Material calendar in
      // tests), gender.
      await tester.enterText(find.byType(TextFormField).at(0), 'newbie');
      await tester.pump(const Duration(milliseconds: 300)); // username check
      await tester.pumpAndSettle();

      // The back arrow (step header) returns to step 1; everything typed
      // survives the round trip.
      await tester.tap(find.byTooltip('Atrás'));
      await tester.pumpAndSettle();
      expect(find.text('Unite a Bracket'), findsOneWidget);
      expect(find.text('Sobre vos'), findsNothing);

      // Step 1 remounts unscrolled: bring the action back into view.
      await tester.scrollUntilVisible(
        next,
        300,
        scrollable: signUpScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('Sobre vos'), findsOneWidget);
      expect(find.text('newbie'), findsOneWidget); // kept by the controller

      await tester.scrollUntilVisible(
        find.text('Tocá para elegir'),
        300,
        scrollable: signUpScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tocá para elegir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(ChoiceChip, 'Hombre'),
        300,
        scrollable: signUpScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Hombre'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Siguiente'));
      await tester.pumpAndSettle();

      // Step 3 — sports (football comes preselected, like on the
      // profile-edit form — the tap adds a second one).
      await tester.scrollUntilVisible(
        find.widgetWithText(ChoiceChip, 'Pádel'),
        300,
        scrollable: signUpScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pádel'));
      await tester.pumpAndSettle();

      final submit = find.widgetWithText(FilledButton, 'Crear cuenta');
      await tester.scrollUntilVisible(
        submit,
        300,
        scrollable: signUpScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();

      // Landed back on the profile tab the user came from (the login link
      // carries `from`), with the collected data and no completion step:
      // no "incomplete profile" banner either.
      expect(find.byType(SignUpScreen), findsNothing);
      expect(find.text('New Bie'), findsOneWidget);
      expect(find.text('@newbie'), findsOneWidget);
      expect(find.text('15 oct 2001'), findsOneWidget);
      expect(find.text('Tu perfil está incompleto'), findsNothing);
    });

    testWidgets('signing up enforces a strong password', (tester) async {
      await tester.pumpWidget(app(signedIn: false));
      await tester.pumpAndSettle();
      await openSignUp(tester);

      // Digits only: in the live checklist only the number rule ticks.
      await tester.enterText(find.byType(TextFormField).at(2), '123456');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);

      final next = find.widgetWithText(FilledButton, 'Siguiente');
      await tester.scrollUntilVisible(
        next,
        300,
        scrollable: signUpScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();

      // The step change is rejected with the first failing rule — still
      // on step 1 (step 2's heading never mounts).
      expect(find.text('Usá al menos 8 caracteres'), findsOneWidget);
      expect(find.text('Sobre vos'), findsNothing);

      // Uppercase + lowercase + digits + length: all four rules tick.
      await tester.scrollUntilVisible(
        find.byType(TextFormField).at(2),
        -300,
        scrollable: signUpScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsNWidgets(4));
    });

    testWidgets('sign-up flags a registered email and a taken username', (
      tester,
    ) async {
      await tester.pumpWidget(app(signedIn: false));
      await tester.pumpAndSettle();
      await openSignUp(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'New Bie');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');

      // Nico's demo email is registered: the field flags it live (250 ms
      // debounce) and the step change is blocked.
      await tester.enterText(find.byType(TextFormField).at(1), 'nico@demo.app');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Ya existe una cuenta con ese email.'), findsOneWidget);

      final next = find.widgetWithText(FilledButton, 'Siguiente');
      await tester.scrollUntilVisible(
        next,
        300,
        scrollable: signUpScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('Sobre vos'), findsNothing); // blocked by the email

      // A free email clears the flag and the step advances.
      await tester.enterText(find.byType(TextFormField).at(1), 'free@demo.app');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Ya existe una cuenta con ese email.'), findsNothing);

      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('Sobre vos'), findsOneWidget);

      // Lucia's seeded username: the same live flag on step 2.
      await tester.enterText(find.byType(TextFormField).at(0), 'lucia');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(
        find.text('Ese nombre de usuario ya está en uso.'),
        findsOneWidget,
      );
    });

    testWidgets('advancing awaits the availability check, not the debounce', (
      tester,
    ) async {
      await tester.pumpWidget(app(signedIn: false));
      await tester.pumpAndSettle();
      await openSignUp(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'New Bie');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      final next = find.widgetWithText(FilledButton, 'Siguiente');
      await tester.scrollUntilVisible(
        next,
        300,
        scrollable: signUpScrollable(),
      );
      await tester.pumpAndSettle();

      // Registered email, then the action right away — far short of the
      // 250 ms debounce: the fresh check must still block the step.
      await tester.enterText(find.byType(TextFormField).at(1), 'nico@demo.app');
      await tester.pump();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('Sobre vos'), findsNothing);
      expect(find.text('Ya existe una cuenta con ese email.'), findsOneWidget);

      // Free email with the same rush: the fresh check clears it and the
      // step advances.
      await tester.enterText(find.byType(TextFormField).at(1), 'free@demo.app');
      await tester.pump();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('Sobre vos'), findsOneWidget);

      // Step 2 the same way: Lucia's handle is taken and the tap waits
      // for it instead of stepping over the field.
      await tester.enterText(find.byType(TextFormField).at(0), 'lucia');
      await tester.pump();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('¿Qué jugás?'), findsNothing);
      expect(
        find.text('Ese nombre de usuario ya está en uso.'),
        findsOneWidget,
      );
    });

    testWidgets('signing out returns to the login screen', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('Nicolas Perez'), findsOneWidget);

      final signOutButton = find.widgetWithText(FilledButton, 'Cerrar sesión');
      // The button sits below the fold in the 800x600 test viewport.
      await tester.scrollUntilVisible(
        signOutButton,
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(signOutButton);
      await tester.pumpAndSettle();

      // The dialog cancels from the close (X) on top — there is no cancel
      // action in the row (design.md §7) — and only the full-width
      // confirm signs out.
      final close = find.descendant(
        of: find.byType(Dialog),
        matching: find.byIcon(Icons.close),
      );
      expect(close, findsOneWidget);
      expect(find.text('Cancelar'), findsNothing);

      await tester.tap(close);
      await tester.pumpAndSettle();
      // Closed without signing out: the profile (and its button) remains.
      expect(find.byType(Dialog), findsNothing);
      expect(signOutButton, findsOneWidget);

      await tester.tap(signOutButton);
      await tester.pumpAndSettle();

      final confirm = find.descendant(
        of: find.byType(Dialog),
        matching: find.widgetWithText(FilledButton, 'Cerrar sesión'),
      );
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('on iOS the sign-out dialog is the native Cupertino alert', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();

        await tester.tap(navIcon(Icons.person_outline));
        await tester.pumpAndSettle();

        final signOutButton = find.widgetWithText(
          FilledButton,
          'Cerrar sesión',
        );
        await tester.scrollUntilVisible(
          signOutButton,
          300,
          scrollable: find.byType(Scrollable),
        );
        await tester.pumpAndSettle();
        await tester.tap(signOutButton);
        await tester.pumpAndSettle();

        // Native alert with the red destructive action and the X on top —
        // no second action (design.md §7 "Platform adaptation").
        final alert = find.byType(CupertinoAlertDialog);
        expect(alert, findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
        expect(
          find.descendant(
            of: alert,
            matching: find.widgetWithText(
              CupertinoDialogAction,
              'Cerrar sesión',
            ),
          ),
          findsOneWidget,
        );

        await tester.tap(
          find.descendant(
            of: alert,
            matching: find.widgetWithText(
              CupertinoDialogAction,
              'Cerrar sesión',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TextFormField), findsNWidgets(2));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  group('Profile phone (widgets)', () {
    /// Profile tab → "Editar perfil" → the profile form.
    Future<void> openProfileForm(WidgetTester tester) async {
      await tester.tap(navIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      final editButton = find.text('Editar perfil');
      await tester.scrollUntilVisible(
        editButton,
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(editButton);
      await tester.pumpAndSettle();
    }

    /// Name, username, phone — in field order on the form.
    Finder phoneField() => find.byType(TextFormField).at(2);

    Finder saveButton() => find.widgetWithText(FilledButton, 'Guardar cambios');

    /// The form's own Scrollable: the profile screen under the pushed route
    /// scrolls too, and nested text fields add their own.
    Finder formScrollable() => find
        .descendant(
          of: find.byType(ProfileFormScreen),
          matching: find.byType(Scrollable),
        )
        .first;

    testWidgets('selected sport chip label reads white on the green fill', (
      tester,
    ) async {
      await tester.pumpWidget(appHarness());
      await tester.pumpAndSettle();

      await openProfileForm(tester);

      // The sports section sits below the fold on the form.
      await tester.scrollUntilVisible(
        find.text('Deportes que jugás'),
        300,
        scrollable: formScrollable(),
      );
      await tester.pumpAndSettle();

      // Nico has football + padel: tennis is the unselected one to tap.
      final chip = find.widgetWithText(ChoiceChip, 'Tenis');
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
      // The selected label rides the theme's secondaryLabelStyle — white,
      // bold — never the resting grey on the solid primary fill.
      final label = tester.widget<RichText>(
        find.descendant(of: chip, matching: find.byType(RichText)).first,
      );
      expect(label.text.style?.color, AppTheme.light.colorScheme.onPrimary);
    });

    testWidgets('dial code defaults to the location country', (tester) async {
      await tester.pumpWidget(
        appHarness(
          signedInAs: MockStore.socialGoogleId,
          withLocation: true,
          reverseCountryCode: 'uy',
        ),
      );
      await tester.pumpAndSettle();

      await openProfileForm(tester);

      // Empty phone: the dial code follows the (fake) device location.
      expect(find.text('+598'), findsOneWidget);
      expect(find.text('+54'), findsNothing);
    });

    testWidgets('falls back to +598 and saves dial + national digits', (
      tester,
    ) async {
      // No device location available: the app's default country.
      await tester.pumpWidget(appHarness(signedInAs: MockStore.socialGoogleId));
      await tester.pumpAndSettle();

      await openProfileForm(tester);
      expect(find.text('+598'), findsOneWidget);

      await tester.enterText(phoneField(), '9912 3456');
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        saveButton(),
        300,
        scrollable: formScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      // One international digit string, no `+`: the format WhatsApp wants.
      expect(
        MockStore().profileById(MockStore.socialGoogleId)!.phone,
        '59899123456',
      );
    });

    testWidgets('a stored number opens split into dial and national part', (
      tester,
    ) async {
      await tester.pumpWidget(appHarness()); // Nico: 5491155551234.
      await tester.pumpAndSettle();

      await openProfileForm(tester);

      expect(find.text('+54'), findsOneWidget);
      expect(find.text('91155551234'), findsOneWidget);
    });

    testWidgets('an untouched optional phone stays empty on save', (
      tester,
    ) async {
      await tester.pumpWidget(appHarness(signedInAs: MockStore.socialGoogleId));
      await tester.pumpAndSettle();

      await openProfileForm(tester);

      await tester.scrollUntilVisible(
        saveButton(),
        300,
        scrollable: formScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      // The empty field must not persist a bare dial code.
      expect(MockStore().profileById(MockStore.socialGoogleId)!.phone, isEmpty);
    });
  });
}
