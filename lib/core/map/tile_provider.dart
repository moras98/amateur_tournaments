import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The tile URL is not here on purpose: see `tile_source.dart` (the OSM policy
// asks apps not to hard-code it, so it lives in an overridable provider).

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
  AppScopedNetworkTileProvider()
    : super(silenceExceptions: true, cachingProvider: appTileCache);

  @override
  Future<void> dispose() async {
    // Intentionally empty: never close the shared HTTP client or drop the
    // shared disk cache.
  }
}

/// Tile cache on disk, shared by every map for the life of the app.
///
/// flutter_map 8 enables its built-in disk cache by default; this makes the
/// configuration explicit because two defaults are wrong for a published app:
///
/// * **1 GB** of the user's storage. Tiles for the Montevideo metro area are a
///   few MB; 300 MB is generous and stops the cache from being the biggest
///   thing the app owns.
/// * **The key**. The default keys a tile on its full URL, and commercial
///   providers put the API key in the query string — rotating the key would
///   silently invalidate every cached tile and re-bill the whole map.
///
/// **Freshness** is pinned to [_freshDays] instead of trusting the provider's
/// `Cache-Control`. Thunderforest answers with `max-age=21600` — six hours —
/// so honoring the header means every returning user re-downloads their whole
/// area every day, which on a 150k/month plan is the difference between
/// hundreds of users and dozens. Streets and venues do not change weekly; a
/// month-old base map is fine for finding a court. Set `TILE_FRESH_DAYS=0` to
/// go back to the server's headers (the OSM policy's option when the header is
/// short), or dial it down if cartography freshness ever matters more than
/// quota.
final MapCachingProvider appTileCache =
    BuiltInMapCachingProvider.getOrCreateInstance(
      maxCacheSize: 300 * 1024 * 1024,
      tileKeyGenerator: tileCacheKey,
      overrideFreshAge: _freshDays > 0 ? Duration(days: _freshDays) : null,
    );

const _freshDays = int.fromEnvironment('TILE_FRESH_DAYS', defaultValue: 30);

/// Cache key for a tile URL: everything except the query string.
///
/// `https://api.thunderforest.com/outdoors/12/1234/5678.png?apikey=A` and
/// `…?apikey=B` are the same tile; the key is what identifies the request, not
/// what is being drawn.
String tileCacheKey(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.query.isEmpty) {
    return BuiltInMapCachingProvider.uuidTileKeyGenerator(url);
  }
  return BuiltInMapCachingProvider.uuidTileKeyGenerator(
    uri.replace(query: '').toString(),
  );
}
