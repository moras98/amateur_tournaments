import 'package:bracket/core/location/reverse_geocoder.dart';
import 'package:bracket/core/map/tile_provider.dart';
import 'package:bracket/data/auth/mock_auth_repository.dart';
import 'package:bracket/data/repositories/providers.dart';
import 'package:bracket/features/explore/explore_providers.dart';
import 'package:bracket/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// Montevideo, used as the fake device location.
const testUserLocation = LatLng(-34.9012, -56.1646);

/// 1x1 transparent GIF served as a fake map tile (no network in tests).
final Uint8List kTransparentGif = Uint8List.fromList(const [
  0x47,
  0x49,
  0x46,
  0x38,
  0x39,
  0x61,
  0x01,
  0x00,
  0x01,
  0x00,
  0x80,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0xff,
  0xff,
  0xff,
  0x21,
  0xf9,
  0x04,
  0x01,
  0x00,
  0x00,
  0x00,
  0x00,
  0x2c,
  0x00,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x01,
  0x00,
  0x00,
  0x02,
  0x02,
  0x44,
  0x01,
  0x00,
  0x3b,
]);

/// Serves a transparent image instead of hitting OSM.
class FakeTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(kTransparentGif);
}

/// Returns a fixed address instead of hitting Nominatim.
class FakeReverseGeocoder implements ReverseGeocoder {
  const FakeReverseGeocoder({this.countryCode = 'ar'});

  /// ISO code the fake location resolves to (feeds the phone dial default).
  final String countryCode;

  @override
  Future<ResolvedAddress?> resolve(LatLng point) async => ResolvedAddress(
    street: 'Av. Siempreviva 742',
    city: 'Springfield',
    countryCode: countryCode,
  );
}

/// The whole app under test, with deterministic overrides:
/// - fake map tiles (no network)
/// - mock auth (signed in unless [signedIn] is false)
/// - optional fixed device location (enables distance sorting/filters)
/// - [locationOverride] drives the device-location future directly (a
///   pending one pins the map in its loading state)
/// - [reverseCountryCode] controls which country the fake reverse geocoder
///   reports (the phone field's dial-code default)
Widget appHarness({
  ExploreView initialView = ExploreView.map,
  bool signedIn = true,
  bool withLocation = false,
  Future<LatLng?>? locationOverride,
  String? signedInAs,
  String reverseCountryCode = 'ar',
}) {
  // The app follows the phone's locale: tests pin the simulated device to
  // Uruguayan Spanish so every assertion sees the Spanish copy (override
  // with `pinTestLocale` before pumping to exercise another locale). Both
  // spellings are pinned: `Localizations` resolves from `platformDispatcher
  // .locales`, while Material/Cupertino read the singular `locale`.
  TestWidgetsFlutterBinding.ensureInitialized();
  TestWidgetsFlutterBinding.instance.platformDispatcher
    ..localeTestValue = const Locale('es', 'UY')
    ..localesTestValue = const [Locale('es', 'UY')];

  return ProviderScope(
    overrides: [
      exploreViewProvider.overrideWith((ref) => initialView),
      tileProviderProvider.overrideWithValue(FakeTileProvider()),
      reverseGeocodeProvider.overrideWithValue(
        FakeReverseGeocoder(countryCode: reverseCountryCode),
      ),
      if (locationOverride != null)
        userLocationProvider.overrideWith((ref) => locationOverride)
      else
        // Always overridden: the real geolocator's channel never answers in
        // tests, and the map waits for a *resolved* location before mounting.
        userLocationProvider.overrideWith(
          (ref) async => withLocation ? testUserLocation : null,
        ),
      if (!signedIn || signedInAs != null)
        authRepositoryProvider.overrideWithValue(
          MockAuthRepository(signedIn: signedIn, userId: signedInAs),
        ),
    ],
    child: const BracketApp(),
  );
}

/// Makes `url_launcher` report success so WhatsApp flows complete in tests
/// (unmocked platform messages would stay pending forever).
void mockUrlLauncher(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/url_launcher'),
    (call) async => true,
  );
}

/// The app follows the phone's locale, so tests pin the simulated device
/// to Uruguayan Spanish — they assert the Spanish copy. A test can
/// override this before `pumpWidget` to exercise another locale.
void pinTestLocale(
  WidgetTester tester, [
  Locale locale = const Locale('es', 'UY'),
]) {
  tester.binding.platformDispatcher
    ..localeTestValue = locale
    ..localesTestValue = [locale];
}
