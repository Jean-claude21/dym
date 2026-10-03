import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
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
      message: l10n.storeSaveError,
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
                fontWeight: FontWeight.w800,
                color: c.brandDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _title(DymLocalizations l10n, VendorOrder o) =>
    l10n.vendorOrderOf(o.customerFirstName ?? '…');

String _time(BuildContext context, DateTime at) =>
    TimeOfDay.fromDateTime(at.toLocal()).format(context);

// ------------------------------------------------------------------ 41

/// Écran 41 : commandes de la boutique (payées ou en cash), les plus récentes
/// d'abord ; relues toutes les 20 s.
class OrdersView extends StackedView<OrdersViewModel> {
  const new({required this.service, required this.onOpen, super.key});

  final OrdersService service;
  final ValueChanged<String> onOpen;

  @override
  OrdersViewModel viewModelBuilder(BuildContext context) =>
      OrdersViewModel(service: service);

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
  const new({required this.order, required this.total, required this.onTap});

  final VendorOrder order;
  final Money? total;
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
    ].join(' · ');
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(DymTokenRadius.tile),
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
              Text(place, style: t.label.copyWith(color: c.textSecondary)),
              Text(
                '${l10n.orderItems(order.itemCount)} · $mode',
                style: t.label.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: DymTokenSpace.s2),
              PaymentPill(paid: order.isPaid),
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
  });

  final OrdersService service;
  final String orderId;
  final VoidCallback onBack;

  @override
  OrderDetailViewModel viewModelBuilder(BuildContext context) =>
      OrderDetailViewModel(service: service, orderId: orderId);

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
              children: [
                Text(
                  order == null ? l10n.navOrders : _title(l10n, order),
                  textAlign: TextAlign.center,
                  style: t.display.copyWith(fontSize: 24),
                ),
                if (order != null)
                  Text(
                    l10n.vendorOrderReceivedAt(_time(context, order.createdAt)),
                    style: t.label.copyWith(color: c.textSecondary),
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
    final payment = order.payment;
    final delivery = order.delivery;
    Widget card(String title, List<Widget> children) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
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
    final children = <Widget>[
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
        ],
      ),
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
          ],
        ),
      ),
    );
  }
}
