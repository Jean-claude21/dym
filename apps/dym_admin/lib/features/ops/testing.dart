import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';

/// Admin en mémoire (tests, galerie). Jamais en production. Les lieux sont
/// génériques (« Quartier 1 », « Ville A ») : aucune ville réelle.
class MemoryAdminService implements AdminService {
  new({DateTime? now, Currency? currency})
    : now = now ?? DateTime.utc(2026, 10, 5, 11),
      currency = currency ?? Currency.xof {
    _seed();
  }

  final DateTime now;
  final Currency currency;

  /// Prochain appel en échec (une fois).
  Failure? failNext;
  final gestures = <String>[];

  final _orders = <String, AdminOrder>{};
  final _disputes = <String, AdminDispute>{};
  final _refunds = <String, AdminRefund>{};
  final _payments = <AdminPendingPayment>[];
  final _stores = <String, AdminStore>{};
  final _countries = <AdminCountry>[];
  final _cities = <String, List<AdminCity>>{};
  final _methods = <String, List<AdminPaymentMethod>>{};
  final _pricing = <String, AdminPricing>{};
  final _categories = <AdminCategory>[];
  final _audit = <AdminAuditEntry>[];

  Result<T>? _fail<T>() {
    final failure = failNext;
    if (failure == null) return null;
    failNext = null;
    return Err(failure);
  }

  int _minor(int major) => major * _unit;
  int get _unit => switch (currency.minorUnits) {
    0 => 1,
    1 => 10,
    2 => 100,
    _ => 1000,
  };

  void _log(String action, String type, String id, {String? reason}) =>
      _audit.insert(
        0,
        AdminAuditEntry(
          id: _audit.length + 1,
          occurredAt: now,
          actorFirstName: 'Mawuena',
          action: action,
          entityType: type,
          entityId: id,
          reason: reason,
        ),
      );

  // ---------------------------------------------------------------- données

  static const _cash = PaymentMethod(
    id: 'cash',
    countryCode: 'TG',
    providerCode: 'cash',
    label: LocalizedText({
      'fr': 'Cash à la livraison',
      'en': 'Cash on delivery',
    }),
  );
  static const _momo = PaymentMethod(
    id: 'sim',
    countryCode: 'TG',
    providerCode: 'simulator',
    label: LocalizedText({'fr': 'Mobile Money', 'en': 'Mobile Money'}),
  );

  AdminOrder _order({
    required String id,
    required String reference,
    required String store,
    required String customer,
    required OrderStatus status,
    required int major,
    required int minutesAgo,
    bool paid = true,
    bool stuck = false,
    Fulfillment mode = Fulfillment.delivery,
    List<(OrderStatus, String, int)> steps = const [],
  }) {
    final created = now.subtract(Duration(minutes: minutesAgo));
    final last = steps.isEmpty
        ? created
        : created.add(Duration(minutes: steps.last.$3));
    return AdminOrder(
      order: CustomerOrder(
        id: id,
        purchaseId: 'pu-$id',
        status: status,
        fulfillment: mode,
        createdAt: created,
        currencyCode: currency.code,
        totalMinor: _minor(major),
        subtotalMinor: _minor(major - 500),
        deliveryFeeMinor: _minor(500),
        itemCount: 3,
        paymentStatus: paid ? PaymentStatus.paid : PaymentStatus.cashOnDelivery,
        paymentMethod: paid ? _momo : _cash,
        store: OrderStoreRef(id: 's-$store', name: store, origin: 'marche'),
        items: [
          OrderLine(
            productId: 'p1',
            variantId: 'v1',
            name: 'Tomates fraîches',
            unitLabel: const LocalizedText({'fr': 'le tas', 'en': 'the heap'}),
            unitPriceMinor: _minor(500),
            quantity: 2,
            amountMinor: _minor(1000),
          ),
          OrderLine(
            productId: 'p2',
            variantId: 'v2',
            name: 'Gombo frais',
            unitLabel: const LocalizedText({'fr': 'le tas', 'en': 'the heap'}),
            unitPriceMinor: _minor(major - 1500),
            quantity: 1,
            amountMinor: _minor(major - 1500),
          ),
        ],
        address: const PurchaseAddress(
          kind: AddressKind.home,
          zoneName: 'Quartier 2',
          cityName: 'Ville A',
          landmark: 'Portail bleu après la pharmacie',
        ),
      ),
      reference: reference,
      storeName: store,
      customer: AdminCustomer(firstName: customer, phone: '+000 00 00 00 00'),
      lastChangeAt: last,
      stuck: stuck,
      timeline: [
        for (final (to, actor, minutes) in steps)
          AdminTimelineEvent(
            toStatus: to,
            actorRole: actor,
            occurredAt: created.add(Duration(minutes: minutes)),
          ),
      ],
      payments: [
        if (paid)
          AdminPayment(
            id: 'pay-$id',
            reference: 'PA-${reference.substring(0, 6)}',
            providerCode: 'simulator',
            status: 'succeeded',
            amountMinor: _minor(major),
            currencyCode: currency.code,
            createdAt: created,
            completedAt: created.add(const Duration(minutes: 1)),
          ),
      ],
      forceableStatuses: status.isActive
          ? [
              for (final s in const [
                OrderStatus.pending,
                OrderStatus.accepted,
                OrderStatus.preparing,
                OrderStatus.ready,
                OrderStatus.outForDelivery,
                OrderStatus.delivered,
              ])
                if (s != status) s,
            ]
          : const [],
      canCancel: status.isActive,
      canAssignCourier:
          mode == Fulfillment.delivery &&
          status.isActive &&
          status != OrderStatus.pending,
    );
  }

  void _seed() {
    for (final o in [
      _order(
        id: 'o1',
        reference: '7K2Q4F1A',
        store: "Étal d'Akossiwa",
        customer: 'Awa',
        status: OrderStatus.preparing,
        major: 1800,
        minutesAgo: 70,
        stuck: true,
        steps: const [
          (OrderStatus.accepted, 'vendor', 7),
          (OrderStatus.preparing, 'vendor', 13),
        ],
      ),
      _order(
        id: 'o2',
        reference: '4M9A0B2C',
        store: 'Les jus d’Esi',
        customer: 'Mariam',
        status: OrderStatus.outForDelivery,
        major: 4100,
        minutesAgo: 31,
        paid: false,
        steps: const [
          (OrderStatus.accepted, 'vendor', 3),
          (OrderStatus.ready, 'vendor', 15),
          (OrderStatus.outForDelivery, 'vendor', 20),
        ],
      ),
      _order(
        id: 'o3',
        reference: '2C6R8D3E',
        store: 'Chez Afi',
        customer: 'Kokou',
        status: OrderStatus.delivered,
        major: 2600,
        minutesAgo: 72,
        steps: const [
          (OrderStatus.accepted, 'vendor', 2),
          (OrderStatus.delivered, 'vendor', 50),
        ],
      ),
      _order(
        id: 'o4',
        reference: '5H8N1F4G',
        store: 'Chez Afi',
        customer: 'Essi',
        status: OrderStatus.refused,
        major: 5400,
        minutesAgo: 124,
        paid: false,
      ),
    ]) {
      _orders[o.id] = o;
    }

    const message = 'Il manquait le gombo dans le sac.';
    _disputes['d1'] = AdminDispute(
      dispute: Dispute(
        id: 'd1',
        orderId: 'o3',
        reason: DisputeReason.missingItem,
        description: message,
        status: 'open',
        createdAt: now.subtract(const Duration(hours: 2)),
        currencyCode: currency.code,
        storeName: 'Chez Afi',
        customerFirstName: 'Kokou',
        messages: [
          DisputeMessage(
            id: 'm0',
            authorRole: 'client',
            body: message,
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
          DisputeMessage(
            id: 'm1',
            authorRole: 'vendor',
            body: 'Pardon, je rembourse le gombo.',
            createdAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      order: _orders['o3']!.order,
    );
    _disputes['d2'] = AdminDispute(
      dispute: Dispute(
        id: 'd2',
        orderId: 'o1',
        reason: DisputeReason.notDelivered,
        description: 'Toujours rien reçu.',
        status: 'open',
        createdAt: now.subtract(const Duration(hours: 26)),
        currencyCode: currency.code,
        storeName: "Étal d'Akossiwa",
        customerFirstName: 'Awa',
        messages: [
          DisputeMessage(
            id: 'm0',
            authorRole: 'client',
            body: 'Toujours rien reçu.',
            createdAt: now.subtract(const Duration(hours: 26)),
          ),
        ],
      ),
      order: _orders['o1']!.order,
    );

    _refunds['r1'] = AdminRefund(
      id: 'r1',
      orderId: 'o3',
      orderReference: '2C6R8D3E',
      disputeId: 'd0',
      reason: 'dispute',
      method: 'provider',
      providerCode: 'simulator',
      amountMinor: _minor(300),
      currencyCode: currency.code,
      status: RefundStatus.pending,
      storeName: 'Chez Afi',
      createdAt: now.subtract(const Duration(minutes: 5)),
    );
    _refunds['r2'] = AdminRefund(
      id: 'r2',
      orderId: 'o4',
      orderReference: '5H8N1F4G',
      reason: 'cancellation',
      method: 'cash',
      amountMinor: _minor(1200),
      currencyCode: currency.code,
      status: RefundStatus.pending,
      storeName: 'Chez Afi',
      createdAt: now.subtract(const Duration(hours: 1)),
    );
    _payments.add(
      AdminPendingPayment(
        id: 'pay9',
        reference: 'PA-9QWE12',
        providerCode: 'simulator',
        amountMinor: _minor(4500),
        currencyCode: currency.code,
        createdAt: now.subtract(const Duration(minutes: 12)),
        orders: const [
          AdminOrderRef(id: 'o9', reference: '9QWE12AB', storeName: 'Chez Afi'),
        ],
      ),
    );

    for (final (id, name, owner, origin, status) in const [
      ('s1', "Étal d'Akossiwa", 'Akossiwa', 'marche', AdminStoreStatus.active),
      ('s2', 'Les jus d’Esi', 'Esi', 'maison', AdminStoreStatus.active),
      ('s3', 'Chez Afi', 'Afi', 'magasin', AdminStoreStatus.active),
      ('s4', 'Saveurs de Koffi', 'Koffi', 'marche', AdminStoreStatus.draft),
      ('s5', 'Épices d’Adjoa', 'Adjoa', 'magasin', AdminStoreStatus.suspended),
    ]) {
      _stores[id] = AdminStore(
        row: AdminStoreRow(
          id: id,
          name: name,
          status: status,
          isOpen: status == AdminStoreStatus.active,
          origin: origin,
          originLabel: LocalizedText({
            'fr': switch (origin) {
              'marche' => 'Au marché',
              'maison' => 'Fait maison',
              _ => 'Boutique',
            },
          }),
          ownerFirstName: owner,
          zoneName: 'Quartier 1',
          cityName: 'Ville A',
          countryCode: 'TG',
          createdAt: DateTime.utc(2026, 9, 12),
          publishedAt: status == AdminStoreStatus.draft
              ? null
              : DateTime.utc(2026, 9, 12),
        ),
        description: 'Légumes frais du marché, livrés le jour même.',
        zoneId: 'z1',
        currencyCode: currency.code,
        orders7d: 46,
        sales7dMinor: _minor(128500),
        publishedProducts: 23,
        openDisputes: id == 's1' ? 1 : 0,
        audit: [
          if (id == 's1')
            AdminAuditEntry(
              occurredAt: DateTime.utc(2026, 10, 3, 16),
              actorFirstName: 'Mawuena',
              action: 'store_updated',
              reason: 'Repère corrigé',
            ),
        ],
      );
    }

    _countries.addAll([
      AdminCountry(
        code: 'TG',
        name: const LocalizedText({'fr': 'Togo', 'en': 'Togo'}),
        currencyCode: currency.code,
        dialCode: '+228',
        timezone: 'UTC',
        isActive: true,
      ),
      const AdminCountry(
        code: 'GH',
        name: LocalizedText({'fr': 'Ghana', 'en': 'Ghana'}),
        currencyCode: 'GHS',
        dialCode: '+233',
        timezone: 'UTC',
        isActive: false,
        missing: ['zones', 'delivery_fees'],
      ),
    ]);
    _cities['TG'] = const [
      AdminCity(
        id: 'c1',
        name: 'Ville A',
        isActive: true,
        zones: [
          AdminZone(
            id: 'z1',
            name: 'Quartier 1',
            isActive: true,
            storeCount: 3,
          ),
          AdminZone(id: 'z2', name: 'Quartier 2', isActive: true),
          AdminZone(id: 'z3', name: 'Quartier 3', isActive: false),
        ],
      ),
    ];
    _methods['TG'] = const [
      AdminPaymentMethod(
        id: 'cash',
        countryCode: 'TG',
        providerCode: 'cash',
        label: LocalizedText({'fr': 'Cash à la livraison', 'en': 'Cash'}),
        isActive: true,
        kind: 'cash',
      ),
      AdminPaymentMethod(
        id: 'sim',
        countryCode: 'TG',
        providerCode: 'simulator',
        label: LocalizedText({
          'fr': 'Mobile Money (simulé)',
          'en': 'Mobile Money',
        }),
        isActive: true,
        kind: 'mobile_money',
      ),
    ];
    _pricing['TG'] = AdminPricing(
      currencyCode: currency.code,
      commissions: const [AdminCommission(id: 'k1', rateBps: 1000)],
      deliveryFees: [
        AdminDeliveryFee(
          id: 'f1',
          baseFeeMinor: _minor(500),
          extraPickupFeeMinor: _minor(200),
          freeThresholdMinor: _minor(15000),
        ),
      ],
    );
    _categories.addAll(const [
      AdminCategory(
        id: 'k1',
        slug: 'legumes',
        label: LocalizedText({'fr': 'Légumes', 'en': 'Vegetables'}),
        isActive: true,
      ),
      AdminCategory(
        id: 'k2',
        slug: 'tomates',
        parentId: 'k1',
        label: LocalizedText({'fr': 'Tomates', 'en': 'Tomatoes'}),
        isActive: true,
      ),
      AdminCategory(
        id: 'k3',
        slug: 'boissons',
        label: LocalizedText({'fr': 'Boissons', 'en': 'Drinks'}),
        isActive: false,
      ),
    ]);
    _log('order_status_forced', 'order', 'o9', reason: 'Vendeuse injoignable');
    _log('store_suspended', 'store', 's5', reason: 'Produits non conformes');
  }

  // ---------------------------------------------------------------- lectures

  @override
  Future<Result<Map<String, Currency>>> currencies() async =>
      _fail<Map<String, Currency>>() ?? Ok({currency.code: currency});

  @override
  Future<Result<AdminOrderPage>> orders({
    AdminOrderFilter filter = AdminOrderFilter.all,
    String? query,
    int offset = 0,
  }) async {
    final failed = _fail<AdminOrderPage>();
    if (failed != null) return failed;
    final q = query?.trim().toLowerCase() ?? '';
    bool keep(AdminOrder o) => switch (filter) {
      AdminOrderFilter.all => true,
      AdminOrderFilter.pending => o.status == OrderStatus.pending,
      AdminOrderFilter.active =>
        o.status.isActive && o.status != OrderStatus.pending,
      AdminOrderFilter.stuck => o.stuck,
      AdminOrderFilter.delivered => o.status == OrderStatus.delivered,
      AdminOrderFilter.closed =>
        o.status == OrderStatus.refused || o.status == OrderStatus.cancelled,
    };
    final hits = _orders.values.where(
      (o) =>
          q.isEmpty ||
          o.reference.toLowerCase().startsWith(q) ||
          o.storeName.toLowerCase().contains(q) ||
          (o.customer.firstName ?? '').toLowerCase().contains(q),
    );
    final rows = [
      for (final o in hits.where(keep))
        AdminOrderRow(
          id: o.id,
          reference: o.reference,
          status: o.status,
          fulfillment: o.order.fulfillment,
          paymentStatus: o.order.paymentStatus,
          storeId: o.order.store.id,
          storeName: o.storeName,
          customerFirstName: o.customer.firstName,
          totalMinor: o.order.totalMinor,
          currencyCode: o.order.currencyCode,
          createdAt: o.order.createdAt,
          lastChangeAt: o.lastChangeAt,
          stuck: o.stuck,
          refundDue: o.order.refundDue,
        ),
    ];
    return Ok(
      AdminOrderPage(
        total: rows.length,
        stuckCount: hits.where((o) => o.stuck).length,
        orders: rows.skip(offset).take(50).toList(),
      ),
    );
  }

  @override
  Future<Result<AdminOrder>> order(String id) async =>
      _fail<AdminOrder>() ??
      (_orders[id] == null
          ? const Err(NotFoundFailure('commande'))
          : Ok(_orders[id]!));

  // ---------------------------------------------------------------- gestes

  AdminOrder _with(
    AdminOrder o, {
    required OrderStatus status,
    String? note,
    OrderCourier? courier,
    List<AdminRefund>? refunds,
  }) {
    final active = status.isActive;
    return AdminOrder(
      order: CustomerOrder(
        id: o.order.id,
        purchaseId: o.order.purchaseId,
        status: status,
        fulfillment: o.order.fulfillment,
        createdAt: o.order.createdAt,
        currencyCode: o.order.currencyCode,
        totalMinor: o.order.totalMinor,
        subtotalMinor: o.order.subtotalMinor,
        deliveryFeeMinor: o.order.deliveryFeeMinor,
        itemCount: o.order.itemCount,
        paymentStatus: o.order.paymentStatus,
        paymentMethod: o.order.paymentMethod,
        store: o.order.store,
        items: o.order.items,
        address: o.order.address,
        cancelledBy: status == OrderStatus.cancelled
            ? 'admin'
            : o.order.cancelledBy,
        refundDue: refunds?.isNotEmpty ?? o.order.refundDue,
      ),
      reference: o.reference,
      storeName: o.storeName,
      customer: o.customer,
      lastChangeAt: status == o.status ? o.lastChangeAt : now,
      statusNote: status == OrderStatus.cancelled ? note : o.statusNote,
      timeline: [
        ...o.timeline,
        if (status != o.status)
          AdminTimelineEvent(
            fromStatus: o.status,
            toStatus: status,
            actorRole: 'admin',
            note: note,
            occurredAt: now,
          ),
      ],
      payments: o.payments,
      refunds: refunds ?? o.refunds,
      dispute: o.dispute,
      courier: courier ?? o.courier,
      audit: o.audit,
      forceableStatuses: active
          ? [
              for (final s in const [
                OrderStatus.pending,
                OrderStatus.accepted,
                OrderStatus.preparing,
                OrderStatus.ready,
                OrderStatus.outForDelivery,
                OrderStatus.delivered,
              ])
                if (s != status) s,
            ]
          : const [],
      canCancel: active,
      canAssignCourier:
          o.order.fulfillment == Fulfillment.delivery &&
          active &&
          status != OrderStatus.pending,
    );
  }

  @override
  Future<Result<AdminOrder>> forceStatus(
    AdminOrder order,
    OrderStatus to,
    String reason,
  ) async {
    final failed = _fail<AdminOrder>();
    if (failed != null) return failed;
    final current = _orders[order.id]!;
    if (current.status != order.status) {
      return const Err(ValidationFailure('status_changed'));
    }
    if (!current.forceableStatuses.contains(to)) {
      return const Err(ValidationFailure('transition_not_allowed'));
    }
    gestures.add('${order.id}:${to.code}');
    _log('order_status_forced', 'order', order.id, reason: reason);
    return Ok(_orders[order.id] = _with(current, status: to, note: reason));
  }

  @override
  Future<Result<AdminOrder>> cancel(AdminOrder order, String reason) async {
    final failed = _fail<AdminOrder>();
    if (failed != null) return failed;
    final current = _orders[order.id]!;
    if (!current.canCancel) return const Err(ValidationFailure('order_closed'));
    gestures.add('${order.id}:cancel');
    _log('order_cancelled', 'order', order.id, reason: reason);
    final paid = current.order.paymentStatus == PaymentStatus.paid;
    final refund = AdminRefund(
      id: 'r-${order.id}',
      orderId: order.id,
      orderReference: current.reference,
      reason: 'cancellation',
      method: 'provider',
      providerCode: 'simulator',
      amountMinor: current.order.totalMinor,
      currencyCode: current.order.currencyCode,
      status: RefundStatus.pending,
      storeName: current.storeName,
      createdAt: now,
    );
    if (paid) _refunds[refund.id] = refund;
    return Ok(
      _orders[order.id] = _with(
        current,
        status: OrderStatus.cancelled,
        note: reason,
        refunds: paid ? [...current.refunds, refund] : null,
      ),
    );
  }

  @override
  Future<Result<AdminOrder>> assignCourier(
    String orderId, {
    required String name,
    required String phone,
  }) async {
    final failed = _fail<AdminOrder>();
    if (failed != null) return failed;
    final current = _orders[orderId]!;
    if (!current.canAssignCourier) {
      return const Err(ValidationFailure('courier_not_allowed'));
    }
    gestures.add('$orderId:courier');
    _log('courier_assigned', 'order', orderId);
    return Ok(
      _orders[orderId] = _with(
        current,
        status: current.status,
        courier: OrderCourier(name: name, phone: phone, assignedAt: now),
      ),
    );
  }

  // ---------------------------------------------------------------- litiges

  @override
  Future<Result<List<AdminDisputeRow>>> disputes() async {
    final failed = _fail<List<AdminDisputeRow>>();
    if (failed != null) return failed;
    final open = _disputes.values.where((d) => d.dispute.isOpen).toList()
      ..sort((a, b) => a.dispute.createdAt.compareTo(b.dispute.createdAt));
    return Ok([
      for (final d in open)
        AdminDisputeRow(
          id: d.dispute.id,
          orderId: d.dispute.orderId,
          reason: d.dispute.reason,
          status: d.dispute.status,
          createdAt: d.dispute.createdAt,
          storeName: d.dispute.storeName ?? '',
          customerFirstName: d.dispute.customerFirstName,
          orderTotalMinor: d.order.totalMinor,
          currencyCode: d.order.currencyCode,
          messageCount: d.dispute.messages.length,
        ),
    ]);
  }

  @override
  Future<Result<AdminDispute>> dispute(String id) async =>
      _fail<AdminDispute>() ??
      (_disputes[id] == null
          ? const Err(NotFoundFailure('litige'))
          : Ok(_disputes[id]!));

  Dispute _copyDispute(
    Dispute d, {
    String? status,
    List<DisputeMessage>? messages,
    DisputeResolution? resolution,
    int? refundMinor,
  }) => Dispute(
    id: d.id,
    orderId: d.orderId,
    reason: d.reason,
    description: d.description,
    status: status ?? d.status,
    createdAt: d.createdAt,
    currencyCode: d.currencyCode,
    storeName: d.storeName,
    customerFirstName: d.customerFirstName,
    resolution: resolution ?? d.resolution,
    refundMinor: refundMinor ?? d.refundMinor,
    resolvedAt: status == 'resolved' ? now : d.resolvedAt,
    messages: messages ?? d.messages,
  );

  @override
  Future<Result<Dispute>> replyDispute(String id, String body) async {
    final failed = _fail<Dispute>();
    if (failed != null) return failed;
    final d = _disputes[id]!;
    if (!d.dispute.isOpen) {
      return const Err(ValidationFailure('dispute_closed'));
    }
    gestures.add('$id:reply');
    final next = _copyDispute(
      d.dispute,
      messages: [
        ...d.dispute.messages,
        DisputeMessage(
          id: 'm${d.dispute.messages.length}',
          authorRole: 'admin',
          body: body,
          createdAt: now,
        ),
      ],
    );
    _disputes[id] = AdminDispute(dispute: next, order: d.order);
    return Ok(next);
  }

  @override
  Future<Result<Dispute>> resolveDispute(
    String id, {
    required DisputeResolution resolution,
    int? refundMinor,
    String? internalNote,
    bool warnVendor = false,
  }) async {
    final failed = _fail<Dispute>();
    if (failed != null) return failed;
    final d = _disputes[id]!;
    if (!d.dispute.isOpen) {
      return const Err(ValidationFailure('dispute_closed'));
    }
    final amount = switch (resolution) {
      DisputeResolution.fullRefund => d.order.totalMinor,
      DisputeResolution.partialRefund => refundMinor,
      _ => null,
    };
    if (resolution == DisputeResolution.partialRefund &&
        (amount == null || amount <= 0 || amount > d.order.totalMinor)) {
      return const Err(ValidationFailure('refund_amount_invalid'));
    }
    gestures.add('$id:${resolution.name}${warnVendor ? ':warn' : ''}');
    _log('dispute_resolved', 'dispute', id, reason: internalNote);
    final next = _copyDispute(
      d.dispute,
      status: 'resolved',
      resolution: resolution,
      refundMinor: amount,
    );
    _disputes[id] = AdminDispute(dispute: next, order: d.order);
    if (amount != null) {
      _refunds['r-$id'] = AdminRefund(
        id: 'r-$id',
        orderId: d.order.id,
        orderReference: d.order.id.toUpperCase(),
        disputeId: id,
        reason: 'dispute',
        method: 'provider',
        providerCode: 'simulator',
        amountMinor: amount,
        currencyCode: d.order.currencyCode,
        status: RefundStatus.pending,
        storeName: d.dispute.storeName,
        createdAt: now,
      );
    }
    return Ok(next);
  }

  // ---------------------------------------------------------------- finances

  @override
  Future<Result<List<AdminRefund>>> refunds(RefundStatus status) async {
    final failed = _fail<List<AdminRefund>>();
    if (failed != null) return failed;
    return Ok([
      for (final r in _refunds.values)
        if (r.status == status ||
            (status == RefundStatus.pending &&
                r.status == RefundStatus.processing))
          r,
    ]);
  }

  @override
  Future<Result<List<AdminPendingPayment>>> pendingPayments() async =>
      _fail<List<AdminPendingPayment>>() ?? Ok(List.of(_payments));

  AdminRefund _done(AdminRefund r) => AdminRefund(
    id: r.id,
    orderId: r.orderId,
    orderReference: r.orderReference,
    disputeId: r.disputeId,
    reason: r.reason,
    method: r.method,
    providerCode: r.providerCode,
    amountMinor: r.amountMinor,
    currencyCode: r.currencyCode,
    status: RefundStatus.succeeded,
    storeName: r.storeName,
    createdAt: r.createdAt,
    completedAt: now,
  );

  @override
  Future<Result<AdminRefund>> executeRefund(String id) async {
    final failed = _fail<AdminRefund>();
    if (failed != null) return failed;
    final r = _refunds[id]!;
    if (r.isCash) return const Err(ValidationFailure('refund_not_provider'));
    gestures.add('$id:execute');
    _log('refund_succeeded', 'refund', id);
    return Ok(_refunds[id] = _done(r));
  }

  @override
  Future<Result<AdminRefund>> markCashRefund(String id) async {
    final failed = _fail<AdminRefund>();
    if (failed != null) return failed;
    final r = _refunds[id]!;
    if (!r.isCash) return const Err(ValidationFailure('refund_not_cash'));
    gestures.add('$id:cash');
    _log('refund_succeeded', 'refund', id);
    return Ok(_refunds[id] = _done(r));
  }

  // ---------------------------------------------------------------- boutiques

  @override
  Future<Result<AdminStorePage>> stores({
    AdminStoreStatus status = AdminStoreStatus.active,
    String? query,
  }) async {
    final failed = _fail<AdminStorePage>();
    if (failed != null) return failed;
    final q = query?.trim().toLowerCase() ?? '';
    final all = _stores.values.map((s) => s.row);
    return Ok(
      AdminStorePage(
        counts: {
          for (final s in const [
            AdminStoreStatus.active,
            AdminStoreStatus.draft,
            AdminStoreStatus.suspended,
          ])
            s.code: all.where((r) => r.status == s).length,
        },
        stores: [
          for (final r in all)
            if (r.status == status &&
                (q.isEmpty ||
                    r.name.toLowerCase().contains(q) ||
                    (r.ownerFirstName ?? '').toLowerCase().contains(q)))
              r,
        ],
      ),
    );
  }

  @override
  Future<Result<AdminStore>> store(String id) async =>
      _fail<AdminStore>() ??
      (_stores[id] == null
          ? const Err(NotFoundFailure('boutique'))
          : Ok(_stores[id]!));

  AdminStore _copyStore(
    AdminStore s, {
    AdminStoreStatus? status,
    String? name,
    AdminAuditEntry? entry,
  }) => AdminStore(
    row: AdminStoreRow(
      id: s.row.id,
      name: name ?? s.row.name,
      status: status ?? s.row.status,
      isOpen: status == null && s.row.isOpen,
      origin: s.row.origin,
      originLabel: s.row.originLabel,
      ownerFirstName: s.row.ownerFirstName,
      zoneName: s.row.zoneName,
      cityName: s.row.cityName,
      countryCode: s.row.countryCode,
      createdAt: s.row.createdAt,
      publishedAt: s.row.publishedAt,
    ),
    description: s.description,
    zoneId: s.zoneId,
    currencyCode: s.currencyCode,
    prepTimeMinutes: s.prepTimeMinutes,
    offersPickup: s.offersPickup,
    orders7d: s.orders7d,
    sales7dMinor: s.sales7dMinor,
    publishedProducts: s.publishedProducts,
    openDisputes: s.openDisputes,
    audit: [?entry, ...s.audit],
  );

  @override
  Future<Result<AdminStore>> setStoreStatus(
    String id, {
    required bool suspended,
    required String reason,
  }) async {
    final failed = _fail<AdminStore>();
    if (failed != null) return failed;
    final s = _stores[id]!;
    if (suspended == (s.row.status == AdminStoreStatus.suspended)) {
      return const Err(ValidationFailure('store_status_unchanged'));
    }
    final action = suspended ? 'store_suspended' : 'store_reactivated';
    gestures.add('$id:$action');
    _log(action, 'store', id, reason: reason);
    return Ok(
      _stores[id] = _copyStore(
        s,
        status: suspended
            ? AdminStoreStatus.suspended
            : (s.row.publishedAt == null
                  ? AdminStoreStatus.draft
                  : AdminStoreStatus.active),
        entry: AdminAuditEntry(
          occurredAt: now,
          actorFirstName: 'Mawuena',
          action: action,
          reason: reason,
        ),
      ),
    );
  }

  @override
  Future<Result<AdminStore>> updateStore(
    String id,
    Map<String, Object?> patch,
    String reason,
  ) async {
    final failed = _fail<AdminStore>();
    if (failed != null) return failed;
    gestures.add('$id:update');
    _log('store_updated', 'store', id, reason: reason);
    return Ok(
      _stores[id] = _copyStore(
        _stores[id]!,
        name: patch['name'] as String?,
        entry: AdminAuditEntry(
          occurredAt: now,
          actorFirstName: 'Mawuena',
          action: 'store_updated',
          reason: reason,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- réglages

  @override
  Future<Result<List<AdminCountry>>> countries() async =>
      _fail<List<AdminCountry>>() ?? Ok(List.of(_countries));

  @override
  Future<Result<List<AdminCountry>>> setCountryActive(
    String code, {
    required bool active,
  }) async {
    final failed = _fail<List<AdminCountry>>();
    if (failed != null) return failed;
    final i = _countries.indexWhere((c) => c.code == code);
    final c = _countries[i];
    if (active && !c.ready) {
      return const Err(ValidationFailure('country_not_ready'));
    }
    gestures.add('$code:${active ? 'on' : 'off'}');
    _countries[i] = AdminCountry(
      code: c.code,
      name: c.name,
      currencyCode: c.currencyCode,
      dialCode: c.dialCode,
      timezone: c.timezone,
      isActive: active,
      missing: c.missing,
    );
    return Ok(List.of(_countries));
  }

  @override
  Future<Result<List<AdminCity>>> geography(String country) async =>
      _fail<List<AdminCity>>() ?? Ok(_cities[country] ?? const []);

  @override
  Future<Result<List<AdminCity>>> saveCity(Map<String, Object?> city) async {
    final failed = _fail<List<AdminCity>>();
    if (failed != null) return failed;
    final country = city['country_code']! as String;
    final list = [...?_cities[country]];
    final id = city['id'] as String?;
    final i = list.indexWhere((c) => c.id == id);
    final next = AdminCity(
      id: id ?? 'c${list.length + 1}',
      name: city['name'] as String? ?? list[i].name,
      isActive: city['is_active'] as bool? ?? (i < 0 || list[i].isActive),
      deliveryMinutes:
          city['delivery_minutes'] as int? ??
          (i < 0 ? 30 : list[i].deliveryMinutes),
      zones: i < 0 ? const [] : list[i].zones,
    );
    if (i < 0) {
      list.add(next);
    } else {
      list[i] = next;
    }
    gestures.add('city:${next.name}');
    return Ok(_cities[country] = list);
  }

  @override
  Future<Result<List<AdminCity>>> saveZone(Map<String, Object?> zone) async {
    final failed = _fail<List<AdminCity>>();
    if (failed != null) return failed;
    final cityId = zone['city_id'] as String?;
    for (final e in _cities.entries) {
      final ci = e.value.indexWhere(
        (c) => c.id == cityId || c.zones.any((z) => z.id == zone['id']),
      );
      if (ci < 0) continue;
      final city = e.value[ci];
      final zones = [...city.zones];
      final id = zone['id'] as String?;
      final zi = zones.indexWhere((z) => z.id == id);
      final next = AdminZone(
        id: id ?? 'z${zones.length + 10}',
        name: zone['name'] as String? ?? zones[zi].name,
        isActive: zone['is_active'] as bool? ?? (zi < 0 || zones[zi].isActive),
      );
      if (zi < 0) {
        zones.add(next);
      } else {
        zones[zi] = next;
      }
      gestures.add('zone:${next.name}');
      final list = [...e.value];
      list[ci] = AdminCity(
        id: city.id,
        name: city.name,
        isActive: city.isActive,
        deliveryMinutes: city.deliveryMinutes,
        zones: zones,
      );
      return Ok(_cities[e.key] = list);
    }
    return const Err(NotFoundFailure('ville'));
  }

  @override
  Future<Result<AdminPaymentSettings>> paymentMethods(String country) async =>
      _fail<AdminPaymentSettings>() ??
      Ok(
        AdminPaymentSettings(
          methods: _methods[country] ?? const [],
          providers: const [
            AdminPaymentProvider(
              code: 'cash',
              label: LocalizedText({'fr': 'Cash', 'en': 'Cash'}),
              kind: 'cash',
              isActive: true,
            ),
            AdminPaymentProvider(
              code: 'simulator',
              label: LocalizedText({'fr': 'Mobile Money (simulé)'}),
              kind: 'mobile_money',
              isActive: true,
            ),
          ],
        ),
      );

  @override
  Future<Result<AdminPaymentSettings>> savePaymentMethod(
    Map<String, Object?> method,
  ) async {
    final failed = _fail<AdminPaymentSettings>();
    if (failed != null) return failed;
    final id = method['id'] as String?;
    for (final e in _methods.entries) {
      final i = e.value.indexWhere((m) => m.id == id);
      if (i < 0) continue;
      final m = e.value[i];
      final list = [...e.value];
      list[i] = AdminPaymentMethod(
        id: m.id,
        countryCode: m.countryCode,
        providerCode: m.providerCode,
        label: m.label,
        isActive: method['is_active'] as bool? ?? m.isActive,
        kind: m.kind,
      );
      gestures.add('method:${m.id}:${list[i].isActive}');
      _methods[e.key] = list;
      return await paymentMethods(e.key);
    }
    final country = method['country_code']! as String;
    final created = AdminPaymentMethod(
      id: 'm${_methods.length + 10}',
      countryCode: country,
      providerCode: method['provider_code']! as String,
      label: LocalizedText(
        (method['label']! as Map).map((k, v) => MapEntry('$k', '$v')),
      ),
      isActive: method['is_active'] as bool? ?? false,
    );
    _methods[country] = [...?_methods[country], created];
    gestures.add('method:${created.providerCode}');
    return await paymentMethods(country);
  }

  @override
  Future<Result<AdminPricing>> pricing(String country) async =>
      _fail<AdminPricing>() ??
      Ok(_pricing[country] ?? AdminPricing(currencyCode: currency.code));

  @override
  Future<Result<AdminPricing>> setCommission(
    String country, {
    required int rateBps,
    String? categoryId,
  }) async {
    final failed = _fail<AdminPricing>();
    if (failed != null) return failed;
    final p = _pricing[country] ?? AdminPricing(currencyCode: currency.code);
    gestures.add('commission:$rateBps');
    return Ok(
      _pricing[country] = AdminPricing(
        currencyCode: p.currencyCode,
        commissions: [
          for (final c in p.commissions)
            if (c.categoryId != categoryId) c,
          AdminCommission(
            id: 'k$rateBps',
            rateBps: rateBps,
            categoryId: categoryId,
          ),
        ],
        deliveryFees: p.deliveryFees,
      ),
    );
  }

  @override
  Future<Result<AdminPricing>> setDeliveryFee(
    String country, {
    required int baseFeeMinor,
    required int extraPickupFeeMinor,
    int? freeThresholdMinor,
    String? cityId,
  }) async {
    final failed = _fail<AdminPricing>();
    if (failed != null) return failed;
    final p = _pricing[country] ?? AdminPricing(currencyCode: currency.code);
    gestures.add('fee:$baseFeeMinor');
    return Ok(
      _pricing[country] = AdminPricing(
        currencyCode: p.currencyCode,
        commissions: p.commissions,
        deliveryFees: [
          for (final f in p.deliveryFees)
            if (f.cityId != cityId) f,
          AdminDeliveryFee(
            id: 'f$baseFeeMinor',
            cityId: cityId,
            baseFeeMinor: baseFeeMinor,
            extraPickupFeeMinor: extraPickupFeeMinor,
            freeThresholdMinor: freeThresholdMinor,
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<List<AdminCategory>>> categories() async =>
      _fail<List<AdminCategory>>() ?? Ok(List.of(_categories));

  @override
  Future<Result<List<AdminCategory>>> saveCategory(
    Map<String, Object?> category,
  ) async {
    final failed = _fail<List<AdminCategory>>();
    if (failed != null) return failed;
    final id = category['id'] as String?;
    final i = _categories.indexWhere((c) => c.id == id);
    final label = category['label'] as Map?;
    final next = AdminCategory(
      id: id ?? 'k${_categories.length + 10}',
      parentId:
          category['parent_id'] as String? ??
          (i < 0 ? null : _categories[i].parentId),
      slug: i < 0 ? 'nouvelle' : _categories[i].slug,
      label: label == null
          ? _categories[i].label
          : LocalizedText(label.map((k, v) => MapEntry('$k', '$v'))),
      isActive:
          category['is_active'] as bool? ?? (i < 0 || _categories[i].isActive),
    );
    if (i < 0) {
      _categories.add(next);
    } else {
      _categories[i] = next;
    }
    gestures.add('category:${next.label.resolve('fr')}:${next.isActive}');
    return Ok(List.of(_categories));
  }

  // ---------------------------------------------------------------- journal

  @override
  Future<Result<AdminAuditPage>> audit({
    String? query,
    String? action,
    String? entityType,
    int offset = 0,
  }) async {
    final failed = _fail<AdminAuditPage>();
    if (failed != null) return failed;
    final q = query?.trim().toLowerCase() ?? '';
    final hits = [
      for (final e in _audit)
        if ((action == null || e.action == action) &&
            (entityType == null || e.entityType == entityType) &&
            (q.isEmpty ||
                e.action.contains(q) ||
                (e.reason ?? '').toLowerCase().contains(q) ||
                (e.entityId ?? '').toLowerCase().contains(q)))
          e,
    ];
    return Ok(
      AdminAuditPage(
        total: hits.length,
        entries: hits.skip(offset).take(50).toList(),
        actions: {for (final e in _audit) e.action}.toList(),
        entityTypes: {for (final e in _audit) ?e.entityType}.toList(),
      ),
    );
  }
}
