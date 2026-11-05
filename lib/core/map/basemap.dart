import 'package:flutter/material.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tile_source.dart';

/// Which renderer draws the streets under the pins.
///
/// **Vector** (default) reads a MapLibre style from `assets/map/` and renders
/// OpenFreeMap's MVT tiles: crisp at any zoom, tinted with the brand palette
/// and — the reason this exists — **without POI icons**, which a raster tile
/// cannot drop because they are painted into the image.
///
/// **Raster** is the previous path (`tile_source.dart`): OSM by default, any
/// provider through `TILE_URL_TEMPLATE`. It stays as the fallback while the
/// style loads, as the offline-safe path if the vector layer ever throws, and
/// because the widget tests run against a fake tile provider.
///
/// Force it with `--dart-define=BASEMAP=raster`.
enum Basemap { vector, raster }

const _basemapDefine = String.fromEnvironment(
  'BASEMAP',
  defaultValue: 'vector',
);

final basemapProvider = Provider<Basemap>(
  (ref) => _basemapDefine.toLowerCase() == 'raster'
      ? Basemap.raster
      : Basemap.vector,
);

/// Style asset for a UI brightness. Two hand-tinted variants live in
/// `assets/map/`, both built by `scripts/build_map_style.py` from OpenFreeMap
/// Positron, so the only thing that differs between them is the palette.
String styleAssetFor(Brightness brightness) => brightness == Brightness.dark
    ? 'assets/map/style_dark.json'
    : 'assets/map/style_light.json';

/// Parsed style, shared by every map in the app.
///
/// Keyed by asset so light and dark can coexist; at most two entries. The
/// [vt.Style] owns HTTP clients, sprites and glyph caches, so it is disposed
/// with the provider instead of per widget — a map unmounting must not pull
/// the style out from under the others.
final mapStyleProvider = FutureProvider.family<vt.Style, String>((
  ref,
  asset,
) async {
  final style = await vt.StyleReader(
    uri: 'asset://$asset',
    language: 'es',
  ).read();
  ref.onDispose(style.dispose);
  return style;
});

/// Credit line for the current basemap: the style's own attributions (OpenFreeMap
/// and OpenMapTiles both require theirs) or, on the raster path, the tile
/// source's.
final mapAttributionProvider = Provider.family<String, String>((ref, asset) {
  if (ref.watch(basemapProvider) == Basemap.raster) {
    return ref.watch(tileSourceProvider).attribution;
  }
  final style = ref.watch(mapStyleProvider(asset)).valueOrNull;
  if (style == null || style.attributions.isEmpty) {
    return ref.watch(tileSourceProvider).attribution;
  }
  return style.attributions.map((a) => a.text).join(' · ');
});
