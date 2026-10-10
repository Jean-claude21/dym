// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pilot_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Review _$ReviewFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Review',
  json,
  ($checkedConvert) {
    final val = Review(
      id: $checkedConvert('id', (v) => v as String),
      orderId: $checkedConvert('order_id', (v) => v as String),
      storeId: $checkedConvert('store_id', (v) => v as String),
      rating: $checkedConvert('rating', (v) => (v as num).toInt()),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      tags: $checkedConvert(
        'tags',
        (v) =>
            (v as List<dynamic>?)
                ?.map(
                  (e) => $enumDecode(
                    _$ReviewTagEnumMap,
                    e,
                    unknownValue: ReviewTag.unknown,
                  ),
                )
                .toList() ??
            const [],
      ),
      comment: $checkedConvert('comment', (v) => v as String?),
      reply: $checkedConvert('reply', (v) => v as String?),
      repliedAt: $checkedConvert(
        'replied_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      authorFirstName: $checkedConvert(
        'author_first_name',
        (v) => v as String?,
      ),
      status: $checkedConvert('status', (v) => v as String? ?? 'published'),
    );
    return val;
  },
  fieldKeyMap: const {
    'orderId': 'order_id',
    'storeId': 'store_id',
    'createdAt': 'created_at',
    'repliedAt': 'replied_at',
    'authorFirstName': 'author_first_name',
  },
);

const _$ReviewTagEnumMap = {
  ReviewTag.fresh: 'fresh',
  ReviewTag.wellPacked: 'well_packed',
  ReviewTag.fast: 'fast',
  ReviewTag.friendly: 'friendly',
  ReviewTag.unknown: 'unknown',
};

StoreReviews _$StoreReviewsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StoreReviews', json, ($checkedConvert) {
      final val = StoreReviews(
        rating: $checkedConvert('rating', (v) => (v as num?)?.toDouble()),
        reviewCount: $checkedConvert(
          'review_count',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
        distribution: $checkedConvert(
          'distribution',
          (v) =>
              (v as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toInt()),
              ) ??
              const {},
        ),
        reviews: $checkedConvert(
          'reviews',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const [],
        ),
      );
      return val;
    }, fieldKeyMap: const {'reviewCount': 'review_count'});

ReorderResult _$ReorderResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReorderResult', json, ($checkedConvert) {
      final val = ReorderResult(
        added: $checkedConvert('added', (v) => (v as num).toInt()),
        skipped: $checkedConvert(
          'skipped',
          (v) =>
              (v as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
        ),
      );
      return val;
    });

TicketMessage _$TicketMessageFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TicketMessage', json, ($checkedConvert) {
  final val = TicketMessage(
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

SupportTicket _$SupportTicketFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SupportTicket',
  json,
  ($checkedConvert) {
    final val = SupportTicket(
      id: $checkedConvert('id', (v) => v as String),
      app: $checkedConvert('app', (v) => v as String),
      subject: $checkedConvert(
        'subject',
        (v) => $enumDecode(
          _$TicketSubjectEnumMap,
          v,
          unknownValue: TicketSubject.unknown,
        ),
      ),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(
          _$TicketStatusEnumMap,
          v,
          unknownValue: TicketStatus.unknown,
        ),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      lastActivityAt: $checkedConvert(
        'last_activity_at',
        (v) => DateTime.parse(v as String),
      ),
      orderId: $checkedConvert('order_id', (v) => v as String?),
      orderReference: $checkedConvert('order_reference', (v) => v as String?),
      firstResponseAt: $checkedConvert(
        'first_response_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      closedAt: $checkedConvert(
        'closed_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      messages: $checkedConvert(
        'messages',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      ),
      userFirstName: $checkedConvert('user_first_name', (v) => v as String?),
      userId: $checkedConvert('user_id', (v) => v as String?),
      storeName: $checkedConvert('store_name', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'createdAt': 'created_at',
    'lastActivityAt': 'last_activity_at',
    'orderId': 'order_id',
    'orderReference': 'order_reference',
    'firstResponseAt': 'first_response_at',
    'closedAt': 'closed_at',
    'userFirstName': 'user_first_name',
    'userId': 'user_id',
    'storeName': 'store_name',
  },
);

const _$TicketSubjectEnumMap = {
  TicketSubject.order: 'order',
  TicketSubject.payment: 'payment',
  TicketSubject.account: 'account',
  TicketSubject.store: 'store',
  TicketSubject.other: 'other',
  TicketSubject.unknown: 'unknown',
};

const _$TicketStatusEnumMap = {
  TicketStatus.open: 'open',
  TicketStatus.pending: 'pending',
  TicketStatus.closed: 'closed',
  TicketStatus.unknown: 'unknown',
};
