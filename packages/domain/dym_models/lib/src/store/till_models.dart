import 'package:dym_models/src/json.dart';
import 'package:meta/meta.dart';

/// Moyen d'une vente hors app.
enum TillMethod {
  cash,
  mobileMoney,
  other,

  /// Payée par QR depuis le wallet DYM (spec 046) : jamais saisie.
  dym;

  String get code => switch (this) {
    cash => 'cash',
    mobileMoney => 'mobile_money',
    other => 'other',
    dym => 'dym',
  };

  /// Moyens d'une vente saisie à la main.
  static const List<TillMethod> manual = [cash, mobileMoney, other];

  static TillMethod parse(Object? value) => switch (value) {
    'mobile_money' => mobileMoney,
    'other' => other,
    'dym' => dym,
    _ => cash,
  };
}

/// Vente hors app (spec 045).
@immutable
class TillSale {
  const new({
    required this.id,
    required this.label,
    required this.amountMinor,
    required this.method,
    required this.soldAt,
    this.quantity = 1,
    this.voided = false,
  });

  factory fromJson(Map<String, dynamic> json) => TillSale(
    id: json['id']! as String,
    label: json['label']! as String,
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    amountMinor: minorFromJson(json['amount_minor']),
    method: TillMethod.parse(json['method']),
    soldAt: DateTime.parse(json['sold_at']! as String),
    voided: json['voided'] as bool? ?? false,
  );

  final String id;
  final String label;
  final int quantity;
  final int amountMinor;
  final TillMethod method;
  final DateTime soldAt;
  final bool voided;
}

/// Versement du solde de la boutique.
@immutable
class TillPayout {
  const new({required this.amountMinor, required this.at});

  factory fromJson(Map<String, dynamic> json) => TillPayout(
    amountMinor: minorFromJson(json['amount_minor']),
    at: DateTime.parse(json['at']! as String),
  );

  final int amountMinor;
  final DateTime at;
}

/// « Ma caisse » (`my_till()`).
@immutable
class Till {
  const new({
    required this.currencyCode,
    this.todayAppMinor = 0,
    this.todayAppCount = 0,
    this.todayOffAppMinor = 0,
    this.todayOffAppCount = 0,
    this.byMethod = const {},
    this.balanceMinor = 0,
    this.simulatedPayout = false,
    this.sales = const [],
    this.payouts = const [],
  });

  factory fromJson(Map<String, dynamic> json) => Till(
    currencyCode: json['currency_code']! as String,
    todayAppMinor: minorFromJson(json['today_app_minor']),
    todayAppCount: (json['today_app_count'] as num?)?.toInt() ?? 0,
    todayOffAppMinor: minorFromJson(json['today_off_app_minor']),
    todayOffAppCount: (json['today_off_app_count'] as num?)?.toInt() ?? 0,
    byMethod: {
      for (final e in ((json['today_by_method'] as Map?) ?? const {}).entries)
        TillMethod.parse(e.key): minorFromJson(e.value),
    },
    balanceMinor: minorFromJson(json['balance_minor']),
    simulatedPayout: json['simulated_payout'] == true,
    sales: [
      for (final s in json['sales'] as List? ?? const [])
        TillSale.fromJson((s as Map).cast<String, dynamic>()),
    ],
    payouts: [
      for (final p in json['payouts'] as List? ?? const [])
        TillPayout.fromJson((p as Map).cast<String, dynamic>()),
    ],
  );

  final String currencyCode;
  final int todayAppMinor;
  final int todayAppCount;
  final int todayOffAppMinor;
  final int todayOffAppCount;
  final Map<TillMethod, int> byMethod;

  /// Solde chez DYM (ventes en app réglées, moins commissions et versements).
  final int balanceMinor;

  /// Versement simulé (décision 0015).
  final bool simulatedPayout;
  final List<TillSale> sales;
  final List<TillPayout> payouts;

  int get todayMinor => todayAppMinor + todayOffAppMinor;
}

/// Vente lue dans un texte dicté ou tapé (`till_parse`).
@immutable
class TillDraft {
  const new({this.label, this.amountMinor, this.quantity = 1, this.variantId});

  factory fromJson(Map<String, dynamic> json) => TillDraft(
    label: json['label'] as String?,
    amountMinor: nullableMinorFromJson(json['amount_minor']),
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    variantId: json['variant_id'] as String?,
  );

  final String? label;
  final int? amountMinor;
  final int quantity;

  /// Produit de la boutique reconnu (stock décompté).
  final String? variantId;
}

/// État d'une demande de paiement par QR.
enum PaymentRequestStatus {
  open,
  paid,
  expired,
  cancelled;

  static PaymentRequestStatus parse(Object? value) => switch (value) {
    'paid' => paid,
    'expired' => expired,
    'cancelled' => cancelled,
    _ => open,
  };
}

/// Demande de paiement par QR (spec 046). [code] et [qr] : côté vendeuse
/// seulement.
@immutable
class PaymentRequest {
  const new({
    required this.id,
    required this.amountMinor,
    required this.currencyCode,
    required this.status,
    required this.expiresAt,
    required this.storeName,
    this.code,
    this.qr,
    this.label,
  });

  factory fromJson(Map<String, dynamic> json) => PaymentRequest(
    id: json['id']! as String,
    code: json['code'] as String?,
    qr: json['qr'] as String?,
    amountMinor: minorFromJson(json['amount_minor']),
    currencyCode: json['currency_code']! as String,
    label: json['label'] as String?,
    status: PaymentRequestStatus.parse(json['status']),
    expiresAt: DateTime.parse(json['expires_at']! as String),
    storeName: json['store_name']! as String,
  );

  final String id;
  final String? code;
  final String? qr;
  final int amountMinor;
  final String currencyCode;
  final String? label;
  final PaymentRequestStatus status;
  final DateTime expiresAt;
  final String storeName;
}
