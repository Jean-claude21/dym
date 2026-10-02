import 'dart:typed_data';

import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_vendor/features/catalog/testing.dart';

import 'store_fixtures.dart';

/// Photo de test (PNG 1 × 1).
final testPhoto = PickedPhoto(
  bytes: Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
  contentType: 'image/jpeg',
);

const bissapSuggestion = ProductSuggestion(
  suggestionId: 's1',
  name: 'Jus de bissap 50 cl',
  categoryId: 'boissons',
  description: 'Jus de bissap frais au gingembre, préparé chaque matin.',
);

/// Produits de « Les jus d'Esi » : publié, en rupture, brouillon, archivé.
List<Product> esiProducts() => const [
  Product(
    id: 'p1',
    name: 'Jus de bissap',
    categoryId: 'boissons',
    unitId: 'unit-piece',
    priceMinor: 500,
    currencyCode: 'XOF',
    status: ProductStatus.published,
    variants: [
      ProductVariant(id: 'v1', label: '50 cl', stockQuantity: 12),
      ProductVariant(id: 'v2', label: '1 L', priceMinor: 900, stockQuantity: 6),
    ],
    photoKeys: ['stores/s/products/p1.jpg'],
    storeCategoryIds: ['c-jus'],
  ),
  Product(
    id: 'p2',
    name: 'Jus de baobab',
    categoryId: 'boissons',
    unitId: 'unit-litre',
    priceMinor: 1000,
    currencyCode: 'XOF',
    status: ProductStatus.published,
    isAvailable: false,
    variants: [ProductVariant(id: 'v3', stockQuantity: 0)],
    photoKeys: ['stores/s/products/p2.jpg'],
    storeCategoryIds: ['c-jus'],
  ),
  Product(
    id: 'p3',
    name: 'Sirop de bissap',
    currencyCode: 'XOF',
    status: ProductStatus.draft,
    variants: [ProductVariant(id: 'v4')],
    storeCategoryIds: ['c-sirops'],
    missing: ['category', 'price', 'photo'],
  ),
  Product(
    id: 'p4',
    name: 'Pâte de gingembre',
    categoryId: 'epices',
    priceMinor: 700,
    currencyCode: 'XOF',
    status: ProductStatus.archived,
    variants: [ProductVariant(id: 'v5', stockQuantity: 3)],
    photoKeys: ['stores/s/products/p4.jpg'],
  ),
];

List<StoreCategory> esiCategories() => const [
  StoreCategory(id: 'c-jus', name: 'Jus'),
  StoreCategory(id: 'c-sirops', name: 'Sirops', sort: 1),
  StoreCategory(id: 'c-patisseries', name: 'Pâtisseries', isArchived: true),
];

MemoryCatalogService memoryCatalog({
  List<Product>? products,
  List<StoreCategory>? categories,
  ProductSuggestion? suggestion = bissapSuggestion,
}) => MemoryCatalogService(
  config: togoConfig(),
  products: products ?? esiProducts(),
  categories: categories ?? esiCategories(),
  pickedPhoto: testPhoto,
  suggestion: suggestion,
);
