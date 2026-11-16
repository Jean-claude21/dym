import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/store/store_service.dart';

/// Chiffres serveur et devise ; remplaçable dans les tests et la galerie.
abstract interface class DashboardService {
  /// Changements en direct (nouvelle commande, message…, spec 067).
  Stream<LiveSignal> get live;

  Future<Result<CountryConfig>> countryConfig();
  Future<Result<VendorDashboard>> summary(DashboardPeriod period);

  /// Accueil poussé (spec 098) : tendance, clientes, meilleurs produits,
  /// alertes de stock.
  Future<Result<VendorInsights>> insights(DashboardPeriod period);

  /// Messages non lus (V-DASH-04).
  Future<Result<int>> unreadMessages();
}

class NeonDashboardService implements DashboardService {
  new({
    required this.repository,
    required this.stores,
    required this.messages,
    this.liveFeed = LiveFeed.none,
  });

  final LiveFeed liveFeed;

  @override
  Stream<LiveSignal> get live => liveFeed.signals;

  final VendorDashboardRepository repository;
  final StoreService stores;
  final MessagingRepository messages;

  @override
  Future<Result<int>> unreadMessages() => messages.unreadCount(ChatRole.vendor);

  @override
  Future<Result<CountryConfig>> countryConfig() => stores.countryConfig();

  @override
  Future<Result<VendorInsights>> insights(DashboardPeriod period) =>
      repository.insights(period);

  @override
  Future<Result<VendorDashboard>> summary(DashboardPeriod period) =>
      repository.summary(period);
}
