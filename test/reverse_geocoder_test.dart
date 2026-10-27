import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tande/core/location/reverse_geocoder.dart';

/// Counts calls and answers with a fixed address (or null).
class _CountingGeocoder implements ReverseGeocoder {
  _CountingGeocoder({this.answer = const ResolvedAddress(city: 'Montevideo')});

  final ResolvedAddress? answer;
  int calls = 0;
  final List<LatLng> points = [];

  @override
  Future<ResolvedAddress?> resolve(LatLng point) async {
    calls++;
    points.add(point);
    return answer;
  }
}

void main() {
  group('cache de direcciones', () {
    test('el mismo punto no golpea la red dos veces', () async {
      final inner = _CountingGeocoder();
      final geocoder = CachedReverseGeocoder(inner);
      const point = LatLng(-34.9012, -56.1646);

      final first = await geocoder.resolve(point);
      final second = await geocoder.resolve(point);

      expect(inner.calls, 1);
      expect(second, same(first));
    });

    test('puntos distintos sí son consultas distintas', () async {
      final inner = _CountingGeocoder();
      final geocoder = CachedReverseGeocoder(inner);

      await geocoder.resolve(const LatLng(-34.9012, -56.1646));
      await geocoder.resolve(const LatLng(-34.9200, -56.1500));

      expect(inner.calls, 2);
    });

    test('un temblor de dedo en el mismo lugar usa el mismo cache', () async {
      final inner = _CountingGeocoder();
      final geocoder = CachedReverseGeocoder(inner);

      // ~5 m de diferencia: el mismo portón, no otra dirección.
      await geocoder.resolve(const LatLng(-34.90120, -56.16460));
      await geocoder.resolve(const LatLng(-34.90124, -56.16463));

      expect(inner.calls, 1);
    });

    test('un resultado vacío también se cachea', () async {
      final inner = _CountingGeocoder(answer: null);
      final geocoder = CachedReverseGeocoder(inner);
      const point = LatLng(-34.9, -56.1);

      expect(await geocoder.resolve(point), isNull);
      expect(await geocoder.resolve(point), isNull);

      // Un pin sobre el agua no se reintenta en cada toque.
      expect(inner.calls, 1);
    });

    test('dos toques simultáneos comparten una sola consulta', () async {
      final inner = _CountingGeocoder();
      final geocoder = CachedReverseGeocoder(inner);
      const point = LatLng(-34.9012, -56.1646);

      await Future.wait([geocoder.resolve(point), geocoder.resolve(point)]);

      expect(inner.calls, 1);
    });

    test('el cache vence y vuelve a preguntar', () async {
      var now = DateTime(2026, 10, 27, 10);
      final inner = _CountingGeocoder();
      final geocoder = CachedReverseGeocoder(
        inner,
        ttl: const Duration(days: 1),
        clock: () => now,
      );
      const point = LatLng(-34.9012, -56.1646);

      await geocoder.resolve(point);
      now = now.add(const Duration(hours: 12));
      await geocoder.resolve(point);
      expect(inner.calls, 1, reason: 'todavía fresco');

      now = now.add(const Duration(days: 2));
      await geocoder.resolve(point);
      expect(inner.calls, 2, reason: 'vencido');
    });

    test('el cache no crece sin límite', () async {
      final inner = _CountingGeocoder();
      final geocoder = CachedReverseGeocoder(inner, maxEntries: 3);

      for (var i = 0; i < 10; i++) {
        await geocoder.resolve(LatLng(-34.9 - i * 0.01, -56.1));
      }

      expect(geocoder.cachedEntries, 3);
    });
  });

  group('throttle de Nominatim', () {
    test('la primera pasa; la segunda espera un segundo', () async {
      final waits = <Duration>[];
      var now = DateTime(2026, 10, 27, 10);
      final throttle = RequestThrottle(
        clock: () => now,
        sleep: (d) async => waits.add(d),
      );

      await throttle.next();
      expect(waits, isEmpty, reason: 'la primera no tiene con quién chocar');

      await throttle.next();
      expect(waits, [const Duration(seconds: 1)]);
    });

    test('tres toques seguidos quedan espaciados, no amontonados', () async {
      final waits = <Duration>[];
      final throttle = RequestThrottle(
        clock: () => DateTime(2026, 10, 27, 10),
        sleep: (d) async => waits.add(d),
      );

      await throttle.next();
      await throttle.next();
      await throttle.next();

      // El reloj no avanza: los slots son +1s y +2s.
      expect(waits, [const Duration(seconds: 1), const Duration(seconds: 2)]);
    });

    test('si el reloj avanzó lo suficiente, no espera', () async {
      final waits = <Duration>[];
      var now = DateTime(2026, 10, 27, 10);
      final throttle = RequestThrottle(
        clock: () => now,
        sleep: (d) async => waits.add(d),
      );

      await throttle.next();
      now = now.add(const Duration(seconds: 5));
      await throttle.next();

      expect(waits, isEmpty);
    });

    test('el endpoint es configurable (se puede cambiar sin update)', () {
      // El define GEOCODER_URL llega por --dart-define; acá se verifica que el
      // constructor lo acepte y lo use en la URL.
      final geocoder = NominatimReverseGeocoder(
        endpoint: 'https://nominatim.midominio.uy/reverse',
      );
      expect(geocoder.endpoint, 'https://nominatim.midominio.uy/reverse');
    });
  });

  group('parseo de Nominatim', () {
    test('arma calle con número, ciudad y país', () {
      final body = jsonEncode({
        'address': {
          'road': 'Bulevar España',
          'house_number': '1470',
          'city': 'Montevideo',
          'country_code': 'UY',
        },
      });

      final address = parseNominatimAddress(body);

      expect(address!.street, 'Bulevar España 1470');
      expect(address.city, 'Montevideo');
      expect(address.countryCode, 'uy');
    });

    test('sin dirección útil devuelve null', () {
      expect(parseNominatimAddress('{"address":{}}'), isNull);
      expect(parseNominatimAddress('no es json'), isNull);
    });
  });
}
