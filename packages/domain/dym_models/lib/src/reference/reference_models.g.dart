// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reference_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrencyInfo _$CurrencyInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CurrencyInfo',
      json,
      ($checkedConvert) {
        final val = CurrencyInfo(
          code: $checkedConvert('code', (v) => v as String),
          minorUnits: $checkedConvert('minor_units', (v) => (v as num).toInt()),
          symbol: $checkedConvert('symbol', (v) => v as String),
          formatLocale: $checkedConvert('format_locale', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'minorUnits': 'minor_units',
        'formatLocale': 'format_locale',
      },
    );

Country _$CountryFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Country',
  json,
  ($checkedConvert) {
    final val = Country(
      code: $checkedConvert('code', (v) => v as String),
      name: $checkedConvert(
        'name',
        (v) => const LocalizedTextConverter().fromJson(v),
      ),
      currencyCode: $checkedConvert('currency_code', (v) => v as String),
      dialCode: $checkedConvert('dial_code', (v) => v as String),
      defaultLocale: $checkedConvert('default_locale', (v) => v as String),
      timezone: $checkedConvert('timezone', (v) => v as String),
      sort: $checkedConvert('sort', (v) => (v as num?)?.toInt() ?? 0),
    );
    return val;
  },
  fieldKeyMap: const {
    'currencyCode': 'currency_code',
    'dialCode': 'dial_code',
    'defaultLocale': 'default_locale',
  },
);

City _$CityFromJson(Map<String, dynamic> json) =>
    $checkedCreate('City', json, ($checkedConvert) {
      final val = City(
        id: $checkedConvert('id', (v) => v as String),
        countryCode: $checkedConvert('country_code', (v) => v as String),
        slug: $checkedConvert('slug', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        sort: $checkedConvert('sort', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    }, fieldKeyMap: const {'countryCode': 'country_code'});

Zone _$ZoneFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Zone', json, ($checkedConvert) {
      final val = Zone(
        id: $checkedConvert('id', (v) => v as String),
        cityId: $checkedConvert('city_id', (v) => v as String),
        slug: $checkedConvert('slug', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        sort: $checkedConvert('sort', (v) => (v as num?)?.toInt() ?? 0),
        latitude: $checkedConvert('latitude', (v) => (v as num?)?.toDouble()),
        longitude: $checkedConvert('longitude', (v) => (v as num?)?.toDouble()),
      );
      return val;
    }, fieldKeyMap: const {'cityId': 'city_id'});

Category _$CategoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Category', json, ($checkedConvert) {
      final val = Category(
        id: $checkedConvert('id', (v) => v as String),
        slug: $checkedConvert('slug', (v) => v as String),
        label: $checkedConvert(
          'label',
          (v) => const LocalizedTextConverter().fromJson(v),
        ),
        parentId: $checkedConvert('parent_id', (v) => v as String?),
        icon: $checkedConvert('icon', (v) => v as String?),
        sort: $checkedConvert('sort', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    }, fieldKeyMap: const {'parentId': 'parent_id'});

StoreOriginInfo _$StoreOriginInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StoreOriginInfo', json, ($checkedConvert) {
      final val = StoreOriginInfo(
        code: $checkedConvert('code', (v) => v as String),
        label: $checkedConvert(
          'label',
          (v) => const LocalizedTextConverter().fromJson(v),
        ),
        description: $checkedConvert(
          'description',
          (v) => const NullableLocalizedTextConverter().fromJson(v),
        ),
        sort: $checkedConvert('sort', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

MarketUnit _$MarketUnitFromJson(Map<String, dynamic> json) => $checkedCreate(
  'MarketUnit',
  json,
  ($checkedConvert) {
    final val = MarketUnit(
      id: $checkedConvert('id', (v) => v as String),
      countryCode: $checkedConvert('country_code', (v) => v as String),
      code: $checkedConvert('code', (v) => v as String),
      label: $checkedConvert(
        'label',
        (v) => const LocalizedTextConverter().fromJson(v),
      ),
      kind: $checkedConvert('kind', (v) => $enumDecode(_$UnitKindEnumMap, v)),
      indicativeGrams: $checkedConvert(
        'indicative_grams',
        (v) => (v as num?)?.toInt(),
      ),
      indicativeMl: $checkedConvert(
        'indicative_ml',
        (v) => (v as num?)?.toInt(),
      ),
      sort: $checkedConvert('sort', (v) => (v as num?)?.toInt() ?? 0),
    );
    return val;
  },
  fieldKeyMap: const {
    'countryCode': 'country_code',
    'indicativeGrams': 'indicative_grams',
    'indicativeMl': 'indicative_ml',
  },
);

const _$UnitKindEnumMap = {
  UnitKind.piece: 'piece',
  UnitKind.weight: 'weight',
  UnitKind.volume: 'volume',
  UnitKind.bundle: 'bundle',
};

PaymentMethod _$PaymentMethodFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentMethod',
      json,
      ($checkedConvert) {
        final val = PaymentMethod(
          id: $checkedConvert('id', (v) => v as String),
          countryCode: $checkedConvert('country_code', (v) => v as String),
          providerCode: $checkedConvert('provider_code', (v) => v as String),
          label: $checkedConvert(
            'label',
            (v) => const LocalizedTextConverter().fromJson(v),
          ),
          operatorCode: $checkedConvert('operator_code', (v) => v as String?),
          sort: $checkedConvert('sort', (v) => (v as num?)?.toInt() ?? 0),
        );
        return val;
      },
      fieldKeyMap: const {
        'countryCode': 'country_code',
        'providerCode': 'provider_code',
        'operatorCode': 'operator_code',
      },
    );

DeliveryFeeDefault _$DeliveryFeeDefaultFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DeliveryFeeDefault',
      json,
      ($checkedConvert) {
        final val = DeliveryFeeDefault(
          countryCode: $checkedConvert('country_code', (v) => v as String),
          currencyCode: $checkedConvert('currency_code', (v) => v as String),
          baseFeeMinor: $checkedConvert(
            'base_fee_minor',
            (v) => minorFromJson(v),
          ),
          extraPickupFeeMinor: $checkedConvert(
            'extra_pickup_fee_minor',
            (v) => minorFromJson(v),
          ),
          cityId: $checkedConvert('city_id', (v) => v as String?),
          freeThresholdMinor: $checkedConvert(
            'free_threshold_minor',
            (v) => nullableMinorFromJson(v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'countryCode': 'country_code',
        'currencyCode': 'currency_code',
        'baseFeeMinor': 'base_fee_minor',
        'extraPickupFeeMinor': 'extra_pickup_fee_minor',
        'cityId': 'city_id',
        'freeThresholdMinor': 'free_threshold_minor',
      },
    );

CommissionRule _$CommissionRuleFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CommissionRule',
      json,
      ($checkedConvert) {
        final val = CommissionRule(
          countryCode: $checkedConvert('country_code', (v) => v as String),
          rateBps: $checkedConvert('rate_bps', (v) => (v as num).toInt()),
          categoryId: $checkedConvert('category_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'countryCode': 'country_code',
        'rateBps': 'rate_bps',
        'categoryId': 'category_id',
      },
    );

FeatureFlag _$FeatureFlagFromJson(Map<String, dynamic> json) => $checkedCreate(
  'FeatureFlag',
  json,
  ($checkedConvert) {
    final val = FeatureFlag(
      key: $checkedConvert('key', (v) => v as String),
      isEnabled: $checkedConvert('is_enabled', (v) => v as bool),
      countryCode: $checkedConvert('country_code', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {'isEnabled': 'is_enabled', 'countryCode': 'country_code'},
);
