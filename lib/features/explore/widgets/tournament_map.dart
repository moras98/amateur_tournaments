import 'package:tande/core/map/basemap.dart';
import 'package:tande/core/map/basemap_layer.dart';
import 'package:tande/core/sports.dart';
import 'package:tande/core/utils/nav_geometry.dart';
import 'package:tande/features/explore/widgets/tournament_card.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

/// OpenStreetMap view with a pin per tournament and the user's location.
///
/// The parent mounts it only when there is a device location or at least one
/// located pin to frame (see `ExploreScreen`): there is no hardcoded fallback
/// city, so no map/tiles ever load for a place the user has no reason to see.
class TournamentMap extends ConsumerStatefulWidget {
  const TournamentMap({
    super.key,
    required this.tournaments,
    this.userLocation,
  });

  final List<TournamentModel> tournaments;
  final LatLng? userLocation;

  @override
  ConsumerState<TournamentMap> createState() => _TournamentMapState();
}

class _TournamentMapState extends ConsumerState<TournamentMap> {
  final _controller = MapController();

  @override
  void initState() {
    super.initState();
    // Without a device location the camera frames the pins themselves on the
    // first frame; with one, initialCenter already sits on the user.
    if (widget.userLocation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitPins());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Located pins, used both as the no-location center and for the fit.
  List<LatLng> get _pins => [
    for (final t in widget.tournaments)
      if (t.location != null) t.location!,
  ];

  void _fitPins() {
    if (!mounted) return;
    final points = _pins;
    if (points.length > 1) {
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(48),
        ),
      );
    } else if (points.length == 1) {
      _controller.move(points.single, 14);
    }
  }

  void _showMarkerSheet(TournamentModel tournament) {
    // Resolve the router before the sheet covers this context.
    final router = GoRouter.of(context);
    // Idempotent: the card and the "Ver detalle" button share one callback —
    // a double activation must not pop+push twice.
    var opened = false;
    showModalBottomSheet<void>(
      context: context,
      // Root navigator: the Explore body runs behind the floating nav
      // capsule, so a branch-anchored sheet would slide underneath the bar.
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => _MarkerSheet(
        tournament: tournament,
        distanceKm: tournament.distanceKmFrom(widget.userLocation),
        onOpen: () {
          if (opened) return;
          opened = true;
          Navigator.of(sheetContext).pop();
          router.push('/tournament/${tournament.id}');
        },
      ),
    );
  }

  /// Bottom sheet listing every tournament a cluster badge stands for.
  void _showClusterSheet(List<TournamentModel> tournaments) {
    // Resolve the router before the sheet covers this context.
    final router = GoRouter.of(context);
    final l10n = AppLocalizations.of(context)!;
    // One shared guard: any card must close the sheet exactly once.
    var opened = false;
    showModalBottomSheet<void>(
      context: context,
      // Root navigator: the Explore body runs behind the floating nav
      // capsule, so a branch-anchored sheet would slide underneath the bar.
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 460),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Text(
                  l10n.eventsInArea(tournaments.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final tournament in tournaments) ...[
                TournamentCard(
                  tournament: tournament,
                  distanceKm: tournament.distanceKmFrom(widget.userLocation),
                  onTap: () {
                    if (opened) return;
                    opened = true;
                    Navigator.of(sheetContext).pop();
                    router.push('/tournament/${tournament.id}');
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Marker _userLocationMarker(LatLng location) {
    return Marker(
      point: location,
      width: 18,
      height: 18,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final location = widget.userLocation;
    final credit = ref.watch(
      mapAttributionProvider(styleAssetFor(Theme.of(context).brightness)),
    );
    // The camera sits on the device location, or on the pins when there is
    // none — never on a hardcoded city (see the class doc).
    final pins = _pins;
    final center = location ?? (pins.isEmpty ? null : pins.first);
    if (center == null) return const SizedBox.shrink();

    // The map runs behind the floating nav capsule (extendBody on this tab),
    // so everything pinned to its bottom edge clears the bar.
    final navClearance = navBarClearanceOf(context);

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: center,
            initialZoom: location != null ? 12.5 : 12,
          ),
          children: [
            const BasemapLayer(),
            _ClusterMarkersLayer(
              tournaments: widget.tournaments,
              onTapSingle: _showMarkerSheet,
              onTapCluster: _showClusterSheet,
            ),
            // The device dot floats above the pins and never clusters with
            // them.
            if (location != null)
              MarkerLayer(markers: [_userLocationMarker(location)]),
          ],
        ),
        // OSM attribution (required by its tile usage policy), lifted clear
        // of the floating nav capsule that sits on top of the map.
        Positioned(
          left: 8,
          bottom: 8 + navClearance,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              credit,
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
            ),
          ),
        ),
        if (location != null)
          Positioned(
            right: 12,
            bottom: 32 + navClearance,
            child: FloatingActionButton.small(
              heroTag: 'explore-recenter',
              tooltip: l10n.centerOnMe,
              onPressed: () => _controller.move(location, 12.5),
              child: const Icon(Icons.my_location),
            ),
          ),
      ],
    );
  }
}

/// Screen-space clustering layer for tournament pins.
///
/// Pins closer than ~46 logical pixels (their hit-box size) overlap and make
/// the ones underneath untappable — the classic two-tournaments-same-venue
/// case, and also two nearby venues when zoomed out. Pins are greedily
/// grouped in pixel space: a lone pin keeps its sport marker; a group
/// becomes a count badge that opens a sheet listing its tournaments.
class _ClusterMarkersLayer extends StatelessWidget {
  const _ClusterMarkersLayer({
    required this.tournaments,
    required this.onTapSingle,
    required this.onTapCluster,
  });

  final List<TournamentModel> tournaments;
  final ValueChanged<TournamentModel> onTapSingle;
  final ValueChanged<List<TournamentModel>> onTapCluster;

  /// Grouping radius: each pin hit box is 44×44, so anything within this
  /// distance has a (partially) covered hit box.
  static const double _radiusPx = 46;

  @override
  Widget build(BuildContext context) {
    // Registers a camera dependency: the layer rebuilds on every pan/zoom,
    // so the pixel-space groups stay correct while the user moves around.
    final camera = MapCamera.of(context);

    final remaining = <MapEntry<Offset, TournamentModel>>[];
    for (final tournament in tournaments) {
      final point = tournament.location;
      if (point == null) continue;
      remaining.add(MapEntry(camera.latLngToScreenOffset(point), tournament));
    }

    final markers = <Marker>[];
    while (remaining.isNotEmpty) {
      final seed = remaining.removeAt(0);
      final members = <TournamentModel>[seed.value];
      final pixels = <Offset>[seed.key];
      for (var i = remaining.length - 1; i >= 0; i--) {
        if ((remaining[i].key - seed.key).distance <= _radiusPx) {
          members.add(remaining[i].value);
          pixels.add(remaining[i].key);
          remaining.removeAt(i);
        }
      }

      // Anchor on the group's centroid so the badge sits among its pins.
      final center = Offset(
        pixels.fold<double>(0, (sum, p) => sum + p.dx) / pixels.length,
        pixels.fold<double>(0, (sum, p) => sum + p.dy) / pixels.length,
      );
      final anchor = camera.screenOffsetToLatLng(center);

      if (members.length == 1) {
        markers.add(_pinMarker(members.first, anchor));
      } else {
        markers.add(
          Marker(
            point: anchor,
            width: 44,
            height: 44,
            child: GestureDetector(
              key: const Key('map-cluster'),
              onTap: () => onTapCluster(members),
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(blurRadius: 6, color: Colors.black38),
                    ],
                  ),
                  child: Text(
                    '${members.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return MarkerLayer(markers: markers);
  }

  Marker _pinMarker(TournamentModel tournament, LatLng point) {
    final accent =
        tournament.isFull || tournament.status != TournamentStatus.open
        ? Colors.grey
        : sportColor(tournament.sport);

    return Marker(
      point: point,
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => onTapSingle(tournament),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(blurRadius: 6, color: Colors.black38),
              ],
            ),
            child: Icon(
              sportIcon(tournament.sport),
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkerSheet extends StatelessWidget {
  const _MarkerSheet({
    required this.tournament,
    required this.onOpen,
    this.distanceKm,
  });

  final TournamentModel tournament;
  final double? distanceKm;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TournamentCard(
            tournament: tournament,
            distanceKm: distanceKm,
            onTap: onOpen,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.arrow_forward),
            label: Text(l10n.viewDetails),
          ),
        ],
      ),
    );
  }
}
