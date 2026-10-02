// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PickupAddress _$PickupAddressFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PickupAddress', json, ($checkedConvert) {
      final val = PickupAddress(
        address: $checkedConvert('address', (v) => v as String),
        landmark: $checkedConvert('landmark', (v) => v as String?),
        latitude: $checkedConvert('latitude', (v) => (v as num?)?.toDouble()),
        longitude: $checkedConvert('longitude', (v) => (v as num?)?.toDouble()),
        contactPhone: $checkedConvert('contact_phone', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'contactPhone': 'contact_phone'});

StoreHours _$StoreHoursFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StoreHours', json, ($checkedConvert) {
      final val = StoreHours(
        weekday: $checkedConvert('weekday', (v) => (v as num).toInt()),
        opensAt: $checkedConvert('opens_at', (v) => v as String),
        closesAt: $checkedConvert('closes_at', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'opensAt': 'opens_at', 'closesAt': 'closes_at'});

Map<String, dynamic> _$StoreHoursToJson(StoreHours instance) =>
    <String, dynamic>{
      'weekday': instance.weekday,
      'opens_at': instance.opensAt,
      'closes_at': instance.closesAt,
    };

MyStore _$MyStoreFromJson(Map<String, dynamic> json) => $checkedCreate(
  'MyStore',
  json,
  ($checkedConvert) {
    final val = MyStore(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$StoreStatusEnumMap, v),
      ),
      isOpen: $checkedConvert('is_open', (v) => v as bool),
      onboardingStep: $checkedConvert(
        'onboarding_step',
        (v) => (v as num).toInt(),
      ),
      prepTimeMinutes: $checkedConvert(
        'prep_time_minutes',
        (v) => (v as num).toInt(),
      ),
      offersPickup: $checkedConvert('offers_pickup', (v) => v as bool),
      description: $checkedConvert('description', (v) => v as String?),
      origin: $checkedConvert('origin', (v) => v as String?),
      zoneId: $checkedConvert('zone_id', (v) => v as String?),
      countryCode: $checkedConvert('country_code', (v) => v as String?),
      currencyCode: $checkedConvert('currency_code', (v) => v as String?),
      mainCategoryId: $checkedConvert('main_category_id', (v) => v as String?),
      deliveryFeeMinor: $checkedConvert(
        'delivery_fee_minor',
        (v) => nullableMinorFromJson(v),
      ),
      pickupAddress: $checkedConvert(
        'pickup_address',
        (v) => v == null
            ? null
            : PickupAddress.fromJson(v as Map<String, dynamic>),
      ),
      deliveryZoneIds: $checkedConvert(
        'delivery_zone_ids',
        (v) =>
            (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      ),
      paymentMethodIds: $checkedConvert(
        'payment_method_ids',
        (v) =>
            (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      ),
      hours: $checkedConvert(
        'hours',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => StoreHours.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      ),
      missing: $checkedConvert(
        'missing',
        (v) =>
            (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'isOpen': 'is_open',
    'onboardingStep': 'onboarding_step',
    'prepTimeMinutes': 'prep_time_minutes',
    'offersPickup': 'offers_pickup',
    'zoneId': 'zone_id',
    'countryCode': 'country_code',
    'currencyCode': 'currency_code',
    'mainCategoryId': 'main_category_id',
    'deliveryFeeMinor': 'delivery_fee_minor',
    'pickupAddress': 'pickup_address',
    'deliveryZoneIds': 'delivery_zone_ids',
    'paymentMethodIds': 'payment_method_ids',
  },
);

const _$StoreStatusEnumMap = {
  StoreStatus.draft: 'draft',
  StoreStatus.active: 'active',
  StoreStatus.suspended: 'suspended',
};
