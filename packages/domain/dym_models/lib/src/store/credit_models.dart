import 'package:dym_models/src/json.dart';
import 'package:meta/meta.dart';

/// Ligne de l'ardoise : dette ou remboursement.
@immutable
class CreditEntry {
  const new({
    required this.id,
    required this.isDebt,
    required this.amountMinor,
    required this.at,
    this.note,
  });

  factory fromJson(Map<String, dynamic> json) => CreditEntry(
    id: json['id']! as String,
    isDebt: json['kind'] == 'debt',
    amountMinor: minorFromJson(json['amount_minor']),
    note: json['note'] as String?,
    at: DateTime.parse(json['at']! as String),
  );

  final String id;
  final bool isDebt;
  final int amountMinor;
  final String? note;
  final DateTime at;
}

/// Cliente à l'ardoise (spec 047).
@immutable
class StoreCredit {
  const new({
    required this.id,
    required this.customerName,
    required this.balanceMinor,
    this.phone,
    this.limitMinor,
    this.canRemind = false,
    this.lastRemindedAt,
    this.entries = const [],
    this.storeName,
  });

  factory fromJson(Map<String, dynamic> json) => StoreCredit(
    id: json['id']! as String,
    customerName: json['customer_name']! as String,
    phone: json['phone'] as String?,
    limitMinor: nullableMinorFromJson(json['limit_minor']),
    balanceMinor: minorFromJson(json['balance_minor']),
    canRemind: json['can_remind'] as bool? ?? false,
    lastRemindedAt: switch (json['last_reminded_at']) {
      final String at => DateTime.parse(at),
      _ => null,
    },
    entries: [
      for (final e in json['entries'] as List? ?? const [])
        CreditEntry.fromJson((e as Map).cast<String, dynamic>()),
    ],
    storeName: json['store_name'] as String?,
  );

  final String id;
  final String customerName;
  final String? phone;

  /// Plafond ; nul : sans plafond.
  final int? limitMinor;

  /// Dû par la cliente.
  final int balanceMinor;
  final bool canRemind;
  final DateTime? lastRemindedAt;
  final List<CreditEntry> entries;

  /// Renseigné par la relance (texte du message).
  final String? storeName;
}

/// Ardoise de la boutique (`my_credits()`).
@immutable
class StoreCredits {
  const new({this.totalMinor = 0, this.credits = const []});

  factory fromJson(Map<String, dynamic> json) => StoreCredits(
    totalMinor: minorFromJson(json['total_minor']),
    credits: [
      for (final c in json['credits'] as List? ?? const [])
        StoreCredit.fromJson((c as Map).cast<String, dynamic>()),
    ],
  );

  final int totalMinor;
  final List<StoreCredit> credits;
}
