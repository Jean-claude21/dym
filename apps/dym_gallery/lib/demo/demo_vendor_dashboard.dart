import 'package:dym_core/dym_core.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/demo/demo_store.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/dashboard/dashboard_service.dart';

/// Données illustratives uniquement dans la galerie de validation.
class DemoDashboardService implements DashboardService {
  new(this.country);

  final DemoCountry country;

  @override
  Stream<LiveSignal> get live => const Stream.empty();

  @override
  Future<Result<CountryConfig>> countryConfig() async =>
      Ok(DemoStore.config(country));

  @override
  Future<Result<int>> unreadMessages() async => const Ok(2);

  @override
  Future<Result<VendorDashboard>> summary(DashboardPeriod period) async => Ok(
    VendorDashboard(
      period: period,
      currencyCode: country.currency.code,
      revenueMinor: country.price(12500).amountMinor,
      orderCount: 6,
      pendingPayments: 2,
      pendingOrders: 2,
      activeOrders: 3,
      outOfStock: 1,
      criticalNotifications: 1,
    ),
  );
}
