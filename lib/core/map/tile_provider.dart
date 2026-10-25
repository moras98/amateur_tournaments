import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Map tile source: one **app-scoped** instance shared by every map
/// (Explore, the event form and the detail mini-map).
///
/// flutter_map's [TileLayer] calls [TileProvider.dispose] on the provider it
/// was given whenever the layer unmounts (toggling the list view, popping the
/// detail screen, closing the form...). Disposing this shared instance would
/// close its HTTP client, and from then on every new tile request on *all*
/// maps fails silently — the maps freeze on pan/zoom. The provider therefore
/// overrides [dispose] to a no-op: its client lives until the app exits.
///
/// Failed tiles render as empty squares (`silenceExceptions: true`).
/// Tests override this with an in-memory provider so no network is touched.
final tileProviderProvider = Provider<TileProvider>(
  (ref) => AppScopedNetworkTileProvider(),
);

/// [NetworkTileProvider] that survives [TileLayer] disposal.
///
/// See [tileProviderProvider] for why disposal must be ignored: flutter_map
/// disposes providers it does not own, and this one belongs to the whole app.
class AppScopedNetworkTileProvider extends NetworkTileProvider {
  AppScopedNetworkTileProvider() : super(silenceExceptions: true);

  @override
  Future<void> dispose() async {
    // Intentionally empty: never close the shared HTTP client.
  }
}

/// OSM tile endpoint. Policy requires a real `userAgentPackageName`
/// identifying the app.
const osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
