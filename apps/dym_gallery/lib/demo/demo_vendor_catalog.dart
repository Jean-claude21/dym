import 'dart:typed_data';

import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/demo/demo_store.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_vendor/features/catalog/testing.dart';

/// Catalogue de démonstration de « Les jus d'Esi » (écrans 24 à 27), sans
/// requête : photos de la galerie, prix dans la devise du pays choisi.
abstract final class DemoVendorCatalog {
  static String _key(String photo) => 'stores/demo/products/$photo.jpg';

  static Product _product(
    DemoCountry c, {
    required String id,
    required String name,
    required String photo,
    required int xof,
    required List<ProductVariant> variants,
    String unit = 'piece',
    List<String> categories = const ['c-jus'],
    bool available = true,
  }) => Product(
    id: id,
    name: name,
    categoryId: 'boissons',
    unitId: 'unit-$unit',
    priceMinor: c.price(xof).amountMinor,
    currencyCode: c.currency.code,
    status: ProductStatus.published,
    isAvailable: available,
    variants: variants,
    photoKeys: [_key(photo)],
    storeCategoryIds: categories,
  );

  static List<Product> products(DemoCountry c) => [
    _product(
      c,
      id: 'p-bissap',
      name: 'Jus de bissap',
      photo: 'bissap',
      xof: 500,
      variants: [
        const ProductVariant(id: 'v1', label: '50 cl', stockQuantity: 12),
        ProductVariant(
          id: 'v2',
          label: '1 L',
          priceMinor: c.price(900).amountMinor,
          stockQuantity: 6,
        ),
      ],
    ),
    _product(
      c,
      id: 'p-gingembre',
      name: 'Jus de gingembre',
      photo: 'gingembre',
      xof: 500,
      variants: const [
        ProductVariant(id: 'v3', label: '50 cl', stockQuantity: 8),
        ProductVariant(id: 'v4', label: '1 L', stockQuantity: 4),
      ],
    ),
    _product(
      c,
      id: 'p-baobab',
      name: 'Jus de baobab',
      photo: 'baobab',
      xof: 1000,
      unit: 'litre',
      available: false,
      variants: const [ProductVariant(id: 'v5', stockQuantity: 0)],
    ),
    _product(
      c,
      id: 'p-pack',
      name: 'Pack découverte',
      photo: 'pack-jus',
      xof: 2500,
      categories: const ['c-sirops'],
      variants: const [ProductVariant(id: 'v6', stockQuantity: 12)],
    ),
  ];

  static const categories = [
    StoreCategory(id: 'c-jus', name: 'Jus'),
    StoreCategory(id: 'c-sirops', name: 'Sirops', sort: 1),
    StoreCategory(id: 'c-plats', name: 'Plats du jour', sort: 2),
    StoreCategory(id: 'c-patisseries', name: 'Pâtisseries', isArchived: true),
  ];

  /// Service en mémoire. La photo « prise » est celle du bissap, et DYM
  /// propose une fiche (écran 25).
  static MemoryCatalogService service(DemoCountry c) => MemoryCatalogService(
    config: DemoStore.config(c),
    products: products(c),
    categories: categories,
    pickedPhoto: PickedPhoto(bytes: Uint8List(0), contentType: 'image/jpeg'),
    uploadKeys: [_key('bissap')],
    suggestion: const ProductSuggestion(
      suggestionId: 'demo',
      name: 'Jus de bissap 50 cl',
      categoryId: 'boissons',
      description: 'Jus de bissap frais au gingembre, préparé chaque matin.',
    ),
    photoResolver: (key) =>
        DemoImages.product(key.split('/').last.replaceAll('.jpg', '')),
  );
}
