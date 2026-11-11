import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_texts.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_admin/features/orders/orders_viewmodels.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

AdminTone _statusTone(OrderStatus s) => switch (s) {
  OrderStatus.pending || OrderStatus.preparing => AdminTone.warning,
  OrderStatus.accepted ||
  OrderStatus.ready ||
  OrderStatus.outForDelivery ||
  OrderStatus.delivered => AdminTone.success,
  _ => AdminTone.neutral,
};

AdminTone _paymentTone(PaymentStatus s) => switch (s) {
  PaymentStatus.paid => AdminTone.success,
  PaymentStatus.failed => AdminTone.danger,
  PaymentStatus.awaitingPayment => AdminTone.warning,
  _ => AdminTone.neutral,
};

// ------------------------------------------------------------------ 52

/// Écran 52 : commandes (filtres, recherche, bloquées en tête de lecture).
class AdminOrdersView extends StackedView<AdminOrdersViewModel> {
  const new({
    required this.service,
    required this.onOpen,
    super.key,
    this.clock = DateTime.now,
  });

  final AdminService service;
  final ValueChanged<String> onOpen;
  final DateTime Function() clock;

  @override
  AdminOrdersViewModel viewModelBuilder(BuildContext context) =>
      AdminOrdersViewModel(service: service);

  @override
  void onViewModelReady(AdminOrdersViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    AdminOrdersViewModel viewModel,
    Widget? child,
  ) {
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final page = vm.page;
    final now = clock();
    return AdminPage(
      title: l10n.navOrders,
      actions: [
        SizedBox(
          width: 420,
          child: DymTextField(
            label: l10n.adminOrderSearch,
            icon: Icons.search_rounded,
            textInputAction: TextInputAction.search,
            onSubmitted: vm.search,
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: DymTokenSpace.s2,
            runSpacing: DymTokenSpace.s2,
            children: [
              for (final f in AdminOrderFilter.values)
                DymFilterChip(
                  label: switch (f) {
                    AdminOrderFilter.all => l10n.adminFilterAll,
                    AdminOrderFilter.pending => l10n.orderStatusPending,
                    AdminOrderFilter.active => l10n.adminFilterActive,
                    AdminOrderFilter.stuck => l10n.adminFilterStuck(
                      page?.stuckCount ?? 0,
                    ),
                    AdminOrderFilter.delivered => l10n.adminFilterDelivered,
                    AdminOrderFilter.closed => l10n.adminFilterClosed,
                  },
                  icon: f == AdminOrderFilter.stuck
                      ? Icons.report_rounded
                      : null,
                  selected: vm.filter == f,
                  onTap: () => vm.selectFilter(f),
                ),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s3),
          if (!vm.ready || page == null)
            AdminState(failure: vm.isBusy ? null : vm.failure, onRetry: vm.load)
          else
            AdminCard(
              padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (page.orders.isEmpty)
                    AdminEmpty(l10n.adminNoOrders)
                  else ...[
                    if (DymWindowClass.of(context) >= DymWindowClass.expanded)
                      const _OrderHeader(),
                    for (final o in page.orders)
                      _OrderRow(
                        row: o,
                        amount: vm.money(o.totalMinor, o.currencyCode),
                        now: now,
                        onTap: () => onOpen(o.id),
                      ),
                  ],
                  _Pager(vm: vm, total: page.total, shown: page.orders.length),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final style = context.dym.text.label.copyWith(
      color: context.dym.colors.textSecondary,
      fontWeight: FontWeight.w700,
    );
    Widget cell(String text, int flex, {TextAlign align = TextAlign.start}) =>
        Expanded(
          flex: flex,
          child: Text(text, style: style, textAlign: align),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DymTokenSpace.s4,
        DymTokenSpace.s2,
        DymTokenSpace.s4,
        DymTokenSpace.s2,
      ),
      child: Row(
        children: [
          cell(l10n.adminColNumber, 2),
          cell(l10n.adminColStore, 3),
          cell(l10n.adminColCustomer, 2),
          cell(l10n.adminColStatus, 3),
          cell(l10n.adminColPayment, 3),
          cell(l10n.adminColAmount, 2, align: TextAlign.end),
          cell(l10n.adminColSince, 2, align: TextAlign.end),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const new({
    required this.row,
    required this.amount,
    required this.now,
    required this.onTap,
  });

  final AdminOrderRow row;
  final String amount;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final wide = DymWindowClass.of(context) >= DymWindowClass.expanded;
    final status = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AdminPill(
          orderStatusLabel(l10n, row.status),
          tone: _statusTone(row.status),
        ),
        if (row.stuck)
          Text(
            l10n.adminStuck,
            style: t.label.copyWith(
              color: c.pimentStrong,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
    final payment = AdminPill(
      paymentStatusLabel(l10n, row.paymentStatus),
      tone: _paymentTone(row.paymentStatus),
    );
    final since = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 18,
          color: row.stuck ? c.pimentStrong : c.textSecondary,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            sinceLabel(l10n, row.lastChangeAt, now),
            style: t.label.copyWith(
              color: row.stuck ? c.pimentStrong : c.textSecondary,
            ),
          ),
        ),
      ],
    );
    final content = wide
        ? Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  row.reference,
                  style: t.title.copyWith(fontSize: 15),
                ),
              ),
              Expanded(flex: 3, child: Text(row.storeName, style: t.body)),
              Expanded(
                flex: 2,
                child: Text(row.customerFirstName ?? '', style: t.body),
              ),
              Expanded(
                flex: 3,
                child: Align(alignment: Alignment.centerLeft, child: status),
              ),
              Expanded(
                flex: 3,
                child: Align(alignment: Alignment.centerLeft, child: payment),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  amount,
                  textAlign: TextAlign.end,
                  style: t.title.copyWith(fontSize: 15),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(alignment: Alignment.centerRight, child: since),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${row.reference} · ${row.storeName}',
                      style: t.title.copyWith(fontSize: 15),
                    ),
                  ),
                  Text(amount, style: t.title.copyWith(fontSize: 15)),
                ],
              ),
              Text(row.customerFirstName ?? '', style: t.label),
              const SizedBox(height: 4),
              Wrap(
                spacing: DymTokenSpace.s2,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [status, payment, since],
              ),
            ],
          );
    return Material(
      color: row.stuck ? c.tintPimentClair : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: row.stuck ? c.pimentStrong : Colors.transparent,
                width: 4,
              ),
              bottom: BorderSide(color: c.background),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DymTokenSpace.s4,
            vertical: DymTokenSpace.s2,
          ),
          child: content,
        ),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const new({required this.vm, required this.total, required this.shown});

  final AdminOrdersViewModel vm;
  final int total;
  final int shown;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final from = total == 0 ? 0 : vm.offset + 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DymTokenSpace.s4,
        DymTokenSpace.s2,
        DymTokenSpace.s2,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.adminPageRange(from, vm.offset + shown, total),
              style: context.dym.text.label.copyWith(
                color: context.dym.colors.textSecondary,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.adminPrevious,
            onPressed: vm.hasPrevious ? vm.previousPage : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: l10n.adminNext,
            onPressed: vm.hasNext ? vm.nextPage : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ 53

/// Écran 53 : détail d'une commande, chronologie et actions de l'équipe.
class AdminOrderView extends StackedView<AdminOrderViewModel> {
  const new({
    required this.service,
    required this.orderId,
    required this.onBack,
    super.key,
    this.clock = DateTime.now,
  });

  final AdminService service;
  final String orderId;
  final VoidCallback onBack;
  final DateTime Function() clock;

  @override
  AdminOrderViewModel viewModelBuilder(BuildContext context) =>
      AdminOrderViewModel(service: service, orderId: orderId);

  @override
  void onViewModelReady(AdminOrderViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    AdminOrderViewModel viewModel,
    Widget? child,
  ) {
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final o = vm.order;
    final back = IconButton(
      tooltip: l10n.authBack,
      onPressed: onBack,
      icon: const Icon(Icons.arrow_back_rounded),
    );
    if (!vm.ready || o == null) {
      return AdminPage(
        title: l10n.navOrders,
        leading: back,
        child: AdminState(
          failure: vm.isBusy ? null : vm.failure,
          onRetry: vm.load,
        ),
      );
    }
    final now = clock();
    final address = o.order.address;
    final main = [
      _Timeline(order: o, vm: vm, now: now),
      const SizedBox(height: DymTokenSpace.s3),
      _Items(order: o, vm: vm),
      const SizedBox(height: DymTokenSpace.s3),
      AdminCard(
        title: l10n.adminActorClient,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminField(l10n.adminFirstName, o.customer.firstName ?? ''),
            if (o.customer.phone case final phone?)
              AdminField(l10n.adminPhone, phone),
            if (address != null)
              AdminField(
                l10n.adminAddress,
                '${address.zoneName}, ${address.cityName} · '
                '${address.landmark}',
              ),
            AdminField(
              l10n.adminColPayment,
              o.order.paymentMethod?.label.resolve(
                    Localizations.localeOf(context).languageCode,
                  ) ??
                  '',
            ),
          ],
        ),
      ),
    ];
    final actions = _Actions(vm: vm, order: o);
    final wide = DymWindowClass.of(context) >= DymWindowClass.expanded;
    return AdminPage(
      title: l10n.adminOrderTitle(o.reference),
      subtitle: [
        o.storeName,
        ?o.customer.firstName,
        if (address != null) '${address.zoneName}, ${address.cityName}',
      ].join(' · '),
      leading: back,
      actions: [
        AdminPill(
          orderStatusLabel(l10n, o.order.status),
          tone: AdminTone.success,
        ),
        if (o.stuck)
          AdminPill(
            l10n.adminStuckSince(sinceLabel(l10n, o.lastChangeAt, now)),
            tone: AdminTone.danger,
            icon: Icons.block_rounded,
          ),
        if (o.dispute?.isOpen ?? false)
          AdminPill(
            l10n.adminOpenDispute,
            tone: AdminTone.warning,
            icon: Icons.forum_rounded,
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Facts(
            facts: [
              (l10n.adminColCustomer, o.customer.firstName ?? '—'),
              (l10n.adminColStore, o.storeName),
              (
                l10n.adminColAmount,
                vm.money(o.order.totalMinor, o.order.currencyCode),
              ),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s3),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: Column(children: main)),
                const SizedBox(width: DymTokenSpace.s4),
                Expanded(flex: 2, child: actions),
              ],
            )
          else ...[
            actions,
            const SizedBox(height: DymTokenSpace.s3),
            ...main,
          ],
        ],
      ),
    );
  }
}

/// Cliente · boutique · montant, séparés par des filets (planche 06).
class _Facts extends StatelessWidget {
  const new({required this.facts});

  final List<(String, String)> facts;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s3),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: c.hairline)),
      ),
      child: Wrap(
        runSpacing: DymTokenSpace.s2,
        children: [
          for (final (label, value) in facts)
            Container(
              constraints: const BoxConstraints(minWidth: 180),
              padding: const EdgeInsets.only(right: DymTokenSpace.s4),
              margin: const EdgeInsets.only(right: DymTokenSpace.s4),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: c.hairline)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: t.label.copyWith(
                      color: c.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    value,
                    style: t.body.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const new({required this.order, required this.vm, required this.now});

  final AdminOrder order;
  final AdminOrderViewModel vm;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final method = order.order.paymentMethod?.label.resolve(locale) ?? '';
    final entries = <(DateTime, String, String)>[
      (order.order.createdAt, l10n.adminActorClient, l10n.adminOrderPlaced),
      for (final p in order.payments)
        if (p.completedAt != null || p.status != 'pending')
          (
            p.completedAt ?? p.createdAt,
            l10n.adminActorPayment,
            l10n.adminPaymentLine(
              p.status == 'succeeded'
                  ? l10n.adminPaid
                  : l10n.paymentFailedTitle,
              method,
              p.reference,
            ),
          ),
      for (final e in order.timeline)
        (
          e.occurredAt,
          actorLabel(l10n, e.actorRole),
          [orderStatusLabel(l10n, e.toStatus), ?e.note].join(' — '),
        ),
      if (order.courier case final courier?)
        (
          courier.assignedAt ?? now,
          l10n.adminActorTeam,
          l10n.adminCourierLine(courier.name, courier.phone),
        ),
      for (final r in order.refunds)
        (
          r.completedAt ?? r.createdAt,
          l10n.adminEntityRefund,
          l10n.adminRefundLine(
            vm.money(r.amountMinor, r.currencyCode ?? order.order.currencyCode),
            _refundStatus(l10n, r.status),
          ),
        ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return AdminCard(
      title: l10n.adminTimeline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, (at, actor, text)) in entries.indexed)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      Icon(Icons.circle, size: 14, color: c.brand),
                      if (i < entries.length - 1 || order.stuck)
                        Expanded(child: Container(width: 2, color: c.brand)),
                    ],
                  ),
                  const SizedBox(width: DymTokenSpace.s2),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${timeLabel(context, at)} · $actor',
                            style: t.title.copyWith(fontSize: 15),
                          ),
                          Text(
                            text,
                            style: t.body.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (order.stuck)
            Row(
              children: [
                Icon(
                  Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: c.pimentStrong,
                ),
                const SizedBox(width: DymTokenSpace.s2),
                Flexible(
                  child: AdminPill(
                    l10n.adminNoStepSince(
                      sinceLabel(l10n, order.lastChangeAt, now),
                    ),
                    tone: AdminTone.danger,
                  ),
                ),
              ],
            ),
          if (order.statusNote case final note?
              when order.status == OrderStatus.cancelled)
            Padding(
              padding: const EdgeInsets.only(top: DymTokenSpace.s2),
              child: AdminAlert(l10n.adminCancelledNote(note)),
            ),
        ],
      ),
    );
  }
}

String _refundStatus(DymLocalizations l10n, RefundStatus s) => switch (s) {
  RefundStatus.pending => l10n.adminRefundPending,
  RefundStatus.processing => l10n.adminRefundProcessing,
  RefundStatus.succeeded => l10n.adminRefundSucceeded,
  RefundStatus.failed => l10n.adminRefundFailed,
  RefundStatus.unknown => l10n.errorGeneric,
};

class _Items extends StatelessWidget {
  const new({required this.order, required this.vm});

  final AdminOrder order;
  final AdminOrderViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final code = order.order.currencyCode;
    Widget line(String label, String amount, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong ? t.title.copyWith(fontSize: 18) : t.body,
            ),
          ),
          Text(amount, style: t.title.copyWith(fontSize: strong ? 20 : 15)),
        ],
      ),
    );
    return AdminCard(
      title: l10n.vendorItems,
      child: Column(
        children: [
          for (final i in order.order.items)
            line(
              [
                i.name,
                ?i.variantLabel,
                ?i.unitLabel?.resolve(locale),
                '× ${i.quantity}',
              ].join(' · '),
              vm.money(i.amountMinor, code),
            ),
          const Divider(),
          if (order.order.fulfillment == Fulfillment.delivery)
            line(
              l10n.vendorDelivery,
              vm.money(order.order.deliveryFeeMinor, code),
            ),
          line(
            l10n.adminTotal,
            vm.money(order.order.totalMinor, code),
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatefulWidget {
  const new({required this.vm, required this.order});

  final AdminOrderViewModel vm;
  final AdminOrder order;

  @override
  State<_Actions> createState() => _ActionsState();
}

class _ActionsState extends State<_Actions> {
  final _reason = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = widget.vm;
    final o = widget.order;
    final paid = o.order.paymentStatus == PaymentStatus.paid;
    Future<void> cancel() async {
      final reason = await showReasonDialog(
        context,
        title: l10n.adminCancelTitle(o.reference),
        confirmLabel: paid ? l10n.adminCancelRefund : l10n.adminCancelOrder,
        destructive: true,
      );
      if (reason != null) await vm.cancel(reason);
    }

    return AdminCard(
      title: l10n.adminActions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (vm.actionFailure case final failure?)
            AdminAlert(adminFailureLabel(l10n, failure)),
          if (o.forceableStatuses.isEmpty && !o.canCancel)
            Text(
              l10n.adminOrderClosed,
              style: t.body.copyWith(color: c.textSecondary),
            ),
          if (o.forceableStatuses.isNotEmpty) ...[
            Text(l10n.adminForceStatus, style: t.title.copyWith(fontSize: 16)),
            const SizedBox(height: DymTokenSpace.s1),
            DropdownButtonFormField<OrderStatus>(
              initialValue: vm.target,
              isExpanded: true,
              hint: Text(l10n.adminChooseStatus),
              items: [
                for (final s in o.forceableStatuses)
                  DropdownMenuItem(
                    value: s,
                    child: Text(orderStatusLabel(l10n, s)),
                  ),
              ],
              onChanged: vm.acting ? null : vm.selectTarget,
            ),
            const SizedBox(height: DymTokenSpace.s2),
            DymTextField(
              label: l10n.adminReasonLabel,
              controller: _reason,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
            ),
            ListenableBuilder(
              listenable: _reason,
              builder: (context, _) => DymButton(
                label: l10n.adminApply,
                icon: Icons.check_rounded,
                loading: vm.acting,
                onPressed:
                    vm.acting ||
                        vm.target == null ||
                        _reason.text.trim().length < 3
                    ? null
                    : () async {
                        if (await vm.forceStatus(_reason.text)) {
                          _reason.clear();
                        }
                      },
              ),
            ),
          ],
          if (o.canAssignCourier) ...[
            const Divider(height: DymTokenSpace.s5),
            Text(
              l10n.adminExternalDelivery,
              style: t.title.copyWith(fontSize: 16),
            ),
            if (o.courier case final courier?)
              Text(
                l10n.adminCourierLine(courier.name, courier.phone),
                style: t.body.copyWith(color: c.brandDeep),
              ),
            const SizedBox(height: DymTokenSpace.s1),
            DymTextField(label: l10n.adminCourierName, controller: _name),
            const SizedBox(height: DymTokenSpace.s2),
            DymTextField(
              label: l10n.adminPhone,
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: DymTokenSpace.s2),
            ListenableBuilder(
              listenable: Listenable.merge([_name, _phone]),
              builder: (context, _) => DymButton(
                label: l10n.adminAssign,
                icon: Icons.two_wheeler_rounded,
                variant: DymButtonVariant.secondary,
                onPressed:
                    vm.acting ||
                        _name.text.trim().length < 2 ||
                        _phone.text.trim().length < 6
                    ? null
                    : () async {
                        if (await vm.assignCourier(_name.text, _phone.text)) {
                          _name.clear();
                          _phone.clear();
                        }
                      },
              ),
            ),
          ],
          if (o.canCancel) ...[
            const SizedBox(height: DymTokenSpace.s3),
            DymButton(
              label: paid ? l10n.adminCancelRefund : l10n.adminCancelOrder,
              icon: Icons.delete_outline_rounded,
              variant: DymButtonVariant.destructive,
              onPressed: vm.acting ? null : cancel,
            ),
          ],
          const SizedBox(height: DymTokenSpace.s2),
          Text(
            l10n.adminAuditNote,
            style: t.label.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
