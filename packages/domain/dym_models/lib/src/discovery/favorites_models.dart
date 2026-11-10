/// Carnet de la cliente (spec 030) : favoris et paniers enregistrés.
library;

import 'package:dym_models/src/discovery/discovery_models.dart';
import 'package:dym_models/src/json.dart';

/// Sorte de favori.
enum FavoriteKind {
  store('store'),
  product('product');

  new(this.code);

  final String code;
}

/// Identifiants des favoris (état des cœurs).
class FavoriteIds {
  const new({this.storeIds = const {}, this.productIds = const {}});

  factory fromJson(Map<String, dynamic> json) => FavoriteIds(
    storeIds: {for (final id in json['store_ids'] as List? ?? const []) '$id'},
    productIds: {
      for (final id in json['product_ids'] as List? ?? const []) '$id',
    },
  );

  final Set<String> storeIds;
  final Set<String> productIds;

  bool contains(FavoriteKind kind, String id) => switch (kind) {
    FavoriteKind.store => storeIds.contains(id),
    FavoriteKind.product => productIds.contains(id),
  };

  /// État après un geste confirmé par le serveur.
  FavoriteIds withState(FavoriteKind kind, String id, {required bool on}) {
    Set<String> apply(Set<String> ids) =>
        on ? {...ids, id} : ({...ids}..remove(id));
    return switch (kind) {
      FavoriteKind.store => FavoriteIds(
        storeIds: apply(storeIds),
        productIds: productIds,
      ),
      FavoriteKind.product => FavoriteIds(
        storeIds: storeIds,
        productIds: apply(productIds),
      ),
    };
  }
}

/// Favoris affichables (boutiques actives, produits en vente).
class Favorites {
  const new({this.stores = const [], this.products = const []});

  factory fromJson(Map<String, dynamic> json) => Favorites(
    stores: [
      for (final s in json['stores'] as List? ?? const [])
        PublicStore.fromJson(s as Map<String, dynamic>),
    ],
    products: [
      for (final p in json['products'] as List? ?? const [])
        CatalogItem.fromJson(p as Map<String, dynamic>),
    ],
  );

  final List<PublicStore> stores;
  final List<CatalogItem> products;

  bool get isEmpty => stores.isEmpty && products.isEmpty;
}

/// Ligne d'un panier enregistré, au prix du jour.
class SavedBasketItem {
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
  });

  factory fromJson(Map<String, dynamic> json) => SavedBasketItem(
    variantId: json['variant_id'] as String,
    productId: json['product_id'] as String,
    name: json['name'] as String,
    variantLabel: json['variant_label'] as String?,
    photoKey: json['photo_key'] as String?,
    storeName: json['store_name'] as String?,
    quantity: (json['quantity'] as num).toInt(),
    unitPriceMinor: minorFromJson(json['unit_price_minor'] ?? 0),
    available: json['available'] as bool? ?? false,
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
}

/// Panier enregistré sous un nom libre.
class SavedBasket {
  const new({
    required this.id,
    required this.name,
    this.currencyCode,
    this.totalMinor = 0,
    this.availableCount = 0,
    this.items = const [],
  });

  factory fromJson(Map<String, dynamic> json) => SavedBasket(
    id: json['id'] as String,
    name: json['name'] as String,
    currencyCode: json['currency_code'] as String?,
    totalMinor: minorFromJson(json['total_minor'] ?? 0),
    availableCount: (json['available_count'] as num?)?.toInt() ?? 0,
    items: [
      for (final i in json['items'] as List? ?? const [])
        SavedBasketItem.fromJson(i as Map<String, dynamic>),
    ],
  );

  final String id;
  final String name;
  final String? currencyCode;

  /// Total du jour des articles disponibles (serveur).
  final int totalMinor;
  final int availableCount;
  final List<SavedBasketItem> items;

  static const maxNameLength = 40;
}
