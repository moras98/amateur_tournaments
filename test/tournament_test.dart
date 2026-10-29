import 'package:tande/core/widgets/tournament_banner.dart';
import 'package:tande/data/repositories/mock/mock_store.dart';
import 'package:tande/data/repositories/mock/mock_tournament_repository.dart';
import 'package:tande/features/explore/explore_providers.dart';
import 'package:tande/features/inscriptions/my_inscriptions_screen.dart';
import 'package:tande/features/tournament/tournament_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

/// Taps the register CTA and confirms the team-name dialog that now sits in
/// front of it (pre-filled with the player's name; the test types a team).
Future<void> registerWithTeam(WidgetTester tester, {String? team}) async {
  await tester.pumpAndSettle();
  if (team != null) {
    await tester.enterText(find.byKey(const Key('team-name-field')), team);
  }
  await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(MockStore().reset);

  /// Taps the search field, waits out the debounce and opens the only result.
  Future<void> openTournament(WidgetTester tester, String search) async {
    await tester.enterText(find.byType(TextField), search);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    // The search field also contains [search] — tap the result card.
    await tester.tap(find.widgetWithText(Card, search));
    await tester.pumpAndSettle();
  }

  /// Explore opens filtered to the profile sports (nico: football + padel)
  /// — widen to every sport before reaching for other events.
  Future<void> showEverySport(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Todos'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
    await tester.pumpAndSettle();
  }

  Finder inDetail(Finder matcher) => find.descendant(
    of: find.byType(TournamentDetailScreen),
    matching: matcher,
  );

  group('Tournament detail', () {
    testWidgets('shows info, organizer, mini-map and current state', (
      tester,
    ) async {
      await tester.pumpWidget(appHarness(initialView: ExploreView.list));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Copa Centro 7v7'));
      await tester.pumpAndSettle();

      expect(find.byType(TournamentDetailScreen), findsOneWidget);
      expect(inDetail(find.text('Copa Centro 7v7')), findsOneWidget);
      expect(inDetail(find.text(r'$ 25.000')), findsOneWidget);

      // The banner pushes the mini-map below the fold (and below the
      // cache extent): bring it into view before asserting it.
      final detailScrollable = find.descendant(
        of: find.byType(TournamentDetailScreen),
        matching: find.byWidgetPredicate(
          (widget) => widget is Scrollable && widget.axis == Axis.vertical,
        ),
      );
      await tester.scrollUntilVisible(
        inDetail(find.byType(FlutterMap)), // location preview
        400,
        scrollable: detailScrollable,
      );
      await tester.pumpAndSettle();
      expect(inDetail(find.byType(FlutterMap)), findsOneWidget);
      // The demo player has a seeded confirmed inscription for this event.
      expect(inDetail(find.text('Estás inscripto')), findsOneWidget);

      // Organizer card and description sit below the fold in the ListView.
      await tester.scrollUntilVisible(
        find.text('Carlos Ruiz'),
        400,
        scrollable: detailScrollable,
      );
      await tester.pumpAndSettle();

      expect(inDetail(find.text('Carlos Ruiz')), findsOneWidget); // organizer
      expect(
        inDetail(find.textContaining('eliminación directa')),
        findsOneWidget,
      );
    });

    testWidgets('registering creates a pending inscription', (tester) async {
      mockUrlLauncher(tester);
      await tester.pumpWidget(appHarness(initialView: ExploreView.list));
      await tester.pumpAndSettle();
      // Explore opens on the profile sports (nico: football + padel);
      // widen it to reach the basketball event.
      await showEverySport(tester);

      await openTournament(tester, 'Copa Prado 3v3');

      expect(
        inDetail(find.widgetWithText(FilledButton, 'Inscribirme')),
        findsOneWidget,
      );

      await tester.tap(
        inDetail(find.widgetWithText(FilledButton, 'Inscribirme')),
      );
      await registerWithTeam(tester, team: 'Los Pibes');

      // Registration is created and WhatsApp opens with a pre-filled message.
      expect(
        find.text(
          'Inscripción solicitada. Coordiná el pago por WhatsApp — '
          'el organizador confirma tu lugar.',
        ),
        findsOneWidget,
      );
      expect(inDetail(find.text('Esperando confirmación')), findsOneWidget);

      // Let the snackbar dismiss so no timers leak into teardown.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // The detail page covers the shell — go back, then open My inscriptions.
      // (pageBack() looks up the English 'Back' tooltip — es_UY says "Atrás".)
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.confirmation_num_outlined),
        ),
      );
      await tester.pumpAndSettle();

      final card = find.widgetWithText(Card, 'Copa Prado 3v3');
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.byIcon(Icons.hourglass_top)),
        findsOneWidget,
      );
    });

    testWidgets(
      'inscriptions tab visited before registering shows the new pending '
      'inscription',
      (tester) async {
        mockUrlLauncher(tester);
        await tester.pumpWidget(appHarness(initialView: ExploreView.list));
        await tester.pumpAndSettle();
        // The profile sport default hides the basketball event — widen first.
        await showEverySport(tester);

        Future<void> openTab(IconData icon) async {
          await tester.tap(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.byIcon(icon),
            ),
          );
          await tester.pumpAndSettle();
        }

        // Open the tab BEFORE registering: it fetches and caches its list.
        await openTab(Icons.confirmation_num_outlined);
        expect(
          find.text('Futbol 5 Nocturno Cordón'), // seeded pending
          findsOneWidget,
        );
        expect(find.text('Copa Prado 3v3'), findsNothing);

        // Back to Explore, register for a new tournament.
        await openTab(Icons.map_outlined);
        await openTournament(tester, 'Copa Prado 3v3');
        await tester.tap(
          inDetail(find.widgetWithText(FilledButton, 'Inscribirme')),
        );
        await registerWithTeam(tester, team: 'Los Pibes');

        // Let the snackbar dismiss so no timers leak into teardown.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await openTab(Icons.confirmation_num_outlined);

        // The cached list must have been refreshed with the new inscription.
        final card = find.widgetWithText(Card, 'Copa Prado 3v3');
        expect(card, findsOneWidget);
        expect(
          find.descendant(of: card, matching: find.byIcon(Icons.hourglass_top)),
          findsOneWidget,
        );
      },
    );

    testWidgets('cancelling an inscription frees the spot', (tester) async {
      await tester.pumpWidget(appHarness(initialView: ExploreView.list));
      await tester.pumpAndSettle();

      // The demo player holds a seeded confirmed inscription for this event.
      await tester.tap(find.text('Copa Centro 7v7'));
      await tester.pumpAndSettle();

      expect(inDetail(find.text('Estás inscripto')), findsOneWidget);

      // The spots card sits below the fold in the detail's ListView.
      final detailScrollable = find.descendant(
        of: find.byType(TournamentDetailScreen),
        matching: find.byWidgetPredicate(
          (widget) => widget is Scrollable && widget.axis == Axis.vertical,
        ),
      );
      await tester.scrollUntilVisible(
        find.text('12 de 16 lugares tomados'),
        400,
        scrollable: detailScrollable,
      );
      await tester.pumpAndSettle();
      expect(inDetail(find.text('12 de 16 lugares tomados')), findsOneWidget);

      await tester.tap(inDetail(find.text('Cancelar inscripción')));
      await tester.pumpAndSettle();

      // Confirmation dialog.
      expect(find.text('¿Cancelar inscripción?'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Cancelar inscripción'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inscripción cancelada'), findsOneWidget);
      // The spot is free again: registration reopens, counts drop.
      expect(
        inDetail(find.widgetWithText(FilledButton, 'Inscribirme')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('11 de 16 lugares tomados'),
        400,
        scrollable: detailScrollable,
      );
      await tester.pumpAndSettle();
      expect(inDetail(find.text('11 de 16 lugares tomados')), findsOneWidget);

      // Let the snackbar dismiss so no timers leak into teardown.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('signed out: the button asks to sign in first', (tester) async {
      await tester.pumpWidget(
        appHarness(initialView: ExploreView.list, signedIn: false),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Copa Centro 7v7'));
      await tester.pumpAndSettle();

      await tester.tap(inDetail(find.text('Iniciar sesión para inscribirte')));
      await tester.pumpAndSettle();

      expect(find.byType(TournamentDetailScreen), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('shows the organizer banner on card and detail', (
      tester,
    ) async {
      // t-1 ("Copa Centro 7v7") ships with the seeded banner; t-2 has none.
      await tester.pumpWidget(appHarness(initialView: ExploreView.list));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.widgetWithText(Card, 'Copa Centro 7v7'),
          matching: find.byType(TournamentBanner),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(Card, 'Liga Abierta de Padel Parque Rodó'),
          matching: find.byType(TournamentBanner),
        ),
        findsNothing,
      );

      await tester.tap(find.text('Copa Centro 7v7'));
      await tester.pumpAndSettle();

      expect(inDetail(find.byType(TournamentBanner)), findsOneWidget);
    });

    testWidgets('sharing sends the title and the store listing', (
      tester,
    ) async {
      String? sharedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        (call) async {
          if (call.method == 'share') {
            sharedText = (call.arguments as Map)['text'] as String?;
            return 'success';
          }
          return null;
        },
      );

      await tester.pumpWidget(appHarness(initialView: ExploreView.list));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Copa Centro 7v7'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Compartir evento'));
      await tester.pumpAndSettle();

      // The text carries the event and points at this platform's store
      // listing (in tests the target platform is Android → the Play link).
      expect(sharedText, contains('Copa Centro 7v7'));
      expect(
        sharedText,
        contains('https://play.google.com/store/apps/details?id=com.tande.app'),
      );
      // Success: no failure notice.
      expect(
        find.text('No pudimos abrir el menú para compartir.'),
        findsNothing,
      );
    });

    testWidgets('when WhatsApp fails the contact sheet offers the other '
        'channels', (tester) async {
      // url_launcher refuses: no WhatsApp installed / no handler.
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (call) async => false,
      );

      await tester.pumpWidget(appHarness(initialView: ExploreView.list));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Copa Centro 7v7'));
      await tester.pumpAndSettle();

      // The organizer card sits below the fold (the banner pushes it down).
      final detailScrollable = find.descendant(
        of: find.byType(TournamentDetailScreen),
        matching: find.byWidgetPredicate(
          (widget) => widget is Scrollable && widget.axis == Axis.vertical,
        ),
      );
      final contact = find.widgetWithText(FilledButton, 'WhatsApp');
      await tester.scrollUntilVisible(
        contact,
        400,
        scrollable: detailScrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(contact);
      await tester.pumpAndSettle();

      // Instead of a dead-end notice the channels sheet opens — "Llamar"
      // carries the same number.
      expect(find.text('Contactar a Carlos Ruiz'), findsOneWidget);
      expect(find.text('Llamar'), findsOneWidget);
      expect(
        find.text('No pudimos abrir esa vía. Probá con otra.'),
        findsNothing,
      );
    });
  });

  group('Banner storage', () {
    test('upload stores bytes and replaces the previous object', () async {
      final store = MockStore();
      final repository = MockTournamentRepository();

      final first = await repository.uploadBanner('t-2', kTransparentGif);
      expect(store.banners[first], kTransparentGif);

      final second = await repository.uploadBanner(
        't-2',
        Uint8List.fromList(const [1, 2, 3]),
      );
      expect(second, isNot(first));
      // The tournament keeps a single object — the stale upload is gone.
      expect(store.banners.containsKey(first), isFalse);
      expect(store.banners[second], const [1, 2, 3]);
      // Other tournaments' banners are untouched.
      expect(store.banners.containsKey('t-1/banner-seed.jpg'), isTrue);
    });

    test('removeBanner deletes the stored object', () async {
      final store = MockStore();
      final repository = MockTournamentRepository();

      final path = await repository.uploadBanner('t-3', kTransparentGif);
      await repository.removeBanner(path);

      expect(store.banners.containsKey(path), isFalse);
    });

    test('deleting a tournament removes its banner object too', () async {
      final store = MockStore();
      final repository = MockTournamentRepository();
      final seeded = store.tournamentById('t-1')!.bannerPath!;
      expect(store.banners.containsKey(seeded), isTrue);

      await repository.delete('t-1');

      expect(store.tournamentById('t-1'), isNull);
      expect(store.banners.containsKey(seeded), isFalse);
    });
  });

  group('My inscriptions', () {
    Future<void> openTab(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.confirmation_num_outlined),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('status chips stay on one row on a narrow phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(appHarness());
      await tester.pumpAndSettle();

      await openTab(tester);

      // All three share a y: a Wrap would push the last chip to a centered
      // second row at this width.
      final tops = [
        for (final label in const ['Todas', 'Pendientes', 'Confirmadas'])
          tester.getTopLeft(find.widgetWithText(ChoiceChip, label)).dy,
      ];
      expect(tops.toSet(), hasLength(1), reason: 'chips wrapped to 2 rows');
      expect(find.byType(ChoiceChip), findsNWidgets(3));
    });

    testWidgets('lists inscriptions with status chips and filters', (
      tester,
    ) async {
      await tester.pumpWidget(appHarness());
      await tester.pumpAndSettle();

      await openTab(tester);
      expect(find.byType(MyInscriptionsScreen), findsOneWidget);

      final confirmedCard = find.widgetWithText(Card, 'Copa Centro 7v7');
      final pendingCard = find.widgetWithText(Card, 'Futbol 5 Nocturno Cordón');
      expect(confirmedCard, findsOneWidget);
      expect(pendingCard, findsOneWidget);
      expect(
        find.descendant(
          of: confirmedCard,
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: pendingCard,
          matching: find.byIcon(Icons.hourglass_top),
        ),
        findsOneWidget,
      );

      // Filter to pending only.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pendientes'));
      await tester.pumpAndSettle();

      expect(confirmedCard, findsNothing);
      expect(pendingCard, findsOneWidget);
    });

    testWidgets('searches inscriptions with the shared rounded capsule', (
      tester,
    ) async {
      await tester.pumpWidget(appHarness());
      await tester.pumpAndSettle();

      await openTab(tester);

      // The same capsule as Explore and Organizar (design.md §7): no app
      // bar, and the field carries no fill of its own — the pill's
      // surface is its background.
      expect(find.byType(AppBar), findsNothing);
      final capsule = find.byKey(const ValueKey('inscriptions-search-capsule'));
      expect(capsule, findsOneWidget);
      final field = tester.widget<TextField>(
        find.descendant(of: capsule, matching: find.byType(TextField)),
      );
      expect(field.decoration?.filled, isFalse);

      // "cordón" narrows to the pending Futbol 5 event…
      await tester.enterText(
        find.descendant(of: capsule, matching: find.byType(TextField)),
        'cordón',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(Card, 'Futbol 5 Nocturno Cordón'),
        findsOneWidget,
      );
      expect(find.widgetWithText(Card, 'Copa Centro 7v7'), findsNothing);

      // …and a dead query answers with the shared no-match copy.
      await tester.enterText(
        find.descendant(of: capsule, matching: find.byType(TextField)),
        'zzzzz',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.textContaining('No encontramos eventos'), findsOneWidget);
    });
  });
}
