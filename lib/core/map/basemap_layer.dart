import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'basemap.dart';
import 'tile_provider.dart';
import 'tile_source.dart';

/// The base map of every [FlutterMap] in the app: vector streets by default,
/// raster tiles as the fallback.
///
/// It is a layer, not a [FlutterMap] subclass, so the camera, markers and
/// clustering stay exactly where they were — only what draws the streets
/// changes. Raster is used while the style parses (a few milliseconds from the
/// bundled asset) and if the vector layer ever fails, so a map can never be
/// left blank.
class BasemapLayer extends ConsumerWidget {
  const BasemapLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(basemapProvider) == Basemap.raster) {
      return const RasterBasemapLayer();
    }

    final asset = styleAssetFor(Theme.of(context).brightness);
    final style = ref.watch(mapStyleProvider(asset));

    return style.when(
      data: (loaded) => vt.VectorTileLayer(
        theme: loaded.theme,
        tileProviders: loaded.providers,
        rasterSources: loaded.rasterSources,
        sprites: loaded.sprites,
        // The style's own fonts: labels keep MapLibre's sizing and collision
        // rules instead of falling back to the platform font.
        glyphs: loaded.glyphs,
      ),
      // Parsing the bundled style takes milliseconds: draw nothing rather than
      // firing real OSM tile requests that would be thrown away (donated
      // servers, and each map open would cost them a screenful).
      loading: () => const SizedBox.expand(),
      error: (error, stack) {
        // A broken style must never leave a blank map: fall back to raster.
        debugPrint('basemap: vector style failed ($error) — usando raster');
        return const RasterBasemapLayer();
      },
    );
  }
}

/// The pre-vector path, kept as the fallback: OSM (or whatever
/// `TILE_PROVIDER` points at) through the app-scoped cache.
class RasterBasemapLayer extends ConsumerWidget {
  const RasterBasemapLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(tileSourceProvider);
    return TileLayer(
      urlTemplate: source.urlTemplate,
      userAgentPackageName: source.userAgentPackageName,
      maxNativeZoom: source.maxZoom,
      tileProvider: ref.watch(tileProviderProvider),
    );
  }
}
