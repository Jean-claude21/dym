/// Espaces partagés (spec 031) : membres, panier commun, budget mensuel.
library;

import 'package:dym_models/src/json.dart';

/// Rôle dans un espace : `payer` valide et paie, `member` remplit.
enum SpaceRole {
  payer('payer'),
  member('member');

  new(this.code);

  final String code;

  static SpaceRole fromCode(Object? code) => code == 'payer' ? payer : member;
}

/// Espace dans la liste « Mes espaces ».
class SpaceSummary {
  const new({
    required this.id,
    required this.name,
    required this.myRole,
    this.currencyCode,
    this.monthlyBudgetMinor,
    this.spentMonthMinor = 0,
    this.membersCount = 1,
    this.itemsCount = 0,
  });

  factory fromJson(Map<String, dynamic> json) => SpaceSummary(
    id: json['id'] as String,
    name: json['name'] as String,
    myRole: SpaceRole.fromCode(json['my_role']),
    currencyCode: json['currency_code'] as String?,
    monthlyBudgetMinor: nullableMinorFromJson(json['monthly_budget_minor']),
    spentMonthMinor: minorFromJson(json['spent_month_minor'] ?? 0),
    membersCount: (json['members_count'] as num?)?.toInt() ?? 1,
    itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String name;
  final SpaceRole myRole;
  final String? currencyCode;
  final int? monthlyBudgetMinor;
  final int spentMonthMinor;
  final int membersCount;
  final int itemsCount;
}

class SpaceMember {
  const new({
    required this.userId,
    required this.firstName,
    required this.role,
    this.isOwner = false,
    this.isMe = false,
    this.contributedMonthMinor = 0,
  });

  factory fromJson(Map<String, dynamic> json) => SpaceMember(
    userId: json['user_id'] as String,
    firstName: json['first_name'] as String? ?? '?',
    role: SpaceRole.fromCode(json['role']),
    isOwner: json['is_owner'] as bool? ?? false,
    isMe: json['is_me'] as bool? ?? false,
    contributedMonthMinor: minorFromJson(json['contributed_month_minor'] ?? 0),
  );

  final String userId;
  final String firstName;
  final SpaceRole role;
  final bool isOwner;
  final bool isMe;

  /// Versé dans la poche commune ce mois (spec 032).
  final int contributedMonthMinor;
}

/// Article du panier commun, au prix du jour.
class SpaceItem {
  const new({
    required this.variantId,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPriceMinor,
    required this.available,
    this.variantLabel,
    this.photoKey,
    this.storeName,
    this.addedBy,
  });

  factory fromJson(Map<String, dynamic> json) => SpaceItem(
    variantId: json['variant_id'] as String,
    productId: json['product_id'] as String,
    name: json['name'] as String,
    variantLabel: json['variant_label'] as String?,
    photoKey: json['photo_key'] as String?,
    storeName: json['store_name'] as String?,
    quantity: (json['quantity'] as num).toInt(),
    unitPriceMinor: minorFromJson(json['unit_price_minor'] ?? 0),
    available: json['available'] as bool? ?? false,
    addedBy: json['added_by'] as String?,
  );

  final String variantId;
  final String productId;
  final String name;
  final String? variantLabel;
  final String? photoKey;
  final String? storeName;
  final int quantity;
  final int unitPriceMinor;
  final bool available;

  /// Prénom de la personne qui l'a ajouté.
  final String? addedBy;
}

/// Espace ouvert : membres, panier commun, budget.
class Space {
  const new({
    required this.id,
    required this.name,
    required this.joinCode,
    required this.myRole,
    this.isOwner = false,
    this.currencyCode,
    this.monthlyBudgetMinor,
    this.spentMonthMinor = 0,
    this.totalMinor = 0,
    this.pocketBalanceMinor = 0,
    this.members = const [],
    this.items = const [],
  });

  factory fromJson(Map<String, dynamic> json) => Space(
    id: json['id'] as String,
    name: json['name'] as String,
    joinCode: json['join_code'] as String? ?? '',
    myRole: SpaceRole.fromCode(json['my_role']),
    isOwner: json['is_owner'] as bool? ?? false,
    currencyCode: json['currency_code'] as String?,
    monthlyBudgetMinor: nullableMinorFromJson(json['monthly_budget_minor']),
    spentMonthMinor: minorFromJson(json['spent_month_minor'] ?? 0),
    totalMinor: minorFromJson(json['total_minor'] ?? 0),
    pocketBalanceMinor: minorFromJson(json['pocket_balance_minor'] ?? 0),
    members: [
      for (final m in json['members'] as List? ?? const [])
        SpaceMember.fromJson(m as Map<String, dynamic>),
    ],
    items: [
      for (final i in json['items'] as List? ?? const [])
        SpaceItem.fromJson(i as Map<String, dynamic>),
    ],
  );

  final String id;
  final String name;
  final String joinCode;
  final SpaceRole myRole;
  final bool isOwner;
  final String? currencyCode;
  final int? monthlyBudgetMinor;
  final int spentMonthMinor;

  /// Total du panier commun (serveur).
  final int totalMinor;

  /// Solde de la poche commune (grand livre, spec 032).
  final int pocketBalanceMinor;
  final List<SpaceMember> members;
  final List<SpaceItem> items;

  bool get canValidate => myRole == SpaceRole.payer;

  /// Reste du budget du mois (nul : sans budget).
  int? get remainingMinor => switch (monthlyBudgetMinor) {
    final b? => b - spentMonthMinor,
    null => null,
  };

  /// Validation qui dépasserait le budget (affichage ; le serveur décide).
  bool get overBudget => switch (remainingMinor) {
    final r? => totalMinor > r,
    null => false,
  };

  /// La poche couvre le panier commun (affichage ; le serveur décide).
  bool get pocketCovers => pocketBalanceMinor >= totalMinor && totalMinor > 0;

  static const maxNameLength = 40;
}
