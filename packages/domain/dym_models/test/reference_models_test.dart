import 'package:dym_models/dym_models.dart';
import 'package:test/test.dart';

CountryConfig _config({List<FeatureFlag> flags = const []}) => CountryConfig(
  country: Country.fromJson(const {
    'code': 'TG',
    'name': {'fr': 'Togo', 'en': 'Togo'},
    'currency_code': 'XOF',
    'dial_code': '+228',
    'default_locale': 'fr',
    'timezone': 'Africa/Lome',
  }),
  currency: CurrencyInfo.fromJson(const {
    'code': 'XOF',
    'minor_units': 0,
    'symbol': 'F CFA',
    'format_locale': 'fr',
  }).toCurrency(),
  cities: const [],
  zones: const [],
  categories: [
    Category.fromJson(const {
      'id': 'c1',
      'parent_id': null,
      'slug': 'legumes',
      'label': {'fr': 'Légumes', 'en': 'Vegetables'},
      'sort': 1,
    }),
    Category.fromJson(const {
      'id': 'c2',
      'parent_id': 'c1',
      'slug': 'tomates',
      'label': {'fr': 'Tomates'},
      'sort': 1,
    }),
  ],
  storeOrigins: const [],
  units: const [],
  paymentMethods: const [],
  deliveryFees: [
    DeliveryFeeDefault.fromJson(const {
      'country_code': 'TG',
      'city_id': null,
      'currency_code': 'XOF',
      'base_fee_minor': 500,
      'extra_pickup_fee_minor': 200,
      'free_threshold_minor': 4000,
    }),
  ],
  featureFlags: flags,
);

void main() {
  test('devise du référentiel → Money', () {
    final config = _config();
    expect(config.currency.minorUnits, 0);
    expect(config.money(4100).format(), contains('4'));
  });

  test('rayons : premier niveau et sous-rayons', () {
    final config = _config();
    expect(config.topCategories.map((c) => c.slug), ['legumes']);
    expect(config.subCategoriesOf('c1').single.label.resolve('en'), 'Tomates');
  });

  test('unités, moyens de paiement et origines depuis la base', () {
    final unit = MarketUnit.fromJson(const {
      'id': 'u1',
      'country_code': 'GH',
      'code': 'olonka',
      'label': {'fr': "l'olonka", 'en': 'the olonka'},
      'kind': 'volume',
      'indicative_grams': null,
      'indicative_ml': 2500,
      'sort': 3,
    });
    expect(unit.kind, UnitKind.volume);
    expect(unit.label.resolve('en'), 'the olonka');

    final cash = PaymentMethod.fromJson(const {
      'id': 'p1',
      'country_code': 'TG',
      'provider_code': 'cash',
      'operator_code': null,
      'label': {'fr': 'Cash à la livraison'},
      'sort': 1,
    });
    expect(cash.isCash, isTrue);

    final origin = StoreOriginInfo.fromJson(const {
      'code': 'maison',
      'label': {'fr': 'Fait maison', 'en': 'Homemade'},
      'description': null,
      'sort': 2,
    });
    expect(origin.description, isNull);
  });

  test('frais par défaut : ville, sinon pays', () {
    final fee = _config().deliveryFeeFor('ville-inconnue');
    expect(fee?.baseFeeMinor, 500);
    expect(fee?.freeThresholdMinor, 4000);
  });

  test('flags : le pays prime sur le global, absent = inactif', () {
    final config = _config(
      flags: const [
        FeatureFlag(key: 'momo_payments', isEnabled: false),
        FeatureFlag(key: 'momo_payments', isEnabled: true, countryCode: 'TG'),
        FeatureFlag(key: 'phone_otp', isEnabled: true),
      ],
    );
    expect(config.isEnabled('momo_payments'), isTrue);
    expect(config.isEnabled('phone_otp'), isTrue);
    expect(config.isEnabled('inconnu'), isFalse);
  });

  test('JSON incomplet : erreur explicite', () {
    expect(
      () => Country.fromJson(const {'code': 'TG'}),
      throwsA(isA<Exception>()),
    );
  });
}
