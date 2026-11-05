import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/store/store_service.dart';

/// Chiffres serveur et devise ; remplaçable dans les tests et la galerie.
abstract interface class DashboardService {
  Future<Result<CountryConfig>> countryConfig();
  Future<Result<VendorDashboard>> summary(DashboardPeriod period);
}

class NeonDashboardService implements DashboardService {
  new({required this.repository, required this.stores});

  final VendorDashboardRepository repository;
  final StoreService stores;

  @override
  Future<Result<CountryConfig>> countryConfig() => stores.countryConfig();

  @override
  Future<Result<VendorDashboard>> summary(DashboardPeriod period) =>
      repository.summary(period);
}
