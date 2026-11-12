import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Admin des opérations (spec 013). Lectures et réglages par la Data API ;
/// gestes qui préviennent quelqu'un ou appellent un fournisseur par la
/// Function. La base vérifie le rôle admin (`ForbiddenFailure` sinon).
class AdminRepository {
  new({required this._data, required this._functions});

  final NeonDataClient _data;
  final NeonFunctionsClient _functions;

  // ---------------------------------------------------------------- commandes

  Future<Result<AdminOrderPage>> orders({
    AdminOrderFilter filter = AdminOrderFilter.all,
    String? query,
    int limit = 50,
    int offset = 0,
  }) => _rpc('admin_orders', {
    'p_filter': filter.code,
    'p_query': query,
    'p_limit': limit,
    'p_offset': offset,
  }, (json) => AdminOrderPage.fromJson(_map(json)));

  Future<Result<AdminOrder>> order(String id) => _rpc('admin_order', {
    'p_id': id,
  }, (json) => AdminOrder.fromJson(_map(json)));

  /// Refus (`ValidationFailure.message`) : `status_changed`, `order_closed`,
  /// `payment_pending`, `transition_not_allowed`, `reason_required`.
  Future<Result<AdminOrder>> forceStatus(
    AdminOrder order,
    OrderStatus to,
    String reason,
  ) => _post('/v1/admin/orders/${order.id}/status', {
    'to': to.code,
    'expected': order.status.code,
    'reason': reason,
  }, (json) => AdminOrder.fromJson(_map(json)));

  /// Annulation ; remboursement du total créé si l'achat est payé en ligne.
  Future<Result<AdminOrder>> cancel(AdminOrder order, String reason) => _post(
    '/v1/admin/orders/${order.id}/cancel',
    {'expected': order.status.code, 'reason': reason},
    (json) => AdminOrder.fromJson(_map(json)),
  );

  /// Refus : `courier_not_allowed`.
  Future<Result<AdminOrder>> assignCourier(
    String orderId, {
    required String name,
    required String phone,
  }) => _post('/v1/admin/orders/$orderId/courier', {
    'name': name,
    'phone': phone,
  }, (json) => AdminOrder.fromJson(_map(json)));

  // ---------------------------------------------------------------- litiges

  Future<Result<List<AdminDisputeRow>>> disputes({bool open = true}) => _rpc(
    'admin_disputes',
    {'p_status': open ? 'open' : 'resolved', 'p_limit': 100},
    (json) => [
      for (final d in json! as List) AdminDisputeRow.fromJson(_map(d)),
    ],
  );

  Future<Result<AdminDispute>> dispute(String id) => _rpc('admin_dispute', {
    'p_id': id,
  }, (json) => AdminDispute.fromJson(_map(json)));

  Future<Result<Dispute>> replyDispute(String id, String body) => _post(
    '/v1/disputes/$id/messages',
    {'body': body},
    (json) => Dispute.fromJson(_map(json)),
  );

  /// Décision. Refus : `dispute_closed`, `refund_amount_invalid`.
  Future<Result<Dispute>> resolveDispute(
    String id, {
    required DisputeResolution resolution,
    int? refundMinor,
    String? internalNote,
    bool warnVendor = false,
  }) => _post('/v1/admin/disputes/$id/resolve', {
    'resolution': switch (resolution) {
      DisputeResolution.partialRefund => 'partial_refund',
      DisputeResolution.fullRefund => 'full_refund',
      _ => 'no_action',
    },
    'refund_minor': resolution == DisputeResolution.partialRefund
        ? refundMinor
        : null,
    'internal_note': internalNote,
    'warn_vendor': warnVendor,
  }, (json) => Dispute.fromJson(_map(json)));

  // ---------------------------------------------------------------- finances

  Future<Result<List<AdminRefund>>> refunds({
    RefundStatus status = RefundStatus.pending,
  }) => _rpc('admin_refunds', {
    'p_status': switch (status) {
      RefundStatus.succeeded => 'succeeded',
      RefundStatus.failed => 'failed',
      _ => 'pending',
    },
    'p_limit': 100,
  }, (json) => [for (final r in json! as List) AdminRefund.fromJson(_map(r))]);

  Future<Result<List<AdminPendingPayment>>> pendingPayments() => _rpc(
    'admin_pending_payments',
    {'p_limit': 100},
    (json) => [
      for (final p in json! as List) AdminPendingPayment.fromJson(_map(p)),
    ],
  );

  /// Exécution par le fournisseur. Refus : `refund_not_pending`,
  /// `refund_not_provider`, `payment_not_found`.
  Future<Result<AdminRefund>> executeRefund(String id) => _post(
    '/v1/admin/refunds/$id/execute',
    const {},
    (json) => AdminRefund.fromJson(_map(json)),
  );

  /// Cash remis en main propre. Refus : `refund_not_cash`,
  /// `refund_not_pending`.
  Future<Result<AdminRefund>> markCashRefund(String id) => _post(
    '/v1/admin/refunds/$id/cash',
    const {},
    (json) => AdminRefund.fromJson(_map(json)),
  );

  // ---------------------------------------------------------------- boutiques

  Future<Result<AdminStorePage>> stores({
    AdminStoreStatus status = AdminStoreStatus.active,
    String? query,
    int limit = 50,
    int offset = 0,
  }) => _rpc('admin_stores', {
    'p_status': status.code,
    'p_query': query,
    'p_limit': limit,
    'p_offset': offset,
  }, (json) => AdminStorePage.fromJson(_map(json)));

  Future<Result<AdminStore>> store(String id) => _rpc('admin_store', {
    'p_id': id,
  }, (json) => AdminStore.fromJson(_map(json)));

  /// Suspendre ou réactiver. Refus : `reason_required`,
  /// `store_status_unchanged`.
  Future<Result<AdminStore>> setStoreStatus(
    String id, {
    required bool suspended,
    required String reason,
  }) => _post('/v1/admin/stores/$id/status', {
    'status': suspended ? 'suspended' : 'active',
    'reason': reason,
  }, (json) => AdminStore.fromJson(_map(json)));

  /// Corrections (nom, description, quartier, préparation, retrait).
  Future<Result<AdminStore>> updateStore(
    String id,
    Map<String, Object?> patch,
    String reason,
  ) => _rpc('admin_update_store', {
    'p_id': id,
    'p_patch': patch,
    'p_reason': reason,
  }, (json) => AdminStore.fromJson(_map(json)));

  // ---------------------------------------------------------------- réglages

  Future<Result<List<AdminCountry>>> countries() => _rpc(
    'admin_countries',
    const {},
    (json) => [for (final c in json! as List) AdminCountry.fromJson(_map(c))],
  );

  /// Refus : `country_not_ready`.
  Future<Result<List<AdminCountry>>> setCountryActive(
    String code, {
    required bool active,
  }) => _rpc('admin_set_country_active', {
    'p_code': code,
    'p_active': active,
  }, (json) => [for (final c in json! as List) AdminCountry.fromJson(_map(c))]);

  Future<Result<List<AdminCity>>> geography(String country) =>
      _rpc('admin_geography', {'p_country': country}, _cities);

  Future<Result<List<AdminCity>>> saveCity(Map<String, Object?> city) =>
      _rpc('admin_save_city', {'p_city': city}, _cities);

  Future<Result<List<AdminCity>>> saveZone(Map<String, Object?> zone) =>
      _rpc('admin_save_zone', {'p_zone': zone}, _cities);

  Future<Result<AdminPaymentSettings>> paymentMethods(String country) => _rpc(
    'admin_payment_methods',
    {'p_country': country},
    (json) => AdminPaymentSettings.fromJson(_map(json)),
  );

  /// Refus : `provider_inactive`.
  Future<Result<AdminPaymentSettings>> savePaymentMethod(
    Map<String, Object?> method,
  ) => _rpc('admin_save_payment_method', {
    'p_method': method,
  }, (json) => AdminPaymentSettings.fromJson(_map(json)));

  Future<Result<AdminPricing>> pricing(String country) => _rpc(
    'admin_pricing',
    {'p_country': country},
    (json) => AdminPricing.fromJson(_map(json)),
  );

  Future<Result<AdminPricing>> setCommission(
    String country, {
    required int rateBps,
    String? categoryId,
  }) => _rpc('admin_set_commission', {
    'p_country': country,
    'p_category': categoryId,
    'p_rate_bps': rateBps,
  }, (json) => AdminPricing.fromJson(_map(json)));

  Future<Result<AdminPricing>> setDeliveryFee(
    String country, {
    required int baseFeeMinor,
    required int extraPickupFeeMinor,
    int? freeThresholdMinor,
    String? cityId,
  }) => _rpc('admin_set_delivery_fee', {
    'p_country': country,
    'p_city': cityId,
    'p_base_fee_minor': baseFeeMinor,
    'p_extra_pickup_fee_minor': extraPickupFeeMinor,
    'p_free_threshold_minor': freeThresholdMinor,
  }, (json) => AdminPricing.fromJson(_map(json)));

  Future<Result<List<AdminCategory>>> categories() =>
      _rpc('admin_categories', const {}, _categories);

  Future<Result<List<AdminCategory>>> saveCategory(
    Map<String, Object?> category,
  ) => _rpc('admin_save_category', {'p_category': category}, _categories);

  // ---------------------------------------------------------------- journal

  Future<Result<AdminAuditPage>> audit({
    String? query,
    String? action,
    String? entityType,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) => _rpc('admin_audit', {
    'p_query': query,
    'p_action': action,
    'p_entity_type': entityType,
    'p_from': from?.toUtc().toIso8601String(),
    'p_to': to?.toUtc().toIso8601String(),
    'p_limit': limit,
    'p_offset': offset,
  }, (json) => AdminAuditPage.fromJson(_map(json)));

  // ---------------------------------------------------------------- pilote

  /// Tableau de bord (écran 67). [period] : `day`, `week`, `month`, `30d`.
  Future<Result<AdminDashboard>> dashboard(String period) => _rpc(
    'admin_dashboard',
    {'p_period': period},
    (json) => AdminDashboard.fromJson(_map(json)),
  );

  /// Positions hors des zones desservies (spec 065).
  Future<Result<AdminCoverage>> coverage(String period) => _rpc(
    'admin_coverage',
    {'p_period': period},
    (json) => AdminCoverage.fromJson(_map(json)),
  );

  /// Revenus (écran 70). [period] : `month`, `last_month`, `30d`.
  Future<Result<AdminRevenue>> revenue(String period) => _rpc('admin_revenue', {
    'p_period': period,
  }, (json) => AdminRevenue.fromJson(_map(json)));

  /// Réglages de la recherche (spec 028).
  Future<Result<AdminSearchSettings>> searchSettings() =>
      _rpc('admin_search_settings', const {}, _searchSettings);

  /// Poids d'un pays (nul : défaut) ; audité.
  Future<Result<AdminSearchSettings>> setRanking(
    String? countryCode,
    Map<String, int> weights,
  ) => _rpc('admin_set_ranking', {
    'p_country': countryCode,
    'p_weights': weights,
  }, _searchSettings);

  /// Synonymes d'un terme (liste vide : terme retiré) ; audité.
  Future<Result<AdminSearchSettings>> setSynonym(
    String? countryCode,
    String term,
    List<String> synonyms,
  ) => _rpc('admin_set_synonym', {
    'p_country': countryCode,
    'p_term': term,
    'p_synonyms': synonyms,
  }, _searchSettings);

  static AdminSearchSettings _searchSettings(Object? value) =>
      AdminSearchSettings.fromJson(value! as Map<String, dynamic>);

  Future<Result<List<AdminFeatureFlag>>> featureFlags() =>
      _rpc('admin_feature_flags', const {}, _flags);

  // ---------------------------------------------------------------- admins

  Future<Result<List<AdminMember>>> admins() =>
      _rpc('admin_admins', const {}, _members);

  /// L'email devient admin à sa première connexion (tout de suite s'il a un
  /// compte vérifié).
  Future<Result<List<AdminMember>>> inviteAdmin(String email) =>
      _rpc('admin_invite_admin', {'p_email': email}, _members);

  Future<Result<List<AdminMember>>> removeAdmin(String email) =>
      _rpc('admin_remove_admin', {'p_email': email}, _members);

  static List<AdminMember> _members(Object? json) => [
    for (final m in json! as List) AdminMember.fromJson(_map(m)),
  ];

  Future<Result<List<AdminFeatureFlag>>> setFeatureFlag(
    String key, {
    required bool enabled,
    String? countryCode,
  }) => _rpc('admin_set_feature_flag', {
    'p_key': key,
    'p_country': countryCode,
    'p_enabled': enabled,
  }, _flags);

  Future<Result<List<SupportTicket>>> tickets(TicketStatus status) => _rpc(
    'admin_tickets',
    {
      'p_status': switch (status) {
        TicketStatus.pending => 'pending',
        TicketStatus.closed => 'closed',
        _ => 'open',
      },
    },
    (json) => [for (final t in json! as List) SupportTicket.fromJson(_map(t))],
  );

  Future<Result<SupportTicket>> replyTicket(String id, String body) => _post(
    '/v1/admin/tickets/$id/reply',
    {'body': body},
    (json) => SupportTicket.fromJson(_map(json)),
  );

  /// Brouillon de réponse rédigé par l'agent support (spec 054) ; l'équipe
  /// relit et envoie. `unavailable` : aucun modèle actif.
  Future<Result<String>> draftReply(String id) => _post(
    '/v1/admin/tickets/$id/draft',
    const {},
    (json) => (json! as Map)['draft'] as String,
  );

  Future<Result<SupportTicket>> closeTicket(String id) => _rpc(
    'admin_close_ticket',
    {'p_ticket': id},
    (json) => SupportTicket.fromJson(_map(json)),
  );

  Future<Result<List<AdminClientRow>>> clients({String? query}) => _rpc(
    'admin_clients',
    {'p_query': query},
    (json) => [for (final c in json! as List) AdminClientRow.fromJson(_map(c))],
  );

  /// Profil d'une cliente ; la consultation est auditée.
  Future<Result<AdminClient>> client(String id) => _rpc('admin_client', {
    'p_user': id,
  }, (json) => AdminClient.fromJson(_map(json)));

  /// Vue de l'app d'une vendeuse, en lecture ; la consultation est auditée.
  Future<Result<AdminVendorView>> vendorView(String storeId) => _rpc(
    'admin_vendor_view',
    {'p_store': storeId},
    (json) => AdminVendorView.fromJson(_map(json)),
  );

  /// Refus : `vendor_has_orders`, `reason_required`.
  Future<Result<void>> deleteVendor(String storeId, String reason) =>
      _post('/v1/admin/stores/$storeId/delete', {'reason': reason}, (_) {});

  /// IA et paiements (écran 77).
  Future<Result<AiHealth>> aiHealth() => _rpc(
    'admin_ai_health',
    const {},
    (json) => AiHealth.fromJson(_map(json)),
  );

  /// File de modération (écran 76) : signalés (`open`) ou traités.
  Future<Result<List<ModerationItem>>> reports({bool decided = false}) => _rpc(
    'admin_reports',
    {'p_status': decided ? 'decided' : 'open'},
    (json) => [for (final r in json! as List) ModerationItem.fromJson(_map(r))],
  );

  /// Garder ou retirer, raison obligatoire (`reason_required`).
  Future<Result<void>> moderate(
    ReportTarget target,
    String targetId, {
    required bool remove,
    required String reason,
  }) => _rpc('admin_moderate', {
    'p_target_type': target.name,
    'p_target_id': targetId,
    'p_decision': remove ? 'removed' : 'kept',
    'p_reason': reason,
  }, (_) {});

  static List<AdminFeatureFlag> _flags(Object? json) => [
    for (final f in json! as List) AdminFeatureFlag.fromJson(_map(f)),
  ];

  // ---------------------------------------------------------------- outils

  static Map<String, dynamic> _map(Object? json) =>
      json! as Map<String, dynamic>;

  static List<AdminCity> _cities(Object? json) => [
    for (final c in json! as List) AdminCity.fromJson(_map(c)),
  ];

  static List<AdminCategory> _categories(Object? json) => [
    for (final c in json! as List) AdminCategory.fromJson(_map(c)),
  ];

  Future<Result<T>> _rpc<T>(
    String name,
    Map<String, Object?> params,
    T Function(Object? json) decode,
  ) async => _decode(await _data.rpc<Object?>(name, params: params), decode);

  Future<Result<T>> _post<T>(
    String path,
    Map<String, Object?> body,
    T Function(Object? json) decode,
  ) async => _decode(
    await _functions.post<Object?>(path, body: body, decode: (json) => json),
    decode,
  );

  Result<T> _decode<T>(Result<Object?> result, T Function(Object? json) f) {
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        try {
          return Ok(f(value));
        } on Object {
          return const Err(ServerFailure('réponse illisible'));
        }
    }
  }
}
