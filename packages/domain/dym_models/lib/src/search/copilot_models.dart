import 'package:dym_core/dym_core.dart';
import 'package:dym_models/src/json.dart';
import 'package:meta/meta.dart';

/// Raison du choix d'un produit par le copilote (spec 028), décidée en base
/// selon les poids de classement du pays.
enum CopilotReason {
  sameStore('same_store'),
  openNow('open_now'),
  topRated('top_rated'),
  bestPrice('best_price'),
  nearby('nearby'),
  bestMatch('best_match');

  new(this.code);

  /// Code renvoyé par la base.
  final String code;

  static CopilotReason? tryParse(Object? value) =>
      values.where((r) => r.code == value).firstOrNull;
}

/// Ligne d'un panier proposé par le copilote (spec 019), chiffrée en base.
@immutable
class CopilotLine {
  const new({
    required this.variantId,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPriceMinor,
    required this.lineMinor,
    this.variantLabel,
    this.unitLabel,
    this.photoKey,
    this.need,
    this.reason,
  });

  factory fromJson(Map<String, dynamic> json) => CopilotLine(
    variantId: json['variant_id'] as String,
    productId: json['product_id'] as String,
    name: json['name'] as String,
    variantLabel: json['variant_label'] as String?,
    unitLabel: switch (json['unit_label']) {
      // Libellé traduit (référentiel) ou texte simple.
      final Map<String, dynamic> m => LocalizedText.fromJson(m),
      final String text => LocalizedText({'fr': text}),
      _ => null,
    },
    quantity: (json['quantity'] as num).toInt(),
    unitPriceMinor: minorFromJson(json['unit_price_minor']),
    lineMinor: minorFromJson(json['line_minor']),
    photoKey: json['photo_key'] as String?,
    need: json['need'] as String?,
    reason: CopilotReason.tryParse(json['reason']),
  );

  final String variantId;
  final String productId;
  final String name;
  final String? variantLabel;
  final LocalizedText? unitLabel;
  final int quantity;
  final int unitPriceMinor;
  final int lineMinor;
  final String? photoKey;

  /// Besoin d'origine (« Gombo »).
  final String? need;

  /// Pourquoi ce produit plutôt qu'un autre (absent : rechiffrage).
  final CopilotReason? reason;
}

/// Lignes d'une même boutique.
@immutable
class CopilotStoreLines {
  const new({required this.id, required this.name, this.lines = const []});

  factory fromJson(Map<String, dynamic> json) => CopilotStoreLines(
    id: json['id'] as String,
    name: json['name'] as String,
    lines: [
      for (final l in json['items'] as List? ?? const [])
        CopilotLine.fromJson(l as Map<String, dynamic>),
    ],
  );

  final String id;
  final String name;
  final List<CopilotLine> lines;
}

/// Panier proposé : lignes par boutique, total serveur, besoins non trouvés.
@immutable
class CopilotProposal {
  const new({
    this.currencyCode,
    this.totalMinor = 0,
    this.stores = const [],
    this.missing = const [],
    this.servings,
    this.baseServings,
  });

  factory fromJson(Map<String, dynamic> json, {List<String>? missing}) =>
      CopilotProposal(
        servings: (json['servings'] as num?)?.toInt(),
        baseServings: (json['base_servings'] as num?)?.toInt(),
        currencyCode: json['currency_code'] as String?,
        totalMinor: minorFromJson(json['total_minor'] ?? 0),
        stores: [
          for (final s in json['stores'] as List? ?? const [])
            CopilotStoreLines.fromJson(s as Map<String, dynamic>),
        ],
        missing:
            missing ??
            [for (final m in json['missing'] as List? ?? const []) m as String],
      );

  final String? currencyCode;
  final int totalMinor;
  final List<CopilotStoreLines> stores;
  final List<String> missing;

  /// Recette (spec 057) : portions demandées et portions de référence ;
  /// nulles hors recette.
  final int? servings;
  final int? baseServings;

  List<CopilotLine> get lines => [for (final s in stores) ...s.lines];

  bool get isEmpty => lines.isEmpty;

  /// Lignes à rechiffrer, sans [variantId] (retrait d'une ligne).
  List<Map<String, Object?>> itemsWithout(String? variantId) => [
    for (final l in lines)
      if (l.variantId != variantId)
        {
          'variant_id': l.variantId,
          'quantity': l.quantity,
          'need': l.need,
          'reason': l.reason?.code,
        },
  ];
}
