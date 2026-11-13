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
