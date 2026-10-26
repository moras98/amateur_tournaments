import 'dart:async';

import 'package:tande/core/utils/nav_geometry.dart';
import 'package:tande/data/repositories/mock/mock_store.dart';
import 'package:tande/data/repositories/mock/mock_tournament_repository.dart';
import 'package:tande/data/repositories/supabase/supabase_tournament_repository.dart';
import 'package:tande/data/repositories/tournament_repository.dart';
import 'package:tande/features/explore/explore_providers.dart';
import 'package:tande/features/tournament/tournament_detail_screen.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'support/harness.dart';

void main() {
  setUp(MockStore().reset);

  group('Explore list', () {
    testWidgets('shows tournaments with spots left and cost', (tester) async {
      await tester.pumpWidget(
        appHarness(initialView: ExploreView.list, withLocation: true),
      );
      await tester.pumpAndSettle();

      // Closest event (sorted by distance from the fake location).
      expect(find.text('Copa Centro 7v7'), findsOneWidget);
      expect(find.text('4 lugares libres'), findsOneWidget);
      expect(find.text(r'$ 25.000'), findsOneWidget);
      expect(find.text('Cerrado'), findsOneWidget);

      // The full padel league is farther away: lazy list, scroll to it.
      await tester.scrollUntilVisible(
        find.text('Completo'),
        400,
        // Exclude the search field's horizontal scrollable.
        scrollable: find.byWidgetPredicate(
          (widget) => widget is Scrollable && widget.axis == Axis.vertical,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Completo'), findsOneWidget);
    });

    testWidgets('debounced search narrows the results', (tester) async {
      await tester.pumpWidget(appHarness(initialView: ExploreView.list));
      await tester.pumpAndSettle();

      expect(find.text('Copa Centro 7v7'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'padel');
      // Debounce window is 300ms.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Liga Abierta de Padel Parque Rodó'), findsOneWidget);
      expect(find.text('Copa Centro 7v7'), findsNothing);
    });

    testWidgets('filter sheet applies a sport filter', (tester) async {
      await tester.pumpWidget(appHarness(initialView: ExploreView.list));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // No device location: the sheet offers an explicit retry instead of
      // hiding the distance filters for the whole session.
      expect(find.text('Actualizar ubicación'), findsOneWidget);

      // The sheet opens with the profile default preselected (nico:
      // football + padel) — a multi-select toggle: drop football to keep
      // padel only.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Fútbol'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
      await tester.pumpAndSettle();

      expect(find.text('Liga Abierta de Padel Parque Rodó'), findsOneWidget);
      expect(find.text('Abierto de Padel Barrio Sur'), findsOneWidget);
      expect(find.text('Copa Centro 7v7'), findsNothing);

      // Badge on the filter button shows one active filter.
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('empty state offers to clear filters and search', (
      tester,
    ) async {
      await tester.pumpWidget(appHarness(initialView: ExploreView.list));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('No se encontraron torneos'), findsOneWidget);

      await tester.tap(find.text('Borrar filtros'));
      await tester.pumpAndSettle();

      expect(find.text('Copa Centro 7v7'), findsOneWidget);
      expect(find.text('No se encontraron torneos'), findsNothing);
      expect(find.widgetWithText(TextField, 'zzzzz'), findsNothing);
    });

    testWidgets('opens filtered to the profile sports until you choose', (
      tester,
    ) async {
      await tester.pumpWidget(appHarness(initialView: ExploreView.list));
      await tester.pumpAndSettle();

      // Nico's profile: football + padel — the other sports stay hidden
      // and the badge already says the view is narrowed.
      expect(find.text('Copa Centro 7v7'), findsOneWidget); // football
      expect(find.text('Liga Abierta de Padel Parque Rodó'), findsOneWidget);
      expect(find.text('Copa Prado 3v3'), findsNothing); // basketball
      expect(find.text('Open de Tenis Ciudad Vieja'), findsNothing); // tennis
      expect(find.text('1'), findsOneWidget); // the filter badge

      // The sheet opens with those sports preselected; "Todos" widens.
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Fútbol'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Pádel'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Todos'))
            .selected,
        isFalse,
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Todos'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
      await tester.pumpAndSettle();

      expect(find.text('Copa Prado 3v3'), findsOneWidget);
      // Lazy list: the tennis open is farther down now that the content
      // clears the capsule's region — scroll it into view.
      await tester.scrollUntilVisible(
        find.text('Open de Tenis Ciudad Vieja'),
        400,
        // Exclude the search field's horizontal scrollable.
        scrollable: find.byWidgetPredicate(
          (widget) => widget is Scrollable && widget.axis == Axis.vertical,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Open de Tenis Ciudad Vieja'), findsOneWidget);
      expect(find.text('1'), findsNothing); // badge gone
    });

    testWidgets('signed out, Explore shows every sport', (tester) async {
      await tester.pumpWidget(
        appHarness(initialView: ExploreView.list, signedIn: false),
      );
      await tester.pumpAndSettle();

      // No profile → no default filter: everything is browsable.
      expect(find.text('Copa Prado 3v3'), findsOneWidget); // basketball
      await tester.scrollUntilVisible(
        find.text('Open de Tenis Ciudad Vieja'),
        400,
        // Exclude the search field's horizontal scrollable.
        scrollable: find.byWidgetPredicate(
          (widget) => widget is Scrollable && widget.axis == Axis.vertical,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Open de Tenis Ciudad Vieja'), findsOneWidget); // tennis
      expect(find.text('1'), findsNothing); // no filter badge either
    });
  });

  group('Explore map', () {
    testWidgets('waits for the device location instead of preloading a city', (
      tester,
    ) async {
      final location = Completer<LatLng?>();
      await tester.pumpWidget(appHarness(locationOverride: location.future));
      // The spinner animates while pending — pump instead of settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // No map mounts (no tiles at all) while the location is resolving.
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      location.complete(testUserLocation);
      await tester.pumpAndSettle();

      // The camera opens exactly on the device location.
      expect(find.byType(FlutterMap), findsOneWidget);
      final camera = MapCamera.of(tester.element(find.byType(TileLayer)));
      expect(camera.center, testUserLocation);
    });

    testWidgets('without a location the map frames the tournaments', (
      tester,
    ) async {
      // Signed out: no profile, no sport default — the frame must hold
      // every seeded pin (it pins "no hardcoded city", not the filter).
      await tester.pumpWidget(appHarness(signedIn: false));
      await tester.pumpAndSettle();

      final camera = MapCamera.of(tester.element(find.byType(TileLayer)));
      // Fitted to the seeded pins' bounds: the camera sits on real content,
      // not on the deleted hardcoded Buenos Aires point.
      expect(camera.center, isNot(const LatLng(-34.6037, -58.3816)));
      for (final t in MockStore().tournaments) {
        expect(
          camera.visibleBounds.contains(t.location!),
          isTrue,
          reason: t.title,
        );
      }
    });

    testWidgets('no location and no pins prompts instead of a map', (
      tester,
    ) async {
      await tester.pumpWidget(appHarness());
      await tester.pumpAndSettle();

      // An impossible search empties the map view's only content.
      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('No pudimos encontrar tu ubicación'), findsOneWidget);

      // Retrying re-requests the location (still unavailable in tests).
      await tester.tap(find.widgetWithText(TextButton, 'Usar mi ubicación'));
      await tester.pumpAndSettle();
      expect(find.text('No pudimos encontrar tu ubicación'), findsOneWidget);
    });

    testWidgets('shows the map and opens the marker sheet', (tester) async {
      await tester.pumpWidget(appHarness(withLocation: true));
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsOneWidget);

      // The Cordón football pin is isolated (other pins may overlap),
      // so it's the safe one to tap.
      await tester.tap(find.byIcon(Icons.sports_soccer).last);
      await tester.pumpAndSettle();

      expect(find.text('Futbol 5 Nocturno Cordón'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Ver detalle'));
      await tester.pumpAndSettle();

      expect(find.byType(TournamentDetailScreen), findsOneWidget);
      expect(find.text('Futbol 5 Nocturno Cordón'), findsOneWidget);
    });

    testWidgets('overlapping pins cluster into a count badge sheet', (
      tester,
    ) async {
      // Signed out: the tennis pin (overlapping the Copa football one) has
      // to exist — a signed-in profile default would filter it away.
      await tester.pumpWidget(appHarness(signedIn: false, withLocation: true));
      await tester.pumpAndSettle();

      // Copa Centro and Open de Tenis Ciudad Vieja sit ~8px apart at the
      // default zoom: they used to overlap (lower pin untappable), now they
      // merge into one count badge.
      await tester.tap(find.byKey(const Key('map-cluster')));
      await tester.pumpAndSettle();

      expect(find.text('Copa Centro 7v7'), findsOneWidget);
      expect(find.text('Open de Tenis Ciudad Vieja'), findsOneWidget);

      await tester.tap(find.text('Copa Centro 7v7'));
      await tester.pumpAndSettle();

      expect(find.byType(TournamentDetailScreen), findsOneWidget);
      expect(find.text('Copa Centro 7v7'), findsOneWidget);
    });

    testWidgets('toggle button switches from map to list', (tester) async {
      await tester.pumpWidget(appHarness());
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsOneWidget);

      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('Copa Centro 7v7'), findsOneWidget);
    });

    testWidgets('the map still mounts after navigation churn', (tester) async {
      await tester.pumpWidget(appHarness(withLocation: true));
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsOneWidget);

      // Open the detail screen: its mini-map unmounts on back, which makes
      // flutter_map dispose the tile provider it was given. The app-scoped
      // provider must survive so every other map keeps loading tiles.
      await tester.tap(find.byIcon(Icons.sports_soccer).last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Ver detalle'));
      await tester.pumpAndSettle();
      expect(
        find.byType(FlutterMap, skipOffstage: false),
        findsNWidgets(2), // explore (covered) + detail mini-map
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Rebuild the explore map from scratch (list → map).
      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('search-capsule')),
          matching: find.byIcon(Icons.map_outlined),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsOneWidget);
    });
    testWidgets('map sits behind the floating nav bar; other tabs do not', (
      tester,
    ) async {
      await tester.pumpWidget(appHarness());
      await tester.pumpAndSettle();

      // The shell body extends behind the capsule on the Explore tab…
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).extendBody,
        isTrue,
      );

      // …and bottom-pinned map content clears the bar. The Scaffold reports
      // the capsule to the extended body as bottom padding (exactly like a
      // system inset), which with no device inset in tests equals the region.
      final mapContext = tester.element(find.byType(FlutterMap));
      expect(MediaQuery.paddingOf(mapContext).bottom, kNavCapsuleRegionHeight);

      final attribution = tester.widget<Positioned>(
        find.ancestor(
          of: find.text('© OpenStreetMap contributors'),
          matching: find.byType(Positioned),
        ),
      );
      expect(attribution.bottom, 8 + kNavCapsuleRegionHeight);

      // Every other tab keeps the reserved area above the bar.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.person_outline),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).extendBody,
        isFalse,
      );
    });
    testWidgets('the row is the same rounded capsule over the map and in list '
        'view', (tester) async {
      await tester.pumpWidget(appHarness());
      await tester.pumpAndSettle();

      // No app bar anywhere: the row floats as a capsule with the bottom
      // nav's recipe (surface fill, hairline border, stadium radius,
      // 12 margin) under the status bar.
      expect(find.byType(AppBar), findsNothing);
      final capsule = find.byKey(const ValueKey('search-capsule'));
      expect(capsule, findsOneWidget);
      // The fill (not the hairline painted over it) starts at the margin.
      final capsuleFill = find.descendant(
        of: capsule,
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color != null,
        ),
      );
      expect(
        tester.getTopLeft(capsuleFill),
        const Offset(kNavCapsuleMargin, kNavCapsuleMargin),
      );
      final decoration =
          tester.widget<DecoratedBox>(capsuleFill).decoration as BoxDecoration;
      expect(
        decoration.borderRadius,
        const BorderRadius.all(Radius.circular(kNavCapsuleBarHeight / 2)),
      );
      expect(
        decoration.color,
        Theme.of(tester.element(capsule)).colorScheme.surface,
      );
      // The whole row lives inside the capsule.
      expect(
        find.descendant(of: capsule, matching: find.byType(TextField)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: capsule, matching: find.byIcon(Icons.tune)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: capsule, matching: find.byIcon(Icons.view_list)),
        findsOneWidget,
      );

      // List view keeps the very same rounded capsule — the pill is the
      // design of the search row everywhere (design.md §7) — and only the
      // content below changes: it slides down to clear the capsule's
      // region (margin + bar + margin).
      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
      expect(capsule, findsOneWidget);
      // One search field in the whole screen — the swap leaves no twin.
      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.descendant(of: capsule, matching: find.byIcon(Icons.map_outlined)),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.byType(Card).first).dy,
        greaterThanOrEqualTo(kNavCapsuleRegionHeight),
      );
    });
    testWidgets('nav labels stay short enough for one line', (tester) async {
      await tester.pumpWidget(appHarness());
      await tester.pumpAndSettle();

      // The SDK's label Text has no maxLines/ellipsis hook: anything wider
      // than a quarter of the capsule wraps to two lines and crowds the
      // capsule ("Mis inscripciones" did). Pin the rename and a length budget
      // (13 chars ≈ 75-80px at 11px, under the ~84px slot at 360dp) — the test
      // font is ~1em per glyph, wider than any real one, so don't measure
      // pixels here.
      expect(find.text('Mis inscripciones'), findsNothing);
      for (final label in const [
        'Explorar',
        'Inscripciones',
        'Organizar',
        'Perfil',
      ]) {
        expect(find.text(label), findsOneWidget);
        expect(
          label.length,
          lessThanOrEqualTo(13),
          reason: '"$label" can wrap in a quarter of the capsule',
        );
      }
    });
  });

  // Server-side query contract (audit 4.8): the radius box, the page cap
  // and the date cut live in the Supabase repository/mock, not in widgets.
  group('Explore query (repository)', () {
    test('the radius box circumscribes the circle around the user', () {
      const center = LatLng(-34.9012, -56.1646); // Montevideo
      final box = SupabaseTournamentRepository.boundingBox(center, 25);

      // Symmetric around the center, which it contains.
      expect(box.latMin, lessThan(center.latitude));
      expect(box.latMax, greaterThan(center.latitude));
      expect(
        center.latitude - box.latMin,
        moreOrLessEquals(box.latMax - center.latitude, epsilon: 1e-9),
      );
      expect(
        center.longitude - box.lonMin,
        moreOrLessEquals(box.lonMax - center.longitude, epsilon: 1e-9),
      );

      // Each latitude side covers the real worst-case km-per-degree
      // (110.57 at the equator … 111.69 at the poles): a box even slightly
      // too small would drop in-range events before the exact client-side
      // circle filter could keep them.
      expect(center.latitude - box.latMin, greaterThanOrEqualTo(25 / 110.57));

      // Away from the equator a degree of longitude is shorter than one of
      // latitude: the box must widen accordingly.
      expect(
        box.lonMax - center.longitude,
        greaterThan(box.latMax - center.latitude),
      );

      // At 65° the longitude degree is under half the latitude one.
      final north = SupabaseTournamentRepository.boundingBox(
        const LatLng(65, -10),
        25,
      );
      expect(
        north.lonMax - north.lonMin,
        greaterThan(2 * (north.latMax - north.latMin)),
      );

      // Wider radius → strictly wider box (chips: 5 / 10 / 25 km).
      final small = SupabaseTournamentRepository.boundingBox(center, 5);
      expect(small.latMin, greaterThan(box.latMin));
      expect(small.latMax, lessThan(box.latMax));
      expect(small.lonMin, greaterThan(box.lonMin));
      expect(small.lonMax, lessThan(box.lonMax));
    });

    test('the Explore page is capped below the PostgREST cut', () {
      // PostgREST stops at 1000 rows: the cap must stay well under it so
      // results stay a bounded page, not an arbitrary slice.
      expect(SupabaseTournamentRepository.exploreLimit, 200);
      expect(SupabaseTournamentRepository.exploreLimit, lessThan(1000));
    });

    test(
      'Explore drops events that already ended; the owner keeps them',
      () async {
        final store = MockStore();
        final repository = MockTournamentRepository(store);
        store.tournaments.add(
          TournamentModel(
            id: 'past-1',
            ownerId: 'u-org-1',
            sport: 'football',
            title: 'Torneo terminado',
            startTime: DateTime.now().subtract(const Duration(days: 3)),
            endTime: DateTime.now().subtract(const Duration(days: 2)),
          ),
        );

        // The date cut (end_time >= now) mirrors the Supabase query.
        final explore = await repository.fetchTournaments(
          const TournamentQuery(),
        );
        expect(explore.any((t) => t.id == 'past-1'), isFalse);

        // The organizer's list keeps the full history (no date cut there).
        final owned = await repository.fetchByOwner('u-org-1');
        expect(owned.any((t) => t.id == 'past-1'), isTrue);
      },
    );
  });
}
