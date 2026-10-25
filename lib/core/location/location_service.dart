import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Thin wrapper around geolocator with permission handling.
///
/// Returns `null` whenever the position is unavailable (service off,
/// permission denied, timeout, missing platform channel in tests) so callers
/// can fall back to a default map center / distance-agnostic sorting.
class LocationService {
  Future<LatLng?> getCurrentLatLng({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition().timeout(timeout);
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      // Missing plugin (tests), timeout, platform errors → treat as unknown.
      return null;
    }
  }
}
