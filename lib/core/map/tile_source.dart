import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the map tiles come from, as data rather than a constant sprinkled
/// through three screens.
///
/// Why it is a provider: the OSM tile usage policy asks apps to *avoid
/// hard-coding the tile URL* so the source can be switched without shipping a
/// new version — and every candidate provider (Thunderforest, Stadia,
/// MapTiler, a self-hosted server) needs its own URL, attribution and zoom
/// ceiling. Swapping the source is one override here, not an app update.
///
/// The default is still OpenStreetMap's donated servers, which the policy
/// allows for light use only: no SLA, and they may block without notice. See
/// `PLAN-PUBLICACION.md` §mapas before publishing at any volume.
class TileSource {
  const TileSource({
    required this.urlTemplate,
    required this.attribution,
    this.maxZoom = 19,
    this.userAgentPackageName = 'com.tande.app',
  });

  final String urlTemplate;

  /// Rendered next to the map, never hidden. Every provider requires it.
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

/// The tile source the whole app draws from.
///
/// Override this (or read it from remote config later) to move to another
/// provider; nothing else in the app knows the URL.
final tileSourceProvider = Provider<TileSource>((ref) => osmTileSource);
