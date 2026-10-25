import 'package:bracket/core/utils/nav_geometry.dart';
import 'package:bracket/data/repositories/mock/mock_store.dart';
import 'package:bracket/features/explore/explore_providers.dart';
import 'package:bracket/features/explore/explore_screen.dart';
import 'package:bracket/features/organizer/event_form_screen.dart';
import 'package:bracket/features/organizer/event_requests_screen.dart';
import 'package:bracket/features/organizer/organizer_screen.dart';
import 'package:bracket/features/profile/profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

void main() {
  setUp(MockStore().reset);

  Future<void> openOrganizeTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.emoji_events_outlined),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder inForm(Finder matcher) =>
      find.descendant(of: find.byType(EventFormScreen), matching: matcher);

  testWidgets('players without organizer mode see the gate', (tester) async {
    await tester.pumpWidget(appHarness());
    await tester.pumpAndSettle();

    await openOrganizeTab(tester);

    expect(find.byType(OrganizerScreen), findsOneWidget);
    expect(find.text('El modo organizador está desactivado'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Ir al perfil'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Nicolas Perez'), findsOneWidget);
  });

  testWidgets('the organizer search bar is the same rounded capsule', (
    tester,
  ) async {
    await tester.pumpWidget(
      appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
    );
    await tester.pumpAndSettle();

    await openOrganizeTab(tester);

    // No app bar: the search row floats as the shared capsule (design.md
    // §7) with the sort menu trailing inside it.
    expect(find.byType(AppBar), findsNothing);
    final capsule = find.byKey(const ValueKey('organizer-search-capsule'));
    expect(capsule, findsOneWidget);
    expect(
      find.descendant(of: capsule, matching: find.byType(TextField)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: capsule, matching: find.byIcon(Icons.sort)),
      findsOneWidget,
    );
    // The list clears the capsule's region (margin + bar + margin).
    expect(
      tester.getTopLeft(find.byType(Card).first).dy,
      greaterThanOrEqualTo(kNavCapsuleRegionHeight),
    );
  });

  testWidgets('organizers see their events with requests badges', (
    tester,
  ) async {
    await tester.pumpWidget(
      appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
    );
    await tester.pumpAndSettle();

    await openOrganizeTab(tester);

    expect(find.widgetWithText(Card, 'Copa Centro 7v7'), findsOneWidget);
    expect(
      find.widgetWithText(Card, 'Liga Abierta de Padel Parque Rodó'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(Card, 'Futbol 5 Nocturno Cordón'),
      findsOneWidget,
    );
    // Another organizer's event never shows up.
    expect(find.text('Copa Prado 3v3'), findsNothing);

    // Pending request badges (one for Copa Centro, one for Cordón).
    expect(find.text('1 solicitud'), findsNWidgets(2));
    expect(find.text('12 de 16 lugares'), findsOneWidget);
  });

  testWidgets('search filters my events by title and venue', (tester) async {
    await tester.pumpWidget(
      appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
    );
    await tester.pumpAndSettle();

    await openOrganizeTab(tester);

    await tester.enterText(find.byType(TextField), 'padel');
    await tester.pump(const Duration(milliseconds: 300)); // debounce
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(Card, 'Liga Abierta de Padel Parque Rodó'),
      findsOneWidget,
    );
    expect(find.text('Copa Centro 7v7'), findsNothing);
    expect(find.text('Futbol 5 Nocturno Cordón'), findsNothing);

    // The venue matches too ("Canchas Cordón").
    await tester.enterText(find.byType(TextField), 'cordón');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(Card, 'Futbol 5 Nocturno Cordón'),
      findsOneWidget,
    );
    expect(find.text('Liga Abierta de Padel Parque Rodó'), findsNothing);

    // No match at all: a friendly empty state, not a blank list.
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(
      find.text('No encontramos eventos que coincidan con "zzz".'),
      findsOneWidget,
    );

    // Clearing the search restores every event.
    await tester.tap(find.byTooltip('Borrar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('Copa Centro 7v7'), findsOneWidget);
    expect(find.text('Liga Abierta de Padel Parque Rodó'), findsOneWidget);
    expect(find.text('Futbol 5 Nocturno Cordón'), findsOneWidget);
  });

  testWidgets('sort menu reorders my events', (tester) async {
    await tester.pumpWidget(
      appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
    );
    await tester.pumpAndSettle();

    await openOrganizeTab(tester);

    double topOf(String title) =>
        tester.getTopLeft(find.widgetWithText(Card, title)).dy;

    // Default order is by date: Cordón (in 2 days) leads.
    expect(
      topOf('Futbol 5 Nocturno Cordón'),
      lessThan(topOf('Copa Centro 7v7')),
    );

    await tester.tap(find.byTooltip('Ordenar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Título (A–Z)'));
    await tester.pumpAndSettle();

    // Alphabetical: "Copa..." leads, "Liga..." closes the list.
    expect(
      topOf('Copa Centro 7v7'),
      lessThan(topOf('Futbol 5 Nocturno Cordón')),
    );
    expect(
      topOf('Futbol 5 Nocturno Cordón'),
      lessThan(topOf('Liga Abierta de Padel Parque Rodó')),
    );

    // Newest-first puts Cordón (created 2 days ago) back on top.
    await tester.tap(find.byTooltip('Ordenar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Creados recientemente'));
    await tester.pumpAndSettle();
    expect(
      topOf('Futbol 5 Nocturno Cordón'),
      lessThan(topOf('Liga Abierta de Padel Parque Rodó')),
    );
  });

  testWidgets('creating an event publishes it to the app', (tester) async {
    await tester.pumpWidget(
      appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
    );
    await tester.pumpAndSettle();

    await openOrganizeTab(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(EventFormScreen), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('event-title')),
      'Copa de Prueba',
    );

    // Teams/cost sit below the fold in the lazy list. The form's own
    // Scrollable is the first match (nested text fields add their own).
    final formScrollable = find
        .descendant(
          of: find.descendant(
            of: find.byType(EventFormScreen),
            matching: find.byType(ListView),
          ),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('event-teams')),
      300,
      scrollable: formScrollable,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('event-teams')), '8');
    await tester.enterText(find.byKey(const Key('event-cost')), '20000');

    // The map pin picker sits further below: scroll to it and tap.
    // (Scoped to the form: Explore keeps its own map offstage in list view.)
    final formMap = find.descendant(
      of: find.byType(EventFormScreen),
      matching: find.byType(FlutterMap),
    );
    await tester.scrollUntilVisible(formMap, 400, scrollable: formScrollable);
    await tester.pumpAndSettle();
    // The map may only be partially visible (built via the cache extent).
    await tester.ensureVisible(formMap);
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getRect(formMap).center);
    // flutter_map holds taps briefly to disambiguate double-taps.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.location_pin), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Publicar evento'));
    await tester.pumpAndSettle();

    expect(find.text('Evento publicado'), findsOneWidget);
    expect(find.byType(EventFormScreen), findsNothing);

    // Back on the organizer list (newest event below the fold).
    await tester.scrollUntilVisible(
      find.text('Copa de Prueba'),
      300,
      scrollable: find.descendant(
        of: find.byType(OrganizerScreen),
        matching: find.byWidgetPredicate(
          (widget) => widget is Scrollable && widget.axis == Axis.vertical,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Card, 'Copa de Prueba'), findsOneWidget);

    // ...and on Explore (list view).
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.map_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Copa de Prueba'),
      300,
      scrollable: find.descendant(
        of: find.byType(ExploreScreen),
        matching: find.byWidgetPredicate(
          (widget) => widget is Scrollable && widget.axis == Axis.vertical,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Copa de Prueba'), findsOneWidget);

    // Let the snackbar dismiss so no timers leak into teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'cost accepts the Uruguayan format ("20.000" is twenty thousand)',
    (tester) async {
      await tester.pumpWidget(
        appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
      );
      await tester.pumpAndSettle();

      await openOrganizeTab(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(EventFormScreen), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('event-title')),
        'Copa Miles',
      );
      final formScrollable = find
          .descendant(
            of: find.descendant(
              of: find.byType(EventFormScreen),
              matching: find.byType(ListView),
            ),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.byKey(const Key('event-teams')),
        300,
        scrollable: formScrollable,
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('event-teams')), '8');
      // Dot = thousands separator here: this must save as 20000, not 20.
      await tester.enterText(find.byKey(const Key('event-cost')), '20.000');

      await tester.tap(find.widgetWithText(FilledButton, 'Publicar evento'));
      await tester.pumpAndSettle();
      expect(find.text('Evento publicado'), findsOneWidget);

      // The Explore card renders the parsed amount.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.map_outlined),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Copa Miles'),
        300,
        scrollable: find.descendant(
          of: find.byType(ExploreScreen),
          matching: find.byWidgetPredicate(
            (widget) => widget is Scrollable && widget.axis == Axis.vertical,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = find.widgetWithText(Card, 'Copa Miles');
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text(r'$ 20.000')),
        findsOneWidget,
      );

      // Let the snackbar dismiss so no timers leak into teardown.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('using current location places the pin and fills the address', (
    tester,
  ) async {
    await tester.pumpWidget(
      appHarness(
        signedInAs: 'u-org-1',
        initialView: ExploreView.list,
        withLocation: true,
      ),
    );
    await tester.pumpAndSettle();

    await openOrganizeTab(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(EventFormScreen), findsOneWidget);

    // The location section sits below the fold in the lazy list. The form's
    // own Scrollable is the first match (nested text fields add their own).
    final formScrollable = find
        .descendant(
          of: find.descendant(
            of: find.byType(EventFormScreen),
            matching: find.byType(ListView),
          ),
          matching: find.byType(Scrollable),
        )
        .first;
    final useLocationButton = find.widgetWithText(
      OutlinedButton,
      'Usar mi ubicación',
    );
    await tester.scrollUntilVisible(
      useLocationButton,
      300,
      scrollable: formScrollable,
    );
    await tester.pumpAndSettle();

    await tester.tap(useLocationButton);
    await tester.pumpAndSettle();

    // The snackbar confirms the fields were completed.
    expect(find.text('Dirección completada con tu ubicación.'), findsOneWidget);

    // The (empty) address/city fields get the reverse-geocoded values. The
    // list is clamped near the bottom, so the fields sit just above the
    // viewport (still built): match them in the scrolled-away tree.
    expect(
      find.text('Av. Siempreviva 742', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Springfield', skipOffstage: false), findsOneWidget);

    // The pin lands on the device location. Jump to the end of the form
    // instead of dragging: the map sits at the viewport center and would
    // swallow the drag gesture.
    final formPosition = tester.state<ScrollableState>(formScrollable).position;
    formPosition.jumpTo(formPosition.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.textContaining('Pin ubicado en -34.9012'), findsOneWidget);

    // Let the snackbar dismiss so no timers leak into teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('tapping the map places the pin and fills the address', (
    tester,
  ) async {
    await tester.pumpWidget(
      appHarness(
        signedInAs: 'u-org-1',
        initialView: ExploreView.list,
        withLocation: true,
      ),
    );
    await tester.pumpAndSettle();

    await openOrganizeTab(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(EventFormScreen), findsOneWidget);

    // Bring the form map onscreen (same nested-Scrollable dance as above).
    final formScrollable = find
        .descendant(
          of: find.descendant(
            of: find.byType(EventFormScreen),
            matching: find.byType(ListView),
          ),
          matching: find.byType(Scrollable),
        )
        .first;
    final map = find.byType(FlutterMap);
    await tester.scrollUntilVisible(map, 300, scrollable: formScrollable);
    await tester.pumpAndSettle();

    await tester.tapAt(tester.getCenter(map));
    await tester.pump(const Duration(milliseconds: 400)); // map tap gesture
    await tester.pump(const Duration(milliseconds: 900)); // geocode debounce
    await tester.pumpAndSettle();

    // The pin row shows under the map and the empty fields are completed.
    expect(find.textContaining('Pin ubicado en'), findsOneWidget);
    expect(
      find.text('Av. Siempreviva 742', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Springfield', skipOffstage: false), findsOneWidget);
  });

  testWidgets('confirming a request moves the player to confirmed', (
    tester,
  ) async {
    await tester.pumpWidget(
      appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
    );
    await tester.pumpAndSettle();

    await openOrganizeTab(tester);
    await tester.tap(find.text('Copa Centro 7v7'));
    await tester.pumpAndSettle();
    expect(find.byType(EventRequestsScreen), findsOneWidget);

    // Lucia's pending request, with her note.
    expect(find.text('Lucia Gomez'), findsOneWidget);
    expect(find.text('"Pago por transferencia hoy."'), findsOneWidget);
    expect(find.text('12 de 16 lugares tomados'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Inscripción confirmada'), findsOneWidget);
    expect(find.text('Lucia Gomez'), findsNothing); // left the pending view
    expect(find.text('13 de 16 lugares tomados'), findsOneWidget);

    // Now visible under the Confirmed filter (with Nicolas's seed).
    await tester.tap(find.widgetWithText(ChoiceChip, 'Confirmadas'));
    await tester.pumpAndSettle();
    expect(find.text('Lucia Gomez'), findsOneWidget);
    expect(find.text('Nicolas Perez'), findsOneWidget);
    expect(find.text('Los Halcones'), findsOneWidget);

    // Back on the list: the badge for this event is gone (Cordón's stays).
    // (pageBack() looks up the English 'Back' tooltip — es_UY says "Atrás".)
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('1 solicitud'), findsNWidgets(1));
    expect(find.text('13 de 16 lugares'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('organizer can count teams confirmed off the app', (
    tester,
  ) async {
    await tester.pumpWidget(
      appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
    );
    await tester.pumpAndSettle();

    await openOrganizeTab(tester);
    await tester.tap(find.text('Copa Centro 7v7'));
    await tester.pumpAndSettle();
    expect(find.byType(EventRequestsScreen), findsOneWidget);
    expect(find.text('12 de 16 lugares tomados'), findsOneWidget);

    // Bump the off-app count: the "lugares tomados" total includes it.
    await tester.tap(find.byKey(const Key('manual-add')));
    await tester.pumpAndSettle();
    expect(
      find.text('Confirmados fuera de la app actualizados'),
      findsOneWidget,
    );
    expect(find.text('13 de 16 lugares tomados'), findsOneWidget);

    // ...and back down; the remove stepper parks at zero.
    await tester.tap(find.byKey(const Key('manual-remove')));
    await tester.pumpAndSettle();
    expect(find.text('12 de 16 lugares tomados'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('manual-remove')))
          .onPressed,
      isNull,
    );

    // Let the snackbar dismiss so no timers leak into teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('the off-app count can be typed and never exceeds the cupo', (
    tester,
  ) async {
    await tester.pumpWidget(
      appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
    );
    await tester.pumpAndSettle();

    await openOrganizeTab(tester);
    await tester.tap(find.text('Copa Centro 7v7'));
    await tester.pumpAndSettle();

    // Tap the number to type an amount: 10 clamps to the spare capacity.
    await tester.tap(find.byKey(const Key('manual-count')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Confirmados fuera de la app'),
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '10');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    // 12 in the app + 4 spare = full house, and the status flips.
    expect(find.text('16 de 16 lugares tomados'), findsOneWidget);
    expect(find.text('COMPLETO'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byKey(const Key('manual-add'))).onPressed,
      isNull,
    );

    // Let the snackbar dismiss so no timers leak into teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('on iOS the off-app count dialog is the native Cupertino alert', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(
        appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
      );
      await tester.pumpAndSettle();

      await openOrganizeTab(tester);
      await tester.tap(find.text('Copa Centro 7v7'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manual-count')));
      await tester.pumpAndSettle();

      // Native alert with the Cupertino field; the clamp survives the
      // widget swap (99 → the 4 spare spots).
      final alert = find.byType(CupertinoAlertDialog);
      expect(alert, findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);

      await tester.enterText(find.byType(CupertinoTextField), '99');
      await tester.tap(
        find.descendant(
          of: alert,
          matching: find.widgetWithText(CupertinoDialogAction, 'Guardar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('16 de 16 lugares tomados'), findsOneWidget);
      expect(find.text('COMPLETO'), findsOneWidget);

      // Let the snackbar dismiss so no timers leak into teardown.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('confirming a request offers a WhatsApp notice to the player', (
    tester,
  ) async {
    mockUrlLauncher(tester);
    await tester.pumpWidget(
      appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
    );
    await tester.pumpAndSettle();

    await openOrganizeTab(tester);
    await tester.tap(find.text('Copa Centro 7v7'));
    await tester.pumpAndSettle();
    expect(find.byType(EventRequestsScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Inscripción confirmada'), findsOneWidget);

    // The snackbar action pings the player with the decision.
    await tester.tap(find.text('Avisar por WhatsApp'));
    await tester.pumpAndSettle();

    // WhatsApp opened with the pre-filled message: no failure snackbar.
    expect(find.textContaining('No se pudo abrir WhatsApp'), findsNothing);

    // Let the snackbar dismiss so no timers leak into teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('editing an event saves the changes', (tester) async {
    await tester.pumpWidget(
      appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
    );
    await tester.pumpAndSettle();

    await openOrganizeTab(tester);
    await tester.tap(find.text('Futbol 5 Nocturno Cordón'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(EventFormScreen), findsOneWidget);

    // The form comes prefilled (the map opens directly on the venue pin:
    // initial data loads before the form mounts).
    expect(
      inForm(find.widgetWithText(TextFormField, 'Futbol 5 Nocturno Cordón')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('event-title')),
      'Futbol 5 Nocturno Cordón 2',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Evento guardado'), findsOneWidget);
    expect(find.byType(EventRequestsScreen), findsOneWidget);
    expect(find.text('Futbol 5 Nocturno Cordón 2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('organizer can close and reopen registrations', (tester) async {
    await tester.pumpWidget(
      appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
    );
    await tester.pumpAndSettle();

    await openOrganizeTab(tester);
    await tester.tap(find.text('Liga Abierta de Padel Parque Rodó'));
    await tester.pumpAndSettle();
    expect(find.byType(EventRequestsScreen), findsOneWidget);

    // Close registrations from the overflow menu.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar inscripciones'));
    await tester.pumpAndSettle();

    expect(find.text('Inscripciones cerradas'), findsOneWidget);
    expect(find.text('CERRADO'), findsOneWidget);

    // ...and reopen. The new snackbar queues behind the still-visible
    // "closed" one — wait it out before asserting.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reabrir inscripciones'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Inscripciones reabiertas'), findsOneWidget);
    expect(find.text('CERRADO'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('organizer can delete an event', (tester) async {
    await tester.pumpWidget(
      appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
    );
    await tester.pumpAndSettle();

    await openOrganizeTab(tester);
    await tester.tap(find.text('Futbol 5 Nocturno Cordón'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar evento'));
    await tester.pumpAndSettle();

    // Confirmation dialog.
    expect(find.text('¿Eliminar evento?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar evento'));
    await tester.pumpAndSettle();

    // Back on the list: the event and its pending badge are gone.
    expect(find.byType(EventRequestsScreen), findsNothing);
    expect(find.text('Futbol 5 Nocturno Cordón'), findsNothing);
    expect(find.text('1 solicitud'), findsNWidgets(1)); // only t-1's remains
  });
}
