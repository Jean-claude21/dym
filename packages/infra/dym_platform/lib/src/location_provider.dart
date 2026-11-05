import 'package:dym_core/dym_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta/meta.dart';

/// Position ponctuelle (jamais conservée).
@immutable
class GeoPoint {
  const new(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Position actuelle, sur demande de l'utilisatrice. `null` : refusée,
/// service désactivé ou indisponible (l'app propose alors la liste).
abstract interface class LocationProvider {
  Future<Result<GeoPoint?>> current();
}

/// Implémentation `geolocator` : précision réduite (le quartier suffit),
/// délai court pour la 3G.
class PluginLocationProvider implements LocationProvider {
  const new();

  @override
  Future<Result<GeoPoint?>> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return const Ok(null);
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return const Ok(null);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return Ok(GeoPoint(position.latitude, position.longitude));
    } on Object catch (error) {
      return Err(
        UnknownFailure('position indisponible : ${error.runtimeType}'),
      );
    }
  }
}
