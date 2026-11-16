import 'package:dym_core/dym_core.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/demo/demo_store.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/dashboard/dashboard_service.dart';

/// Données illustratives uniquement dans la galerie de validation.
class DemoDashboardService implements DashboardService {
  new(this.country);

  final DemoCountry country;

  /// Accueil poussé (spec 098) : données illustratives de la galerie.
  @override
  Future<Result<VendorInsights>> insights(DashboardPeriod period) async {
    final now = DateTime.now();
    const sales = [12000, 18500, 9000, 21000, 15500, 26000, 17000];
    return Ok(
      VendorInsights(
        currencyCode: 'XOF',
        days: [
          for (var i = 0; i < 7; i++)
            InsightDay(
              day: now.subtract(Duration(days: 6 - i)),
              revenueMinor: sales[i],
              orders: 3 + i,
            ),
        ],
        orderCount: 42,
        averageBasketMinor: 2850,
        customers: 27,
        newCustomers: 6,
        returningCustomers: 21,
        topProducts: const [
          TopProduct(
            productId: 'p1',
            name: 'Tomates',
            quantity: 38,
            revenueMinor: 19000,
          ),
          TopProduct(
            productId: 'p2',
            name: 'Gombo',
            quantity: 22,
            revenueMinor: 8800,
          ),
          TopProduct(
            productId: 'p3',
            name: 'Piment frais',
            quantity: 15,
            revenueMinor: 4500,
          ),
        ],
        loyalCustomers: const [
          LoyalCustomer(firstName: 'Awa', orders: 7),
          LoyalCustomer(firstName: 'Mia', orders: 4),
        ],
        lowStock: const [
          LowStockItem(
            productId: 'p2',
            name: 'Gombo',
            variant: 'le tas',
            stock: 2,
          ),
        ],
      ),
    );
  }

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
