// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disputes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisputeMessage _$DisputeMessageFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DisputeMessage', json, ($checkedConvert) {
  final val = DisputeMessage(
    id: $checkedConvert('id', (v) => v as String),
    authorRole: $checkedConvert('author_role', (v) => v as String),
    body: $checkedConvert('body', (v) => v as String),
    createdAt: $checkedConvert(
      'created_at',
      (v) => DateTime.parse(v as String),
    ),
  );
  return val;
}, fieldKeyMap: const {'authorRole': 'author_role', 'createdAt': 'created_at'});

Dispute _$DisputeFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Dispute',
  json,
  ($checkedConvert) {
    final val = Dispute(
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
      description: $checkedConvert('description', (v) => v as String),
      status: $checkedConvert('status', (v) => v as String),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      currencyCode: $checkedConvert('currency_code', (v) => v as String),
      storeName: $checkedConvert('store_name', (v) => v as String?),
      resolution: $checkedConvert(
        'resolution',
        (v) => $enumDecodeNullable(
          _$DisputeResolutionEnumMap,
          v,
          unknownValue: DisputeResolution.unknown,
        ),
      ),
      refundMinor: $checkedConvert(
        'refund_minor',
        (v) => nullableMinorFromJson(v),
      ),
      vendorWarned: $checkedConvert(
        'vendor_warned',
        (v) => v as bool? ?? false,
      ),
      resolvedAt: $checkedConvert(
        'resolved_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      messages: $checkedConvert(
        'messages',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => DisputeMessage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      ),
      internalNote: $checkedConvert('internal_note', (v) => v as String?),
      customerFirstName: $checkedConvert(
        'customer_first_name',
        (v) => v as String?,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orderId': 'order_id',
    'createdAt': 'created_at',
    'currencyCode': 'currency_code',
    'storeName': 'store_name',
    'refundMinor': 'refund_minor',
    'vendorWarned': 'vendor_warned',
    'resolvedAt': 'resolved_at',
    'internalNote': 'internal_note',
    'customerFirstName': 'customer_first_name',
  },
);

const _$DisputeReasonEnumMap = {
  DisputeReason.missingItem: 'missing_item',
  DisputeReason.wrongItem: 'wrong_item',
  DisputeReason.damaged: 'damaged',
  DisputeReason.quality: 'quality',
  DisputeReason.notDelivered: 'not_delivered',
  DisputeReason.other: 'other',
  DisputeReason.unknown: 'unknown',
};

const _$DisputeResolutionEnumMap = {
  DisputeResolution.noAction: 'no_action',
  DisputeResolution.partialRefund: 'partial_refund',
  DisputeResolution.fullRefund: 'full_refund',
  DisputeResolution.unknown: 'unknown',
};
