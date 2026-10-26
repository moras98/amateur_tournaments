import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Street address resolved for a coordinate.
class ResolvedAddress {
  const ResolvedAddress({
    this.street = '',
    this.city = '',
    this.countryCode = '',
  });

  /// Street with house number, e.g. `Bulevar España 1470`.
  final String street;

  /// City or neighbourhood, e.g. `Montevideo`.
  final String city;

  /// ISO 3166-1 alpha-2 country code in lowercase, e.g. `ar`. Feeds the
  /// profile form's phone country default.
  final String countryCode;

  bool get isEmpty => street.isEmpty && city.isEmpty && countryCode.isEmpty;
}

/// Reverse geocoding (coordinate → address) behind the event form's
/// "Usar mi ubicación" action.
///
/// Overridden in tests so no network is hit.
final reverseGeocodeProvider = Provider<ReverseGeocoder>(
  (ref) => const NominatimReverseGeocoder(),
);

abstract class ReverseGeocoder {
  /// Resolves [point] to a street address, or `null` when unknown.
  Future<ResolvedAddress?> resolve(LatLng point);
}

/// [Nominatim](https://nominatim.org) (OpenStreetMap) reverse geocoding:
/// free, no API key. Its usage policy asks for a descriptive User-Agent and
/// at most ~1 request/second — a manual button press qualifies.
class NominatimReverseGeocoder implements ReverseGeocoder {
  const NominatimReverseGeocoder();

  static const _endpoint = 'https://nominatim.openstreetmap.org/reverse';

  @override
  Future<ResolvedAddress?> resolve(LatLng point) async {
    final uri = Uri.parse(
      '$_endpoint?format=jsonv2&zoom=18&accept-language=es'
      '&lat=${point.latitude}&lon=${point.longitude}',
    );
    final response = await http
        .get(
          uri,
          headers: const {
            'User-Agent':
                'tande/1.0.0 '
                '(com.tande.app)',
          },
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    return parseNominatimAddress(response.body);
  }
}

/// Extracts street/city/country from a Nominatim `jsonv2` response body.
///
/// Returns `null` when the response carries no usable address (errors,
/// water bodies, malformed JSON). A response with only a country (remote
/// spots) still resolves: the phone field only needs the dial code.
ResolvedAddress? parseNominatimAddress(String body) {
  Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;

  final address = decoded['address'];
  if (address is! Map<String, dynamic>) return null;

  String pick(List<String> keys) {
    for (final key in keys) {
      final value = address[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  final street = pick(['road', 'pedestrian', 'street', 'footway', 'path']);
  final number = address['house_number'];
  final city = pick(['city', 'town', 'village', 'municipality', 'suburb']);
  final countryCode = pick(['country_code']).toLowerCase();

  final resolved = ResolvedAddress(
    street: [
      street,
      if (number is String && number.trim().isNotEmpty) number.trim(),
    ].join(' '),
    city: city,
    countryCode: countryCode,
  );
  return resolved.isEmpty ? null : resolved;
}
