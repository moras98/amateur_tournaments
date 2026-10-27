import 'package:flutter_test/flutter_test.dart';
import 'package:tande/core/map/tile_source.dart';

void main() {
  test('sin configurar, usa los tiles de OpenStreetMap', () {
    final source = resolveTileSource(provider: 'osm', key: '');

    expect(source.urlTemplate, osmTileSource.urlTemplate);
    expect(source.attribution, '© OpenStreetMap contributors');
  });

  test('el default del build también es OSM', () {
    // Lo que compila hoy: sin defines, el proveedor es osm.
    expect(osmTileSource.urlTemplate, contains('tile.openstreetmap.org'));
  });

  test('thunderforest arma la URL de la API con la key y su atribución', () {
    final source = resolveTileSource(provider: 'thunderforest', key: 'abc123');

    expect(
      source.urlTemplate,
      'https://api.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=abc123',
    );
    // Su licencia no permite quitar el crédito, y el de OSM viaja con los
    // datos: los dos tienen que estar.
    expect(source.attribution, contains('Thunderforest'));
    expect(source.attribution, contains('OpenStreetMap'));
  });

  test('sin key, thunderforest cae a OSM en vez de dejar el mapa vacío', () {
    // En debug el assert avisa; en release la app sigue mostrando mapas.
    expect(
      () => resolveTileSource(provider: 'thunderforest', key: ''),
      throwsA(isA<AssertionError>()),
    );
    // (El fallback silencioso se verifica en release: build-release.sh es el
    // que impide publicar con esa combinación.)
  });

  test('un proveedor desconocido no se inventa: avisa y usa OSM', () {
    expect(
      () => resolveTileSource(provider: 'mapbox', key: 'x'),
      throwsA(isA<AssertionError>()),
    );
  });

  test('cualquier proveedor raster entra por TILE_URL_TEMPLATE', () {
    // La vía para no quedar atado a un salto de precio: otro proveedor es
    // template + crédito, sin tocar código ni publicar lógica nueva.
    final source = resolveTileSource(
      provider: 'custom',
      urlTemplate: 'https://tiles.ejemplo.com/base/{z}/{x}/{y}.png?key=K',
      attribution: '© Ejemplo, © OpenStreetMap',
    );

    expect(
      source.urlTemplate,
      'https://tiles.ejemplo.com/base/{z}/{x}/{y}.png?key=K',
    );
    expect(source.attribution, contains('Ejemplo'));
  });

  test('custom sin template no inventa nada', () {
    expect(
      () => resolveTileSource(provider: 'custom', urlTemplate: ''),
      throwsA(isA<AssertionError>()),
    );
  });

  test('el proveedor se lee sin importar mayúsculas', () {
    final source = resolveTileSource(provider: 'ThunderForest', key: 'k');

    expect(source.urlTemplate, contains('api.thunderforest.com'));
  });
}
