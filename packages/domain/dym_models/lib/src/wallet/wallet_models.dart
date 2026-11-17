import 'package:dym_models/src/json.dart';
import 'package:meta/meta.dart';

/// Nature d'un mouvement du wallet (`ledger_transactions.kind`).
enum WalletMovementKind {
  walletTopup,
  walletTransfer,
  paymentReceived,
  refundPaid,
  cashback,
  spaceContribution,
  spacePayout,
  affiliateCommission,
  courierFee,
  cashTopup,
  walletWithdrawal,
  membership,
  memberBenefit,
  qrPayment,
  p2pSent,
  p2pReceived,
  unknown;

  static WalletMovementKind parse(Object? value) => switch (value) {
    'wallet_topup' => walletTopup,
    'wallet_transfer' => walletTransfer,
    'payment_received' => paymentReceived,
    'refund_paid' => refundPaid,
    'cashback' => cashback,
    'space_contribution' => spaceContribution,
    'space_payout' => spacePayout,
    'affiliate_commission' => affiliateCommission,
    'courier_fee' => courierFee,
    'cash_topup' => cashTopup,
    'wallet_withdrawal' => walletWithdrawal,
    'membership' => membership,
    'member_benefit' => memberBenefit,
    'qr_payment' => qrPayment,
    'p2p_sent' => p2pSent,
    'p2p_received' => p2pReceived,
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
    this.counterpart,
  });

  factory fromJson(Map<String, dynamic> json) => WalletMovement(
    id: json['id']! as String,
    kind: WalletMovementKind.parse(json['kind']),
    amountMinor: minorFromJson(json['amount_minor']),
    occurredAt: DateTime.parse(json['occurred_at']! as String),
    pocketId: json['pocket_id'] as String?,
    orderId: json['order_id'] as String?,
    counterpart: json['counterpart'] as String?,
  );

  final String id;
  final WalletMovementKind kind;
  final int amountMinor;
  final DateTime occurredAt;
  final String? pocketId;
  final String? orderId;

  /// Prénom de la personne, pour un mouvement entre proches (spec 104).
  final String? counterpart;
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
    this.simulatedWithdrawal = false,
  });

  factory fromJson(Map<String, dynamic> json) => Wallet(
    currencyCode: json['currency_code']! as String,
    balanceMinor: minorFromJson(json['balance_minor']),
    simulatedTopup: json['simulated_topup'] == true,
    simulatedWithdrawal: json['simulated_withdrawal'] == true,
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

  /// Retrait simulé actif (aucun versement réel, décision 0015).
  final bool simulatedWithdrawal;
  final List<WalletPocket> pockets;
  final List<WalletMovement> movements;

  /// Total : wallet + poches.
  int get totalMinor =>
      balanceMinor + pockets.fold(0, (sum, p) => sum + p.balanceMinor);
}
