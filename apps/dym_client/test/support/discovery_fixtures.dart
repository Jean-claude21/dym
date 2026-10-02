import 'package:dym_client/features/discovery/testing.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';

/// Référentiel du Togo réduit (quartiers, rayons, origines, unités).
CountryConfig togoConfig() {
  const zones = [('be', 'Bè'), ('tokoin', 'Tokoin'), ('agoe', 'Agoè')];
  const categories = [
    ('legumes', null, 'Légumes', 'Vegetables', 'legumes'),
    ('tomates', 'legumes', 'Tomates', 'Tomatoes', null),
    ('boissons', null, 'Boissons', 'Drinks', 'boissons'),
    ('fait-maison', null, 'Fait maison', 'Homemade', 'fait-maison'),
    ('epices', null, 'Épices', 'Spices', 'epices'),
  ];
  const origins = [
    ('marche', 'Au marché', 'At the market'),
    ('maison', 'Fait maison', 'Homemade'),
    ('magasin', 'Boutique', 'Shop'),
  ];
  return CountryConfig(
    country: Country.fromJson(const {
      'code': 'TG',
      'name': {'fr': 'Togo'},
      'currency_code': 'XOF',
      'dial_code': '+228',
      'default_locale': 'fr',
      'timezone': 'Africa/Lome',
    }),
    currency: Currency.xof,
    cities: [
      City.fromJson(const {
        'id': 'lome',
        'country_code': 'TG',
        'slug': 'lome',
        'name': 'Lomé',
      }),
    ],
    zones: [
      for (final (id, name) in zones)
        Zone.fromJson({'id': id, 'city_id': 'lome', 'slug': id, 'name': name}),
    ],
    categories: [
      for (final (i, (id, parent, fr, en, icon)) in categories.indexed)
        Category.fromJson({
          'id': id,
          'parent_id': parent,
          'slug': id,
          'label': {'fr': fr, 'en': en},
          'icon': icon,
          'sort': i,
        }),
    ],
    storeOrigins: [
      for (final (code, fr, en) in origins)
        StoreOriginInfo.fromJson({
          'code': code,
          'label': {'fr': fr, 'en': en},
        }),
    ],
    units: const [],
    paymentMethods: const [],
    deliveryFees: const [],
    featureFlags: const [],
  );
}

PublicStore _store(
  String id,
  String name,
  String origin,
  String zoneId,
  String zoneName, {
  bool open = true,
  int prep = 30,
}) => PublicStore(
  id: id,
  name: name,
  origin: origin,
  zoneId: zoneId,
  zoneName: zoneName,
  currencyCode: 'XOF',
  prepTimeMinutes: prep,
  deliveryMinutes: prep + 20,
  offersPickup: origin == 'maison',
  openNow: open,
  closesAt: '19:00',
  coverKey: 'stores/$id/products/cover.jpg',
  productCount: 2,
);

final PublicStore esi = _store(
  'esi',
  "Les jus d'Esi",
  'maison',
  'tokoin',
  'Tokoin',
);
final PublicStore kodjo = _store(
  'kodjo',
  'Étal de Kodjo',
  'marche',
  'be',
  'Bè',
  prep: 15,
);
final PublicStore afi = _store(
  'afi',
  'Chez Afi',
  'magasin',
  'agoe',
  'Agoè',
  open: false,
);

ProductPageData _product(
  String id,
  String name,
  PublicStore store,
  String category,
  int price, {
  bool available = true,
  String? description,
  List<PublicVariant>? variants,
  String unit = 'le tas',
}) {
  final list = variants ?? [PublicVariant(id: '$id-v', priceMinor: price)];
  final min = list.map((v) => v.priceMinor).reduce((a, b) => a < b ? a : b);
  return ProductPageData(
    item: CatalogItem(
      id: id,
      name: name,
      categoryId: category,
      priceMinor: price,
      minPriceMinor: min,
      currencyCode: 'XOF',
      unitLabel: LocalizedText.fromJson({'fr': unit, 'en': unit}),
      photoKey: 'stores/${store.id}/products/$id.jpg',
      variantCount: list.length,
      available: available,
      store: CatalogItemStore(
        id: store.id,
        name: store.name,
        origin: store.origin,
        zoneName: store.zoneName,
      ),
    ),
    store: store,
    description: description,
    photoKeys: [
      'stores/${store.id}/products/$id.jpg',
      'stores/${store.id}/products/$id-2.jpg',
    ],
    variants: list,
  );
}

List<ProductPageData> products() => [
  _product(
    'bissap',
    'Jus de bissap',
    esi,
    'boissons',
    700,
    unit: 'le litre',
    description: 'Préparé chaque matin.',
    variants: const [
      PublicVariant(id: 'v50', label: '50 cl', priceMinor: 400),
      PublicVariant(id: 'v1l', label: '1 L', priceMinor: 700, available: false),
    ],
  ),
  _product('sirop', 'Sirop de bissap', esi, 'boissons', 2500, available: false),
  _product('tomates', 'Tomates fraîches', kodjo, 'tomates', 500),
  _product('epices', 'Épices du marché', kodjo, 'epices', 300),
];

MemoryDiscoveryService memoryDiscovery({ZoneMatch? zoneMatch}) =>
    MemoryDiscoveryService(
      config: togoConfig(),
      stores: [esi, kodjo, afi],
      products: products(),
      zoneMatch: zoneMatch,
      initialZone: 'be',
    );
