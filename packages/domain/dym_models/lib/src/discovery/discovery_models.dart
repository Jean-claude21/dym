import 'package:dym_core/dym_core.dart';
import 'package:dym_models/src/json.dart';
import 'package:dym_models/src/store/store_models.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'discovery_models.g.dart';

/// Boutique active vue par une cliente (sans adresse ni propriétaire).
@immutable
@JsonSerializable()
class PublicStore {
  const new({
    required this.id,
    required this.name,
    required this.zoneId,
    required this.zoneName,
    required this.currencyCode,
    required this.prepTimeMinutes,
    required this.deliveryMinutes,
    this.description,
    this.origin,
    this.zoneLatitude,
    this.zoneLongitude,
    this.countryCode,
    this.offersPickup = false,
    this.openNow = false,
    this.closesAt,
    this.coverKey,
    this.productCount = 0,
    this.rating,
    this.reviewCount = 0,
    this.latitude,
    this.longitude,
    this.deliveryRadiusM,
    this.distanceM,
    this.longDistance = false,
  });

  factory fromJson(Map<String, dynamic> json) => _$PublicStoreFromJson(json);

  final String id;
  final String name;
  final String? description;
  final String? origin;
  final String zoneId;
  final String zoneName;
  final double? zoneLatitude;
  final double? zoneLongitude;
  final String? countryCode;
  final String currencyCode;
  final int prepTimeMinutes;
  final bool offersPickup;
  final bool openNow;

  /// Fermeture du jour (`HH:MM`, heure locale).
  final String? closesAt;

  /// Préparation + livraison de la ville (minutes).
  final int deliveryMinutes;

  /// Photo de couverture (premier produit publié).
  final String? coverKey;
  final int productCount;

  /// Note moyenne sur 5 (nulle sans avis, spec 016).
  final double? rating;
  final int reviewCount;

  /// Position de la boutique (adresse de retrait, sinon centre du quartier)
  /// et rayon de livraison en mètres (spec 094).
  final double? latitude;
  final double? longitude;
  final int? deliveryRadiusM;

  /// Distance depuis la position de la cliente, en mètres (découverte).
  final int? distanceM;

  /// Hors du rayon de la boutique : livraison longue distance, à confirmer
  /// par elle (spec 096).
  final bool longDistance;
}

/// Boutique d'un élément de liste.
@immutable
@JsonSerializable()
class CatalogItemStore {
  const new({
    required this.id,
    required this.name,
    required this.zoneName,
    this.origin,
  });

  factory fromJson(Map<String, dynamic> json) =>
      _$CatalogItemStoreFromJson(json);

  final String id;
  final String name;
  final String? origin;
  final String zoneName;
}

/// Produit publié dans une liste (rayon, recherche, page boutique).
@immutable
@JsonSerializable()
class CatalogItem {
  const new({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.store,
    this.categoryId,
    this.priceMinor,
    this.minPriceMinor,
    this.unitLabel,
    this.photoKey,
    this.variantCount = 1,
    this.defaultVariantId,
    this.available = true,
    this.storeCategoryIds = const [],
    this.arrivalOn,
    this.endOfMarketPercent,
  });

  factory fromJson(Map<String, dynamic> json) => _$CatalogItemFromJson(json);

  final String id;
  final String name;
  final String? categoryId;
  @JsonKey(fromJson: nullableMinorFromJson)
  final int? priceMinor;

  /// Prix le plus bas, variantes comprises (« dès … »).
  @JsonKey(fromJson: nullableMinorFromJson)
  final int? minPriceMinor;
  final String currencyCode;
  @NullableLocalizedTextConverter()
  final LocalizedText? unitLabel;
  final String? photoKey;
  final int variantCount;

  /// Première variante : ajout direct au panier s'il n'y en a qu'une.
  final String? defaultVariantId;
  final bool available;
  final CatalogItemStore store;
  final List<String> storeCategoryIds;

  /// Arrivage à venir (spec 033) : précommande à prix bloqué.
  final DateTime? arrivalOn;

  /// Fin de marché en cours (spec 048) : remise en pourcentage, déjà
  /// appliquée au prix.
  @JsonKey(readValue: _endOfMarketPercent)
  final int? endOfMarketPercent;

  /// Prix affiché : le plus bas s'il y a plusieurs variantes.
  int? get displayPriceMinor =>
      variantCount > 1 ? (minPriceMinor ?? priceMinor) : priceMinor;
}

/// Accueil : boutiques qui livrent le quartier et estimation.
@immutable
@JsonSerializable()
class DiscoverResult {
  const new({
    this.estimateMinutes,
    this.stores = const [],
    this.sponsored = const [],
  });

  factory fromJson(Map<String, dynamic> json) => _$DiscoverResultFromJson(json);

  /// « Livré en … min » (nul : aucune boutique ouverte).
  final int? estimateMinutes;
  final List<PublicStore> stores;

  /// « À la une » : boutiques sponsorisées, signalées comme telles (spec 052).
  final List<PublicStore> sponsored;

  List<PublicStore> get openStores => stores.where((s) => s.openNow).toList();
}

/// Résultats d'une recherche ou d'un rayon.
@immutable
@JsonSerializable()
class SearchResults {
  const new({
    this.total = 0,
    this.products = const [],
    this.stores = const [],
    this.fuzzy = false,
  });

  factory fromJson(Map<String, dynamic> json) => _$SearchResultsFromJson(json);

  final int total;
  final List<CatalogItem> products;
  final List<PublicStore> stores;

  /// Résultats approchés : la recherche exacte n'a rien trouvé (spec 079).
  final bool fuzzy;

  bool get isEmpty => products.isEmpty && stores.isEmpty;
}

/// Tri des résultats.
enum SearchSort {
  relevance('relevance'),
  priceAsc('price_asc'),
  priceDesc('price_desc');

  new(this.code);

  final String code;
}

/// Critères d'une recherche (montants en unités mineures).
@immutable
class SearchQuery {
  const new({
    this.text,
    this.zoneId,
    this.categoryId,
    this.origin,
    this.minPriceMinor,
    this.maxPriceMinor,
    this.availableOnly = false,
    this.sort = SearchSort.relevance,
    this.limit = 20,
    this.offset = 0,
  });

  final String? text;
  final String? zoneId;
  final String? categoryId;
  final String? origin;
  final int? minPriceMinor;
  final int? maxPriceMinor;
  final bool availableOnly;
  final SearchSort sort;
  final int limit;
  final int offset;

  /// Filtres actifs (hors texte et quartier), pour l'événement et le badge.
  int get activeFilters => [
    categoryId,
    origin,
    minPriceMinor,
    maxPriceMinor,
    if (availableOnly) true,
    if (sort != SearchSort.relevance) true,
  ].nonNulls.length;

  Map<String, Object?> toParams() => {
    'p_query': text,
    'p_zone': zoneId,
    'p_category': categoryId,
    'p_origin': origin,
    'p_min_price': minPriceMinor,
    'p_max_price': maxPriceMinor,
    'p_available_only': availableOnly,
    'p_sort': sort.code,
    'p_limit': limit,
    'p_offset': offset,
  };

  SearchQuery copyWith({String? text, String? zoneId, int? offset}) =>
      SearchQuery(
        text: text ?? this.text,
        zoneId: zoneId ?? this.zoneId,
        categoryId: categoryId,
        origin: origin,
        minPriceMinor: minPriceMinor,
        maxPriceMinor: maxPriceMinor,
        availableOnly: availableOnly,
        sort: sort,
        limit: limit,
        offset: offset ?? this.offset,
      );
}

/// Catégorie de boutique vue par une cliente.
@immutable
@JsonSerializable()
class PublicStoreCategory {
  const new({required this.id, required this.name});

  factory fromJson(Map<String, dynamic> json) =>
      _$PublicStoreCategoryFromJson(json);

  final String id;
  final String name;
}

/// Page boutique (écran 04).
@immutable
class StorePageData {
  const new({
    required this.store,
    this.hours = const [],
    this.categories = const [],
    this.products = const [],
  });

  factory fromJson(Map<String, dynamic> json) => StorePageData(
    store: PublicStore.fromJson(json),
    hours: [
      for (final h in (json['hours'] as List? ?? const []))
        StoreHours.fromJson(h as Map<String, dynamic>),
    ],
    categories: [
      for (final c in (json['categories'] as List? ?? const []))
        PublicStoreCategory.fromJson(c as Map<String, dynamic>),
    ],
    products: [
      for (final p in (json['products'] as List? ?? const []))
        CatalogItem.fromJson(p as Map<String, dynamic>),
    ],
  );

  final PublicStore store;
  final List<StoreHours> hours;
  final List<PublicStoreCategory> categories;
  final List<CatalogItem> products;
}

/// Variante d'une fiche publique (prix effectif).
@immutable
@JsonSerializable()
class PublicVariant {
  const new({
    required this.id,
    required this.priceMinor,
    this.label,
    this.available = true,
  });

  factory fromJson(Map<String, dynamic> json) => _$PublicVariantFromJson(json);

  final String id;
  final String? label;
  @JsonKey(fromJson: minorFromJson)
  final int priceMinor;
  final bool available;
}

/// Fiche produit (écran 28).
@immutable
class ProductPageData {
  const new({
    required this.item,
    required this.store,
    this.description,
    this.photoKeys = const [],
    this.variants = const [],
    this.zoneName,
    this.servesZone = true,
    this.canHaggle = false,
  });

  factory fromJson(Map<String, dynamic> json) {
    final storeJson = json['store'] as Map<String, dynamic>;
    return ProductPageData(
      item: CatalogItem.fromJson({
        ...json,
        'store': {
          'id': storeJson['id'],
          'name': storeJson['name'],
          'origin': storeJson['origin'],
          'zone_name': storeJson['zone_name'],
        },
      }),
      store: PublicStore.fromJson(storeJson),
      description: json['description'] as String?,
      photoKeys: [
        for (final k in (json['photo_keys'] as List? ?? const [])) k as String,
      ],
      variants: [
        for (final v in (json['variants'] as List? ?? const []))
          PublicVariant.fromJson(v as Map<String, dynamic>),
      ],
      zoneName: json['zone_name'] as String?,
      servesZone: json['serves_zone'] as bool? ?? true,
      canHaggle: json['can_haggle'] as bool? ?? false,
    );
  }

  final CatalogItem item;
  final PublicStore store;
  final String? description;
  final List<String> photoKeys;
  final List<PublicVariant> variants;

  /// Quartier de la cliente (« Livré en … à Bè »).
  final String? zoneName;
  final bool servesZone;

  /// La vendeuse accepte de marchander ce produit (spec 050).
  final bool canHaggle;
}

/// Quartier proposé à partir d'une position.
@immutable
@JsonSerializable()
class ZoneMatch {
  const new({
    required this.zoneId,
    required this.zoneName,
    required this.cityId,
    required this.cityName,
    required this.countryCode,
    required this.distanceM,
    this.covered = true,
  });

  factory fromJson(Map<String, dynamic> json) => _$ZoneMatchFromJson(json);

  final String zoneId;
  final String zoneName;
  final String cityId;
  final String cityName;
  final String countryCode;
  final int distanceM;

  /// La position tient dans le rayon de service de la ville (spec 065) :
  /// sinon, le quartier n'est qu'une indication, jamais choisi d'office.
  @JsonKey(defaultValue: true)
  final bool covered;

  /// Distance arrondie au kilomètre (événement « hors zone », sans position).
  int get distanceKm => (distanceM / 1000).round();
}

/// Dernière commande livrée, proposée au réachat sur l'accueil (spec 027).
@immutable
class LastOrder {
  const new({
    required this.orderId,
    required this.storeName,
    required this.itemCount,
  });

  factory fromJson(Map<String, dynamic> json) => LastOrder(
    orderId: json['order_id']! as String,
    storeName: json['store_name']! as String,
    itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
  );

  final String orderId;
  final String storeName;
  final int itemCount;
}

/// Fil personnel de l'accueil (`public.home_feed`, spec 027).
@immutable
class HomeFeed {
  const new({this.lastOrder, this.popular = const [], this.fresh = const []});

  factory fromJson(Map<String, dynamic> json) => HomeFeed(
    lastOrder: json['last_order'] is Map<String, dynamic>
        ? LastOrder.fromJson(json['last_order'] as Map<String, dynamic>)
        : null,
    popular: [
      for (final p
          in (json['popular'] as List? ?? const [])
              .cast<Map<String, dynamic>>())
        CatalogItem.fromJson(p),
    ],
    fresh: [
      for (final p
          in (json['fresh'] as List? ?? const []).cast<Map<String, dynamic>>())
        CatalogItem.fromJson(p),
    ],
  );

  final LastOrder? lastOrder;

  /// Les plus demandés du quartier (30 jours).
  final List<CatalogItem> popular;

  /// Publiés depuis 14 jours.
  final List<CatalogItem> fresh;

  bool get isEmpty => lastOrder == null && popular.isEmpty && fresh.isEmpty;
}

Object? _endOfMarketPercent(Map<dynamic, dynamic> json, String key) =>
    (json['end_of_market'] as Map?)?['percent'];
