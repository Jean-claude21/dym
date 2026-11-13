// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_tracking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderCourier _$OrderCourierFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OrderCourier', json, ($checkedConvert) {
      final val = OrderCourier(
        name: $checkedConvert('name', (v) => v as String),
        phone: $checkedConvert('phone', (v) => v as String),
        assignedAt: $checkedConvert(
          'assigned_at',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        isDym: $checkedConvert('is_dym', (v) => v as bool? ?? false),
      );
      return val;
    }, fieldKeyMap: const {'assignedAt': 'assigned_at', 'isDym': 'is_dym'});

OrderStatusEvent _$OrderStatusEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OrderStatusEvent',
      json,
      ($checkedConvert) {
        final val = OrderStatusEvent(
          toStatus: $checkedConvert(
            'to_status',
            (v) => $enumDecode(
              _$OrderStatusEnumMap,
              v,
              unknownValue: OrderStatus.unknown,
            ),
          ),
          actorRole: $checkedConvert('actor_role', (v) => v as String),
          occurredAt: $checkedConvert(
            'occurred_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'toStatus': 'to_status',
        'actorRole': 'actor_role',
        'occurredAt': 'occurred_at',
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

CustomerOrder _$CustomerOrderFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CustomerOrder',
      json,
      ($checkedConvert) {
        final val = CustomerOrder(
          id: $checkedConvert('id', (v) => v as String),
          purchaseId: $checkedConvert('purchase_id', (v) => v as String),
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
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          currencyCode: $checkedConvert('currency_code', (v) => v as String),
          totalMinor: $checkedConvert('total_minor', (v) => minorFromJson(v)),
          store: $checkedConvert(
            'store',
            (v) => OrderStoreRef.fromJson(v as Map<String, dynamic>),
          ),
          subtotalMinor: $checkedConvert(
            'subtotal_minor',
            (v) => v == null ? 0 : minorFromJson(v),
          ),
          deliveryFeeMinor: $checkedConvert(
            'delivery_fee_minor',
            (v) => v == null ? 0 : minorFromJson(v),
          ),
          itemCount: $checkedConvert(
            'item_count',
            (v) => (v as num?)?.toInt() ?? 0,
          ),
          etaAt: $checkedConvert(
            'eta_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          scheduledStart: $checkedConvert(
            'scheduled_start',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          scheduledEnd: $checkedConvert(
            'scheduled_end',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          adjustments: $checkedConvert(
            'adjustments',
            (v) => v == null ? const [] : adjustmentsFromJson(v),
          ),
          acceptedAt: $checkedConvert(
            'accepted_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          deliveredAt: $checkedConvert(
            'delivered_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          cancelledAt: $checkedConvert(
            'cancelled_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          refusedAt: $checkedConvert(
            'refused_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          cancelledBy: $checkedConvert('cancelled_by', (v) => v as String?),
          statusReason: $checkedConvert(
            'status_reason',
            (v) => $enumDecodeNullable(
              _$RefusalReasonEnumMap,
              v,
              unknownValue: RefusalReason.unknown,
            ),
          ),
          cashCollectedAt: $checkedConvert(
            'cash_collected_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          refundDue: $checkedConvert('refund_due', (v) => v as bool? ?? false),
          paymentStatus: $checkedConvert(
            'payment_status',
            (v) =>
                $enumDecodeNullable(
                  _$PaymentStatusEnumMap,
                  v,
                  unknownValue: PaymentStatus.unknown,
                ) ??
                PaymentStatus.cashOnDelivery,
          ),
          paymentMethod: $checkedConvert(
            'payment_method',
            (v) => v == null
                ? null
                : PaymentMethod.fromJson(v as Map<String, dynamic>),
          ),
          items: $checkedConvert(
            'items',
            (v) =>
                (v as List<dynamic>?)
                    ?.map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                const [],
          ),
          history: $checkedConvert(
            'history',
            (v) =>
                (v as List<dynamic>?)
                    ?.map(
                      (e) =>
                          OrderStatusEvent.fromJson(e as Map<String, dynamic>),
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
          address: $checkedConvert(
            'address',
            (v) => v == null
                ? null
                : PurchaseAddress.fromJson(v as Map<String, dynamic>),
          ),
          courier: $checkedConvert(
            'courier',
            (v) => v == null
                ? null
                : OrderCourier.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'purchaseId': 'purchase_id',
        'createdAt': 'created_at',
        'currencyCode': 'currency_code',
        'totalMinor': 'total_minor',
        'subtotalMinor': 'subtotal_minor',
        'deliveryFeeMinor': 'delivery_fee_minor',
        'itemCount': 'item_count',
        'etaAt': 'eta_at',
        'scheduledStart': 'scheduled_start',
        'scheduledEnd': 'scheduled_end',
        'acceptedAt': 'accepted_at',
        'deliveredAt': 'delivered_at',
        'cancelledAt': 'cancelled_at',
        'refusedAt': 'refused_at',
        'cancelledBy': 'cancelled_by',
        'statusReason': 'status_reason',
        'cashCollectedAt': 'cash_collected_at',
        'refundDue': 'refund_due',
        'paymentStatus': 'payment_status',
        'paymentMethod': 'payment_method',
        'nextStatuses': 'next_statuses',
      },
    );

const _$FulfillmentEnumMap = {
  Fulfillment.delivery: 'delivery',
  Fulfillment.pickup: 'pickup',
};

const _$RefusalReasonEnumMap = {
  RefusalReason.outOfStock: 'out_of_stock',
  RefusalReason.tooBusy: 'too_busy',
  RefusalReason.areaNotServed: 'area_not_served',
  RefusalReason.other: 'other',
  RefusalReason.noResponse: 'no_response',
  RefusalReason.unknown: 'unknown',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.cashOnDelivery: 'cash_on_delivery',
  PaymentStatus.awaitingPayment: 'awaiting_payment',
  PaymentStatus.paid: 'paid',
  PaymentStatus.failed: 'failed',
  PaymentStatus.unknown: 'unknown',
};

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AppNotification',
      json,
      ($checkedConvert) {
        final val = AppNotification(
          id: $checkedConvert('id', (v) => v as String),
          kind: $checkedConvert('kind', (v) => v as String),
          category: $checkedConvert(
            'category',
            (v) => $enumDecode(
              _$NotificationCategoryEnumMap,
              v,
              unknownValue: NotificationCategory.unknown,
            ),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          orderId: $checkedConvert('order_id', (v) => v as String?),
          purchaseId: $checkedConvert('purchase_id', (v) => v as String?),
          params: $checkedConvert(
            'params',
            (v) => v as Map<String, dynamic>? ?? const {},
          ),
          readAt: $checkedConvert(
            'read_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'orderId': 'order_id',
        'purchaseId': 'purchase_id',
        'readAt': 'read_at',
      },
    );

const _$NotificationCategoryEnumMap = {
  NotificationCategory.orders: 'orders',
  NotificationCategory.payments: 'payments',
  NotificationCategory.messages: 'messages',
  NotificationCategory.promotions: 'promotions',
  NotificationCategory.unknown: 'unknown',
};

NotificationPreference _$NotificationPreferenceFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NotificationPreference', json, ($checkedConvert) {
  final val = NotificationPreference(
    category: $checkedConvert(
      'category',
      (v) => $enumDecode(
        _$NotificationCategoryEnumMap,
        v,
        unknownValue: NotificationCategory.unknown,
      ),
    ),
    pushEnabled: $checkedConvert('push_enabled', (v) => v as bool),
  );
  return val;
}, fieldKeyMap: const {'pushEnabled': 'push_enabled'});
