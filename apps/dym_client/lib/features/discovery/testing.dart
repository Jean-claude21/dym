import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Découverte en mémoire pour les tests et la galerie : reproduit les règles
/// des fonctions SQL (boutiques ouvertes d'abord, recherche sans accents et
/// par préfixes, filtres, tris). N'est jamais branchée en production.
class MemoryDiscoveryService implements DiscoveryService {
  new({
    required this.config,
    this.stores = const [],
    this.products = const [],
    this.zoneMatch,
    this.cityDeliveryMinutes = 20,
    this.photoResolver,
    String? initialZone,
  }) : _zone = ValueNotifier(initialZone);

  final CountryConfig config;
  final List<PublicStore> stores;

  /// Fiches complètes (la liste en est dérivée).
  final List<ProductPageData> products;

  /// Quartier proposé par la position (`null` : refusée).
  final ZoneMatch? zoneMatch;
  final int cityDeliveryMinutes;
  final ImageProvider Function(String key)? photoResolver;
  final ValueNotifier<String?> _zone;

  /// Prochain appel en échec (une fois).
  Failure? failNext;

  final calls = <String>[];
  final searches = <(SearchQuery, int)>[];
  final viewed = <String>[];

  Result<T>? _fail<T>(String name) {
    calls.add(name);
    final failure = failNext;
    if (failure == null) return null;
    failNext = null;
    return Err(failure);
  }

  @override
  ValueListenable<String?> get zone => _zone;

  @override
  void selectZone(String zoneId) => _zone.value = zoneId;

  @override
  Future<Result<CountryConfig>> countryConfig() async {
    final failed = _fail<CountryConfig>('countryConfig');
    if (failed != null) return failed;
    _zone.value ??= config.zones.firstOrNull?.id;
    return Ok(config);
  }

  @override
  Future<Result<DiscoverResult>> discover() async {
    final failed = _fail<DiscoverResult>('discover');
    if (failed != null) return failed;
    final zoneId = _zone.value;
    final list = [...stores]
      ..sort((a, b) {
        if (a.openNow != b.openNow) return a.openNow ? -1 : 1;
        final sameA = a.zoneId == zoneId;
        final sameB = b.zoneId == zoneId;
        if (sameA != sameB) return sameA ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    final open = list.where((s) => s.openNow);
    return Ok(
      DiscoverResult(
        estimateMinutes: open.isEmpty
            ? null
            : open
                      .map((s) => s.prepTimeMinutes)
                      .reduce((a, b) => a < b ? a : b) +
                  cityDeliveryMinutes,
        stores: list,
      ),
    );
  }

  @override
  Future<Result<ZoneMatch?>> locateZone() async =>
      _fail('locateZone') ?? Ok(zoneMatch);

  static String _normalize(String text) {
    const from = 'àâäáãéèêëíìîïóòôöõúùûüçñ';
    const to = 'aaaaaeeeeiiiiooooouuuucn';
    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      final i = from.indexOf(char);
      buffer.write(i < 0 ? char : to[i]);
    }
    return buffer.toString();
  }

  static bool _matches(String? query, String text) {
    final tokens = _normalize(query ?? '')
        .split(RegExp('[^a-z0-9]+'))
        .where((t) => t.isNotEmpty);
    if (tokens.isEmpty) return true;
    final words = _normalize(text).split(RegExp('[^a-z0-9]+'));
    return tokens.every((t) => words.any((w) => w.startsWith(t)));
  }

  int _price(ProductPageData p) =>
      p.item.minPriceMinor ?? p.item.priceMinor ?? 0;

  @override
  Future<Result<SearchResults>> search(SearchQuery query) async {
    final failed = _fail<SearchResults>('search');
    if (failed != null) return failed;
    final category = config.categories
        .where((c) => c.id == query.categoryId)
        .firstOrNull;
    final matches = [
      for (final p in products)
        if (_matches(query.text, '${p.item.name} ${p.description ?? ''}') &&
            (category == null ||
                p.item.categoryId == category.id ||
                config.categories.any(
                  (c) => c.id == p.item.categoryId && c.parentId == category.id,
                )) &&
            (query.origin == null || p.item.store.origin == query.origin) &&
            (query.minPriceMinor == null ||
                _price(p) >= query.minPriceMinor!) &&
            (query.maxPriceMinor == null ||
                _price(p) <= query.maxPriceMinor!) &&
            (!query.availableOnly || p.item.available))
          p,
    ];
    switch (query.sort) {
      case SearchSort.priceAsc:
        matches.sort((a, b) => _price(a).compareTo(_price(b)));
      case SearchSort.priceDesc:
        matches.sort((a, b) => _price(b).compareTo(_price(a)));
      case SearchSort.relevance:
        break;
    }
    final page = matches.skip(query.offset).take(query.limit);
    final hasText = (query.text ?? '').trim().isNotEmpty;
    return Ok(
      SearchResults(
        total: matches.length,
        products: [for (final p in page) p.item],
        stores: hasText && query.offset == 0
            ? [
                for (final s in stores)
                  if (_matches(query.text, s.name) &&
                      (query.origin == null || s.origin == query.origin))
                    s,
              ]
            : const [],
      ),
    );
  }

  @override
  Future<Result<StorePageData>> storePage(String storeId) async {
    final failed = _fail<StorePageData>('storePage');
    if (failed != null) return failed;
    final store = stores.where((s) => s.id == storeId).firstOrNull;
    if (store == null) return const Err(NotFoundFailure('boutique'));
    final items = [
      for (final p in products)
        if (p.item.store.id == storeId) p.item,
    ];
    return Ok(StorePageData(store: store, products: items));
  }

  @override
  Future<Result<ProductPageData>> productPage(String productId) async {
    final failed = _fail<ProductPageData>('productPage');
    if (failed != null) return failed;
    final page = products.where((p) => p.item.id == productId).firstOrNull;
    if (page == null) return const Err(NotFoundFailure('produit'));
    final zoneName = config.zones
        .where((z) => z.id == _zone.value)
        .firstOrNull
        ?.name;
    return Ok(
      ProductPageData(
        item: page.item,
        store: page.store,
        description: page.description,
        photoKeys: page.photoKeys,
        variants: page.variants,
        zoneName: zoneName,
        servesZone: page.servesZone,
      ),
    );
  }

  @override
  ImageProvider photo(String objectKey) =>
      photoResolver?.call(objectKey) ?? MemoryImage(_transparentPng);

  @override
  void searchPerformed(SearchQuery query, int total) =>
      searches.add((query, total));

  @override
  void productViewed(String productId) => viewed.add(productId);

  /// PNG 1 × 1 transparent.
  static final _transparentPng = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);
}
