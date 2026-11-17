import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/material.dart';

/// Libellé d'un statut (retrait : « Récupérée » au lieu de « Livrée »).
String orderStatusLabel(
  DymLocalizations l10n,
  OrderStatus status, {
  Fulfillment fulfillment = Fulfillment.delivery,
}) => switch (status) {
  OrderStatus.pending => l10n.orderStatusPending,
  OrderStatus.accepted => l10n.orderStatusAccepted,
  OrderStatus.preparing => l10n.orderStatusPreparing,
  OrderStatus.ready => l10n.orderStatusReady,
  OrderStatus.outForDelivery => l10n.orderStatusOutForDelivery,
  OrderStatus.delivered =>
    fulfillment == Fulfillment.pickup
        ? l10n.orderStatusCollected
        : l10n.orderStatusDelivered,
  OrderStatus.refused => l10n.orderStatusRefused,
  OrderStatus.cancelled => l10n.orderStatusCancelled,
  OrderStatus.unknown => l10n.errorGeneric,
};

String refusalReasonLabel(DymLocalizations l10n, RefusalReason? reason) =>
    switch (reason) {
      RefusalReason.outOfStock => l10n.reasonOutOfStock,
      RefusalReason.tooBusy => l10n.reasonTooBusy,
      RefusalReason.areaNotServed => l10n.reasonAreaNotServed,
      RefusalReason.noResponse => l10n.reasonNoResponse,
      _ => l10n.reasonOther,
    };

/// Heure locale courte (« 11:30 »).
String shortTime(BuildContext context, DateTime at) =>
    TimeOfDay.fromDateTime(at.toLocal()).format(context);

/// Date courte (« 01/10/2026 »).
String shortDate(BuildContext context, DateTime at) =>
    MaterialLocalizations.of(context).formatShortDate(at.toLocal());

/// « il y a 5 min », « hier »… par rapport à [now].
String timeAgo(DymLocalizations l10n, DateTime at, DateTime now) {
  final d = now.difference(at);
  if (d.inMinutes < 1) return l10n.timeJustNow;
  if (d.inMinutes < 60) return l10n.timeMinutesAgo(d.inMinutes);
  if (d.inHours < 24) return l10n.timeHoursAgo(d.inHours);
  if (d.inDays < 2) return l10n.timeYesterday;
  return l10n.timeDaysAgo(d.inDays);
}

/// Titre et texte d'une notification (type + paramètres).
(String, String) notificationText(DymLocalizations l10n, AppNotification n) {
  final store = n.param('store_name') ?? '';
  return switch (n.kind) {
    'order_accepted' => (
      l10n.notifAcceptedTitle,
      l10n.notifAcceptedBody(store),
    ),
    'order_refused' => (l10n.notifRefusedTitle, l10n.notifRefusedBody(store)),
    'order_preparing' => (
      l10n.orderStatusPreparing,
      l10n.notifPreparingBody(store),
    ),
    'order_ready' => (l10n.notifReadyTitle, l10n.notifReadyBody(store)),
    'order_out_for_delivery' => (
      l10n.orderStatusOutForDelivery,
      l10n.notifOnTheWayBody,
    ),
    'order_delivered' => (l10n.orderStatusDelivered, l10n.notifDeliveredBody),
    'payment_succeeded' => (l10n.paymentConfirmed, l10n.notifPaidBody),
    'payment_failed' => (
      l10n.notifPaymentFailedTitle,
      l10n.notifPaymentFailedBody,
    ),
    'new_order' => (
      l10n.notifNewOrderTitle,
      l10n.notifNewOrderBody(n.param('customer_first_name') ?? ''),
    ),
    'order_cancelled_by_client' => (
      l10n.notifCancelledByClientTitle,
      l10n.notifCancelledByClientBody,
    ),
    'new_message' => (
      l10n.notifNewMessageTitle,
      l10n.notifNewMessageBody(n.param('sender_name') ?? ''),
    ),
    // Groupes (spec 112).
    'new_message_group' => (
      n.param('group') ?? l10n.notifNewMessageTitle,
      l10n.notifGroupMessageBody(n.param('sender_name') ?? ''),
    ),
    'group_added' => (
      l10n.notifGroupAddedTitle,
      l10n.notifGroupAddedBody(
        n.param('by_name') ?? '',
        n.param('group') ?? '',
      ),
    ),
    'dispute_replied' => (
      l10n.notifDisputeRepliedTitle,
      l10n.notifDisputeRepliedBody(n.param('author') ?? ''),
    ),
    'dispute_resolved' => (
      l10n.notifDisputeResolvedTitle,
      l10n.notifDisputeResolvedBody,
    ),
    'store_broadcast' => (store, n.param('message') ?? ''),
    'space_validated' => (
      l10n.notifSpaceValidatedTitle,
      l10n.notifSpaceValidatedBody(
        n.param('by_name') ?? '',
        n.param('space_name') ?? '',
      ),
    ),
    'substitution_proposed' => (
      l10n.notifSubstitutionTitle,
      l10n.notifSubstitutionBody(
        n.param('item_name') ?? '',
        n.param('proposed_name') ?? '',
      ),
    ),
    'shopping_list_due' => (
      l10n.notifShoppingDueTitle,
      l10n.notifShoppingDueBody(n.param('list_name') ?? ''),
    ),
    'cart_reminder' => (
      l10n.notifCartReminderTitle,
      l10n.notifCartReminderBody(n.param('items_summary') ?? ''),
    ),
    _ => (l10n.notificationsTitle, ''),
  };
}

/// Icône d'une notification.
IconData notificationIcon(String kind) => switch (kind) {
  'order_accepted' || 'payment_succeeded' => Icons.check_circle_rounded,
  'order_preparing' => Icons.soup_kitchen_rounded,
  'order_ready' => Icons.shopping_bag_rounded,
  'order_out_for_delivery' => Icons.two_wheeler_rounded,
  'order_delivered' => Icons.home_rounded,
  'order_refused' || 'order_cancelled_by_client' => Icons.cancel_rounded,
  'payment_failed' => Icons.error_rounded,
  'dispute_replied' => Icons.forum_rounded,
  'new_message' => Icons.chat_bubble_rounded,
  'new_message_group' || 'group_added' => Icons.groups_rounded,
  'dispute_resolved' => Icons.verified_rounded,
  'store_broadcast' => Icons.campaign_rounded,
  'shopping_list_due' => Icons.checklist_rounded,
  'space_validated' => Icons.groups_rounded,
  'substitution_proposed' => Icons.swap_horiz_rounded,
  'cart_reminder' => Icons.shopping_basket_rounded,
  _ => Icons.notifications_rounded,
};
