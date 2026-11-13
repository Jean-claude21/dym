// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminOrderRow _$AdminOrderRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminOrderRow',
      json,
      ($checkedConvert) {
        final val = AdminOrderRow(
          id: $checkedConvert('id', (v) => v as String),
          reference: $checkedConvert('reference', (v) => v as String),
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
          paymentStatus: $checkedConvert(
            'payment_status',
            (v) => $enumDecode(
              _$PaymentStatusEnumMap,
              v,
              unknownValue: PaymentStatus.unknown,
            ),
          ),
          storeId: $checkedConvert('store_id', (v) => v as String),
          storeName: $checkedConvert('store_name', (v) => v as String),
          totalMinor: $checkedConvert('total_minor', (v) => minorFromJson(v)),
          currencyCode: $checkedConvert('currency_code', (v) => v as String),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          lastChangeAt: $checkedConvert(
            'last_change_at',
            (v) => DateTime.parse(v as String),
          ),
          customerFirstName: $checkedConvert(
            'customer_first_name',
            (v) => v as String?,
          ),
          stuck: $checkedConvert('stuck', (v) => v as bool? ?? false),
          refundDue: $checkedConvert('refund_due', (v) => v as bool? ?? false),
          hasOpenDispute: $checkedConvert(
            'has_open_dispute',
            (v) => v as bool? ?? false,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'paymentStatus': 'payment_status',
        'storeId': 'store_id',
        'storeName': 'store_name',
        'totalMinor': 'total_minor',
        'currencyCode': 'currency_code',
        'createdAt': 'created_at',
        'lastChangeAt': 'last_change_at',
        'customerFirstName': 'customer_first_name',
        'refundDue': 'refund_due',
        'hasOpenDispute': 'has_open_dispute',
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

AdminOrderPage _$AdminOrderPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminOrderPage', json, ($checkedConvert) {
      final val = AdminOrderPage(
        total: $checkedConvert('total', (v) => (v as num).toInt()),
        stuckCount: $checkedConvert('stuck_count', (v) => (v as num).toInt()),
        orders: $checkedConvert(
          'orders',
          (v) => (v as List<dynamic>)
              .map((e) => AdminOrderRow.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'stuckCount': 'stuck_count'});

AdminTimelineEvent _$AdminTimelineEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminTimelineEvent',
      json,
      ($checkedConvert) {
        final val = AdminTimelineEvent(
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
          fromStatus: $checkedConvert(
            'from_status',
            (v) => $enumDecodeNullable(
              _$OrderStatusEnumMap,
              v,
              unknownValue: OrderStatus.unknown,
            ),
          ),
          reason: $checkedConvert('reason', (v) => v as String?),
          note: $checkedConvert('note', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'toStatus': 'to_status',
        'actorRole': 'actor_role',
        'occurredAt': 'occurred_at',
        'fromStatus': 'from_status',
      },
    );

AdminPayment _$AdminPaymentFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminPayment',
      json,
      ($checkedConvert) {
        final val = AdminPayment(
          id: $checkedConvert('id', (v) => v as String),
          reference: $checkedConvert('reference', (v) => v as String),
          providerCode: $checkedConvert('provider_code', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          amountMinor: $checkedConvert('amount_minor', (v) => minorFromJson(v)),
          currencyCode: $checkedConvert('currency_code', (v) => v as String),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          lastError: $checkedConvert('last_error', (v) => v as String?),
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
        'currencyCode': 'currency_code',
        'createdAt': 'created_at',
        'lastError': 'last_error',
        'completedAt': 'completed_at',
      },
    );

AdminRefund _$AdminRefundFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AdminRefund',
  json,
  ($checkedConvert) {
    final val = AdminRefund(
      id: $checkedConvert('id', (v) => v as String),
      method: $checkedConvert('method', (v) => v as String),
      amountMinor: $checkedConvert('amount_minor', (v) => minorFromJson(v)),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(
          _$RefundStatusEnumMap,
          v,
          unknownValue: RefundStatus.unknown,
        ),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      orderId: $checkedConvert('order_id', (v) => v as String?),
      orderReference: $checkedConvert('order_reference', (v) => v as String?),
      disputeId: $checkedConvert('dispute_id', (v) => v as String?),
      reason: $checkedConvert('reason', (v) => v as String?),
      providerCode: $checkedConvert('provider_code', (v) => v as String?),
      currencyCode: $checkedConvert('currency_code', (v) => v as String?),
      lastError: $checkedConvert('last_error', (v) => v as String?),
      storeName: $checkedConvert('store_name', (v) => v as String?),
      completedAt: $checkedConvert(
        'completed_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'amountMinor': 'amount_minor',
    'createdAt': 'created_at',
    'orderId': 'order_id',
    'orderReference': 'order_reference',
    'disputeId': 'dispute_id',
    'providerCode': 'provider_code',
    'currencyCode': 'currency_code',
    'lastError': 'last_error',
    'storeName': 'store_name',
    'completedAt': 'completed_at',
  },
);

const _$RefundStatusEnumMap = {
  RefundStatus.pending: 'pending',
  RefundStatus.processing: 'processing',
  RefundStatus.succeeded: 'succeeded',
  RefundStatus.failed: 'failed',
  RefundStatus.unknown: 'unknown',
};

AdminDisputeRef _$AdminDisputeRefFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminDisputeRef', json, ($checkedConvert) {
      final val = AdminDisputeRef(
        id: $checkedConvert('id', (v) => v as String),
        status: $checkedConvert('status', (v) => v as String),
        reason: $checkedConvert(
          'reason',
          (v) => $enumDecode(
            _$DisputeReasonEnumMap,
            v,
            unknownValue: DisputeReason.unknown,
          ),
        ),
        createdAt: $checkedConvert(
          'created_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'createdAt': 'created_at'});

const _$DisputeReasonEnumMap = {
  DisputeReason.missingItem: 'missing_item',
  DisputeReason.wrongItem: 'wrong_item',
  DisputeReason.damaged: 'damaged',
  DisputeReason.quality: 'quality',
  DisputeReason.notDelivered: 'not_delivered',
  DisputeReason.other: 'other',
  DisputeReason.unknown: 'unknown',
};

AdminAuditEntry _$AdminAuditEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminAuditEntry',
      json,
      ($checkedConvert) {
        final val = AdminAuditEntry(
          action: $checkedConvert('action', (v) => v as String),
          occurredAt: $checkedConvert(
            'occurred_at',
            (v) => DateTime.parse(v as String),
          ),
          id: $checkedConvert('id', (v) => (v as num?)?.toInt()),
          actorId: $checkedConvert('actor_id', (v) => v as String?),
          actorFirstName: $checkedConvert(
            'actor_first_name',
            (v) => v as String?,
          ),
          entityType: $checkedConvert('entity_type', (v) => v as String?),
          entityId: $checkedConvert('entity_id', (v) => v as String?),
          before: $checkedConvert('before', (v) => v as Map<String, dynamic>?),
          after: $checkedConvert('after', (v) => v as Map<String, dynamic>?),
          reason: $checkedConvert('reason', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'occurredAt': 'occurred_at',
        'actorId': 'actor_id',
        'actorFirstName': 'actor_first_name',
        'entityType': 'entity_type',
        'entityId': 'entity_id',
      },
    );

AdminCustomer _$AdminCustomerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminCustomer', json, ($checkedConvert) {
      final val = AdminCustomer(
        firstName: $checkedConvert('first_name', (v) => v as String?),
        phone: $checkedConvert('phone', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'firstName': 'first_name'});

AdminOrder _$AdminOrderFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AdminOrder',
  json,
  ($checkedConvert) {
    final val = AdminOrder(
      order: $checkedConvert(
        'order',
        (v) => CustomerOrder.fromJson(v as Map<String, dynamic>),
        readValue: _self,
      ),
      reference: $checkedConvert('reference', (v) => v as String),
      storeName: $checkedConvert('store_name', (v) => v as String),
      lastChangeAt: $checkedConvert(
        'last_change_at',
        (v) => DateTime.parse(v as String),
      ),
      customer: $checkedConvert(
        'customer',
        (v) => v == null
            ? const AdminCustomer()
            : AdminCustomer.fromJson(v as Map<String, dynamic>),
      ),
      stuck: $checkedConvert('stuck', (v) => v as bool? ?? false),
      hasOpenDispute: $checkedConvert(
        'has_open_dispute',
        (v) => v as bool? ?? false,
      ),
      statusNote: $checkedConvert('status_note', (v) => v as String?),
      timeline: $checkedConvert(
        'timeline',
        (v) =>
            (v as List<dynamic>?)
                ?.map(
                  (e) => AdminTimelineEvent.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
      ),
      payments: $checkedConvert(
        'payments',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => AdminPayment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      ),
      refunds: $checkedConvert(
        'refunds',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => AdminRefund.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      ),
      dispute: $checkedConvert(
        'dispute',
        (v) => v == null
            ? null
            : AdminDisputeRef.fromJson(v as Map<String, dynamic>),
      ),
      courier: $checkedConvert(
        'courier',
        (v) =>
            v == null ? null : OrderCourier.fromJson(v as Map<String, dynamic>),
      ),
      audit: $checkedConvert(
        'audit',
        (v) =>
            (v as List<dynamic>?)
                ?.map(
                  (e) => AdminAuditEntry.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
      ),
      forceableStatuses: $checkedConvert(
        'forceable_statuses',
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
      canCancel: $checkedConvert('can_cancel', (v) => v as bool? ?? false),
      canAssignCourier: $checkedConvert(
        'can_assign_courier',
        (v) => v as bool? ?? false,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'storeName': 'store_name',
    'lastChangeAt': 'last_change_at',
    'hasOpenDispute': 'has_open_dispute',
    'statusNote': 'status_note',
    'forceableStatuses': 'forceable_statuses',
    'canCancel': 'can_cancel',
    'canAssignCourier': 'can_assign_courier',
  },
);

AdminPendingPayment _$AdminPendingPaymentFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminPendingPayment',
      json,
      ($checkedConvert) {
        final val = AdminPendingPayment(
          id: $checkedConvert('id', (v) => v as String),
          reference: $checkedConvert('reference', (v) => v as String),
          providerCode: $checkedConvert('provider_code', (v) => v as String),
          amountMinor: $checkedConvert('amount_minor', (v) => minorFromJson(v)),
          currencyCode: $checkedConvert('currency_code', (v) => v as String),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          orders: $checkedConvert(
            'orders',
            (v) =>
                (v as List<dynamic>?)
                    ?.map(
                      (e) => AdminOrderRef.fromJson(e as Map<String, dynamic>),
                    )
                    .toList() ??
                const [],
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'providerCode': 'provider_code',
        'amountMinor': 'amount_minor',
        'currencyCode': 'currency_code',
        'createdAt': 'created_at',
      },
    );

AdminOrderRef _$AdminOrderRefFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminOrderRef', json, ($checkedConvert) {
      final val = AdminOrderRef(
        id: $checkedConvert('id', (v) => v as String),
        reference: $checkedConvert('reference', (v) => v as String),
        storeName: $checkedConvert('store_name', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'storeName': 'store_name'});

AdminDisputeRow _$AdminDisputeRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminDisputeRow',
      json,
      ($checkedConvert) {
        final val = AdminDisputeRow(
          id: $checkedConvert('id', (v) => v as String),
          orderId: $checkedConvert('order_id', (v) => v as String),
          reason: $checkedConvert(
            'reason',
            (v) => $enumDecode(
              _$DisputeReasonEnumMap,
              v,
              unknownValue: DisputeReason.unknown,
            ),
          ),
          status: $checkedConvert('status', (v) => v as String),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          storeName: $checkedConvert('store_name', (v) => v as String),
          orderTotalMinor: $checkedConvert(
            'order_total_minor',
            (v) => minorFromJson(v),
          ),
          currencyCode: $checkedConvert('currency_code', (v) => v as String),
          customerFirstName: $checkedConvert(
            'customer_first_name',
            (v) => v as String?,
          ),
          messageCount: $checkedConvert(
            'message_count',
            (v) => (v as num?)?.toInt() ?? 0,
          ),
          lastMessageAt: $checkedConvert(
            'last_message_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'orderId': 'order_id',
        'createdAt': 'created_at',
        'storeName': 'store_name',
        'orderTotalMinor': 'order_total_minor',
        'currencyCode': 'currency_code',
        'customerFirstName': 'customer_first_name',
        'messageCount': 'message_count',
        'lastMessageAt': 'last_message_at',
      },
    );

AdminDispute _$AdminDisputeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminDispute', json, ($checkedConvert) {
      final val = AdminDispute(
        dispute: $checkedConvert(
          'dispute',
          (v) => Dispute.fromJson(v as Map<String, dynamic>),
          readValue: _self,
        ),
        order: $checkedConvert(
          'order',
          (v) => CustomerOrder.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

AdminStoreRow _$AdminStoreRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminStoreRow',
      json,
      ($checkedConvert) {
        final val = AdminStoreRow(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(
              _$AdminStoreStatusEnumMap,
              v,
              unknownValue: AdminStoreStatus.unknown,
            ),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          isOpen: $checkedConvert('is_open', (v) => v as bool? ?? false),
          origin: $checkedConvert('origin', (v) => v as String?),
          originLabel: $checkedConvert(
            'origin_label',
            (v) => const NullableLocalizedTextConverter().fromJson(v),
          ),
          ownerFirstName: $checkedConvert(
            'owner_first_name',
            (v) => v as String?,
          ),
          zoneName: $checkedConvert('zone_name', (v) => v as String?),
          cityName: $checkedConvert('city_name', (v) => v as String?),
          countryCode: $checkedConvert('country_code', (v) => v as String?),
          publishedAt: $checkedConvert(
            'published_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'isOpen': 'is_open',
        'originLabel': 'origin_label',
        'ownerFirstName': 'owner_first_name',
        'zoneName': 'zone_name',
        'cityName': 'city_name',
        'countryCode': 'country_code',
        'publishedAt': 'published_at',
      },
    );

const _$AdminStoreStatusEnumMap = {
  AdminStoreStatus.active: 'active',
  AdminStoreStatus.draft: 'draft',
  AdminStoreStatus.suspended: 'suspended',
  AdminStoreStatus.unknown: 'unknown',
};

AdminStorePage _$AdminStorePageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminStorePage', json, ($checkedConvert) {
      final val = AdminStorePage(
        counts: $checkedConvert(
          'counts',
          (v) => Map<String, int>.from(v as Map),
        ),
        stores: $checkedConvert(
          'stores',
          (v) => (v as List<dynamic>)
              .map((e) => AdminStoreRow.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

AdminStore _$AdminStoreFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AdminStore',
  json,
  ($checkedConvert) {
    final val = AdminStore(
      row: $checkedConvert(
        'row',
        (v) => AdminStoreRow.fromJson(v as Map<String, dynamic>),
        readValue: _self,
      ),
      description: $checkedConvert('description', (v) => v as String?),
      zoneId: $checkedConvert('zone_id', (v) => v as String?),
      currencyCode: $checkedConvert('currency_code', (v) => v as String?),
      prepTimeMinutes: $checkedConvert(
        'prep_time_minutes',
        (v) => (v as num?)?.toInt() ?? 30,
      ),
      offersPickup: $checkedConvert(
        'offers_pickup',
        (v) => v as bool? ?? false,
      ),
      orders7d: $checkedConvert('orders_7d', (v) => (v as num?)?.toInt() ?? 0),
      sales7dMinor: $checkedConvert(
        'sales_7d_minor',
        (v) => v == null ? 0 : minorFromJson(v),
      ),
      publishedProducts: $checkedConvert(
        'published_products',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      openDisputes: $checkedConvert(
        'open_disputes',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      audit: $checkedConvert(
        'audit',
        (v) =>
            (v as List<dynamic>?)
                ?.map(
                  (e) => AdminAuditEntry.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'zoneId': 'zone_id',
    'currencyCode': 'currency_code',
    'prepTimeMinutes': 'prep_time_minutes',
    'offersPickup': 'offers_pickup',
    'orders7d': 'orders_7d',
    'sales7dMinor': 'sales_7d_minor',
    'publishedProducts': 'published_products',
    'openDisputes': 'open_disputes',
  },
);

AdminCountry _$AdminCountryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminCountry',
      json,
      ($checkedConvert) {
        final val = AdminCountry(
          code: $checkedConvert('code', (v) => v as String),
          name: $checkedConvert(
            'name',
            (v) => const LocalizedTextConverter().fromJson(v),
          ),
          currencyCode: $checkedConvert('currency_code', (v) => v as String),
          dialCode: $checkedConvert('dial_code', (v) => v as String),
          timezone: $checkedConvert('timezone', (v) => v as String),
          isActive: $checkedConvert('is_active', (v) => v as bool),
          missing: $checkedConvert(
            'missing',
            (v) =>
                (v as List<dynamic>?)?.map((e) => e as String).toList() ??
                const [],
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'currencyCode': 'currency_code',
        'dialCode': 'dial_code',
        'isActive': 'is_active',
      },
    );

AdminZone _$AdminZoneFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AdminZone',
  json,
  ($checkedConvert) {
    final val = AdminZone(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      isActive: $checkedConvert('is_active', (v) => v as bool),
      latitude: $checkedConvert('latitude', (v) => (v as num?)?.toDouble()),
      longitude: $checkedConvert('longitude', (v) => (v as num?)?.toDouble()),
      storeCount: $checkedConvert(
        'store_count',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
    );
    return val;
  },
  fieldKeyMap: const {'isActive': 'is_active', 'storeCount': 'store_count'},
);

AdminCity _$AdminCityFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AdminCity',
  json,
  ($checkedConvert) {
    final val = AdminCity(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      isActive: $checkedConvert('is_active', (v) => v as bool),
      deliveryMinutes: $checkedConvert(
        'delivery_minutes',
        (v) => (v as num?)?.toInt() ?? 30,
      ),
      serviceRadiusM: $checkedConvert(
        'service_radius_m',
        (v) => (v as num?)?.toInt() ?? 15000,
      ),
      zones: $checkedConvert(
        'zones',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => AdminZone.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'isActive': 'is_active',
    'deliveryMinutes': 'delivery_minutes',
    'serviceRadiusM': 'service_radius_m',
  },
);

AdminDispatch _$AdminDispatchFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminDispatch',
      json,
      ($checkedConvert) {
        final val = AdminDispatch(
          couriersActive: $checkedConvert(
            'couriers_active',
            (v) => (v as num?)?.toInt() ?? 0,
          ),
          couriersOnline: $checkedConvert(
            'couriers_online',
            (v) => (v as num?)?.toInt() ?? 0,
          ),
          waiting: $checkedConvert('waiting', (v) => (v as num?)?.toInt() ?? 0),
          medianAcceptMinutes: $checkedConvert(
            'median_accept_minutes',
            (v) => (v as num?)?.toInt(),
          ),
          relaunches: $checkedConvert(
            'relaunches',
            (v) => (v as num?)?.toInt() ?? 0,
          ),
          widened: $checkedConvert('widened', (v) => (v as num?)?.toInt() ?? 0),
          autoRefused: $checkedConvert(
            'auto_refused',
            (v) => (v as num?)?.toInt() ?? 0,
          ),
          readyAlerts: $checkedConvert(
            'ready_alerts',
            (v) => (v as num?)?.toInt() ?? 0,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'couriersActive': 'couriers_active',
        'couriersOnline': 'couriers_online',
        'medianAcceptMinutes': 'median_accept_minutes',
        'autoRefused': 'auto_refused',
        'readyAlerts': 'ready_alerts',
      },
    );

AdminExchanges _$AdminExchangesFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AdminExchanges',
  json,
  ($checkedConvert) {
    final val = AdminExchanges(
      messages: $checkedConvert('messages', (v) => (v as num?)?.toInt() ?? 0),
      messagesWithOrder: $checkedConvert(
        'messages_with_order',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      conversationsActive: $checkedConvert(
        'conversations_active',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      storesByOrigin: $checkedConvert(
        'stores_by_origin',
        (v) =>
            (v as List<dynamic>?)
                ?.map(
                  (e) => AdminOriginCount.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
      ),
      pushSent: $checkedConvert('push_sent', (v) => (v as num?)?.toInt() ?? 0),
      pushSkipped: $checkedConvert(
        'push_skipped',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      pushFailed: $checkedConvert(
        'push_failed',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      quietNightUsers: $checkedConvert(
        'quiet_night_users',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'messagesWithOrder': 'messages_with_order',
    'conversationsActive': 'conversations_active',
    'storesByOrigin': 'stores_by_origin',
    'pushSent': 'push_sent',
    'pushSkipped': 'push_skipped',
    'pushFailed': 'push_failed',
    'quietNightUsers': 'quiet_night_users',
  },
);

AdminOriginCount _$AdminOriginCountFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminOriginCount', json, ($checkedConvert) {
      final val = AdminOriginCount(
        code: $checkedConvert('code', (v) => v as String),
        label: $checkedConvert(
          'label',
          (v) => const LocalizedTextConverter().fromJson(v),
        ),
        stores: $checkedConvert('stores', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

AdminCoverage _$AdminCoverageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminCoverage', json, ($checkedConvert) {
      final val = AdminCoverage(
        total: $checkedConvert('total', (v) => (v as num).toInt()),
        countries: $checkedConvert(
          'countries',
          (v) =>
              (v as List<dynamic>?)
                  ?.map(
                    (e) => AdminCoverageCountry.fromJson(
                      e as Map<String, dynamic>,
                    ),
                  )
                  .toList() ??
              const [],
        ),
      );
      return val;
    });

AdminCoverageCountry _$AdminCoverageCountryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminCoverageCountry', json, ($checkedConvert) {
  final val = AdminCoverageCountry(
    countryCode: $checkedConvert('country_code', (v) => v as String),
    misses: $checkedConvert('misses', (v) => (v as num).toInt()),
    medianKm: $checkedConvert('median_km', (v) => (v as num?)?.toInt()),
  );
  return val;
}, fieldKeyMap: const {'countryCode': 'country_code', 'medianKm': 'median_km'});

AdminPaymentProvider _$AdminPaymentProviderFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminPaymentProvider', json, ($checkedConvert) {
  final val = AdminPaymentProvider(
    code: $checkedConvert('code', (v) => v as String),
    label: $checkedConvert(
      'label',
      (v) => const LocalizedTextConverter().fromJson(v),
    ),
    kind: $checkedConvert('kind', (v) => v as String),
    isActive: $checkedConvert('is_active', (v) => v as bool),
  );
  return val;
}, fieldKeyMap: const {'isActive': 'is_active'});

AdminPaymentMethod _$AdminPaymentMethodFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminPaymentMethod',
      json,
      ($checkedConvert) {
        final val = AdminPaymentMethod(
          id: $checkedConvert('id', (v) => v as String),
          countryCode: $checkedConvert('country_code', (v) => v as String),
          providerCode: $checkedConvert('provider_code', (v) => v as String),
          label: $checkedConvert(
            'label',
            (v) => const LocalizedTextConverter().fromJson(v),
          ),
          isActive: $checkedConvert('is_active', (v) => v as bool),
          operatorCode: $checkedConvert('operator_code', (v) => v as String?),
          sort: $checkedConvert('sort', (v) => (v as num?)?.toInt() ?? 0),
          providerActive: $checkedConvert(
            'provider_active',
            (v) => v as bool? ?? true,
          ),
          kind: $checkedConvert('kind', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'countryCode': 'country_code',
        'providerCode': 'provider_code',
        'isActive': 'is_active',
        'operatorCode': 'operator_code',
        'providerActive': 'provider_active',
      },
    );

AdminPaymentSettings _$AdminPaymentSettingsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminPaymentSettings', json, ($checkedConvert) {
  final val = AdminPaymentSettings(
    methods: $checkedConvert(
      'methods',
      (v) => (v as List<dynamic>)
          .map((e) => AdminPaymentMethod.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    providers: $checkedConvert(
      'providers',
      (v) => (v as List<dynamic>)
          .map((e) => AdminPaymentProvider.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

AdminCommission _$AdminCommissionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminCommission',
      json,
      ($checkedConvert) {
        final val = AdminCommission(
          id: $checkedConvert('id', (v) => v as String),
          rateBps: $checkedConvert('rate_bps', (v) => (v as num).toInt()),
          categoryId: $checkedConvert('category_id', (v) => v as String?),
          categoryLabel: $checkedConvert(
            'category_label',
            (v) => const NullableLocalizedTextConverter().fromJson(v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'rateBps': 'rate_bps',
        'categoryId': 'category_id',
        'categoryLabel': 'category_label',
      },
    );

AdminDeliveryFee _$AdminDeliveryFeeFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminDeliveryFee',
      json,
      ($checkedConvert) {
        final val = AdminDeliveryFee(
          id: $checkedConvert('id', (v) => v as String),
          baseFeeMinor: $checkedConvert(
            'base_fee_minor',
            (v) => minorFromJson(v),
          ),
          extraPickupFeeMinor: $checkedConvert(
            'extra_pickup_fee_minor',
            (v) => minorFromJson(v),
          ),
          cityId: $checkedConvert('city_id', (v) => v as String?),
          cityName: $checkedConvert('city_name', (v) => v as String?),
          freeThresholdMinor: $checkedConvert(
            'free_threshold_minor',
            (v) => nullableMinorFromJson(v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'baseFeeMinor': 'base_fee_minor',
        'extraPickupFeeMinor': 'extra_pickup_fee_minor',
        'cityId': 'city_id',
        'cityName': 'city_name',
        'freeThresholdMinor': 'free_threshold_minor',
      },
    );

AdminPricing _$AdminPricingFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminPricing',
      json,
      ($checkedConvert) {
        final val = AdminPricing(
          currencyCode: $checkedConvert('currency_code', (v) => v as String),
          commissions: $checkedConvert(
            'commissions',
            (v) =>
                (v as List<dynamic>?)
                    ?.map(
                      (e) =>
                          AdminCommission.fromJson(e as Map<String, dynamic>),
                    )
                    .toList() ??
                const [],
          ),
          deliveryFees: $checkedConvert(
            'delivery_fees',
            (v) =>
                (v as List<dynamic>?)
                    ?.map(
                      (e) =>
                          AdminDeliveryFee.fromJson(e as Map<String, dynamic>),
                    )
                    .toList() ??
                const [],
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'currencyCode': 'currency_code',
        'deliveryFees': 'delivery_fees',
      },
    );

AdminCategory _$AdminCategoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminCategory', json, ($checkedConvert) {
      final val = AdminCategory(
        id: $checkedConvert('id', (v) => v as String),
        slug: $checkedConvert('slug', (v) => v as String),
        label: $checkedConvert(
          'label',
          (v) => const LocalizedTextConverter().fromJson(v),
        ),
        isActive: $checkedConvert('is_active', (v) => v as bool),
        parentId: $checkedConvert('parent_id', (v) => v as String?),
        icon: $checkedConvert('icon', (v) => v as String?),
        sort: $checkedConvert('sort', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    }, fieldKeyMap: const {'isActive': 'is_active', 'parentId': 'parent_id'});

AdminAuditPage _$AdminAuditPageFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminAuditPage', json, ($checkedConvert) {
  final val = AdminAuditPage(
    total: $checkedConvert('total', (v) => (v as num).toInt()),
    entries: $checkedConvert(
      'entries',
      (v) => (v as List<dynamic>)
          .map((e) => AdminAuditEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    actions: $checkedConvert(
      'actions',
      (v) =>
          (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
    ),
    entityTypes: $checkedConvert(
      'entity_types',
      (v) =>
          (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
    ),
  );
  return val;
}, fieldKeyMap: const {'entityTypes': 'entity_types'});

AdminFeatureFlag _$AdminFeatureFlagFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminFeatureFlag',
      json,
      ($checkedConvert) {
        final val = AdminFeatureFlag(
          id: $checkedConvert('id', (v) => v as String),
          key: $checkedConvert('key', (v) => v as String),
          isEnabled: $checkedConvert('is_enabled', (v) => v as bool),
          description: $checkedConvert('description', (v) => v as String),
          countryCode: $checkedConvert('country_code', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'isEnabled': 'is_enabled',
        'countryCode': 'country_code',
      },
    );

AdminClientRow _$AdminClientRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminClientRow',
      json,
      ($checkedConvert) {
        final val = AdminClientRow(
          id: $checkedConvert('id', (v) => v as String),
          firstName: $checkedConvert('first_name', (v) => v as String),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          orders: $checkedConvert('orders', (v) => (v as num?)?.toInt() ?? 0),
        );
        return val;
      },
      fieldKeyMap: const {'firstName': 'first_name', 'createdAt': 'created_at'},
    );

AdminClientAddress _$AdminClientAddressFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminClientAddress', json, ($checkedConvert) {
      final val = AdminClientAddress(
        kind: $checkedConvert('kind', (v) => v as String),
        zoneName: $checkedConvert('zone_name', (v) => v as String),
        landmark: $checkedConvert('landmark', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'zoneName': 'zone_name'});

AdminVendorProduct _$AdminVendorProductFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminVendorProduct',
      json,
      ($checkedConvert) {
        final val = AdminVendorProduct(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          priceMinor: $checkedConvert(
            'price_minor',
            (v) => nullableMinorFromJson(v),
          ),
          isAvailable: $checkedConvert(
            'is_available',
            (v) => v as bool? ?? true,
          ),
          stock: $checkedConvert('stock', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'priceMinor': 'price_minor',
        'isAvailable': 'is_available',
      },
    );
