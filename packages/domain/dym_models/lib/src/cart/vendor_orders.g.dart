// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_orders.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorOrderDelivery _$VendorOrderDeliveryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('VendorOrderDelivery', json, ($checkedConvert) {
      final val = VendorOrderDelivery(
        zoneName: $checkedConvert('zone_name', (v) => v as String?),
        cityName: $checkedConvert('city_name', (v) => v as String?),
        landmark: $checkedConvert('landmark', (v) => v as String?),
        phone: $checkedConvert('phone', (v) => v as String?),
        latitude: $checkedConvert('latitude', (v) => (v as num?)?.toDouble()),
        longitude: $checkedConvert('longitude', (v) => (v as num?)?.toDouble()),
      );
      return val;
    }, fieldKeyMap: const {'zoneName': 'zone_name', 'cityName': 'city_name'});

VendorOrderPayment _$VendorOrderPaymentFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorOrderPayment',
      json,
      ($checkedConvert) {
        final val = VendorOrderPayment(
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(
              _$PaymentAttemptStatusEnumMap,
              v,
              unknownValue: PaymentAttemptStatus.unknown,
            ),
          ),
          providerCode: $checkedConvert('provider_code', (v) => v as String),
          amountMinor: $checkedConvert('amount_minor', (v) => minorFromJson(v)),
          reference: $checkedConvert('reference', (v) => v as String),
          completedAt: $checkedConvert(
            'completed_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'providerCode': 'provider_code',
        'amountMinor': 'amount_minor',
        'completedAt': 'completed_at',
      },
    );

const _$PaymentAttemptStatusEnumMap = {
  PaymentAttemptStatus.pending: 'pending',
  PaymentAttemptStatus.succeeded: 'succeeded',
  PaymentAttemptStatus.failed: 'failed',
  PaymentAttemptStatus.cancelled: 'cancelled',
  PaymentAttemptStatus.unknown: 'unknown',
};

VendorOrder _$VendorOrderFromJson(Map<String, dynamic> json) => $checkedCreate(
  'VendorOrder',
  json,
  ($checkedConvert) {
    final val = VendorOrder(
      id: $checkedConvert('id', (v) => v as String),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(
          _$OrderStatusEnumMap,
          v,
          unknownValue: OrderStatus.unknown,
        ),
      ),
      fulfillment: $checkedConvert(
        'fulfillment',
        (v) => $enumDecode(_$FulfillmentEnumMap, v),
      ),
      currencyCode: $checkedConvert('currency_code', (v) => v as String),
      subtotalMinor: $checkedConvert('subtotal_minor', (v) => minorFromJson(v)),
      deliveryFeeMinor: $checkedConvert(
        'delivery_fee_minor',
        (v) => minorFromJson(v),
      ),
      totalMinor: $checkedConvert('total_minor', (v) => minorFromJson(v)),
      paymentStatus: $checkedConvert(
        'payment_status',
        (v) => $enumDecode(
          _$PaymentStatusEnumMap,
          v,
          unknownValue: PaymentStatus.unknown,
        ),
      ),
      paymentMethod: $checkedConvert(
        'payment_method',
        (v) => PaymentMethod.fromJson(v as Map<String, dynamic>),
      ),
      itemCount: $checkedConvert(
        'item_count',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      customerFirstName: $checkedConvert(
        'customer_first_name',
        (v) => v as String?,
      ),
      zoneName: $checkedConvert('zone_name', (v) => v as String?),
      substitutionAllowed: $checkedConvert(
        'substitution_allowed',
        (v) => v as bool? ?? true,
      ),
      items: $checkedConvert(
        'items',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      ),
      delivery: $checkedConvert(
        'delivery',
        (v) => v == null
            ? null
            : VendorOrderDelivery.fromJson(v as Map<String, dynamic>),
      ),
      payment: $checkedConvert(
        'payment',
        (v) => v == null
            ? null
            : VendorOrderPayment.fromJson(v as Map<String, dynamic>),
      ),
      etaAt: $checkedConvert(
        'eta_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      acceptedAt: $checkedConvert(
        'accepted_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      deliveredAt: $checkedConvert(
        'delivered_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      cashCollectedAt: $checkedConvert(
        'cash_collected_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      statusReason: $checkedConvert(
        'status_reason',
        (v) => $enumDecodeNullable(
          _$RefusalReasonEnumMap,
          v,
          unknownValue: RefusalReason.unknown,
        ),
      ),
      statusNote: $checkedConvert('status_note', (v) => v as String?),
      refundDue: $checkedConvert('refund_due', (v) => v as bool? ?? false),
      history: $checkedConvert(
        'history',
        (v) =>
            (v as List<dynamic>?)
                ?.map(
                  (e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
      ),
      nextStatuses: $checkedConvert(
        'next_statuses',
        (v) =>
            (v as List<dynamic>?)
                ?.map(
                  (e) => $enumDecode(
                    _$OrderStatusEnumMap,
                    e,
                    unknownValue: OrderStatus.unknown,
                  ),
                )
                .toList() ??
            const [],
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'createdAt': 'created_at',
    'currencyCode': 'currency_code',
    'subtotalMinor': 'subtotal_minor',
    'deliveryFeeMinor': 'delivery_fee_minor',
    'totalMinor': 'total_minor',
    'paymentStatus': 'payment_status',
    'paymentMethod': 'payment_method',
    'itemCount': 'item_count',
    'customerFirstName': 'customer_first_name',
    'zoneName': 'zone_name',
    'substitutionAllowed': 'substitution_allowed',
    'etaAt': 'eta_at',
    'acceptedAt': 'accepted_at',
    'deliveredAt': 'delivered_at',
    'cashCollectedAt': 'cash_collected_at',
    'statusReason': 'status_reason',
    'statusNote': 'status_note',
    'refundDue': 'refund_due',
    'nextStatuses': 'next_statuses',
  },
);

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.accepted: 'accepted',
  OrderStatus.preparing: 'preparing',
  OrderStatus.ready: 'ready',
  OrderStatus.outForDelivery: 'out_for_delivery',
  OrderStatus.delivered: 'delivered',
  OrderStatus.refused: 'refused',
  OrderStatus.cancelled: 'cancelled',
  OrderStatus.unknown: 'unknown',
};

const _$FulfillmentEnumMap = {
  Fulfillment.delivery: 'delivery',
  Fulfillment.pickup: 'pickup',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.cashOnDelivery: 'cash_on_delivery',
  PaymentStatus.awaitingPayment: 'awaiting_payment',
  PaymentStatus.paid: 'paid',
  PaymentStatus.failed: 'failed',
  PaymentStatus.unknown: 'unknown',
};

const _$RefusalReasonEnumMap = {
  RefusalReason.outOfStock: 'out_of_stock',
  RefusalReason.tooBusy: 'too_busy',
  RefusalReason.areaNotServed: 'area_not_served',
  RefusalReason.other: 'other',
  RefusalReason.unknown: 'unknown',
};
