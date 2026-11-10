import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';

/// Admin des opérations (spec 013) : commandes, litiges, finances,
/// boutiques, réglages et journal. Remplaçable en test.
abstract interface class AdminService {
  /// Devises du référentiel (montants de tous les pays).
  Future<Result<Map<String, Currency>>> currencies();

  Future<Result<AdminOrderPage>> orders({
    AdminOrderFilter filter = AdminOrderFilter.all,
    String? query,
    int offset = 0,
  });

  Future<Result<AdminOrder>> order(String id);

  Future<Result<AdminOrder>> forceStatus(
    AdminOrder order,
    OrderStatus to,
    String reason,
  );

  Future<Result<AdminOrder>> cancel(AdminOrder order, String reason);

  Future<Result<AdminOrder>> assignCourier(
    String orderId, {
    required String name,
    required String phone,
  });

  Future<Result<List<AdminDisputeRow>>> disputes();

  Future<Result<AdminDispute>> dispute(String id);

  Future<Result<Dispute>> replyDispute(String id, String body);

  Future<Result<Dispute>> resolveDispute(
    String id, {
    required DisputeResolution resolution,
    int? refundMinor,
    String? internalNote,
    bool warnVendor = false,
  });

  Future<Result<List<AdminRefund>>> refunds(RefundStatus status);

  Future<Result<List<AdminPendingPayment>>> pendingPayments();

  Future<Result<AdminRefund>> executeRefund(String id);

  Future<Result<AdminRefund>> markCashRefund(String id);

  Future<Result<AdminStorePage>> stores({
    AdminStoreStatus status = AdminStoreStatus.active,
    String? query,
  });

  Future<Result<AdminStore>> store(String id);

  Future<Result<AdminStore>> setStoreStatus(
    String id, {
    required bool suspended,
    required String reason,
  });

  Future<Result<AdminStore>> updateStore(
    String id,
    Map<String, Object?> patch,
    String reason,
  );

  Future<Result<List<AdminCountry>>> countries();

  Future<Result<List<AdminCountry>>> setCountryActive(
    String code, {
    required bool active,
  });

  Future<Result<List<AdminCity>>> geography(String country);

  Future<Result<List<AdminCity>>> saveCity(Map<String, Object?> city);

  Future<Result<List<AdminCity>>> saveZone(Map<String, Object?> zone);

  Future<Result<AdminPaymentSettings>> paymentMethods(String country);

  Future<Result<AdminPaymentSettings>> savePaymentMethod(
    Map<String, Object?> method,
  );

  Future<Result<AdminPricing>> pricing(String country);

  Future<Result<AdminPricing>> setCommission(
    String country, {
    required int rateBps,
    String? categoryId,
  });

  Future<Result<AdminPricing>> setDeliveryFee(
    String country, {
    required int baseFeeMinor,
    required int extraPickupFeeMinor,
    int? freeThresholdMinor,
    String? cityId,
  });

  Future<Result<List<AdminCategory>>> categories();

  Future<Result<List<AdminCategory>>> saveCategory(
    Map<String, Object?> category,
  );

  Future<Result<AdminAuditPage>> audit({
    String? query,
    String? action,
    String? entityType,
    int offset = 0,
  });

  // ---------------------------------------------------------------- pilote

  Future<Result<AdminDashboard>> dashboard(String period);

  Future<Result<AdminRevenue>> revenue(String period);

  Future<Result<List<AdminFeatureFlag>>> featureFlags();

  /// Réglages de la recherche (spec 028).
  Future<Result<AdminSearchSettings>> searchSettings();
  Future<Result<AdminSearchSettings>> setRanking(
    String? countryCode,
    Map<String, int> weights,
  );
  Future<Result<AdminSearchSettings>> setSynonym(
    String? countryCode,
    String term,
    List<String> synonyms,
  );

  Future<Result<List<AdminMember>>> admins();

  Future<Result<List<AdminMember>>> inviteAdmin(String email);

  Future<Result<List<AdminMember>>> removeAdmin(String email);

  Future<Result<List<AdminFeatureFlag>>> setFeatureFlag(
    String key, {
    required bool enabled,
    String? countryCode,
  });

  Future<Result<List<SupportTicket>>> tickets(TicketStatus status);

  Future<Result<SupportTicket>> replyTicket(String id, String body);

  /// Brouillon de l'agent support (spec 054).
  Future<Result<String>> draftReply(String id);

  Future<Result<SupportTicket>> closeTicket(String id);

  Future<Result<List<AdminClientRow>>> clients({String? query});

  Future<Result<AdminClient>> client(String id);

  Future<Result<AdminVendorView>> vendorView(String storeId);

  Future<Result<void>> deleteVendor(String storeId, String reason);

  /// IA et paiements (écran 77).
  Future<Result<AiHealth>> aiHealth();

  /// File de modération (écran 76).
  Future<Result<List<ModerationItem>>> reports({bool decided = false});

  /// Garder ou retirer une cible signalée ; raison obligatoire.
  Future<Result<void>> moderate(
    ReportTarget target,
    String targetId, {
    required bool remove,
    required String reason,
  });
}

/// Implémentation Neon.
class NeonAdminService implements AdminService {
  new({required this._admin, required this._reference});

  final AdminRepository _admin;
  final ReferenceRepository _reference;
  Map<String, Currency>? _currencies;

  @override
  Future<Result<Map<String, Currency>>> currencies() async {
    final cached = _currencies;
    if (cached != null) return Ok(cached);
    switch (await _reference.currencies()) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        return Ok(
          _currencies = {for (final c in value) c.code: c.toCurrency()},
        );
    }
  }

  @override
  Future<Result<AdminOrderPage>> orders({
    AdminOrderFilter filter = AdminOrderFilter.all,
    String? query,
    int offset = 0,
  }) => _admin.orders(filter: filter, query: query, offset: offset);

  @override
  Future<Result<AdminOrder>> order(String id) => _admin.order(id);

  @override
  Future<Result<AdminOrder>> forceStatus(
    AdminOrder order,
    OrderStatus to,
    String reason,
  ) => _admin.forceStatus(order, to, reason);

  @override
  Future<Result<AdminOrder>> cancel(AdminOrder order, String reason) =>
      _admin.cancel(order, reason);

  @override
  Future<Result<AdminOrder>> assignCourier(
    String orderId, {
    required String name,
    required String phone,
  }) => _admin.assignCourier(orderId, name: name, phone: phone);

  @override
  Future<Result<List<AdminDisputeRow>>> disputes() => _admin.disputes();

  @override
  Future<Result<AdminDispute>> dispute(String id) => _admin.dispute(id);

  @override
  Future<Result<Dispute>> replyDispute(String id, String body) =>
      _admin.replyDispute(id, body);

  @override
  Future<Result<Dispute>> resolveDispute(
    String id, {
    required DisputeResolution resolution,
    int? refundMinor,
    String? internalNote,
    bool warnVendor = false,
  }) => _admin.resolveDispute(
    id,
    resolution: resolution,
    refundMinor: refundMinor,
    internalNote: internalNote,
    warnVendor: warnVendor,
  );

  @override
  Future<Result<List<AdminRefund>>> refunds(RefundStatus status) =>
      _admin.refunds(status: status);

  @override
  Future<Result<List<AdminPendingPayment>>> pendingPayments() =>
      _admin.pendingPayments();

  @override
  Future<Result<AdminRefund>> executeRefund(String id) =>
      _admin.executeRefund(id);

  @override
  Future<Result<AdminRefund>> markCashRefund(String id) =>
      _admin.markCashRefund(id);

  @override
  Future<Result<AdminStorePage>> stores({
    AdminStoreStatus status = AdminStoreStatus.active,
    String? query,
  }) => _admin.stores(status: status, query: query);

  @override
  Future<Result<AdminStore>> store(String id) => _admin.store(id);

  @override
  Future<Result<AdminStore>> setStoreStatus(
    String id, {
    required bool suspended,
    required String reason,
  }) => _admin.setStoreStatus(id, suspended: suspended, reason: reason);

  @override
  Future<Result<AdminStore>> updateStore(
    String id,
    Map<String, Object?> patch,
    String reason,
  ) => _admin.updateStore(id, patch, reason);

  @override
  Future<Result<List<AdminCountry>>> countries() => _admin.countries();

  @override
  Future<Result<List<AdminCountry>>> setCountryActive(
    String code, {
    required bool active,
  }) => _admin.setCountryActive(code, active: active);

  @override
  Future<Result<List<AdminCity>>> geography(String country) =>
      _admin.geography(country);

  @override
  Future<Result<List<AdminCity>>> saveCity(Map<String, Object?> city) =>
      _admin.saveCity(city);

  @override
  Future<Result<List<AdminCity>>> saveZone(Map<String, Object?> zone) =>
      _admin.saveZone(zone);

  @override
  Future<Result<AdminPaymentSettings>> paymentMethods(String country) =>
      _admin.paymentMethods(country);

  @override
  Future<Result<AdminPaymentSettings>> savePaymentMethod(
    Map<String, Object?> method,
  ) => _admin.savePaymentMethod(method);

  @override
  Future<Result<AdminPricing>> pricing(String country) =>
      _admin.pricing(country);

  @override
  Future<Result<AdminPricing>> setCommission(
    String country, {
    required int rateBps,
    String? categoryId,
  }) => _admin.setCommission(country, rateBps: rateBps, categoryId: categoryId);

  @override
  Future<Result<AdminPricing>> setDeliveryFee(
    String country, {
    required int baseFeeMinor,
    required int extraPickupFeeMinor,
    int? freeThresholdMinor,
    String? cityId,
  }) => _admin.setDeliveryFee(
    country,
    baseFeeMinor: baseFeeMinor,
    extraPickupFeeMinor: extraPickupFeeMinor,
    freeThresholdMinor: freeThresholdMinor,
    cityId: cityId,
  );

  @override
  Future<Result<List<AdminCategory>>> categories() => _admin.categories();

  @override
  Future<Result<List<AdminCategory>>> saveCategory(
    Map<String, Object?> category,
  ) => _admin.saveCategory(category);

  @override
  Future<Result<AdminAuditPage>> audit({
    String? query,
    String? action,
    String? entityType,
    int offset = 0,
  }) => _admin.audit(
    query: query,
    action: action,
    entityType: entityType,
    offset: offset,
  );

  @override
  Future<Result<AdminDashboard>> dashboard(String period) =>
      _admin.dashboard(period);

  @override
  Future<Result<AdminRevenue>> revenue(String period) => _admin.revenue(period);

  @override
  Future<Result<List<AdminFeatureFlag>>> featureFlags() =>
      _admin.featureFlags();

  @override
  Future<Result<AdminSearchSettings>> searchSettings() =>
      _admin.searchSettings();

  @override
  Future<Result<AdminSearchSettings>> setRanking(
    String? countryCode,
    Map<String, int> weights,
  ) => _admin.setRanking(countryCode, weights);

  @override
  Future<Result<AdminSearchSettings>> setSynonym(
    String? countryCode,
    String term,
    List<String> synonyms,
  ) => _admin.setSynonym(countryCode, term, synonyms);

  @override
  Future<Result<List<AdminMember>>> admins() => _admin.admins();

  @override
  Future<Result<List<AdminMember>>> inviteAdmin(String email) =>
      _admin.inviteAdmin(email);

  @override
  Future<Result<List<AdminMember>>> removeAdmin(String email) =>
      _admin.removeAdmin(email);

  @override
  Future<Result<List<AdminFeatureFlag>>> setFeatureFlag(
    String key, {
    required bool enabled,
    String? countryCode,
  }) => _admin.setFeatureFlag(key, enabled: enabled, countryCode: countryCode);

  @override
  Future<Result<List<SupportTicket>>> tickets(TicketStatus status) =>
      _admin.tickets(status);

  @override
  Future<Result<SupportTicket>> replyTicket(String id, String body) =>
      _admin.replyTicket(id, body);

  @override
  Future<Result<String>> draftReply(String id) => _admin.draftReply(id);

  @override
  Future<Result<SupportTicket>> closeTicket(String id) =>
      _admin.closeTicket(id);

  @override
  Future<Result<List<AdminClientRow>>> clients({String? query}) =>
      _admin.clients(query: query);

  @override
  Future<Result<AdminClient>> client(String id) => _admin.client(id);

  @override
  Future<Result<AdminVendorView>> vendorView(String storeId) =>
      _admin.vendorView(storeId);

  @override
  Future<Result<void>> deleteVendor(String storeId, String reason) =>
      _admin.deleteVendor(storeId, reason);

  @override
  Future<Result<AiHealth>> aiHealth() => _admin.aiHealth();

  @override
  Future<Result<List<ModerationItem>>> reports({bool decided = false}) =>
      _admin.reports(decided: decided);

  @override
  Future<Result<void>> moderate(
    ReportTarget target,
    String targetId, {
    required bool remove,
    required String reason,
  }) => _admin.moderate(target, targetId, remove: remove, reason: reason);
}
