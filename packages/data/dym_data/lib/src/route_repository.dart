import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Itinéraire entre des points (spec 109), calculé par la Function
/// (fournisseur derrière une interface).
class RouteRepository {
  new(this._functions);

  final NeonFunctionsClient _functions;

  Future<Result<DeliveryRoute>> route(List<TrackPoint> points) =>
      _functions.post(
        '/v1/route',
        body: {
          'points': [
            for (final p in points) [p.latitude, p.longitude],
          ],
        },
        decode: (json) =>
            DeliveryRoute.fromJson((json! as Map).cast<String, dynamic>()),
      );
}
