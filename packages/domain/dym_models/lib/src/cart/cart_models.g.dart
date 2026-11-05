// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartLine _$CartLineFromJson(Map<String, dynamic> json) => $checkedCreate(
  'CartLine',
  json,
  ($checkedConvert) {
    final val = CartLine(
      variantId: $checkedConvert('variant_id', (v) => v as String),
      productId: $checkedConvert('product_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      quantity: $checkedConvert('quantity', (v) => (v as num).toInt()),
      unitPriceMinor: $checkedConvert(
        'unit_price_minor',
        (v) => minorFromJson(v),
      ),
      amountMinor: $checkedConvert('amount_minor', (v) => minorFromJson(v)),
      variantLabel: $checkedConvert('variant_label', (v) => v as String?),
      unitLabel: $checkedConvert(
        'unit_label',
        (v) => const NullableLocalizedTextConverter().fromJson(v),
      ),
      photoKey: $checkedConvert('photo_key', (v) => v as String?),
      stockQuantity: $checkedConvert(
        'stock_quantity',
        (v) => (v as num?)?.toInt(),
      ),
      issues: $checkedConvert(
        'issues',
        (v) =>
            (v as List<dynamic>?)
                ?.map(
                  (e) => $enumDecode(
                    _$CartLineIssueEnumMap,
                    e,
                    unknownValue: CartLineIssue.unknown,
                  ),
                )
                .toList() ??
            const [],
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'variantId': 'variant_id',
    'productId': 'product_id',
    'unitPriceMinor': 'unit_price_minor',
    'amountMinor': 'amount_minor',
    'variantLabel': 'variant_label',
    'unitLabel': 'unit_label',
    'photoKey': 'photo_key',
    'stockQuantity': 'stock_quantity',
  },
);

const _$CartLineIssueEnumMap = {
  CartLineIssue.unavailable: 'unavailable',
  CartLineIssue.stock: 'stock',
  CartLineIssue.priceChanged: 'price_changed',
  CartLineIssue.unknown: 'unknown',
};

CartStoreGroup _$CartStoreGroupFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CartStoreGroup',
      json,
      ($checkedConvert) {
        final val = CartStoreGroup(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          zoneName: $checkedConvert('zone_name', (v) => v as String),
          fulfillment: $checkedConvert(
            'fulfillment',
            (v) => $enumDecode(_$FulfillmentEnumMap, v),
          ),
          subtotalMinor: $checkedConvert(
            'subtotal_minor',
            (v) => minorFromJson(v),
          ),
          deliveryFeeMinor: $checkedConvert(
            'delivery_fee_minor',
            (v) => minorFromJson(v),
          ),
          lines: $checkedConvert(
            'lines',
            (v) => (v as List<dynamic>)
                .map((e) => CartLine.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          origin: $checkedConvert('origin', (v) => v as String?),
          offersPickup: $checkedConvert(
            'offers_pickup',
            (v) => v as bool? ?? false,
          ),
          isOpen: $checkedConvert('is_open', (v) => v as bool? ?? true),
          prepTimeMinutes: $checkedConvert(
            'prep_time_minutes',
            (v) => (v as num?)?.toInt() ?? 0,
          ),
          issues: $checkedConvert(
            'issues',
            (v) =>
                (v as List<dynamic>?)
                    ?.map(
                      (e) => $enumDecode(
                        _$CartStoreIssueEnumMap,
                        e,
                        unknownValue: CartStoreIssue.unknown,
                      ),
                    )
                    .toList() ??
                const [],
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'zoneName': 'zone_name',
        'subtotalMinor': 'subtotal_minor',
        'deliveryFeeMinor': 'delivery_fee_minor',
        'offersPickup': 'offers_pickup',
        'isOpen': 'is_open',
        'prepTimeMinutes': 'prep_time_minutes',
      },
    );

const _$FulfillmentEnumMap = {
  Fulfillment.delivery: 'delivery',
  Fulfillment.pickup: 'pickup',
};

const _$CartStoreIssueEnumMap = {
  CartStoreIssue.suspended: 'suspended',
  CartStoreIssue.closed: 'closed',
  CartStoreIssue.notDelivered: 'not_delivered',
  CartStoreIssue.pickupUnavailable: 'pickup_unavailable',
  CartStoreIssue.paymentNotAccepted: 'payment_not_accepted',
  CartStoreIssue.unknown: 'unknown',
};

CartView _$CartViewFromJson(Map<String, dynamic> json) => $checkedCreate(
  'CartView',
  json,
  ($checkedConvert) {
    final val = CartView(
      countryCode: $checkedConvert('country_code', (v) => v as String?),
      currencyCode: $checkedConvert('currency_code', (v) => v as String?),
      currency: $checkedConvert(
        'currency',
        (v) =>
            v == null ? null : CurrencyInfo.fromJson(v as Map<String, dynamic>),
      ),
      stores: $checkedConvert(
        'stores',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => CartStoreGroup.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      ),
      paymentMethods: $checkedConvert(
        'payment_methods',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      ),
      paymentMethodId: $checkedConvert(
        'payment_method_id',
        (v) => v as String?,
      ),
      itemCount: $checkedConvert(
        'item_count',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      pickupCount: $checkedConvert(
        'pickup_count',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      deliveryMinutes: $checkedConvert(
        'delivery_minutes',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      subtotalMinor: $checkedConvert(
        'subtotal_minor',
        (v) => v == null ? 0 : minorFromJson(v),
      ),
      deliveryFeeMinor: $checkedConvert(
        'delivery_fee_minor',
        (v) => v == null ? 0 : minorFromJson(v),
      ),
      totalMinor: $checkedConvert(
        'total_minor',
        (v) => v == null ? 0 : minorFromJson(v),
      ),
      freeThresholdMinor: $checkedConvert(
        'free_threshold_minor',
        (v) => nullableMinorFromJson(v),
      ),
      remainingForFreeMinor: $checkedConvert(
        'remaining_for_free_minor',
        (v) => nullableMinorFromJson(v),
      ),
      blocking: $checkedConvert('blocking', (v) => v as bool? ?? false),
      addressId: $checkedConvert('address_id', (v) => v as String?),
      zoneId: $checkedConvert('zone_id', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'countryCode': 'country_code',
    'currencyCode': 'currency_code',
    'paymentMethods': 'payment_methods',
    'paymentMethodId': 'payment_method_id',
    'itemCount': 'item_count',
    'pickupCount': 'pickup_count',
    'deliveryMinutes': 'delivery_minutes',
    'subtotalMinor': 'subtotal_minor',
    'deliveryFeeMinor': 'delivery_fee_minor',
    'totalMinor': 'total_minor',
    'freeThresholdMinor': 'free_threshold_minor',
    'remainingForFreeMinor': 'remaining_for_free_minor',
    'addressId': 'address_id',
    'zoneId': 'zone_id',
  },
);

CustomerAddress _$CustomerAddressFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CustomerAddress',
      json,
      ($checkedConvert) {
        final val = CustomerAddress(
          id: $checkedConvert('id', (v) => v as String),
          kind: $checkedConvert(
            'kind',
            (v) => $enumDecode(_$AddressKindEnumMap, v),
          ),
          zoneId: $checkedConvert('zone_id', (v) => v as String),
          zoneName: $checkedConvert('zone_name', (v) => v as String),
          cityName: $checkedConvert('city_name', (v) => v as String),
          landmark: $checkedConvert('landmark', (v) => v as String),
          phone: $checkedConvert('phone', (v) => v as String),
          label: $checkedConvert('label', (v) => v as String?),
          countryCode: $checkedConvert('country_code', (v) => v as String?),
          latitude: $checkedConvert('latitude', (v) => (v as num?)?.toDouble()),
          longitude: $checkedConvert(
            'longitude',
            (v) => (v as num?)?.toDouble(),
          ),
          isDefault: $checkedConvert('is_default', (v) => v as bool? ?? false),
        );
        return val;
      },
      fieldKeyMap: const {
        'zoneId': 'zone_id',
        'zoneName': 'zone_name',
        'cityName': 'city_name',
        'countryCode': 'country_code',
        'isDefault': 'is_default',
      },
    );

const _$AddressKindEnumMap = {
  AddressKind.home: 'home',
  AddressKind.work: 'work',
  AddressKind.other: 'other',
};

PurchaseAddress _$PurchaseAddressFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PurchaseAddress', json, ($checkedConvert) {
      final val = PurchaseAddress(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$AddressKindEnumMap, v),
        ),
        zoneName: $checkedConvert('zone_name', (v) => v as String),
        cityName: $checkedConvert('city_name', (v) => v as String),
        landmark: $checkedConvert('landmark', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'zoneName': 'zone_name', 'cityName': 'city_name'});

OrderStoreRef _$OrderStoreRefFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OrderStoreRef', json, ($checkedConvert) {
      final val = OrderStoreRef(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        origin: $checkedConvert('origin', (v) => v as String?),
      );
      return val;
    });

OrderLine _$OrderLineFromJson(Map<String, dynamic> json) => $checkedCreate(
  'OrderLine',
  json,
  ($checkedConvert) {
    final val = OrderLine(
      productId: $checkedConvert('product_id', (v) => v as String),
      variantId: $checkedConvert('variant_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      unitPriceMinor: $checkedConvert(
        'unit_price_minor',
        (v) => minorFromJson(v),
      ),
      quantity: $checkedConvert('quantity', (v) => (v as num).toInt()),
      amountMinor: $checkedConvert('amount_minor', (v) => minorFromJson(v)),
      variantLabel: $checkedConvert('variant_label', (v) => v as String?),
      unitLabel: $checkedConvert(
        'unit_label',
        (v) => const NullableLocalizedTextConverter().fromJson(v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'productId': 'product_id',
    'variantId': 'variant_id',
    'unitPriceMinor': 'unit_price_minor',
    'amountMinor': 'amount_minor',
    'variantLabel': 'variant_label',
    'unitLabel': 'unit_label',
  },
);

PurchaseOrder _$PurchaseOrderFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PurchaseOrder',
      json,
      ($checkedConvert) {
        final val = PurchaseOrder(
          id: $checkedConvert('id', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          fulfillment: $checkedConvert(
            'fulfillment',
            (v) => $enumDecode(_$FulfillmentEnumMap, v),
          ),
          store: $checkedConvert(
            'store',
            (v) => OrderStoreRef.fromJson(v as Map<String, dynamic>),
          ),
          subtotalMinor: $checkedConvert(
            'subtotal_minor',
            (v) => minorFromJson(v),
          ),
          deliveryFeeMinor: $checkedConvert(
            'delivery_fee_minor',
            (v) => minorFromJson(v),
          ),
          totalMinor: $checkedConvert('total_minor', (v) => minorFromJson(v)),
          itemCount: $checkedConvert(
            'item_count',
            (v) => (v as num?)?.toInt() ?? 0,
          ),
          items: $checkedConvert(
            'items',
            (v) =>
                (v as List<dynamic>?)
                    ?.map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                const [],
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'subtotalMinor': 'subtotal_minor',
        'deliveryFeeMinor': 'delivery_fee_minor',
        'totalMinor': 'total_minor',
        'itemCount': 'item_count',
      },
    );

Purchase _$PurchaseFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Purchase',
  json,
  ($checkedConvert) {
    final val = Purchase(
      id: $checkedConvert('id', (v) => v as String),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      currencyCode: $checkedConvert('currency_code', (v) => v as String),
      paymentMethod: $checkedConvert(
        'payment_method',
        (v) => PaymentMethod.fromJson(v as Map<String, dynamic>),
      ),
      subtotalMinor: $checkedConvert('subtotal_minor', (v) => minorFromJson(v)),
      deliveryFeeMinor: $checkedConvert(
        'delivery_fee_minor',
        (v) => minorFromJson(v),
      ),
      totalMinor: $checkedConvert('total_minor', (v) => minorFromJson(v)),
      orders: $checkedConvert(
        'orders',
        (v) => (v as List<dynamic>)
            .map((e) => PurchaseOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      countryCode: $checkedConvert('country_code', (v) => v as String?),
      address: $checkedConvert(
        'address',
        (v) => v == null
            ? null
            : PurchaseAddress.fromJson(v as Map<String, dynamic>),
      ),
      substitutionAllowed: $checkedConvert(
        'substitution_allowed',
        (v) => v as bool? ?? true,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'createdAt': 'created_at',
    'currencyCode': 'currency_code',
    'paymentMethod': 'payment_method',
    'subtotalMinor': 'subtotal_minor',
    'deliveryFeeMinor': 'delivery_fee_minor',
    'totalMinor': 'total_minor',
    'countryCode': 'country_code',
    'substitutionAllowed': 'substitution_allowed',
  },
);
