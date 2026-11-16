import 'package:dym_models/src/json.dart';
import 'package:meta/meta.dart';

/// Période calculée dans le fuseau du pays par Postgres.
enum DashboardPeriod { day, week, month }

/// Chiffres exclusivement calculés par la base (spec 014).
@immutable
class VendorDashboard {
  const new({
    required this.period,
    required this.currencyCode,
    required this.revenueMinor,
    required this.orderCount,
    required this.pendingPayments,
    required this.pendingOrders,
    required this.activeOrders,
    required this.outOfStock,
    required this.criticalNotifications,
    this.previousRevenueMinor,
    this.previousOrderCount,
    this.respondBy,
  });

  factory fromJson(Map<String, dynamic> json) => VendorDashboard(
    period: DashboardPeriod.values.byName(json['period'] as String),
    currencyCode: json['currency_code'] as String,
    revenueMinor: minorFromJson(json['revenue_minor']),
    orderCount: minorFromJson(json['order_count']),
    pendingPayments: minorFromJson(json['pending_payments']),
    pendingOrders: minorFromJson(json['pending_orders']),
    activeOrders: minorFromJson(json['active_orders']),
    outOfStock: minorFromJson(json['out_of_stock']),
    criticalNotifications: minorFromJson(json['critical_notifications']),
    previousRevenueMinor: switch (json['previous']) {
      final Map<String, dynamic> p => minorFromJson(p['revenue_minor']),
      _ => null,
    },
    previousOrderCount: switch (json['previous']) {
      final Map<String, dynamic> p => minorFromJson(p['order_count']),
      _ => null,
    },
    respondBy: switch (json['respond_by']) {
      final String at => DateTime.parse(at),
      _ => null,
    },
  );

  /// Ventes et commandes de la période précédente au même moment (spec 076).
  final int? previousRevenueMinor;
  final int? previousOrderCount;

  /// Heure limite de la commande en attente la plus ancienne.
  final DateTime? respondBy;

  /// Évolution des ventes en % (nulle sans base de comparaison).
  int? get revenueChange => _change(revenueMinor, previousRevenueMinor);

  /// Évolution du nombre de commandes en %.
  int? get ordersChange => _change(orderCount, previousOrderCount);

  static int? _change(int current, int? previous) =>
      previous == null || previous == 0
      ? null
      : ((current - previous) * 100 / previous).round();

  final DashboardPeriod period;
  final String currencyCode;
  final int revenueMinor;
  final int orderCount;
  final int pendingPayments;
  final int pendingOrders;
  final int activeOrders;
  final int outOfStock;
  final int criticalNotifications;
}

/// Jour de la tendance (spec 098).
@immutable
class InsightDay {
  const new({
    required this.day,
    required this.revenueMinor,
    required this.orders,
  });

  final DateTime day;
  final int revenueMinor;
  final int orders;
}

/// Produit le plus vendu de la période.
@immutable
class TopProduct {
  const new({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.revenueMinor,
    this.photoKey,
  });

  final String productId;
  final String name;
  final num quantity;
  final int revenueMinor;
  final String? photoKey;
}

/// Cliente fidèle : prénom et nombre de commandes, rien d'autre.
@immutable
class LoyalCustomer {
  const new({required this.firstName, required this.orders, this.lastOrderAt});

  final String firstName;
  final int orders;
  final DateTime? lastOrderAt;
}

/// Produit sous le seuil d'alerte.
@immutable
class LowStockItem {
  const new({
    required this.productId,
    required this.name,
    required this.stock,
    this.variant,
  });

  final String productId;
  final String name;
  final String? variant;
  final num stock;
}

/// Accueil poussé de la vendeuse (spec 098) : `my_vendor_insights`.
@immutable
class VendorInsights {
  const new({
    required this.currencyCode,
    this.days = const [],
    this.orderCount = 0,
    this.averageBasketMinor = 0,
    this.customers = 0,
    this.newCustomers = 0,
    this.returningCustomers = 0,
    this.topProducts = const [],
    this.loyalCustomers = const [],
    this.lowStock = const [],
    this.lowStockThreshold = 5,
  });

  factory fromJson(Map<String, dynamic> j) {
    int i(Object? v) => (v as num?)?.toInt() ?? 0;
    List<Map<String, dynamic>> rows(String key) => [
      for (final r in j[key] as List? ?? const [])
        (r as Map).cast<String, dynamic>(),
    ];
    return VendorInsights(
      currencyCode: j['currency_code'] as String? ?? '',
      days: [
        for (final d in rows('days'))
          InsightDay(
            day: DateTime.parse(d['day'] as String),
            revenueMinor: i(d['revenue_minor']),
            orders: i(d['orders']),
          ),
      ],
      orderCount: i(j['order_count']),
      averageBasketMinor: i(j['average_basket_minor']),
      customers: i(j['customers']),
      newCustomers: i(j['new_customers']),
      returningCustomers: i(j['returning_customers']),
      topProducts: [
        for (final p in rows('top_products'))
          TopProduct(
            productId: p['product_id'] as String,
            name: p['name'] as String? ?? '',
            quantity: (p['quantity'] as num?) ?? 0,
            revenueMinor: i(p['revenue_minor']),
            photoKey: p['photo_key'] as String?,
          ),
      ],
      loyalCustomers: [
        for (final c in rows('loyal_customers'))
          LoyalCustomer(
            firstName: c['first_name'] as String? ?? '',
            orders: i(c['orders']),
            lastOrderAt: switch (c['last_order_at']) {
              final String s => DateTime.tryParse(s),
              _ => null,
            },
          ),
      ],
      lowStock: [
        for (final s in rows('low_stock'))
          LowStockItem(
            productId: s['product_id'] as String,
            name: s['name'] as String? ?? '',
            variant: s['variant'] as String?,
            stock: (s['stock'] as num?) ?? 0,
          ),
      ],
      lowStockThreshold: i(j['low_stock_threshold']),
    );
  }

  final String currencyCode;
  final List<InsightDay> days;
  final int orderCount;
  final int averageBasketMinor;
  final int customers;
  final int newCustomers;
  final int returningCustomers;
  final List<TopProduct> topProducts;
  final List<LoyalCustomer> loyalCustomers;
  final List<LowStockItem> lowStock;
  final int lowStockThreshold;
}
