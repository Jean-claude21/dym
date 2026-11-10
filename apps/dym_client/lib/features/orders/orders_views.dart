import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_client/features/orders/order_texts.dart';
import 'package:dym_client/features/orders/orders_service.dart';
import 'package:dym_client/features/orders/orders_viewmodels.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Pastille de statut (en cours : plantain ; acceptée : vert ; livrée :
/// neutre ; refusée ou annulée : piment clair).
class OrderStatusPill extends StatelessWidget {
  const new({required this.status, required this.fulfillment, super.key});

  final OrderStatus status;
  final Fulfillment fulfillment;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final (fill, ink) = switch (status) {
      OrderStatus.accepted => (c.brand, c.onBrand),
      OrderStatus.delivered => (
        c.textSecondary.withValues(alpha: 0.15),
        c.textPrimary,
      ),
      OrderStatus.refused || OrderStatus.cancelled => (
        c.pimentStrong.withValues(alpha: 0.12),
        c.pimentStrong,
      ),
      _ => (c.tintPlantainClair, c.textPrimary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DymTokenSpace.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
      ),
      child: Text(
        orderStatusLabel(l10n, status, fulfillment: fulfillment),
        style: context.dym.text.label.copyWith(
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
    );
  }
}

/// Cloche avec le nombre de non-lues.
class NotificationsBell extends StatelessWidget {
  const new({required this.service, required this.onOpen, super.key});

  final OrdersService service;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: service.unread,
      builder: (context, count, _) => IconButton(
        tooltip: count == 0
            ? l10n.notificationsTitle
            : '${l10n.notificationsTitle} · ${l10n.notificationsUnread(count)}',
        onPressed: onOpen,
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          backgroundColor: c.pimentStrong,
          child: Icon(Icons.notifications_rounded, color: c.textPrimary),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ 43

/// Écran 43 : mes commandes (en cours, puis terminées).
class MyOrdersView extends StackedView<MyOrdersViewModel> {
  const new({
    required this.service,
    required this.onOpen,
    required this.onNotifications,
    super.key,
  });

  final OrdersService service;
  final ValueChanged<String> onOpen;
  final VoidCallback onNotifications;

  @override
  MyOrdersViewModel viewModelBuilder(BuildContext context) =>
      MyOrdersViewModel(service: service);

  @override
  void onViewModelReady(MyOrdersViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    MyOrdersViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final header = DymContentWidth.form(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.ordersMineTitle,
                style: t.display.copyWith(fontSize: 30),
              ),
            ),
            NotificationsBell(service: service, onOpen: onNotifications),
          ],
        ),
      ),
    );
    Widget section(String title, List<CustomerOrder> orders) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s2),
          child: Text(title, style: t.title.copyWith(fontSize: 20)),
        ),
        for (final o in orders)
          Padding(
            padding: const EdgeInsets.only(bottom: DymTokenSpace.s3),
            child: _OrderRow(order: o, vm: vm, onTap: () => onOpen(o.id)),
          ),
      ],
    );
    return SafeArea(
      child: Column(
        children: [
          header,
          Expanded(
            child: !vm.ready
                ? DiscoveryState(
                    failure: vm.isBusy ? null : vm.failure,
                    onRetry: vm.load,
                  )
                : RefreshIndicator(
                    color: c.brand,
                    onRefresh: vm.refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        if (vm.offline)
                          DymContentWidth.form(
                            child: CartIssue(label: l10n.errorOffline),
                          ),
                        if (vm.isEmpty)
                          DymContentWidth.form(
                            child: DymStateView(
                              kind: DymStateKind.empty,
                              title: l10n.ordersEmptyTitle,
                              message: l10n.ordersMineEmptyMessage,
                            ),
                          ),
                        if (vm.active.isNotEmpty)
                          DymContentWidth.form(
                            child: section(l10n.ordersActive, vm.active),
                          ),
                        if (vm.done.isNotEmpty)
                          DymContentWidth.form(
                            child: section(l10n.ordersDone, vm.done),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const new({required this.order, required this.vm, required this.onTap});

  final CustomerOrder order;
  final MyOrdersViewModel vm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final eta = order.etaAt;
    final when = order.status.isActive && eta != null
        ? (order.fulfillment == Fulfillment.pickup
              ? l10n.orderPickupAt(shortTime(context, eta))
              : l10n.orderEtaAt(shortTime(context, eta)))
        : l10n.orderOn(shortDate(context, order.createdAt));
    final total = vm.money(order.totalMinor)?.format() ?? '';
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s3),
          child: Row(
            children: [
              DymAvatar(
                image: storeFallback(order.store.origin),
                size: 52,
                ring: false,
              ),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: DymTokenSpace.s2,
                      runSpacing: DymTokenSpace.s1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          order.store.name,
                          style: t.title.copyWith(fontSize: 18),
                        ),
                        OrderStatusPill(
                          status: order.status,
                          fulfillment: order.fulfillment,
                        ),
                      ],
                    ),
                    Text(when, style: t.label.copyWith(color: c.textSecondary)),
                    Text(
                      '${l10n.orderItems(order.itemCount)} · $total',
                      style: t.label.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ 06

/// Suivi d'une commande (maquette 06, sans carte ni livreur en direct) :
/// frise, heure estimée, boutique, cash à payer, annulation.
class TrackingView extends StackedView<TrackingViewModel> {
  const new({
    required this.service,
    required this.orderId,
    required this.onBack,
    super.key,
    this.onReport,
    this.onDispute,
    this.onReview,
    this.onReordered,
    this.clock = DateTime.now,
  });

  final OrdersService service;
  final String orderId;
  final VoidCallback onBack;

  /// Heure courante (fenêtre de signalement de 7 jours) ; fixée en test.
  final DateTime Function() clock;

  /// Écran 63 (commande, boutique) ; `true` si un avis est publié.
  final Future<bool> Function(String orderId, String storeName)? onReview;

  /// Réachat réussi : ouvrir le panier.
  final VoidCallback? onReordered;

  /// Écran 49 (commande, boutique) ; `true` si un signalement est envoyé.
  final Future<bool> Function(String orderId, String storeName)? onReport;

  /// Écran 50.
  final ValueChanged<String>? onDispute;

  @override
  TrackingViewModel viewModelBuilder(BuildContext context) =>
      TrackingViewModel(service: service, orderId: orderId)..clock = clock;

  @override
  void onViewModelReady(TrackingViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    TrackingViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final order = vm.order;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(
              title: order?.store.name ?? l10n.trackTitle,
              subtitle: order == null
                  ? null
                  : orderStatusLabel(
                      l10n,
                      order.status,
                      fulfillment: order.fulfillment,
                    ),
              onBack: onBack,
            ),
            Expanded(
              child: !vm.ready || order == null
                  ? DiscoveryState(
                      failure: vm.isBusy ? null : vm.failure,
                      onRetry: vm.load,
                    )
                  : _Tracking(
                      vm: vm,
                      order: order,
                      onReport: onReport,
                      onDispute: onDispute,
                      onReview: onReview,
                      onReordered: onReordered,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tracking extends StatelessWidget {
  const new({
    required this.vm,
    required this.order,
    this.onReport,
    this.onDispute,
    this.onReview,
    this.onReordered,
  });

  final TrackingViewModel vm;
  final CustomerOrder order;
  final Future<bool> Function(String orderId, String storeName)? onReport;
  final ValueChanged<String>? onDispute;
  final Future<bool> Function(String orderId, String storeName)? onReview;
  final VoidCallback? onReordered;

  Future<void> _confirmCancel(BuildContext context) async {
    final l10n = DymLocalizations.of(context);
    final yes = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.dym.colors.card,
      constraints: const BoxConstraints(maxWidth: DymTokenLayout.formMax),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.trackCancelTitle,
                style: sheet.dym.text.title.copyWith(fontSize: 22),
              ),
              const SizedBox(height: DymTokenSpace.s2),
              Text(l10n.trackCancelBody),
              const SizedBox(height: DymTokenSpace.s4),
              DymButton(
                label: l10n.trackCancel,
                icon: Icons.close_rounded,
                variant: DymButtonVariant.destructive,
                onPressed: () => Navigator.pop(sheet, true),
              ),
              const SizedBox(height: DymTokenSpace.s2),
              DymButton(
                label: l10n.trackCancelKeep,
                variant: DymButtonVariant.secondary,
                onPressed: () => Navigator.pop(sheet, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (yes ?? false) await vm.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final pickup = order.fulfillment == Fulfillment.pickup;
    final eta = order.etaAt;
    final steps = pickup
        ? [
            (OrderStatus.accepted, l10n.trackConfirmed),
            (OrderStatus.ready, l10n.orderStatusReady),
            (OrderStatus.delivered, l10n.orderStatusCollected),
          ]
        : [
            (OrderStatus.accepted, l10n.trackConfirmed),
            (OrderStatus.ready, l10n.trackPrepared),
            (OrderStatus.outForDelivery, l10n.orderStatusOutForDelivery),
            (OrderStatus.delivered, l10n.orderStatusDelivered),
          ];
    const order_ = [
      OrderStatus.pending,
      OrderStatus.accepted,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];
    final reached = order_.indexOf(order.status);
    final children = <Widget>[
      if (eta != null && order.status.isActive)
        CartCard(
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, color: c.brand, size: 36),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Text(
                  pickup
                      ? l10n.trackReadyAt(shortTime(context, eta))
                      : l10n.trackArrives(shortTime(context, eta)),
                  style: t.display.copyWith(fontSize: 26),
                ),
              ),
            ],
          ),
        ),
      if (order.status == OrderStatus.refused)
        CartIssue(
          label: l10n.trackRefused(
            refusalReasonLabel(l10n, order.statusReason),
          ),
        ),
      if (order.status == OrderStatus.cancelled &&
          order.cancelledBy == 'client')
        CartIssue(label: l10n.trackCancelledByYou, blocking: false),
      if (order.refundDue)
        CartIssue(label: l10n.trackRefundDue, blocking: false),
      const SizedBox(height: DymTokenSpace.s3),
      if (order.status.isActive || order.status == OrderStatus.delivered)
        CartCard(
          child: Column(
            children: [
              for (final (i, (status, label)) in steps.indexed)
                _Step(
                  label: label,
                  done: reached >= order_.indexOf(status),
                  current:
                      order.status == status ||
                      (status == OrderStatus.ready &&
                          order.status == OrderStatus.preparing &&
                          i == 1),
                  at: order.reachedAt(status),
                  last: i == steps.length - 1,
                ),
            ],
          ),
        ),
      const SizedBox(height: DymTokenSpace.s3),
      CartCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${line.name} × ${line.quantity}',
                        style: t.label.copyWith(fontSize: 15),
                      ),
                    ),
                    if (vm.money(line.amountMinor) case final amount?)
                      MoneyText(amount, size: 15, color: c.brandDeep),
                  ],
                ),
              ),
            const Divider(height: 20),
            SumRow(
              label: l10n.cartTotal,
              amount: vm.money(order.totalMinor),
              strong: true,
            ),
          ],
        ),
      ),
      if (order.payOnDelivery) ...[
        const SizedBox(height: DymTokenSpace.s3),
        CartCard(
          child: Row(
            children: [
              Icon(Icons.payments_rounded, color: c.brand, size: 36),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.trackPayOnDelivery,
                      style: t.label.copyWith(fontSize: 15),
                    ),
                    Text(
                      l10n.trackCashAmount(
                        vm.money(order.totalMinor)?.format() ?? '',
                      ),
                      style: t.display.copyWith(
                        fontSize: 24,
                        color: c.brandDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      if (vm.canReview && onReview != null) ...[
        const SizedBox(height: DymTokenSpace.s3),
        DymButton(
          label: l10n.reviewGive,
          icon: Icons.star_rounded,
          variant: DymButtonVariant.plantain,
          onPressed: () async {
            if (await onReview!(order.id, order.store.name)) await vm.refresh();
          },
        ),
      ] else if (vm.review case final review?) ...[
        const SizedBox(height: DymTokenSpace.s3),
        CartIssue(label: l10n.reviewThanks(review.rating), blocking: false),
      ],
      if (vm.canReorder && onReordered != null) ...[
        const SizedBox(height: DymTokenSpace.s3),
        DymButton(
          label: l10n.reorder,
          icon: Icons.replay_rounded,
          variant: DymButtonVariant.secondary,
          loading: vm.reordering,
          onPressed: vm.reordering
              ? null
              : () async {
                  if (await vm.reorder()) onReordered!();
                },
        ),
        if (vm.reordered case ReorderResult(:final skipped)
            when skipped.isNotEmpty)
          CartIssue(
            label: l10n.reorderSkipped(skipped.join(', ')),
            blocking: false,
          ),
        if (vm.reordered case ReorderResult(added: 0))
          CartIssue(label: l10n.reorderNothing, blocking: false),
        if (vm.reorderFailure != null)
          CartIssue(
            label: vm.reorderFailure is NetworkFailure
                ? l10n.errorOffline
                : l10n.errorGeneric,
          ),
      ],
      if (vm.dispute != null && onDispute != null) ...[
        const SizedBox(height: DymTokenSpace.s3),
        DymButton(
          label: l10n.disputeSeeThread,
          icon: Icons.forum_rounded,
          variant: DymButtonVariant.secondary,
          onPressed: () => onDispute!(order.id),
        ),
      ] else if (vm.canReport && onReport != null) ...[
        const SizedBox(height: DymTokenSpace.s3),
        DymButton(
          label: l10n.disputeReport,
          icon: Icons.report_problem_rounded,
          variant: DymButtonVariant.secondary,
          onPressed: () async {
            if (await onReport!(order.id, order.store.name)) await vm.refresh();
          },
        ),
      ],
      if (vm.statusChanged)
        CartIssue(label: l10n.orderStatusChanged, blocking: false),
      if (vm.offline) CartIssue(label: l10n.errorOffline, blocking: false),
    ];
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              for (final w in children) DymContentWidth.form(child: w),
            ],
          ),
        ),
        if (order.canCancel)
          DymContentWidth.form(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: DymButton(
                label: l10n.trackCancel,
                icon: Icons.close_rounded,
                variant: DymButtonVariant.secondary,
                loading: vm.cancelling,
                onPressed: vm.cancelling ? null : () => _confirmCancel(context),
              ),
            ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const new({
    required this.label,
    required this.done,
    required this.current,
    required this.last,
    this.at,
  });

  final String label;
  final bool done;
  final bool current;
  final bool last;
  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final color = done ? c.brand : (current ? c.plantain : c.textSecondary);
    return Semantics(
      selected: current,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : (current
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded),
                color: color,
                size: 28,
              ),
              if (!last)
                Container(
                  width: 3,
                  height: 22,
                  color: done
                      ? c.brand
                      : c.textSecondary.withValues(alpha: 0.3),
                ),
            ],
          ),
          const SizedBox(width: DymTokenSpace.s3),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                label,
                style: t.title.copyWith(
                  fontSize: 17,
                  color: done || current ? c.textPrimary : c.textSecondary,
                ),
              ),
            ),
          ),
          if (at != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                shortTime(context, at!),
                style: t.label.copyWith(color: c.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ 44

/// Écran 44 : centre de notifications.
class NotificationsView extends StackedView<NotificationsViewModel> {
  const new({
    required this.service,
    required this.onBack,
    required this.onOpenOrder,
    this.onOpenConversation,
    this.onOpenShoppingList,
    super.key,
    this.clock = DateTime.now,
  });

  final OrdersService service;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenOrder;

  /// Notification de message : ouvrir la conversation (spec 015).
  final ValueChanged<String>? onOpenConversation;

  /// Rappel de courses : ouvrir la liste (spec 029).
  final ValueChanged<String>? onOpenShoppingList;
  final DateTime Function() clock;

  @override
  NotificationsViewModel viewModelBuilder(BuildContext context) =>
      NotificationsViewModel(service: service, clock: clock);

  @override
  void onViewModelReady(NotificationsViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    NotificationsViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final now = vm.clock();
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            DymContentWidth(
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.authBack,
                    onPressed: onBack,
                    icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                  ),
                  Expanded(
                    child: Text(
                      l10n.notificationsTitle,
                      style: t.display.copyWith(fontSize: 26),
                    ),
                  ),
                  if (vm.hasUnread)
                    TextButton(
                      onPressed: vm.readAll,
                      child: Text(
                        l10n.notificationsReadAll,
                        style: t.label.copyWith(
                          fontWeight: FontWeight.w800,
                          color: c.brandDeep,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: !vm.ready
                  ? DiscoveryState(
                      failure: vm.isBusy ? null : vm.failure,
                      onRetry: vm.load,
                    )
                  : vm.items.isEmpty
                  ? DymStateView(
                      kind: DymStateKind.empty,
                      title: l10n.notificationsEmptyTitle,
                      message: l10n.notificationsEmptyMessage,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        for (final n in vm.items)
                          DymContentWidth.form(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: DymTokenSpace.s2,
                              ),
                              child: _NotificationRow(
                                notification: n,
                                ago: timeAgo(l10n, n.createdAt, now),
                                onTap: () async {
                                  await vm.open(n);
                                  if (n.orderId case final id?) {
                                    onOpenOrder(id);
                                  } else if (n.param('conversation_id')
                                      case final conv?) {
                                    onOpenConversation?.call(conv);
                                  } else if (n.param('list_id')
                                      case final list?) {
                                    onOpenShoppingList?.call(list);
                                  }
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const new({
    required this.notification,
    required this.ago,
    required this.onTap,
  });

  final AppNotification notification;
  final String ago;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final (title, body) = notificationText(l10n, notification);
    final unread = notification.unread;
    return Material(
      color: unread ? c.tintVertTendre : c.card,
      borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                notificationIcon(notification.kind),
                color: c.brand,
                size: 30,
              ),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.title.copyWith(fontSize: 17)),
                    if (body.isNotEmpty)
                      Text(body, style: t.label.copyWith(fontSize: 15)),
                    Text(ago, style: t.label.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              if (unread)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: c.brand,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ 46

/// Écran 46 : réglages des notifications (push par catégorie).
class NotificationSettingsView
    extends StackedView<NotificationSettingsViewModel> {
  const new({required this.service, required this.onBack, super.key});

  final OrdersService service;
  final VoidCallback onBack;

  @override
  NotificationSettingsViewModel viewModelBuilder(BuildContext context) =>
      NotificationSettingsViewModel(service: service);

  @override
  void onViewModelReady(NotificationSettingsViewModel viewModel) =>
      viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    NotificationSettingsViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    (String, String) texts(NotificationCategory cat) => switch (cat) {
      NotificationCategory.orders => (
        l10n.prefOrdersTitle,
        l10n.prefOrdersBody,
      ),
      NotificationCategory.payments => (
        l10n.prefPaymentsTitle,
        l10n.prefPaymentsBody,
      ),
      NotificationCategory.messages => (
        l10n.prefMessagesTitle,
        l10n.prefMessagesBody,
      ),
      _ => (l10n.prefPromotionsTitle, l10n.prefPromotionsBody),
    };
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(title: l10n.notifSettingsTitle, onBack: onBack),
            Expanded(
              child: !vm.ready
                  ? DiscoveryState(
                      failure: vm.isBusy ? null : vm.failure,
                      onRetry: vm.load,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        DymContentWidth.form(
                          child: Text(
                            l10n.notifSettingsIntro,
                            style: t.body.copyWith(color: c.textSecondary),
                          ),
                        ),
                        const SizedBox(height: DymTokenSpace.s3),
                        for (final p in vm.preferences)
                          DymContentWidth.form(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: DymTokenSpace.s2,
                              ),
                              child: DymSwitchTile(
                                title: texts(p.category).$1,
                                subtitle: texts(p.category).$2,
                                value: p.pushEnabled,
                                onChanged: (on) =>
                                    vm.toggle(p.category, on: on),
                              ),
                            ),
                          ),
                        if (vm.saveFailure != null)
                          DymContentWidth.form(
                            child: CartIssue(label: l10n.errorGeneric),
                          ),
                        DymContentWidth.form(
                          child: Text(
                            l10n.notifSettingsNote,
                            style: t.label.copyWith(color: c.textSecondary),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
