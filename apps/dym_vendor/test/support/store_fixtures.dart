import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/store/testing.dart';

/// Référentiel du Togo réduit, au format renvoyé par la base.
CountryConfig togoConfig() {
  const zones = [
    ('tokoin', 'Tokoin'),
    ('be', 'Bè'),
    ('adawlato', 'Adawlato'),
    ('be-kpota', 'Bè Kpota'),
    ('nyekonakpoe', 'Nyékonakpoè'),
    ('hedzranawoe', 'Hédzranawoé'),
    ('agoe', 'Agoè'),
  ];
  const categories = [
    ('legumes', 'Légumes', 'Vegetables'),
    ('fruits', 'Fruits', 'Fruit'),
    ('fait-maison', 'Fait maison', 'Homemade'),
    ('tubercules', 'Tubercules', 'Tubers'),
    ('poissons', 'Poissons fumés', 'Smoked fish'),
    ('epices', 'Épices', 'Spices'),
    ('boissons', 'Boissons', 'Drinks'),
    ('cereales', 'Céréales et farines', 'Grains and flours'),
  ];
  const origins = [
    ('marche', 'Au marché', 'At the market', 'Tu as un étal au marché.'),
    ('maison', 'Fait maison', 'Homemade', 'Tu prépares depuis ta maison.'),
    ('magasin', 'Boutique', 'Shop', 'Tu as un magasin ou un kiosque.'),
  ];
  return CountryConfig(
    country: Country.fromJson(const {
      'code': 'TG',
      'name': {'fr': 'Togo', 'en': 'Togo'},
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
      for (final (i, (slug, fr, en)) in categories.indexed)
        Category.fromJson({
          'id': slug,
          'slug': slug,
          'label': {'fr': fr, 'en': en},
          'icon': slug,
          'sort': i,
        }),
    ],
    storeOrigins: [
      for (final (code, fr, en, description) in origins)
        StoreOriginInfo.fromJson({
          'code': code,
          'label': {'fr': fr, 'en': en},
          'description': {'fr': description},
        }),
    ],
    units: const [],
    paymentMethods: [
      PaymentMethod.fromJson(const {
        'id': 'cash',
        'country_code': 'TG',
        'provider_code': 'cash',
        'label': {'fr': 'Cash à la livraison', 'en': 'Cash on delivery'},
      }),
    ],
    deliveryFees: const [],
    featureFlags: const [],
  );
}

/// Moyens proposés : le cash, et Mobile Money « Bientôt ».
List<PaymentOption> togoPaymentOptions() => [
  for (final (id, provider, operator, kind, label, available) in const [
    ('cash', 'cash', null, 'cash', 'Cash à la livraison', true),
    ('tmoney', 'moneroo', 'tmoney', 'mobile_money', 'T-Money', false),
    ('flooz', 'moneroo', 'flooz', 'mobile_money', 'Flooz', false),
  ])
    PaymentOption.fromJson({
      'id': id,
      'provider_code': provider,
      'operator_code': operator,
      'kind': kind,
      'label': {'fr': label},
      'is_available': available,
    }),
];

/// Boutique complète et ouverte (« Les jus d'Esi »).
MyStore openStore({
  bool open = true,
  StoreStatus status = StoreStatus.active,
}) => MyStore(
  id: 'store',
  name: "Les jus d'Esi",
  origin: 'maison',
  zoneId: 'tokoin',
  countryCode: 'TG',
  currencyCode: 'XOF',
  mainCategoryId: 'fait-maison',
  prepTimeMinutes: 30,
  offersPickup: true,
  status: status,
  isOpen: open,
  onboardingStep: 7,
  pickupAddress: const PickupAddress(address: 'Rue des Hibiscus'),
  deliveryZoneIds: const ['tokoin', 'be', 'adawlato', 'nyekonakpoe'],
  paymentMethodIds: const ['cash'],
  hours: [
    for (var day = 1; day <= 6; day++)
      StoreHours(weekday: day, opensAt: '07:00', closesAt: '19:00'),
  ],
);

MemoryStoreService memoryStores({MyStore? initial}) => MemoryStoreService(
  config: togoConfig(),
  paymentOptionsList: togoPaymentOptions(),
  profileZoneId: 'tokoin',
  initial: initial,
);
