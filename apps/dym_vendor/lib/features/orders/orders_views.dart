import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/orders/adjustments_panel.dart';
import 'package:dym_vendor/features/orders/orders_service.dart';
import 'package:dym_vendor/features/orders/orders_viewmodels.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Chargement, échec ou hors ligne d'un écran de commandes.
class _State extends StatelessWidget {
  const new({required this.failure, required this.onRetry});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final current = failure;
    if (current == null) {
      return Center(
        child: Semantics(
          label: l10n.startupPreparing,
          child: CircularProgressIndicator(color: c.brand),
        ),
      );
    }
    final offline = current is NetworkFailure;
    return DymStateView(
      kind: offline ? DymStateKind.offline : DymStateKind.error,
      title: offline ? l10n.errorOffline : l10n.errorGeneric,
      message: l10n.errorLoadMessage,
      actionLabel: l10n.retry,
      onAction: onRetry,
    );
  }
}

/// « Paiement confirmé » (vert) ou « Cash à la livraison » (crème).
class PaymentPill extends StatelessWidget {
  const new({required this.paid, super.key});

  final bool paid;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DymTokenSpace.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: paid ? c.tintVertTendre : c.tintPlantainClair,
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            paid ? Icons.check_circle_rounded : Icons.payments_rounded,
            size: 18,
            color: c.brandDeep,
          ),
          const SizedBox(width: DymTokenSpace.s1),
          Flexible(
            child: Text(
              paid ? l10n.paymentConfirmed : l10n.paymentCashOnDelivery,
              style: context.dym.text.label.copyWith(
                fontWeight: FontWeight.w700,
                color: c.brandDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Libellé d'un statut (retrait : « Récupérée »).
String vendorStatusLabel(DymLocalizations l10n, VendorOrder o) =>
    switch (o.status) {
      OrderStatus.pending => l10n.orderStatusPending,
      OrderStatus.accepted => l10n.orderStatusAccepted,
      OrderStatus.preparing => l10n.orderStatusPreparing,
      OrderStatus.ready => l10n.orderStatusReady,
      OrderStatus.outForDelivery => l10n.orderStatusOutForDelivery,
      OrderStatus.delivered =>
        o.fulfillment == Fulfillment.pickup
            ? l10n.orderStatusCollected
            : l10n.orderStatusDelivered,
      OrderStatus.refused => l10n.orderStatusRefused,
      OrderStatus.cancelled => l10n.orderStatusCancelled,
      OrderStatus.unknown => l10n.errorGeneric,
    };

/// Libellé d'un statut de la frise.
String statusOnlyLabel(
  DymLocalizations l10n,
  OrderStatus status,
  Fulfillment fulfillment,
) => switch (status) {
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

/// Qui a fait le geste.
String actorLabel(DymLocalizations l10n, String role) => switch (role) {
  'vendor' => l10n.actorVendor,
  'client' => l10n.actorClient,
  'courier' => l10n.actorCourier,
  'admin' => l10n.actorAdmin,
  _ => l10n.actorSystem,
};

String reasonLabel(DymLocalizations l10n, RefusalReason? r) => switch (r) {
  RefusalReason.outOfStock => l10n.reasonOutOfStock,
  RefusalReason.tooBusy => l10n.reasonTooBusy,
  RefusalReason.noResponse => l10n.reasonNoResponse,
  RefusalReason.areaNotServed => l10n.reasonAreaNotServed,
  _ => l10n.reasonOther,
};

/// Libellé du geste qui mène à [to].
String stepLabel(DymLocalizations l10n, OrderStatus to, Fulfillment mode) =>
    switch (to) {
      OrderStatus.accepted => l10n.vendorAccept,
      OrderStatus.preparing => l10n.vendorStartPreparing,
      OrderStatus.ready => l10n.vendorMarkReady,
      OrderStatus.outForDelivery => l10n.vendorOutForDelivery,
      OrderStatus.delivered =>
        mode == Fulfillment.pickup
            ? l10n.vendorMarkCollected
            : l10n.vendorMarkDelivered,
      _ => l10n.vendorRefuse,
    };

IconData stepIcon(OrderStatus to) => switch (to) {
  OrderStatus.accepted => Icons.check_rounded,
  OrderStatus.preparing => Icons.soup_kitchen_rounded,
  OrderStatus.ready => Icons.shopping_bag_rounded,
  OrderStatus.outForDelivery => Icons.two_wheeler_rounded,
  OrderStatus.delivered => Icons.task_alt_rounded,
  _ => Icons.close_rounded,
};

String _title(DymLocalizations l10n, VendorOrder o) =>
    l10n.vendorOrderOf(o.customerFirstName ?? '…');

String _time(BuildContext context, DateTime at) =>
    TimeOfDay.fromDateTime(at.toLocal()).format(context);

/// Pastille « Réponds avant 13:35 · 18 min restantes » (spec 075) ; rouge
/// sous 5 minutes.
class RespondCountdown extends StatelessWidget {
  const new({required this.respondBy, required this.minutesLeft, super.key});

  final DateTime respondBy;
  final int? minutesLeft;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final left = minutesLeft;
    final urgent = left != null && left <= 5;
    final (bg, fg) = urgent
        ? (c.tintPimentClair, c.pimentStrong)
        : (c.tintPeche, c.originMaisonFg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              [
                l10n.vendorRespondBefore(_time(context, respondBy)),
                if (left != null) l10n.vendorMinutesLeft(left),
              ].join(' · '),
              style: t.label.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ 41

/// Écran 41 : commandes de la boutique (payées ou en cash), les plus récentes
/// d'abord ; relues toutes les 20 s.
class OrdersView extends StackedView<OrdersViewModel> {
  const new({
    required this.service,
    required this.onOpen,
    super.key,
    this.clock = DateTime.now,
  });

  final OrdersService service;
  final ValueChanged<String> onOpen;

  /// Heure courante (compte à rebours) ; fixée en test.
  final DateTime Function() clock;

  @override
  OrdersViewModel viewModelBuilder(BuildContext context) =>
      OrdersViewModel(service: service)..clock = clock;

  @override
  void onViewModelReady(OrdersViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    OrdersViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    // Nouvelle commande : alerte plein écran sur tous les onglets
    // (`NewOrderAlertHost`, spec 075).
    final vm = viewModel;
    if (!vm.ready) {
      return SafeArea(
        child: _State(failure: vm.isBusy ? null : vm.failure, onRetry: vm.load),
      );
    }
    return SafeArea(
      child: RefreshIndicator(
        color: c.brand,
        onRefresh: vm.refresh,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            DymLayout.gutter(context),
            16,
            DymLayout.gutter(context),
            24,
          ),
          children: [
            DymContentWidth.form(
              child: Text(
                l10n.navOrders,
                style: t.display.copyWith(fontSize: 30),
              ),
            ),
            if (vm.offline)
              DymContentWidth.form(
                child: Padding(
                  padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                  child: Text(
                    l10n.errorOffline,
                    style: t.label.copyWith(color: c.textSecondary),
                  ),
                ),
              ),
            const SizedBox(height: DymTokenSpace.s2),
            DymContentWidth.form(
              child: Wrap(
                runSpacing: DymTokenSpace.s2,
                spacing: DymTokenSpace.s2,
                children: [
                  for (final (scope, label) in [
                    (
                      VendorOrderScope.newOrders,
                      vm.newCount == 0
                          ? l10n.vendorScopeNew
                          : '${l10n.vendorScopeNew} (${vm.newCount})',
                    ),
                    (VendorOrderScope.active, l10n.vendorScopeActive),
                    (VendorOrderScope.done, l10n.vendorScopeDone),
                  ])
                    DymFilterChip(
                      label: label,
                      selected: vm.scope == scope,
                      onTap: () => vm.selectScope(scope),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            if (vm.orders.isEmpty)
              DymContentWidth.form(
                child: DymStateView(
                  kind: DymStateKind.empty,
                  title: l10n.ordersEmptyTitle,
                  message: l10n.ordersEmptyMessage,
                ),
              ),
            for (final o in vm.orders)
              DymContentWidth.form(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: DymTokenSpace.s3),
                  child: _OrderCard(
                    order: o,
                    total: vm.money(o.totalMinor),
                    now: vm.clock(),
                    onTap: () => onOpen(o.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const new({
    required this.order,
    required this.total,
    required this.now,
    required this.onTap,
  });

  final VendorOrder order;
  final Money? total;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final mode = order.fulfillment == Fulfillment.delivery
        ? l10n.deliveryModeDelivery
        : l10n.deliveryModePickup;
    final place = [
      ?order.zoneName,
      l10n.vendorOrderReceivedAt(_time(context, order.createdAt)),
      if ((order.scheduledStart, order.scheduledEnd) case (
        final start?,
        final end?,
      ))
        l10n.vendorOrderScheduled(
          MaterialLocalizations.of(context).formatShortDate(start.toLocal()),
          _time(context, start),
          _time(context, end),
        ),
    ].join(' · ');
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _title(l10n, order),
                      style: t.title.copyWith(fontSize: 18),
                    ),
                  ),
                  if (total != null)
                    MoneyText(total!, size: 18, color: c.brandDeep),
                ],
              ),
              Text(
                [place, vendorStatusLabel(l10n, order)].join(' · '),
                style: t.label.copyWith(color: c.textSecondary),
              ),
              Text(
                '${l10n.orderItems(order.itemCount)} · $mode',
                style: t.label.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: DymTokenSpace.s2),
              Wrap(
                spacing: DymTokenSpace.s2,
                runSpacing: DymTokenSpace.s1,
                children: [
                  PaymentPill(paid: order.isPaid),
                  if (order.respondBy case final by?)
                    RespondCountdown(
                      respondBy: by,
                      minutesLeft: order.minutesToRespond(now),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ 42

/// Écran 42 : détail d'une commande et de son paiement (V-PAY-04).
class OrderDetailView extends StackedView<OrderDetailViewModel> {
  const new({
    required this.service,
    required this.orderId,
    required this.onBack,
    super.key,
    this.clock = DateTime.now,
    this.adjustments,
  });

  /// Remplacement validé par photo (spec 034) ; absent : masqué.
  final VendorAdjustmentsService? adjustments;

  final OrdersService service;

  /// Heure courante (compte à rebours) ; fixée en test.
  final DateTime Function() clock;
  final String orderId;
  final VoidCallback onBack;

  @override
  OrderDetailViewModel viewModelBuilder(BuildContext context) =>
      OrderDetailViewModel(service: service, orderId: orderId)..clock = clock;

  @override
  void onViewModelReady(OrderDetailViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    OrderDetailViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final vm = viewModel;
    final order = vm.order;
    final header = DymContentWidth(
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.authBack,
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order == null ? l10n.navOrders : _title(l10n, order),
                  style: t.display.copyWith(fontSize: 24),
                ),
                if (order != null)
                  Text(
                    l10n.vendorOrderReceivedAt(_time(context, order.createdAt)),
                    style: t.label.copyWith(color: c.textSecondary),
                  ),
                if ((order?.scheduledStart, order?.scheduledEnd) case (
                  final start?,
                  final end?,
                ))
                  Text(
                    l10n.vendorOrderScheduled(
                      MaterialLocalizations.of(context)
                          .formatShortDate(start.toLocal()),
                      _time(context, start),
                      _time(context, end),
                    ),
                    style: t.label.copyWith(color: c.brandDeep),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
    if (!vm.ready || order == null) {
      return Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Column(
            children: [
              header,
              Expanded(
                child: _State(
                  failure: vm.isBusy ? null : vm.failure,
                  onRetry: vm.load,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final pending = order.status == OrderStatus.pending;
    final next = vm.nextStep;
    Future<void> refuse() async {
      final choice = await showRefusalSheet(context);
      if (choice != null) await vm.refuse(choice.$1, choice.$2);
    }

    final actions = <Widget>[
      if (vm.statusChanged)
        _Note(text: l10n.orderStatusChanged, icon: Icons.sync_rounded),
      if (vm.actionFailure != null && !vm.statusChanged)
        _Note(
          text: vm.actionFailure is NetworkFailure
              ? l10n.errorOffline
              : l10n.errorGeneric,
          icon: Icons.error_outline_rounded,
        ),
      if (pending)
        Row(
          children: [
            Expanded(
              child: DymButton(
                label: l10n.vendorRefuse,
                icon: Icons.close_rounded,
                variant: DymButtonVariant.secondary,
                onPressed: vm.acting ? null : refuse,
              ),
            ),
            const SizedBox(width: DymTokenSpace.s2),
            Expanded(
              child: DymButton(
                label: l10n.vendorAccept,
                icon: Icons.check_rounded,
                loading: vm.acting,
                onPressed: vm.acting
                    ? null
                    : () => vm.advance(OrderStatus.accepted),
              ),
            ),
          ],
        )
      else if (next != null)
        DymButton(
          label: stepLabel(l10n, next, order.fulfillment),
          icon: stepIcon(next),
          loading: vm.acting,
          onPressed: vm.acting ? null : () => vm.advance(next),
        )
      else if (order.awaitsCash)
        DymButton(
          label: l10n.vendorConfirmCash(
            vm.money(order.totalMinor)?.format() ?? '',
          ),
          icon: Icons.payments_rounded,
          loading: vm.acting,
          onPressed: vm.acting ? null : vm.confirmCash,
        ),
    ];
    final payment = order.payment;
    final delivery = order.delivery;
    Widget card(String title, List<Widget> children) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.title.copyWith(fontSize: 20)),
          const SizedBox(height: DymTokenSpace.s2),
          ...children,
        ],
      ),
    );
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: t.label.copyWith(fontSize: 15, color: c.textSecondary),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: t.title.copyWith(fontSize: 15),
            ),
          ),
        ],
      ),
    );
    final total = vm.money(order.totalMinor)?.format() ?? '';
    final dispute = vm.dispute;
    Future<void> reply() async {
      final body = await showDisputeReplySheet(context);
      if (body != null) await vm.replyDispute(body);
    }

    final children = <Widget>[
      if (dispute != null) ...[
        DisputeBanner(
          dispute: dispute,
          onReply: dispute.isOpen && !vm.acting ? reply : null,
        ),
        const SizedBox(height: DymTokenSpace.s3),
      ],
      if (pending) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DymTokenSpace.s3),
          // Nouvelle commande : menthe, sans aplat foncé (design « Épuré »).
          decoration: BoxDecoration(
            color: c.tintVertTendre,
            borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: c.brandDeep,
                size: 28,
              ),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.notifNewOrderTitle,
                      style: t.body.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: c.brandDeep,
                      ),
                    ),
                    Text(
                      l10n.vendorReplyQuickly,
                      style: t.label.copyWith(
                        color: c.brandDeep,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (order.respondBy case final by?) ...[
                      const SizedBox(height: DymTokenSpace.s2),
                      RespondCountdown(
                        respondBy: by,
                        minutesLeft: order.minutesToRespond(vm.clock()),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.vendorAutoRefuseAt(_time(context, by)),
                        style: t.label.copyWith(
                          fontSize: 12,
                          color: c.brandDeep,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DymTokenSpace.s3),
      ],
      if (order.status == OrderStatus.refused)
        _Note(
          text: l10n.vendorOrderRefusedReason(
            reasonLabel(l10n, order.statusReason),
          ),
          icon: Icons.cancel_rounded,
        ),
      if (order.status == OrderStatus.cancelled)
        _Note(
          text: l10n.notifCancelledByClientBody,
          icon: Icons.cancel_rounded,
        ),
      if (order.refundDue)
        _Note(text: l10n.vendorRefundDue, icon: Icons.info_rounded),
      if (order.cashCollectedAt != null)
        _Note(text: l10n.vendorCashCollected, icon: Icons.verified_rounded),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DymTokenSpace.s4),
        decoration: BoxDecoration(
          color: order.isPaid ? c.brandDeep : c.tintPlantainClair,
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        ),
        child: Row(
          children: [
            Icon(
              order.isPaid ? Icons.verified_rounded : Icons.payments_rounded,
              size: 36,
              color: order.isPaid ? c.onBrand : c.brandDeep,
            ),
            const SizedBox(width: DymTokenSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.isPaid ? l10n.vendorPaidTitle : l10n.vendorCashTitle,
                    style: t.title.copyWith(
                      fontSize: 20,
                      color: order.isPaid ? c.onBrand : c.brandDeep,
                    ),
                  ),
                  Text(
                    order.isPaid
                        ? l10n.vendorPaidBody
                        : (order.courier?.isDym ?? false)
                        // Livreur DYM : c'est lui qui encaisse (spec 068).
                        ? l10n.vendorCashBodyCourier(
                            total,
                            vm.money(order.subtotalMinor)?.format() ?? '',
                          )
                        : l10n.vendorCashBody(total),
                    style: t.label.copyWith(
                      fontSize: 15,
                      color: order.isPaid ? c.onBrand : c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: DymTokenSpace.s3),
      card(l10n.vendorItems, [
        for (final line in order.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      line.name,
                      ?line.variantLabel,
                      ?line.unitLabel?.resolve(locale),
                      l10n.vendorQuantity(line.quantity),
                    ].join(' · '),
                    style: t.label.copyWith(fontSize: 15),
                  ),
                ),
                if (vm.money(line.amountMinor) case final amount?)
                  MoneyText(amount, size: 15, color: c.brandDeep),
              ],
            ),
          ),
      ]),
      if (adjustments case final service?)
        VendorAdjustmentsPanel(
          key: ValueKey('adjust-${order.id}-${order.status.name}'),
          service: service,
          order: order,
        ),
      const SizedBox(height: DymTokenSpace.s3),
      card(l10n.vendorPayment, [
        row(
          l10n.vendorPaymentMethod,
          order.paymentMethod.label.resolve(locale),
        ),
        row(l10n.paymentAmount, total),
        if (payment?.completedAt case final at?)
          row(
            l10n.vendorPaymentDate,
            '${MaterialLocalizations.of(context).formatShortDate(at.toLocal())}'
            ' · ${_time(context, at)}',
          ),
        if (payment != null) row(l10n.paymentReference, payment.reference),
      ]),
      const SizedBox(height: DymTokenSpace.s3),
      card(
        order.fulfillment == Fulfillment.delivery
            ? l10n.vendorDelivery
            : l10n.vendorPickup,
        [
          if (delivery != null) ...[
            Row(
              children: [
                Icon(Icons.location_on_rounded, color: c.brand),
                const SizedBox(width: DymTokenSpace.s2),
                Expanded(
                  child: Text(
                    [?delivery.zoneName, ?delivery.cityName].join(', '),
                    style: t.title.copyWith(fontSize: 17),
                  ),
                ),
              ],
            ),
            if (delivery.landmark case final landmark?)
              Text(
                l10n.vendorLandmark(landmark),
                style: t.label.copyWith(fontSize: 15),
              ),
            if (delivery.phone case final phone?)
              Padding(
                padding: const EdgeInsets.only(top: DymTokenSpace.s1),
                child: Row(
                  children: [
                    Icon(Icons.phone_rounded, size: 20, color: c.brandDeep),
                    const SizedBox(width: DymTokenSpace.s1),
                    Flexible(
                      child: SelectableText(
                        phone,
                        style: t.title.copyWith(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          // Livreur assigné (spec 068) : la vendeuse sait à qui remettre.
          if (order.courier case final courier?)
            Padding(
              padding: const EdgeInsets.only(top: DymTokenSpace.s3),
              child: Row(
                children: [
                  Icon(Icons.two_wheeler_rounded, color: c.brand),
                  const SizedBox(width: DymTokenSpace.s2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courier.isDym
                              ? l10n.vendorCourierDym(courier.name)
                              : l10n.vendorCourierExternal(courier.name),
                          style: t.title.copyWith(fontSize: 16),
                        ),
                        SelectableText(
                          courier.phone,
                          style: t.label.copyWith(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      if (order.history.isNotEmpty) ...[
        const SizedBox(height: DymTokenSpace.s4),
        DymSectionHeader(title: l10n.orderTimeline),
        for (final e in order.history)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(Icons.circle, size: 12, color: c.brand),
            title: Text(statusOnlyLabel(l10n, e.toStatus, order.fulfillment)),
            subtitle: Text(
              actorLabel(l10n, e.actorRole),
              style: t.label.copyWith(color: c.textSecondary),
            ),
            trailing: Text(
              TimeOfDay.fromDateTime(e.occurredAt.toLocal()).format(context),
            ),
          ),
      ],
    ];
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            header,
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  for (final w in children) DymContentWidth.form(child: w),
                ],
              ),
            ),
            if (actions.isNotEmpty)
              DymContentWidth.form(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: actions,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _disputeReason(DymLocalizations l10n, DisputeReason r) => switch (r) {
  DisputeReason.missingItem => l10n.disputeReasonMissingItem,
  DisputeReason.wrongItem => l10n.disputeReasonWrongItem,
  DisputeReason.damaged => l10n.disputeReasonDamaged,
  DisputeReason.quality => l10n.disputeReasonQuality,
  DisputeReason.notDelivered => l10n.disputeReasonNotDelivered,
  _ => l10n.disputeReasonOther,
};

/// Écran 51 : problème signalé par la cliente, fil et bouton « Répondre ».
class DisputeBanner extends StatelessWidget {
  const new({required this.dispute, required this.onReply, super.key});

  final Dispute dispute;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final d = dispute;
    String author(DisputeMessage m) => switch (m.authorRole) {
      'vendor' => l10n.disputeYou,
      'admin' => l10n.disputeTeam,
      _ => d.customerFirstName ?? l10n.disputeCustomer,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: d.isOpen ? c.tintPimentClair : c.tintVertTendre,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        border: Border.all(color: d.isOpen ? c.piment : c.brand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                d.isOpen ? Icons.error_rounded : Icons.verified_rounded,
                size: 36,
                color: d.isOpen ? c.pimentStrong : c.brandDeep,
              ),
              const SizedBox(width: DymTokenSpace.s2),
              Expanded(
                child: Text(
                  l10n.disputeVendorBanner(_disputeReason(l10n, d.reason)),
                  style: t.title.copyWith(
                    fontSize: 19,
                    color: d.isOpen ? c.pimentStrong : c.brandDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s1),
          for (final m in d.messages)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.disputeMessageLine(author(m), m.body),
                style: t.label.copyWith(
                  fontSize: 15,
                  fontWeight: m.authorRole == 'client'
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          if (!d.isOpen)
            Padding(
              padding: const EdgeInsets.only(top: DymTokenSpace.s1),
              child: Text(
                l10n.disputeResolvedStatus,
                style: t.title.copyWith(fontSize: 15, color: c.brandDeep),
              ),
            ),
          if (d.isOpen) ...[
            const SizedBox(height: DymTokenSpace.s2),
            DymButton(
              label: l10n.disputeReply,
              icon: Icons.chat_bubble_outline_rounded,
              variant: DymButtonVariant.secondary,
              onPressed: onReply,
            ),
          ],
        ],
      ),
    );
  }
}

/// Feuille de réponse au litige (écran 51) ; renvoie le texte saisi.
Future<String?> showDisputeReplySheet(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.dym.colors.card,
      constraints: const BoxConstraints(maxWidth: DymTokenLayout.formMax),
      builder: (_) => const DisputeReplySheet(),
    );

/// Contenu de la feuille de réponse (écran 51).
class DisputeReplySheet extends StatefulWidget {
  const new({super.key});

  @override
  State<DisputeReplySheet> createState() => _DisputeReplySheetState();
}

class _DisputeReplySheetState extends State<DisputeReplySheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DymTextField(
                label: l10n.disputeReplyHint,
                hint: l10n.disputeWriteMessage,
                controller: _text,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: DymTokenSpace.s4),
              ListenableBuilder(
                listenable: _text,
                builder: (context, _) => DymButton(
                  label: l10n.disputeSendMessage,
                  icon: Icons.send_rounded,
                  onPressed: _text.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(context, _text.text.trim()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const new({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
      child: Row(
        children: [
          Icon(icon, color: c.brandDeep),
          const SizedBox(width: DymTokenSpace.s2),
          Expanded(
            child: Text(
              text,
              style: context.dym.text.label.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Écran 45 : refus avec une raison (et une précision facultative).
Future<(RefusalReason, String?)?> showRefusalSheet(BuildContext context) =>
    showModalBottomSheet<(RefusalReason, String?)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.dym.colors.card,
      constraints: const BoxConstraints(maxWidth: DymTokenLayout.formMax),
      builder: (_) => const RefusalSheet(),
    );

/// Contenu de la feuille de refus (écran 45).
class RefusalSheet extends StatefulWidget {
  const new({super.key});

  @override
  State<RefusalSheet> createState() => _RefusalSheetState();
}

class _RefusalSheetState extends State<RefusalSheet> {
  RefusalReason _reason = RefusalReason.outOfStock;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.vendorRefuseTitle,
                textAlign: TextAlign.center,
                style: t.title.copyWith(fontSize: 22),
              ),
              Text(
                l10n.vendorRefuseBody,
                textAlign: TextAlign.center,
                style: t.label.copyWith(color: c.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: DymTokenSpace.s3),
              RadioGroup<RefusalReason>(
                groupValue: _reason,
                onChanged: (r) => setState(() => _reason = r ?? _reason),
                child: Column(
                  children: [
                    for (final r in const [
                      RefusalReason.outOfStock,
                      RefusalReason.tooBusy,
                      RefusalReason.areaNotServed,
                      RefusalReason.other,
                    ])
                      RadioListTile<RefusalReason>(
                        value: r,
                        title: Text(reasonLabel(l10n, r)),
                        activeColor: c.brand,
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
              DymTextField(
                label: l10n.vendorRefuseNote,
                controller: _note,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: DymTokenSpace.s4),
              DymButton(
                label: l10n.vendorRefuseConfirm,
                icon: Icons.close_rounded,
                variant: DymButtonVariant.destructive,
                onPressed: () => Navigator.pop(context, (
                  _reason,
                  _note.text.trim().isEmpty ? null : _note.text.trim(),
                )),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
