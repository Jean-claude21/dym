import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/cart/cart_viewmodels.dart';
import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_client/features/orders/order_texts.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Écran 37 : commande envoyée (une commande par boutique, en attente
/// d'acceptation). Le suivi arrive avec order-lifecycle.
class OrderSentView extends StackedView<OrderSentViewModel> {
  const new({
    required this.service,
    required this.purchase,
    required this.onHome,
    super.key,
    this.onTrack,
  });

  final CartService service;
  final Purchase purchase;
  final VoidCallback onHome;

  /// Onglet « Commandes » (suivi).
  final VoidCallback? onTrack;

  @override
  OrderSentViewModel viewModelBuilder(BuildContext context) =>
      OrderSentViewModel(service: service, purchase: purchase);

  @override
  void onViewModelReady(OrderSentViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    OrderSentViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final vm = viewModel;
    final p = vm.purchase;
    final address = p.address;
    final children = <Widget>[
      const SizedBox(height: DymTokenSpace.s4),
      Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: c.tintVertTendre,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, color: c.brandDeep, size: 52),
        ),
      ),
      const SizedBox(height: DymTokenSpace.s3),
      Text(l10n.orderSentTitle, textAlign: TextAlign.center, style: t.display),
      const SizedBox(height: DymTokenSpace.s1),
      Text(
        l10n.orderSentSubtitle,
        textAlign: TextAlign.center,
        style: t.body.copyWith(color: c.textSecondary),
      ),
      const SizedBox(height: DymTokenSpace.s4),
      for (final order in p.orders) ...[
        _OrderCard(
          order: order,
          total: vm.money(order.totalMinor),
          originText: originLabel(vm.config, order.store.origin, locale),
        ),
        const SizedBox(height: DymTokenSpace.s3),
      ],
      CartCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, color: c.brandDeep),
                const SizedBox(width: DymTokenSpace.s2),
                Expanded(
                  child: Text(
                    p.paymentMethod.label.resolve(locale),
                    style: t.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (p.isPaid) const _PaymentBadge(paid: true),
              ],
            ),
            Divider(height: 24, color: c.hairline),
            SumRow(
              label: l10n.cartTotal,
              amount: vm.money(p.totalMinor),
              strong: true,
            ),
            if (address != null) ...[
              const SizedBox(height: DymTokenSpace.s2),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: c.brandDeep),
                  const SizedBox(width: DymTokenSpace.s2),
                  Expanded(
                    child: Text(
                      l10n.orderDeliveryTo(
                        addressTitle(l10n, address.kind, address.label),
                      ),
                      style: t.label.copyWith(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ];
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  for (final w in children) DymContentWidth.form(child: w),
                ],
              ),
            ),
            DymContentWidth.form(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (onTrack != null) ...[
                      DymButton(
                        label: l10n.trackTitle,
                        icon: Icons.local_shipping_rounded,
                        onPressed: onTrack,
                      ),
                      const SizedBox(height: DymTokenSpace.s2),
                    ],
                    DymButton(
                      label: l10n.orderBackHome,
                      icon: Icons.home_rounded,
                      variant: onTrack == null
                          ? DymButtonVariant.primary
                          : DymButtonVariant.secondary,
                      onPressed: onHome,
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

class _OrderCard extends StatelessWidget {
  const new({
    required this.order,
    required this.total,
    required this.originText,
  });

  final PurchaseOrder order;
  final Money? total;
  final String originText;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final origin = originOf(order.store.origin);
    final mode = order.fulfillment == Fulfillment.delivery
        ? l10n.deliveryModeDelivery
        : l10n.deliveryModePickup;
    final start = order.scheduledStart;
    final end = order.scheduledEnd;
    return CartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: DymTokenSpace.s2,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      order.store.name,
                      style: t.body.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (origin != null)
                      DymOriginBadge(
                        origin: origin,
                        label: originText,
                        dense: true,
                      ),
                  ],
                ),
              ),
              if (total != null)
                MoneyText(total!, size: 16, color: c.textPrimary),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.orderItems(order.itemCount)} · $mode',
            style: t.label.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (start != null && end != null) ...[
            const SizedBox(height: DymTokenSpace.s2),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 18, color: c.brandDeep),
                const SizedBox(width: DymTokenSpace.s1),
                Expanded(
                  child: Text(
                    l10n.orderScheduled(
                      shortDate(context, start),
                      shortTime(context, start),
                      shortTime(context, end),
                    ),
                    style: t.label.copyWith(color: c.brandDeep),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: DymTokenSpace.s2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DymTokenSpace.s2,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: c.tintVertTendre,
              borderRadius: BorderRadius.circular(DymTokenRadius.chip),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_outlined, size: 16, color: c.brandDeep),
                const SizedBox(width: DymTokenSpace.s1),
                Flexible(
                  child: Text(
                    l10n.orderPending,
                    style: t.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.brandDeep,
                    ),
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

/// « Paiement confirmé » (menthe).
class _PaymentBadge extends StatelessWidget {
  const new({required this.paid});

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
        color: c.tintVertTendre,
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            paid ? Icons.check_circle_outline_rounded : Icons.payments_outlined,
            size: 18,
            color: c.brandDeep,
          ),
          const SizedBox(width: DymTokenSpace.s1),
          Flexible(
            child: Text(
              paid ? l10n.paymentConfirmed : l10n.paymentCashOnDelivery,
              style: context.dym.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: c.brandDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
