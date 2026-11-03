import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tande/core/map/basemap.dart';

/// The map's cartography is an asset that a script generates, so these checks
/// guard the two properties the product depends on: the style parses as a
/// MapLibre style, and it carries **no POI layers** — the reason the app moved
/// off raster tiles at all.
void main() {
  Map<String, dynamic> load(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  const assets = ['assets/map/style_light.json', 'assets/map/style_dark.json'];

  group('map style assets', () {
    for (final asset in assets) {
      test('$asset is a usable MapLibre style', () {
        final style = load(asset);
        expect(style['version'], 8);
        expect(style['sources'], isA<Map<String, dynamic>>());
        expect((style['sources'] as Map).containsKey('openmaptiles'), isTrue);
        expect(style['glyphs'], startsWith('https://'));
        expect(style['layers'], isNotEmpty);
      });

      test('$asset ships no POI layers', () {
        final style = load(asset);
        final layers = (style['layers'] as List).cast<Map<String, dynamic>>();
        final poi = layers.where(
          (l) => const {'poi', 'aerodrome_label'}.contains(l['source-layer']),
        );
        expect(poi, isEmpty, reason: 'los íconos de POI vuelven si aparece una');
      });

      test('$asset keeps the streets and the place labels', () {
        final style = load(asset);
        final ids = (style['layers'] as List)
            .map((l) => (l as Map)['id'] as String)
            .toSet();
        expect(ids, containsAll(['background', 'water', 'highway_major_inner']));
        expect(ids.any((id) => id.startsWith('label_')), isTrue);
      });
    }

    test('light and dark differ in palette only', () {
      final light = load(assets[0]);
      final dark = load(assets[1]);
      final lightBg = (light['layers'] as List).first as Map;
      final darkBg = (dark['layers'] as List).first as Map;
      expect(lightBg['id'], darkBg['id']);
      expect(
        (lightBg['paint'] as Map)['background-color'],
        isNot((darkBg['paint'] as Map)['background-color']),
      );
      expect(
        (light['layers'] as List).map((l) => (l as Map)['id']).toList(),
        (dark['layers'] as List).map((l) => (l as Map)['id']).toList(),
      );
    });
  });

  test('styleAssetFor maps brightness to the two bundled styles', () {
    expect(styleAssetFor(Brightness.light), 'assets/map/style_light.json');
    expect(styleAssetFor(Brightness.dark), 'assets/map/style_dark.json');
  });
}
