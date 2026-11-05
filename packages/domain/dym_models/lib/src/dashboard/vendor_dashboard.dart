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
  );

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
