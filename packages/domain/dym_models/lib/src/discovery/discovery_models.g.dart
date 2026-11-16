// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicStore _$PublicStoreFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PublicStore',
  json,
  ($checkedConvert) {
    final val = PublicStore(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      zoneId: $checkedConvert('zone_id', (v) => v as String),
      zoneName: $checkedConvert('zone_name', (v) => v as String),
      currencyCode: $checkedConvert('currency_code', (v) => v as String),
      prepTimeMinutes: $checkedConvert(
        'prep_time_minutes',
        (v) => (v as num).toInt(),
      ),
      deliveryMinutes: $checkedConvert(
        'delivery_minutes',
        (v) => (v as num).toInt(),
      ),
      description: $checkedConvert('description', (v) => v as String?),
      origin: $checkedConvert('origin', (v) => v as String?),
      zoneLatitude: $checkedConvert(
        'zone_latitude',
        (v) => (v as num?)?.toDouble(),
      ),
      zoneLongitude: $checkedConvert(
        'zone_longitude',
        (v) => (v as num?)?.toDouble(),
      ),
      countryCode: $checkedConvert('country_code', (v) => v as String?),
      offersPickup: $checkedConvert(
        'offers_pickup',
        (v) => v as bool? ?? false,
      ),
      openNow: $checkedConvert('open_now', (v) => v as bool? ?? false),
      closesAt: $checkedConvert('closes_at', (v) => v as String?),
      coverKey: $checkedConvert('cover_key', (v) => v as String?),
      productCount: $checkedConvert(
        'product_count',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      rating: $checkedConvert('rating', (v) => (v as num?)?.toDouble()),
      reviewCount: $checkedConvert(
        'review_count',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      latitude: $checkedConvert('latitude', (v) => (v as num?)?.toDouble()),
      longitude: $checkedConvert('longitude', (v) => (v as num?)?.toDouble()),
      deliveryRadiusM: $checkedConvert(
        'delivery_radius_m',
        (v) => (v as num?)?.toInt(),
      ),
      distanceM: $checkedConvert('distance_m', (v) => (v as num?)?.toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'zoneId': 'zone_id',
    'zoneName': 'zone_name',
    'currencyCode': 'currency_code',
    'prepTimeMinutes': 'prep_time_minutes',
    'deliveryMinutes': 'delivery_minutes',
    'zoneLatitude': 'zone_latitude',
    'zoneLongitude': 'zone_longitude',
    'countryCode': 'country_code',
    'offersPickup': 'offers_pickup',
    'openNow': 'open_now',
    'closesAt': 'closes_at',
    'coverKey': 'cover_key',
    'productCount': 'product_count',
    'reviewCount': 'review_count',
    'deliveryRadiusM': 'delivery_radius_m',
    'distanceM': 'distance_m',
  },
);

CatalogItemStore _$CatalogItemStoreFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CatalogItemStore', json, ($checkedConvert) {
      final val = CatalogItemStore(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        zoneName: $checkedConvert('zone_name', (v) => v as String),
        origin: $checkedConvert('origin', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'zoneName': 'zone_name'});

CatalogItem _$CatalogItemFromJson(Map<String, dynamic> json) => $checkedCreate(
  'CatalogItem',
  json,
  ($checkedConvert) {
    final val = CatalogItem(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      currencyCode: $checkedConvert('currency_code', (v) => v as String),
      store: $checkedConvert(
        'store',
        (v) => CatalogItemStore.fromJson(v as Map<String, dynamic>),
      ),
      categoryId: $checkedConvert('category_id', (v) => v as String?),
      priceMinor: $checkedConvert(
        'price_minor',
        (v) => nullableMinorFromJson(v),
      ),
      minPriceMinor: $checkedConvert(
        'min_price_minor',
        (v) => nullableMinorFromJson(v),
      ),
      unitLabel: $checkedConvert(
        'unit_label',
        (v) => const NullableLocalizedTextConverter().fromJson(v),
      ),
      photoKey: $checkedConvert('photo_key', (v) => v as String?),
      variantCount: $checkedConvert(
        'variant_count',
        (v) => (v as num?)?.toInt() ?? 1,
      ),
      defaultVariantId: $checkedConvert(
        'default_variant_id',
        (v) => v as String?,
      ),
      available: $checkedConvert('available', (v) => v as bool? ?? true),
      storeCategoryIds: $checkedConvert(
        'store_category_ids',
        (v) =>
            (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      ),
      arrivalOn: $checkedConvert(
        'arrival_on',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      endOfMarketPercent: $checkedConvert(
        'end_of_market_percent',
        (v) => (v as num?)?.toInt(),
        readValue: _endOfMarketPercent,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'currencyCode': 'currency_code',
    'categoryId': 'category_id',
    'priceMinor': 'price_minor',
    'minPriceMinor': 'min_price_minor',
    'unitLabel': 'unit_label',
    'photoKey': 'photo_key',
    'variantCount': 'variant_count',
    'defaultVariantId': 'default_variant_id',
    'storeCategoryIds': 'store_category_ids',
    'arrivalOn': 'arrival_on',
    'endOfMarketPercent': 'end_of_market_percent',
  },
);

DiscoverResult _$DiscoverResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DiscoverResult', json, ($checkedConvert) {
      final val = DiscoverResult(
        estimateMinutes: $checkedConvert(
          'estimate_minutes',
          (v) => (v as num?)?.toInt(),
        ),
        stores: $checkedConvert(
          'stores',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => PublicStore.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const [],
        ),
        sponsored: $checkedConvert(
          'sponsored',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => PublicStore.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const [],
        ),
      );
      return val;
    }, fieldKeyMap: const {'estimateMinutes': 'estimate_minutes'});

SearchResults _$SearchResultsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SearchResults', json, ($checkedConvert) {
      final val = SearchResults(
        total: $checkedConvert('total', (v) => (v as num?)?.toInt() ?? 0),
        products: $checkedConvert(
          'products',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const [],
        ),
        stores: $checkedConvert(
          'stores',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => PublicStore.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const [],
        ),
        fuzzy: $checkedConvert('fuzzy', (v) => v as bool? ?? false),
      );
      return val;
    });

PublicStoreCategory _$PublicStoreCategoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublicStoreCategory', json, ($checkedConvert) {
      final val = PublicStoreCategory(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

PublicVariant _$PublicVariantFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublicVariant', json, ($checkedConvert) {
      final val = PublicVariant(
        id: $checkedConvert('id', (v) => v as String),
        priceMinor: $checkedConvert('price_minor', (v) => minorFromJson(v)),
        label: $checkedConvert('label', (v) => v as String?),
        available: $checkedConvert('available', (v) => v as bool? ?? true),
      );
      return val;
    }, fieldKeyMap: const {'priceMinor': 'price_minor'});

ZoneMatch _$ZoneMatchFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ZoneMatch',
  json,
  ($checkedConvert) {
    final val = ZoneMatch(
      zoneId: $checkedConvert('zone_id', (v) => v as String),
      zoneName: $checkedConvert('zone_name', (v) => v as String),
      cityId: $checkedConvert('city_id', (v) => v as String),
      cityName: $checkedConvert('city_name', (v) => v as String),
      countryCode: $checkedConvert('country_code', (v) => v as String),
      distanceM: $checkedConvert('distance_m', (v) => (v as num).toInt()),
      covered: $checkedConvert('covered', (v) => v as bool? ?? true),
    );
    return val;
  },
  fieldKeyMap: const {
    'zoneId': 'zone_id',
    'zoneName': 'zone_name',
    'cityId': 'city_id',
    'cityName': 'city_name',
    'countryCode': 'country_code',
    'distanceM': 'distance_m',
  },
);
