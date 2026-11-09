import 'package:dym_models/src/json.dart';
import 'package:meta/meta.dart';

/// Nature d'un mouvement du wallet (`ledger_transactions.kind`).
enum WalletMovementKind {
  walletTopup,
  walletTransfer,
  paymentReceived,
  refundPaid,
  cashback,
  unknown;

  static WalletMovementKind parse(Object? value) => switch (value) {
    'wallet_topup' => walletTopup,
    'wallet_transfer' => walletTransfer,
    'payment_received' => paymentReceived,
    'refund_paid' => refundPaid,
    'cashback' => cashback,
    _ => unknown,
  };
}

/// Une poche du wallet (nom libre, objectif et arrondi facultatifs).
@immutable
class WalletPocket {
  const new({
    required this.id,
    required this.name,
    required this.balanceMinor,
    this.goalMinor,
    this.roundUpMinor,
  });

  factory fromJson(Map<String, dynamic> json) => WalletPocket(
    id: json['id']! as String,
    name: json['name']! as String,
    balanceMinor: minorFromJson(json['balance_minor']),
    goalMinor: nullableMinorFromJson(json['goal_minor']),
    roundUpMinor: nullableMinorFromJson(json['round_up_minor']),
  );

  final String id;
  final String name;
  final int balanceMinor;
  final int? goalMinor;
  final int? roundUpMinor;

  /// Avancement vers l'objectif, de 0 à 1 (null : pas d'objectif).
  double? get progress {
    final goal = goalMinor;
    if (goal == null) return null;
    return (balanceMinor / goal).clamp(0, 1).toDouble();
  }
}

/// Un mouvement : montant signé vu par la personne (positif : entrée).
@immutable
class WalletMovement {
  const new({
    required this.id,
    required this.kind,
    required this.amountMinor,
    required this.occurredAt,
    this.pocketId,
    this.orderId,
  });

  factory fromJson(Map<String, dynamic> json) => WalletMovement(
    id: json['id']! as String,
    kind: WalletMovementKind.parse(json['kind']),
    amountMinor: minorFromJson(json['amount_minor']),
    occurredAt: DateTime.parse(json['occurred_at']! as String),
    pocketId: json['pocket_id'] as String?,
    orderId: json['order_id'] as String?,
  );

  final String id;
  final WalletMovementKind kind;
  final int amountMinor;
  final DateTime occurredAt;
  final String? pocketId;
  final String? orderId;
}

/// Mon wallet (`public.my_wallet()`).
@immutable
class Wallet {
  const new({
    required this.currencyCode,
    required this.balanceMinor,
    required this.simulatedTopup,
    required this.pockets,
    required this.movements,
  });

  factory fromJson(Map<String, dynamic> json) => Wallet(
    currencyCode: json['currency_code']! as String,
    balanceMinor: minorFromJson(json['balance_minor']),
    simulatedTopup: json['simulated_topup'] == true,
    pockets: [
      for (final p
          in (json['pockets'] as List? ?? const [])
              .cast<Map<String, dynamic>>())
        WalletPocket.fromJson(p),
    ],
    movements: [
      for (final m
          in (json['movements'] as List? ?? const [])
              .cast<Map<String, dynamic>>())
        WalletMovement.fromJson(m),
    ],
  );

  final String currencyCode;

  /// Solde disponible (hors poches).
  final int balanceMinor;

  /// Recharge simulée autorisée (environnement de test).
  final bool simulatedTopup;
  final List<WalletPocket> pockets;
  final List<WalletMovement> movements;

  /// Total : wallet + poches.
  int get totalMinor =>
      balanceMinor + pockets.fold(0, (sum, p) => sum + p.balanceMinor);
}
