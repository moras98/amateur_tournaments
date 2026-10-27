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
/// "Usar mi ubicación" action and the profile's phone country default.
///
/// The Nominatim policy (donated servers) asks for at most **1 request per
/// second across all users**, caching of results, and the ability to switch
/// the service *without an app update*. Hence three layers here:
///
/// * [NominatimReverseGeocoder] throttles itself to one request per second.
/// * [CachedReverseGeocoder] answers repeats from memory (the same pin, the
///   same profile edit) without touching the network.
/// * The endpoint comes from `--dart-define=GEOCODER_URL`, so a move to
///   Photon, a self-hosted Nominatim or a paid geocoder is a build flag.
///
/// Overridden in tests so no network is hit.
final reverseGeocodeProvider = Provider<ReverseGeocoder>(
  (ref) => CachedReverseGeocoder(NominatimReverseGeocoder()),
);

/// Reverse geocoding endpoint. Nominatim by default; override at build time to
/// move off the donated server without shipping a new version.
const _geocoderUrlDefine = String.fromEnvironment(
  'GEOCODER_URL',
  defaultValue: 'https://nominatim.openstreetmap.org/reverse',
);

abstract class ReverseGeocoder {
  /// Resolves [point] to a street address, or `null` when unknown.
  Future<ResolvedAddress?> resolve(LatLng point);
}

/// [Nominatim](https://nominatim.org) (OpenStreetMap) reverse geocoding:
/// free, no API key. Its usage policy asks for a descriptive User-Agent and
/// at most ~1 request/second — a manual button press qualifies.
class NominatimReverseGeocoder implements ReverseGeocoder {
  NominatimReverseGeocoder({
    this.endpoint = _geocoderUrlDefine,
    this.minInterval = const Duration(seconds: 1),
    DateTime Function()? clock,
    Future<void> Function(Duration)? sleep,
  }) : _clock = clock ?? DateTime.now,
       _sleep = sleep ?? Future<void>.delayed;

  final String endpoint;

  /// Minimum spacing between requests. The policy's ceiling is 1/second for
  /// the whole application, not per user.
  final Duration minInterval;

  final DateTime Function() _clock;
  final Future<void> Function(Duration) _sleep;

  late final _throttle = RequestThrottle(
    minInterval: minInterval,
    clock: _clock,
    sleep: _sleep,
  );

  @override
  Future<ResolvedAddress?> resolve(LatLng point) async {
    await _throttle.next();

    final uri = Uri.parse(
      '$endpoint?format=jsonv2&zoom=18&accept-language=es'
      '&lat=${point.latitude}&lon=${point.longitude}',
    );
    final response = await http
        .get(uri, headers: const {'User-Agent': 'tande/1.0.0 (com.tande.app)'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    return parseNominatimAddress(response.body);
  }
}

/// Spaces requests at least [minInterval] apart, across every caller.
///
/// The Nominatim policy's ceiling is one request per second for the whole
/// application, so two taps in the same second must not become two requests.
/// Slots are reserved rather than measured after the fact: concurrent callers
/// line up instead of racing into the same window.
class RequestThrottle {
  RequestThrottle({
    this.minInterval = const Duration(seconds: 1),
    DateTime Function()? clock,
    Future<void> Function(Duration)? sleep,
  }) : _clock = clock ?? DateTime.now,
       _sleep = sleep ?? Future<void>.delayed;

  final Duration minInterval;
  final DateTime Function() _clock;
  final Future<void> Function(Duration) _sleep;

  DateTime _nextSlot = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> next() async {
    final now = _clock();
    final slot = _nextSlot.isAfter(now) ? _nextSlot : now;
    _nextSlot = slot.add(minInterval);
    final wait = slot.difference(now);
    if (wait > Duration.zero) await _sleep(wait);
  }
}

/// Keeps resolved addresses in memory so repeated lookups never reach the
/// server, which is what the Nominatim policy asks for ("results must be
/// cached on your side").
///
/// Tiny on purpose: addresses are keyed by a ~11 m grid and the map/list is
/// small. A negative result is cached too — a pin on a river that resolved to
/// nothing should not be retried on every tap.
class CachedReverseGeocoder implements ReverseGeocoder {
  CachedReverseGeocoder(
    this._inner, {
    this.ttl = const Duration(days: 30),
    this.maxEntries = 200,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ReverseGeocoder _inner;
  final Duration ttl;
  final int maxEntries;
  final DateTime Function() _clock;

  /// Insertion-ordered, so the oldest key is dropped first (a plain LRU for
  /// this size costs more bookkeeping than it saves).
  final Map<String, _CacheEntry> _entries = {};

  /// Lookups in flight, so two taps on the same pin share one request.
  final Map<String, Future<ResolvedAddress?>> _pending = {};

  @override
  Future<ResolvedAddress?> resolve(LatLng point) async {
    final key = _keyOf(point);
    final cached = _entries[key];
    if (cached != null && !cached.isStale(_clock(), ttl)) {
      return cached.address;
    }

    final inFlight = _pending[key];
    if (inFlight != null) return inFlight;

    final request = _inner.resolve(point);
    _pending[key] = request;
    try {
      final address = await request;
      _store(key, address);
      return address;
    } finally {
      _pending.remove(key);
    }
  }

  void _store(String key, ResolvedAddress? address) {
    if (_entries.length >= maxEntries) _entries.remove(_entries.keys.first);
    _entries[key] = _CacheEntry(address: address, storedAt: _clock());
  }

  /// ~11 m at the equator: the same venue tapped twice lands on one key, and
  /// neighbouring streets do not.
  String _keyOf(LatLng point) =>
      '${point.latitude.toStringAsFixed(4)},'
      '${point.longitude.toStringAsFixed(4)}';

  /// Exposed for tests and for a future "clear cache" action.
  int get cachedEntries => _entries.length;
}

class _CacheEntry {
  const _CacheEntry({required this.address, required this.storedAt});

  final ResolvedAddress? address;
  final DateTime storedAt;

  bool isStale(DateTime now, Duration ttl) => now.difference(storedAt) > ttl;
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
