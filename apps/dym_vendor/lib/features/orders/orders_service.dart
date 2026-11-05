import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/store/store_service.dart';

/// Commandes de la boutique (payées ou en cash). Remplaçable en test.
abstract interface class OrdersService {
  /// Référentiel du pays de la boutique (devise).
  Future<Result<CountryConfig>> countryConfig();

  Future<Result<List<VendorOrder>>> orders();

  Future<Result<VendorOrder>> order(String id);
}

/// Implémentation Neon.
class NeonOrdersService implements OrdersService {
  new({required this._orders, required this._stores});

  final VendorOrderRepository _orders;
  final StoreService _stores;

  @override
  Future<Result<CountryConfig>> countryConfig() => _stores.countryConfig();

  @override
  Future<Result<List<VendorOrder>>> orders() => _orders.orders();

  @override
  Future<Result<VendorOrder>> order(String id) => _orders.order(id);
}
