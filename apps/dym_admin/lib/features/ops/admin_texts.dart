import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/material.dart';

/// Libellé d'un statut de commande.
String orderStatusLabel(DymLocalizations l10n, OrderStatus status) =>
    switch (status) {
      OrderStatus.pending => l10n.orderStatusPending,
      OrderStatus.accepted => l10n.orderStatusAccepted,
      OrderStatus.preparing => l10n.orderStatusPreparing,
      OrderStatus.ready => l10n.orderStatusReady,
      OrderStatus.outForDelivery => l10n.orderStatusOutForDelivery,
      OrderStatus.delivered => l10n.orderStatusDelivered,
      OrderStatus.refused => l10n.orderStatusRefused,
      OrderStatus.cancelled => l10n.orderStatusCancelled,
      OrderStatus.unknown => l10n.errorGeneric,
    };

/// Libellé d'un état de paiement d'achat.
String paymentStatusLabel(DymLocalizations l10n, PaymentStatus status) =>
    switch (status) {
      PaymentStatus.paid => l10n.adminPaid,
      PaymentStatus.cashOnDelivery => l10n.paymentCashOnDelivery,
      PaymentStatus.awaitingPayment => l10n.adminAwaitingPayment,
      PaymentStatus.failed => l10n.paymentFailedTitle,
      PaymentStatus.unknown => l10n.errorGeneric,
    };

/// Auteur d'une étape (cliente, vendeuse, équipe, système).
String actorLabel(DymLocalizations l10n, String role) => switch (role) {
  'client' => l10n.adminActorClient,
  'vendor' => l10n.adminActorVendor,
  'admin' => l10n.adminActorTeam,
  _ => l10n.adminActorSystem,
};

String disputeReasonLabel(DymLocalizations l10n, DisputeReason r) =>
    switch (r) {
      DisputeReason.missingItem => l10n.disputeReasonMissingItem,
      DisputeReason.wrongItem => l10n.disputeReasonWrongItem,
      DisputeReason.damaged => l10n.disputeReasonDamaged,
      DisputeReason.quality => l10n.disputeReasonQuality,
      DisputeReason.notDelivered => l10n.disputeReasonNotDelivered,
      _ => l10n.disputeReasonOther,
    };

/// Action du journal d'audit (code inconnu : affiché tel quel).
String auditActionLabel(DymLocalizations l10n, String action) =>
    switch (action) {
      'admin_signed_in' => l10n.adminAuditSignedIn,
      'order_status_forced' => l10n.adminAuditStatusForced,
      'order_cancelled' => l10n.adminAuditOrderCancelled,
      'courier_assigned' => l10n.adminAuditCourierAssigned,
      'dispute_resolved' => l10n.adminAuditDisputeResolved,
      'refund_succeeded' => l10n.adminAuditRefundSucceeded,
      'refund_failed' => l10n.adminAuditRefundFailed,
      'store_suspended' => l10n.adminAuditStoreSuspended,
      'store_reactivated' => l10n.adminAuditStoreReactivated,
      'store_updated' => l10n.adminAuditStoreUpdated,
      'country_activated' => l10n.adminAuditCountryActivated,
      'country_deactivated' => l10n.adminAuditCountryDeactivated,
      'city_created' || 'city_updated' => l10n.adminAuditCity,
      'zone_created' || 'zone_updated' => l10n.adminAuditZone,
      'payment_method_created' ||
      'payment_method_updated' => l10n.adminAuditPaymentMethod,
      'commission_set' => l10n.adminAuditCommission,
      'delivery_fee_set' => l10n.adminAuditDeliveryFee,
      'category_created' || 'category_updated' => l10n.adminAuditCategory,
      'role_granted' || 'role_revoked' => l10n.adminAuditRole,
      _ => action,
    };

/// Type d'entité du journal.
String auditEntityLabel(DymLocalizations l10n, String? type) => switch (type) {
  'order' => l10n.adminEntityOrder,
  'dispute' => l10n.adminEntityDispute,
  'refund' => l10n.adminEntityRefund,
  'store' => l10n.adminEntityStore,
  'country' => l10n.adminEntityCountry,
  'city' => l10n.adminEntityCity,
  'zone' => l10n.adminEntityZone,
  'payment_method' => l10n.adminEntityPaymentMethod,
  'category' => l10n.adminEntityCategory,
  'user' => l10n.adminEntityUser,
  _ => type ?? '',
};

/// Refus de la base traduit (codes `ValidationFailure.message`).
String adminFailureLabel(DymLocalizations l10n, Failure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.errorOffline,
      ForbiddenFailure() => l10n.adminAccessDenied,
      ValidationFailure(:final message) => switch (message) {
        'status_changed' => l10n.orderStatusChanged,
        'order_closed' => l10n.adminOrderClosed,
        'payment_pending' => l10n.adminPaymentPendingRefusal,
        'reason_required' => l10n.adminReasonRequired,
        'courier_not_allowed' => l10n.adminCourierNotAllowed,
        'dispute_closed' => l10n.adminDisputeClosed,
        'refund_amount_invalid' => l10n.adminRefundAmountInvalid,
        'refund_not_pending' => l10n.adminRefundNotPending,
        'country_not_ready' => l10n.adminCountryNotReady,
        'provider_inactive' => l10n.adminProviderInactive,
        'store_status_unchanged' => l10n.adminStoreStatusUnchanged,
        _ => l10n.errorGeneric,
      },
      _ => l10n.errorGeneric,
    };

/// Durée écoulée courte (« 52 min », « 2 h 04 »).
String sinceLabel(DymLocalizations l10n, DateTime at, DateTime now) {
  final d = now.difference(at);
  if (d.inHours < 1) return l10n.adminMinutes(d.inMinutes.clamp(0, 59));
  if (d.inDays < 1) {
    return l10n.adminHoursMinutes(
      d.inHours,
      (d.inMinutes % 60).toString().padLeft(2, '0'),
    );
  }
  return l10n.timeDaysAgo(d.inDays);
}

/// « il y a 5 min », « hier »…
String agoLabel(DymLocalizations l10n, DateTime at, DateTime now) {
  final d = now.difference(at);
  if (d.inMinutes < 1) return l10n.timeJustNow;
  if (d.inMinutes < 60) return l10n.timeMinutesAgo(d.inMinutes);
  if (d.inHours < 24) return l10n.timeHoursAgo(d.inHours);
  if (d.inDays < 2) return l10n.timeYesterday;
  return l10n.timeDaysAgo(d.inDays);
}

/// Date et heure locales courtes.
String dateTimeLabel(BuildContext context, DateTime at) {
  final m = MaterialLocalizations.of(context);
  return '${m.formatShortMonthDay(at.toLocal())} · '
      '${TimeOfDay.fromDateTime(at.toLocal()).format(context)}';
}

String timeLabel(BuildContext context, DateTime at) =>
    TimeOfDay.fromDateTime(at.toLocal()).format(context);

/// Référence lisible d'un identifiant (8 premiers caractères).
String shortRef(String id) =>
    (id.length > 8 ? id.substring(0, 8) : id).toUpperCase();

/// Montant formaté dans sa devise (vide si la devise est inconnue).
String moneyLabel(Map<String, Currency> currencies, int minor, String? code) {
  final currency = currencies[code];
  return currency == null ? '' : Money(minor, currency).format();
}
