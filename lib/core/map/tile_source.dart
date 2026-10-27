import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the map tiles come from, as data rather than a constant sprinkled
/// through three screens.
///
/// Why it is a provider: the OSM tile usage policy asks apps to *avoid
/// hard-coding the tile URL* so the source can be switched without shipping a
/// new version — and every candidate provider needs its own URL, attribution
/// and zoom ceiling.
///
/// The source is chosen at build time:
///
///     --dart-define=TILE_PROVIDER=thunderforest \
///     --dart-define=THUNDERFOREST_KEY=xxxxxxxx
///
/// With no defines it stays on OpenStreetMap's donated servers, which the
/// policy allows for light use only: no SLA, and they may block without
/// notice. See `LAUNCH.md` §Mapas before publishing at any volume.
class TileSource {
  const TileSource({
    required this.urlTemplate,
    required this.attribution,
    this.maxZoom = 19,
    this.userAgentPackageName = 'com.tande.app',
  });

  final String urlTemplate;

  /// Rendered next to the map, never hidden. Every provider requires it, and
  /// some require their own wording.
  final String attribution;

  final int maxZoom;

  /// Identifies the app to the tile server (OSM's policy requires a real one).
  final String userAgentPackageName;
}

/// OpenStreetMap's own tiles — free to use lightly, donated, best effort.
const osmTileSource = TileSource(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  attribution: '© OpenStreetMap contributors',
);

const _providerDefine = String.fromEnvironment(
  'TILE_PROVIDER',
  defaultValue: 'osm',
);
const _thunderforestKey = String.fromEnvironment('THUNDERFOREST_KEY');

/// Escape hatch for any other raster provider: give the template and the
/// credit line at build time and nothing else needs to change. Keeps the app
/// from being locked into a provider whose next price tier is abusive.
const _urlTemplateDefine = String.fromEnvironment('TILE_URL_TEMPLATE');
const _attributionDefine = String.fromEnvironment(
  'TILE_ATTRIBUTION',
  defaultValue: '© OpenStreetMap contributors',
);

/// Resolves the configured provider. Pure on purpose: tests cover every
/// branch without touching the app.
///
/// A missing key falls back to OSM — a published app must never render a blank
/// map — but trips an assert in debug so the misconfiguration is impossible to
/// miss. `scripts/build-release.sh` refuses to build in that state, which is
/// the check that actually matters for a release.
TileSource resolveTileSource({
  String provider = _providerDefine,
  String key = _thunderforestKey,
  String urlTemplate = _urlTemplateDefine,
  String attribution = _attributionDefine,
}) {
  switch (provider.toLowerCase()) {
    case 'thunderforest':
      if (key.isEmpty) {
        assert(
          false,
          'TILE_PROVIDER=thunderforest without THUNDERFOREST_KEY: falling '
          'back to OSM. Set the key or TILE_PROVIDER=osm.',
        );
        return osmTileSource;
      }
      return TileSource(
        // Verified against Thunderforest's API docs; note it is api., not
        // tile.thunderforest.com.
        urlTemplate:
            'https://api.thunderforest.com/outdoors/{z}/{x}/{y}.png'
            '?apikey=$key',
        // Their terms: the Thunderforest credit may not be removed, and the
        // OSM data credit travels with it.
        attribution: 'Maps © Thunderforest, Data © OpenStreetMap contributors',
      );
    case 'custom':
      if (urlTemplate.isEmpty) {
        assert(
          false,
          'TILE_PROVIDER=custom without TILE_URL_TEMPLATE: falling back to '
          'OSM.',
        );
        return osmTileSource;
      }
      return TileSource(urlTemplate: urlTemplate, attribution: attribution);
    case 'osm':
    case '':
      return osmTileSource;
    default:
      assert(false, 'Unknown TILE_PROVIDER "$provider": using OSM.');
      return osmTileSource;
  }
}

/// The tile source the whole app draws from.
final tileSourceProvider = Provider<TileSource>((ref) => resolveTileSource());
