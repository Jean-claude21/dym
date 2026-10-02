import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/store/testing.dart';

/// Boutique de démonstration (écrans 16 à 23) : référentiel du pays choisi
/// et boutique « Les jus d'Esi », sans aucune requête.
abstract final class DemoStore {
  static const _zones = {
    'TG': [
      'Tokoin',
      'Bè',
      'Adawlato',
      'Bè Kpota',
      'Nyékonakpoè',
      'Hédzranawoé',
      'Agoè',
    ],
    'GH': ['Osu', 'Madina', 'Makola', 'Kaneshie', 'East Legon'],
  };

  static const _categories = [
    ('legumes', 'Légumes', 'Vegetables'),
    ('fruits', 'Fruits', 'Fruit'),
    ('fait-maison', 'Fait maison', 'Homemade'),
    ('tubercules', 'Tubercules', 'Tubers'),
    ('poissons', 'Poissons fumés', 'Smoked fish'),
    ('epices', 'Épices', 'Spices'),
    ('boissons', 'Boissons', 'Drinks'),
    ('hygiene', 'Hygiène', 'Hygiene'),
  ];

  static const _origins = [
    (
      'marche',
      'Au marché',
      'At the market',
      'Tu as un étal ou une place au marché.',
      'You have a stall at the market.',
    ),
    (
      'maison',
      'Fait maison',
      'Homemade',
      'Tu prépares ou vends depuis ta maison.',
      'You cook or sell from home.',
    ),
    (
      'magasin',
      'Boutique',
      'Shop',
      'Tu as un magasin ou un kiosque.',
      'You have a shop or a kiosk.',
    ),
  ];

  static const _units = {
    'TG': [
      ('piece', 'la pièce', 'each'),
      ('litre', 'le litre', 'per litre'),
      ('bol', 'le bol', 'the bowl'),
      ('sachet', 'le sachet', 'the bag'),
    ],
    'GH': [
      ('piece', 'la pièce', 'each'),
      ('litre', 'le litre', 'per litre'),
      ('olonka', "l'olonka", 'the olonka'),
      ('margarine_tin', 'la boîte', 'the margarine tin'),
    ],
  };

  static const _mobileMoney = {
    'TG': [('tmoney', 'T-Money'), ('flooz', 'Flooz')],
    'GH': [('mtn', 'MTN MoMo'), ('telecel', 'Telecel Cash')],
  };

  static String _zoneId(String name) => name.toLowerCase().replaceAll(' ', '-');

  /// Identifiant de démonstration d'un quartier.
  static String zoneIdOf(String name) => _zoneId(name);

  /// Quartiers de démonstration du pays.
  static List<String> zoneNames(DemoCountry country) =>
      _zones[country.code] ?? const [];

  static CountryConfig config(DemoCountry country) => CountryConfig(
    country: Country.fromJson({
      'code': country.code,
      'name': {'fr': country.name, 'en': country.name},
      'currency_code': country.currency.code,
      'dial_code': country.code == 'GH' ? '+233' : '+228',
      'default_locale': country.code == 'GH' ? 'en' : 'fr',
      'timezone': country.code == 'GH' ? 'Africa/Accra' : 'Africa/Lome',
    }),
    currency: country.currency,
    cities: [
      City.fromJson({
        'id': 'city',
        'country_code': country.code,
        'slug': 'city',
        'name': country.city.split(',').last.trim(),
      }),
    ],
    zones: [
      for (final name in _zones[country.code] ?? const <String>[])
        Zone.fromJson({
          'id': _zoneId(name),
          'city_id': 'city',
          'slug': _zoneId(name),
          'name': name,
        }),
    ],
    categories: [
      for (final (i, (slug, fr, en)) in _categories.indexed)
        Category.fromJson({
          'id': slug,
          'slug': slug,
          'label': {'fr': fr, 'en': en},
          'icon': slug,
          'sort': i,
        }),
    ],
    storeOrigins: [
      for (final (code, fr, en, frText, enText) in _origins)
        StoreOriginInfo.fromJson({
          'code': code,
          'label': {'fr': fr, 'en': en},
          'description': {'fr': frText, 'en': enText},
        }),
    ],
    units: [
      for (final (i, (code, fr, en))
          in (_units[country.code] ?? const []).indexed)
        MarketUnit.fromJson({
          'id': 'unit-$code',
          'country_code': country.code,
          'code': code,
          'label': {'fr': fr, 'en': en},
          'kind': 'piece',
          'sort': i,
        }),
    ],
    paymentMethods: [
      PaymentMethod.fromJson({
        'id': 'cash',
        'country_code': country.code,
        'provider_code': 'cash',
        'label': const {'fr': 'Cash à la livraison', 'en': 'Cash on delivery'},
      }),
    ],
    deliveryFees: const [],
    featureFlags: const [],
  );

  static List<PaymentOption> paymentOptions(DemoCountry country) => [
    PaymentOption.fromJson(const {
      'id': 'cash',
      'provider_code': 'cash',
      'kind': 'cash',
      'label': {'fr': 'Cash à la livraison', 'en': 'Cash on delivery'},
      'is_available': true,
    }),
    for (final (code, label) in _mobileMoney[country.code] ?? const [])
      PaymentOption.fromJson({
        'id': code,
        'provider_code': 'moneroo',
        'operator_code': code,
        'kind': 'mobile_money',
        'label': {'fr': label},
        'is_available': false,
      }),
  ];

  static String _firstZone(DemoCountry country) =>
      _zoneId(_zones[country.code]!.first);

  /// Boutique « Les jus d'Esi », remplie jusqu'à l'étape [step] (8 :
  /// ouverte).
  static MyStore store(DemoCountry country, {int step = 8}) {
    final zones = _zones[country.code]!.map(_zoneId).toList();
    return MyStore(
      id: 'demo',
      name: "Les jus d'Esi",
      description: 'Jus de bissap, gingembre et baobab préparés chaque matin.',
      origin: step > 2 ? 'maison' : null,
      zoneId: zones.first,
      countryCode: country.code,
      currencyCode: country.currency.code,
      mainCategoryId: step >= 4 ? 'fait-maison' : null,
      prepTimeMinutes: 30,
      offersPickup: true,
      status: step > 7 ? StoreStatus.active : StoreStatus.draft,
      isOpen: step > 7,
      onboardingStep: step.clamp(1, 7),
      pickupAddress: step >= 3
          ? const PickupAddress(
              address: 'Rue des Hibiscus, maison bleue au portail vert',
              landmark: 'Derrière la pharmacie du Soleil',
            )
          : null,
      deliveryZoneIds: step >= 5 ? zones.take(4).toList() : const [],
      paymentMethodIds: step >= 6 ? const ['cash'] : const [],
      hours: step > 7
          ? [
              for (var day = 1; day <= 6; day++)
                StoreHours(weekday: day, opensAt: '07:00', closesAt: '19:00'),
            ]
          : const [],
    );
  }

  /// Service en mémoire ouvert à l'étape [step].
  static MemoryStoreService service(DemoCountry country, {int step = 8}) =>
      MemoryStoreService(
        config: config(country),
        paymentOptionsList: paymentOptions(country),
        profileZoneId: _firstZone(country),
        initial: store(country, step: step),
      );
}
