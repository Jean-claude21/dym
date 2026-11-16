import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Résumé de la boutique connectée. Aucune agrégation ni montant dans l'app.
class VendorDashboardRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<VendorDashboard>> summary(DashboardPeriod period) async {
    final result = await _data.rpc<Object?>(
      'my_vendor_dashboard',
      params: {'p_period': period.name},
    );
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        try {
          return Ok(VendorDashboard.fromJson(value! as Map<String, dynamic>));
        } on Object {
          return const Err(ServerFailure('invalid_dashboard_response'));
        }
    }
  }

  /// Accueil poussé (spec 098) : tendance, clientes, meilleurs produits, stock.
  Future<Result<VendorInsights>> insights(DashboardPeriod period) async =>
      (await _data.rpc<Object?>(
        'my_vendor_insights',
        params: {'p_period': period.name},
      )).map((j) => VendorInsights.fromJson((j! as Map).cast()));
}
