/// Assistant de courses (spec 029) : listes nommées librement, résolues en
/// base chez le meilleur marchand à chaque ouverture.
library;

/// Un article d'une liste : libellé affiché, mot de recherche, quantité.
class ShoppingItem {
  const new({required this.label, String? query, this.quantity = 1})
    : query = query ?? label;

  factory fromJson(Map<String, dynamic> json) => ShoppingItem(
    label: json['label'] as String? ?? '',
    query: json['query'] as String?,
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  );

  final String label;
  final String query;
  final int quantity;

  /// Quantités possibles (règle serveur : 1 à 10).
  static const minQuantity = 1;
  static const maxQuantity = 10;

  ShoppingItem withQuantity(int value) => ShoppingItem(
    label: label,
    query: query,
    quantity: value.clamp(minQuantity, maxQuantity),
  );

  Map<String, Object?> toJson() => {
    'label': label,
    'query': query,
    'quantity': quantity,
  };
}

/// Périodes de récurrence acceptées par le serveur.
enum ShoppingPeriod {
  weekly(7),
  biweekly(14),
  monthly(30);

  new(this.days);

  final int days;

  static ShoppingPeriod? fromDays(int? days) => switch (days) {
    7 => weekly,
    14 => biweekly,
    30 => monthly,
    _ => null,
  };
}

/// Une liste de courses de la personne.
class ShoppingList {
  const new({
    required this.id,
    required this.name,
    required this.items,
    this.period,
    this.nextDueOn,
    this.zoneId,
  });

  factory fromJson(Map<String, dynamic> json) => ShoppingList(
    id: json['id'] as String,
    name: json['name'] as String,
    items: [
      for (final i in json['items'] as List? ?? const [])
        ShoppingItem.fromJson(i as Map<String, dynamic>),
    ],
    period: ShoppingPeriod.fromDays((json['every_days'] as num?)?.toInt()),
    nextDueOn: switch (json['next_due_on']) {
      final String d => DateTime.parse(d),
      _ => null,
    },
    zoneId: json['zone_id'] as String?,
  );

  final String id;
  final String name;
  final List<ShoppingItem> items;

  /// Absente : liste sans rappel.
  final ShoppingPeriod? period;

  /// Prochain rappel (date locale du pays).
  final DateTime? nextDueOn;
  final String? zoneId;

  /// Règles serveur, reprises pour l'édition.
  static const maxItems = 20;
  static const maxNameLength = 40;
}
