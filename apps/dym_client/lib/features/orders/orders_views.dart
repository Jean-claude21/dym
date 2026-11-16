import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_client/features/orders/adjustments_view.dart';
import 'package:dym_client/features/orders/live_map_card.dart';
import 'package:dym_client/features/orders/order_texts.dart';
import 'package:dym_client/features/orders/orders_service.dart';
import 'package:dym_client/features/orders/orders_viewmodels.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Pastille de statut (en cours : menthe ; acceptée : vert ; livrée :
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
      OrderStatus.delivered => (c.muted, c.textSecondary),
      OrderStatus.refused || OrderStatus.cancelled => (
        c.pimentStrong.withValues(alpha: 0.12),
        c.pimentStrong,
      ),
      _ => (c.tintVertTendre, c.brandDeep),
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
          fontWeight: FontWeight.w600,
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
    this.onBack,
  });

  final OrdersService service;
  final ValueChanged<String> onOpen;
  final VoidCallback onNotifications;

  /// Retour (page ouverte depuis « Moi ») ; nul : pas de bouton.
  final VoidCallback? onBack;

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
        padding: EdgeInsets.fromLTRB(onBack == null ? 16 : 4, 12, 4, 4),
        child: Row(
          children: [
            if (onBack case final back?)
              IconButton(
                tooltip: l10n.authBack,
                onPressed: back,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            Expanded(child: Text(l10n.ordersMineTitle, style: t.display)),
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
          child: Text(title, style: t.title),
        ),
        for (final o in orders)
          Padding(
            padding: const EdgeInsets.only(bottom: DymTokenSpace.s3),
            child: _OrderRow(order: o, vm: vm, onTap: () => onOpen(o.id)),
          ),
      ],
    );
    // Page à part entière depuis « Moi » : son propre Scaffold.
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
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
                                icon: Icons.receipt_long_outlined,
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
    final start = order.scheduledStart;
    final end = order.scheduledEnd;
    final when = order.status.isActive && start != null && end != null
        ? l10n.orderScheduled(
            shortDate(context, start),
            shortTime(context, start),
            shortTime(context, end),
          )
        : order.status.isActive && eta != null
        ? (order.fulfillment == Fulfillment.pickup
              ? l10n.orderPickupAt(shortTime(context, eta))
              : l10n.orderEtaAt(shortTime(context, eta)))
        : l10n.orderOn(shortDate(context, order.createdAt));
    final total = vm.money(order.totalMinor)?.format() ?? '';
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        side: BorderSide(color: c.hairline),
      ),
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
                initial: order.store.name,
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
    this.onChat,
    this.onCall,
    this.clock = DateTime.now,
    this.adjustments,
  });

  final OrdersService service;
  final String orderId;

  /// Écrire à la boutique (identifiant de la boutique).
  final ValueChanged<String>? onChat;

  /// Appeler un numéro (livreur).
  final ValueChanged<String>? onCall;

  /// Remplacements et garantie fraîcheur (spec 034) ; absents : masqués.
  final AdjustmentsService? adjustments;
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
              // Commande en cours : la phase est dite en grand juste dessous.
              subtitle: order == null || vm.phase != TrackPhase.ended
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
                      onChat: onChat,
                      onCall: onCall,
                      adjustments: adjustments,
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
    this.onChat,
    this.onCall,
    this.adjustments,
  });

  final TrackingViewModel vm;
  final CustomerOrder order;
  final ValueChanged<String>? onChat;
  final ValueChanged<String>? onCall;
  final AdjustmentsService? adjustments;
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
              const SizedBox(height: DymTokenSpace.s3),
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
    // Étape de préparation : « En préparation » tant qu'elle dure.
    final preparing =
        order.status == OrderStatus.accepted ||
        order.status == OrderStatus.preparing;
    final steps = pickup
        ? [
            (OrderStatus.pending, l10n.trackSent),
            (OrderStatus.accepted, l10n.trackConfirmed),
            (OrderStatus.ready, l10n.orderStatusReady),
            (OrderStatus.delivered, l10n.orderStatusCollected),
          ]
        : [
            (OrderStatus.pending, l10n.trackSent),
            (OrderStatus.accepted, l10n.trackConfirmed),
            (
              OrderStatus.ready,
              preparing ? l10n.orderStatusPreparing : l10n.trackPrepared,
            ),
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
      if (vm.phase != TrackPhase.ended)
        _PhaseCard(vm: vm, order: order, pickup: pickup, eta: eta),
      // Livreur assigné (spec 068) : nom et téléphone, pour se retrouver.
      if (order.courier case final courier?
          when order.status.isActive && !pickup)
        CartCard(
          child: Row(
            children: [
              Icon(Icons.two_wheeler_rounded, color: c.brandDeep, size: 28),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.trackCourier(courier.name),
                      style: t.title.copyWith(fontSize: 17),
                    ),
                    SelectableText(
                      courier.phone,
                      style: t.label.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              if (onCall case final call?)
                DymButton(
                  label: l10n.trackCallCourier,
                  icon: Icons.call_rounded,
                  compact: true,
                  expanded: false,
                  onPressed: () => call(courier.phone),
                ),
            ],
          ),
        ),
      LiveMapCard(vm: vm),
      if (vm.handoverCode case final code?)
        CartCard(
          child: Row(
            children: [
              Icon(Icons.pin_outlined, color: c.brandDeep, size: 32),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.trackHandoverCode, style: t.label),
                    Text(
                      code,
                      style: t.display.copyWith(fontSize: 32, letterSpacing: 6),
                    ),
                    Text(
                      l10n.trackHandoverHint,
                      style: t.label.copyWith(color: c.textSecondary),
                    ),
                  ],
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
                      (status == OrderStatus.ready && preparing && !pickup),
                  at: status == OrderStatus.pending
                      ? order.createdAt
                      : order.reachedAt(status),
                  last: i == steps.length - 1,
                ),
            ],
          ),
        ),
      if (onChat case final chat? when order.status.isActive) ...[
        const SizedBox(height: DymTokenSpace.s3),
        DymButton(
          label: l10n.chatWriteToStore,
          icon: Icons.chat_bubble_outline_rounded,
          variant: DymButtonVariant.secondary,
          onPressed: () => chat(order.store.id),
        ),
      ],
      const SizedBox(height: DymTokenSpace.s3),
      CartCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.trackSummary, style: t.title.copyWith(fontSize: 18)),
            const SizedBox(height: DymTokenSpace.s2),
            for (final line in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 30),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: c.tintVertTendre,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${line.quantity}×',
                        textAlign: TextAlign.center,
                        style: t.label.copyWith(
                          color: c.brandDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: DymTokenSpace.s2),
                    Expanded(
                      child: Text(
                        line.name,
                        style: t.body.copyWith(fontSize: 15),
                      ),
                    ),
                    if (vm.money(line.amountMinor) case final amount?)
                      MoneyText(amount, size: 15),
                  ],
                ),
              ),
            const Divider(height: 20),
            SumRow(
              label: l10n.cartSubtotal,
              amount: vm.money(order.subtotalMinor),
            ),
            if (pickup)
              SumRow(label: l10n.trackPickupFee, text: l10n.trackFree)
            else if (order.deliveryFeeMinor == 0)
              SumRow(label: l10n.cartDelivery, text: l10n.trackFree)
            else
              SumRow(
                label: l10n.cartDelivery,
                amount: vm.money(order.deliveryFeeMinor),
              ),
            const SizedBox(height: 4),
            SumRow(
              label: l10n.cartTotal,
              amount: vm.money(order.totalMinor),
              strong: true,
            ),
            if (order.paymentMethod case final method?
                when !order.payOnDelivery) ...[
              const SizedBox(height: DymTokenSpace.s2),
              Text(
                order.paymentStatus == PaymentStatus.paid
                    ? l10n.trackPaidWith(
                        method.label.resolve(
                          Localizations.localeOf(context).languageCode,
                        ),
                      )
                    : l10n.trackPayWith(
                        method.label.resolve(
                          Localizations.localeOf(context).languageCode,
                        ),
                      ),
                style: t.label.copyWith(color: c.textSecondary),
              ),
            ],
          ],
        ),
      ),
      if (adjustments case final service?)
        OrderAdjustmentsPanel(
          key: ValueKey('adjust-${order.id}-${order.status.name}'),
          service: service,
          order: order,
          money: (minor) => vm.money(minor)?.format(),
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
      const SizedBox(height: DymTokenSpace.s3),
      Text(
        l10n.trackOrderedOn(
          MaterialLocalizations.of(context)
              .formatShortMonthDay(order.createdAt.toLocal()),
          shortTime(context, order.createdAt),
        ),
        textAlign: TextAlign.center,
        style: t.label.copyWith(color: c.textSecondary),
      ),
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

/// Phase en clair, heure prévue et avancement (spec 074).
class _PhaseCard extends StatelessWidget {
  const new({
    required this.vm,
    required this.order,
    required this.pickup,
    required this.eta,
  });

  final TrackingViewModel vm;
  final CustomerOrder order;
  final bool pickup;
  final DateTime? eta;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final store = order.store.name;
    final (title, hint, icon) = switch (vm.phase) {
      TrackPhase.waiting => (
        l10n.trackPhaseWaiting,
        l10n.trackPhaseWaitingHint(store),
        Icons.hourglass_top_rounded,
      ),
      TrackPhase.preparing => (
        l10n.trackPhasePreparing,
        l10n.trackPhasePreparingHint(store),
        Icons.soup_kitchen_rounded,
      ),
      TrackPhase.ready => (
        l10n.trackPhaseReady,
        pickup
            ? l10n.trackPhaseReadyPickupHint(store)
            : l10n.trackPhaseReadyHint,
        Icons.inventory_2_rounded,
      ),
      TrackPhase.onTheWay => (
        l10n.trackPhaseOnTheWay,
        l10n.trackPhaseOnTheWayHint,
        Icons.delivery_dining_rounded,
      ),
      _ => (
        pickup ? l10n.trackPhaseCollected : l10n.trackPhaseDelivered,
        l10n.trackPhaseDeliveredHint,
        Icons.check_circle_rounded,
      ),
    };
    final at = eta;
    final when = at == null || !order.status.isActive
        ? null
        : [
            if (pickup)
              l10n.trackReadyAt(shortTime(context, at))
            else
              l10n.trackArrives(shortTime(context, at)),
            if (vm.minutesLeft case final m?) l10n.trackInMinutes(m),
          ].join(' · ');
    return CartCard(
      color: c.tintVertTendre,
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: c.card,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: c.brandDeep, size: 28),
                ),
                const SizedBox(width: DymTokenSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: t.display.copyWith(
                          fontSize: 26,
                          color: c.brandDeep,
                        ),
                      ),
                      Text(hint, style: t.body.copyWith(color: c.brandDeep)),
                    ],
                  ),
                ),
              ],
            ),
            if (when != null) ...[
              const SizedBox(height: DymTokenSpace.s2),
              Text(
                when,
                style: t.title.copyWith(fontSize: 18, color: c.textPrimary),
              ),
            ],
            const SizedBox(height: DymTokenSpace.s2),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: vm.progress,
                minHeight: 8,
                color: c.brand,
                backgroundColor: c.card,
              ),
            ),
          ],
        ),
      ),
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
    final color = done || current ? c.brand : c.textSecondary;
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
    this.onOpenSpace,
    this.onOpenCart,
    super.key,
    this.clock = DateTime.now,
  });

  final OrdersService service;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenOrder;

  /// Rappel de panier (spec 080) : ouvrir le panier.
  final VoidCallback? onOpenCart;

  /// Notification de message : ouvrir la conversation (spec 015).
  final ValueChanged<String>? onOpenConversation;

  /// Rappel de courses : ouvrir la liste (spec 029).
  final ValueChanged<String>? onOpenShoppingList;

  /// Panier commun validé : ouvrir l'espace (spec 031).
  final ValueChanged<String>? onOpenSpace;
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
                          fontWeight: FontWeight.w700,
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
                      icon: Icons.notifications_none_rounded,
                      title: l10n.notificationsEmptyTitle,
                      message: l10n.notificationsEmptyMessage,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        for (final (i, n) in vm.items.indexed)
                          DymContentWidth.form(
                            child: Padding(
                              padding: EdgeInsets.zero,
                              child: _NotificationRow(
                                first: i == 0,
                                notification: n,
                                ago: timeAgo(l10n, n.createdAt, now),
                                onTap: () async {
                                  await vm.open(n);
                                  if (n.kind == 'cart_reminder') {
                                    onOpenCart?.call();
                                  } else if (n.orderId case final id?) {
                                    onOpenOrder(id);
                                  } else if (n.param('conversation_id')
                                      case final conv?) {
                                    onOpenConversation?.call(conv);
                                  } else if (n.param('list_id')
                                      case final list?) {
                                    onOpenShoppingList?.call(list);
                                  } else if (n.param('space_id')
                                      case final space?) {
                                    onOpenSpace?.call(space);
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
    this.first = false,
  });

  final AppNotification notification;
  final String ago;
  final VoidCallback onTap;

  /// Pas de filet au-dessus de la première ligne.
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final (title, body) = notificationText(l10n, notification);
    final unread = notification.unread;
    // Ligne à filet (design « Épuré ») ; non lue : titre plus marqué et point.
    return DecoratedBox(
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: c.hairline)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: unread ? c.tintVertTendre : c.muted,
                  borderRadius: BorderRadius.circular(DymTokenRadius.field),
                ),
                child: Icon(
                  notificationIcon(notification.kind),
                  color: unread ? c.brandDeep : c.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: t.body.copyWith(
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (body.isNotEmpty)
                      Text(
                        body,
                        style: t.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      ago,
                      style: t.label.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                      ),
                    ),
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
      NotificationCategory.quietNight => (
        l10n.prefQuietNightTitle,
        l10n.prefQuietNightBody,
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
                              // « Nuit calme » : un réglage à part, détaché.
                              padding: EdgeInsets.only(
                                top:
                                    p.category ==
                                        NotificationCategory.quietNight
                                    ? DymTokenSpace.s3
                                    : 0,
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
