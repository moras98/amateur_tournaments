import 'dart:convert';

import 'package:bracket/core/location/reverse_geocoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseNominatimAddress', () {
    test('reads street with house number, city and country code', () {
      final resolved = parseNominatimAddress(
        jsonEncode({
          'place_id': 123,
          'lat': '-34.9040',
          'lon': '-56.1660',
          'address': {
            'road': 'Bulevar España',
            'house_number': '3450',
            'suburb': 'Centro',
            'city': 'Montevideo',
            'country': 'Uruguay',
            'country_code': 'uy',
          },
        }),
      );

      expect(resolved, isNotNull);
      expect(resolved!.street, 'Bulevar España 3450');
      expect(resolved.city, 'Montevideo');
      expect(resolved.countryCode, 'uy');
    });

    test('falls back to neighbourhood when there is no city', () {
      final resolved = parseNominatimAddress(
        jsonEncode({
          'address': {'pedestrian': 'Calle Falsa', 'suburb': 'Pocitos'},
        }),
      );

      expect(resolved!.street, 'Calle Falsa');
      expect(resolved.city, 'Pocitos');
    });

    test('keeps partial results (city only)', () {
      final resolved = parseNominatimAddress(
        jsonEncode({
          'address': {'village': 'Trinidad'},
        }),
      );

      expect(resolved!.street, isEmpty);
      expect(resolved.city, 'Trinidad');
      expect(resolved.isEmpty, isFalse);
    });

    test(
      'resolves a remote spot with only a country (feeds the phone dial)',
      () {
        final resolved = parseNominatimAddress(
          jsonEncode({
            'address': {'country': 'Uruguay', 'country_code': 'UY'},
          }),
        );

        expect(resolved, isNotNull);
        expect(resolved!.street, isEmpty);
        expect(resolved.city, isEmpty);
        expect(resolved.countryCode, 'uy'); // Lowercased, like Nominatim sends.
        expect(resolved.isEmpty, isFalse);
      },
    );

    test('returns null for errors, empty results and bad JSON', () {
      expect(
        parseNominatimAddress('{"error":{"code":42,"message":"Too many"}}'),
        isNull,
      );
      expect(parseNominatimAddress('{"address":{}}'), isNull);
      expect(parseNominatimAddress('not json at all'), isNull);
      expect(parseNominatimAddress('[1, 2, 3]'), isNull);
    });
  });
}
