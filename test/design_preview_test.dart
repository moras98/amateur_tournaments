import 'dart:io';

import 'package:tande/features/explore/explore_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

/// Design review renders: pumps the real screens at phone size and writes PNGs
/// to `test/goldens/`. Run with:
///
/// ```bash
/// flutter test test/design_preview_test.dart --update-goldens
/// ```
///
/// Not a regression gate (the UI moves too much while the product is young);
/// it exists so design changes can be looked at instead of guessed. The tests
/// Skip unless explicitly asked for, so a design change never turns `flutter
/// test` red:
///
/// ```bash
/// flutter test test/design_preview_test.dart \
///   --dart-define=DESIGN_PREVIEW=true --update-goldens
/// ```
const previewEnabled = bool.fromEnvironment('DESIGN_PREVIEW');
const previewSkip = !previewEnabled;

void main() {
  setUpAll(() async {
    // Without the real families every glyph renders as a box in the test env:
    // text needs the bundled family, icons need MaterialIcons from the SDK.
    Future<void> load(String family, String path) async {
      final file = File(path);
      if (!file.existsSync()) return;
      await (FontLoader(family)
            ..addFont(
              Future.value(ByteData.sublistView(file.readAsBytesSync())),
            ))
          .load();
    }

    await load(
      'PlusJakartaSans',
      'assets/fonts/PlusJakartaSans-Variable.ttf',
    );
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
        '/home/agustin/snap/flutter/common/flutter';
    await load(
      'MaterialIcons',
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
  });

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('explore lista', (tester) async {
    await phone(tester);
    await tester.pumpWidget(appHarness(initialView: ExploreView.list));
    await tester.pumpAndSettle();
    await shot(tester, '01-explore-lista');
  }, skip: previewSkip);

  testWidgets('explore mapa', (tester) async {
    await phone(tester);
    await tester.pumpWidget(
      appHarness(initialView: ExploreView.map, withLocation: true),
    );
    await tester.pumpAndSettle();
    await shot(tester, '02-explore-mapa');
  }, skip: previewSkip);

  testWidgets('detalle de torneo', (tester) async {
    await phone(tester);
    await tester.pumpWidget(appHarness(initialView: ExploreView.list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copa Centro 7v7').first);
    await tester.pumpAndSettle();
    await shot(tester, '03-detalle');
  }, skip: previewSkip);

  testWidgets('detalle sin banner (hero con gradiente)', (tester) async {
    await phone(tester);
    await tester.pumpWidget(appHarness(initialView: ExploreView.list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Futbol 5 Nocturno Cordón').first);
    await tester.pumpAndSettle();
    await shot(tester, '03b-detalle-sin-banner');
  }, skip: previewSkip);

  testWidgets('organizar', (tester) async {
    await phone(tester);
    await tester.pumpWidget(
      appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.emoji_events_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await shot(tester, '04-organizar');
  }, skip: previewSkip);

  testWidgets('solicitudes del organizador', (tester) async {
    await phone(tester);
    await tester.pumpWidget(
      appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.emoji_events_outlined),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copa Centro 7v7').first);
    await tester.pumpAndSettle();
    await shot(tester, '05-solicitudes');
  }, skip: previewSkip);

  testWidgets('perfil', (tester) async {
    await phone(tester);
    await tester.pumpWidget(appHarness(initialView: ExploreView.list));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.person_outline),
      ),
    );
    await tester.pumpAndSettle();
    await shot(tester, '06-perfil');
  }, skip: previewSkip);
}