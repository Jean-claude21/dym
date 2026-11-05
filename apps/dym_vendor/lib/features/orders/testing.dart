import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/orders/orders_service.dart';

/// Commandes en mémoire (tests, galerie). Jamais en production.
class MemoryOrdersService implements OrdersService {
  new({required this.config, List<VendorOrder> orders = const []})
    : _orders = [...orders];

  final CountryConfig config;
  final List<VendorOrder> _orders;

  /// Prochain appel en échec (une fois).
  Failure? failNext;
  int reads = 0;

  Result<T>? _fail<T>() {
    final failure = failNext;
    if (failure == null) return null;
    failNext = null;
    return Err(failure);
  }

  /// Une commande devient visible (paiement confirmé, cash).
  void arrive(VendorOrder order) => _orders.insert(0, order);

  @override
  Future<Result<CountryConfig>> countryConfig() async =>
      _fail<CountryConfig>() ?? Ok(config);

  @override
  Future<Result<List<VendorOrder>>> orders() async {
    reads++;
    return _fail<List<VendorOrder>>() ?? Ok(List.of(_orders));
  }

  @override
  Future<Result<VendorOrder>> order(String id) async =>
      _fail<VendorOrder>() ??
      (_orders.where((o) => o.id == id).firstOrNull == null
          ? const Err(NotFoundFailure('commande'))
          : Ok(_orders.firstWhere((o) => o.id == id)));
}
