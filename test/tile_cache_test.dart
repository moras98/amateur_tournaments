import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tande/core/map/tile_provider.dart';

void main() {
  group('clave de cache', () {
    test('la API key no forma parte de la clave', () {
      // Rotar la key no puede tirar todo el cache ni volver a facturar el mapa.
      final a = tileCacheKey(
        'https://api.thunderforest.com/outdoors/12/1234/5678.png?apikey=AAA',
      );
      final b = tileCacheKey(
        'https://api.thunderforest.com/outdoors/12/1234/5678.png?apikey=BBB',
      );

      expect(a, b);
    });

    test('tiles distintos dan claves distintas', () {
      final base = tileCacheKey(
        'https://tile.openstreetmap.org/12/1234/5678.png',
      );
      final otherZoom = tileCacheKey(
        'https://tile.openstreetmap.org/13/1234/5678.png',
      );
      final otherTile = tileCacheKey(
        'https://tile.openstreetmap.org/12/1235/5678.png',
      );

      expect({base, otherZoom, otherTile}, hasLength(3));
    });

    test('un proveedor distinto no comparte clave del mismo tile', () {
      final osm = tileCacheKey(
        'https://tile.openstreetmap.org/12/1234/5678.png',
      );
      final thunderforest = tileCacheKey(
        'https://api.thunderforest.com/outdoors/12/1234/5678.png?apikey=A',
      );

      expect(osm, isNot(thunderforest));
    });
  });

  // The built-in store asks path_provider for a cache directory when it is
  // created: in the test VM there is no plugin, so it is faked here.
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });

  // flutter_map 8 caches tiles on disk through NetworkTileProvider, but its
  // built-in store spawns workers that hang under flutter_test — so the
  // round trip is not unit-testable. What *is* pinnable is the wiring: the app
  // must not fall back to the stock cache (1 GB, keyed on the full URL).
  //
  // The real check is on a device: pan the map, kill the app, turn data off,
  // reopen — tiles still draw.
  test('el provider de tiles usa el cache configurado de la app', () {
    final provider = AppScopedNetworkTileProvider();

    expect(provider.cachingProvider, same(appTileCache));
    expect(appTileCache, isA<BuiltInMapCachingProvider>());
  });

  test('dispose del provider compartido no rompe los mapas', () async {
    final provider = AppScopedNetworkTileProvider();

    // flutter_map disposes the provider on every layer unmount; a real dispose
    // would close the shared client and freeze every map for the rest of the
    // session.
    await provider.dispose();
  });
}
