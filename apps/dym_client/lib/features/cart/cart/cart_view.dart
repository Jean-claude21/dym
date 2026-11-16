import 'dart:async';

import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/cart/cart_viewmodels.dart';
import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

/// Écran 05 : panier multi-boutiques (sous-paniers, livraison, paiement,
/// total, commande en un tap). Montants calculés par la base.
class CartPageView extends StackedView<CartViewModel> {
  const new({
    required this.service,
    required this.onDelivery,
    required this.onOrdered,
    required this.onBrowse,
    super.key,
    this.onBack,
    this.onSave,
    this.onSendToSpace,
  });

  final CartService service;

  /// Retour ; nul dans l'onglet « Panier ».
  final VoidCallback? onBack;

  /// Écran 34 (adresse, mode par boutique).
  final VoidCallback onDelivery;
  final void Function(Purchase purchase) onOrdered;

  /// Panier vide : retour aux boutiques.
  final VoidCallback onBrowse;

  /// « Enregistrer ce panier » (spec 030) ; absent : masqué.
  final Future<void> Function(BuildContext context)? onSave;

  /// « Envoyer à un espace » (spec 031) ; absent : masqué.
  final Future<void> Function(BuildContext context)? onSendToSpace;

  @override
  CartViewModel viewModelBuilder(BuildContext context) => CartViewModel(
    service: service,
    onOrdered: onOrdered,
    onSuccess: () => unawaited(HapticFeedback.mediumImpact()),
  );

  @override
  void onViewModelReady(CartViewModel viewModel) =>
      viewModel.load().then((_) => viewModel.loadSlots());

  @override
  Widget builder(BuildContext context, CartViewModel viewModel, Widget? child) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final cart = vm.cart;
    final header = CartHeader(
      title: l10n.cartTitle,
      subtitle: cart.isEmpty
          ? null
          : l10n.cartSummary(cart.storeCount, cart.itemCount),
      onBack: onBack,
      trailing: cart.isEmpty || (onSave == null && onSendToSpace == null)
          ? null
          : PopupMenuButton<Future<void> Function(BuildContext)>(
              tooltip: l10n.cartMoreActions,
              icon: Icon(Icons.more_horiz_rounded, color: c.textPrimary),
              onSelected: (action) => unawaited(action(context)),
              itemBuilder: (_) => [
                if (onSave case final save?)
                  PopupMenuItem(
                    value: save,
                    child: ListTile(
                      leading: const Icon(Icons.bookmark_add_rounded),
                      title: Text(l10n.basketSave),
                    ),
                  ),
                if (onSendToSpace case final send?)
                  PopupMenuItem(
                    value: send,
                    child: ListTile(
                      leading: const Icon(Icons.groups_rounded),
                      title: Text(l10n.spaceSendToSpace),
                    ),
                  ),
              ],
            ),
    );

    Widget body;
    if (!vm.ready && cart.isEmpty) {
      body = DiscoveryState(
        failure: vm.isBusy ? null : vm.failure,
        onRetry: vm.load,
      );
    } else if (cart.isEmpty) {
      body = DymStateView(
        kind: DymStateKind.empty,
        title: l10n.cartEmptyTitle,
        message: l10n.cartEmptyMessage,
        actionLabel: l10n.cartBrowse,
        onAction: onBrowse,
      );
    } else {
      body = _CartContent(vm: vm, onDelivery: onDelivery);
    }
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            header,
            if (vm.offline && !cart.isEmpty)
              _OfflineBanner(label: l10n.errorOffline),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// « Quand ? » (spec 033) : dès que possible, ou un jour et un créneau.
class _SlotCard extends StatelessWidget {
  const new({required this.vm, required this.slots});

  final CartViewModel vm;
  final DeliverySlots slots;

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final today = DateTime.now();
    String dayLabel(DateTime d) {
      final diff = DateTime(
        d.year,
        d.month,
        d.day,
      ).difference(DateTime(today.year, today.month, today.day)).inDays;
      return switch (diff) {
        0 => l10n.slotToday,
        1 => l10n.slotTomorrow,
        _ => material.formatShortDate(d),
      };
    }

    final chosen = vm.slot;
    final shown = chosen?.date ?? vm.slotDay;
    final day =
        slots.days.where((d) => d.date == shown).firstOrNull ??
        slots.days.first;
    return CartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.slotTitle,
            style: t.body.copyWith(fontWeight: FontWeight.w600),
          ),
          if (slots.required && slots.minDate != null)
            Text(
              l10n.slotRequiredFrom(material.formatMediumDate(slots.minDate!)),
              style: t.label.copyWith(color: c.brandDeep),
            ),
          const SizedBox(height: DymTokenSpace.s2),
          Wrap(
            spacing: DymTokenSpace.s2,
            runSpacing: DymTokenSpace.s2,
            children: [
              if (!slots.required)
                ChoiceChip(
                  label: Text(l10n.slotAsap),
                  selected: chosen == null,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) => vm.selectSlot(null),
                ),
              for (final d in slots.days)
                ChoiceChip(
                  label: Text(dayLabel(d.date)),
                  selected: chosen?.date == d.date,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) => vm.showDay(d.date),
                ),
            ],
          ),
          // Créneaux du jour choisi ; masqués sur « dès que possible ».
          if (chosen != null || slots.required) ...[
            const SizedBox(height: DymTokenSpace.s2),
            Wrap(
              spacing: DymTokenSpace.s2,
              runSpacing: DymTokenSpace.s2,
              children: [
                for (final w in day.windows)
                  ChoiceChip(
                    label: Text(l10n.slotWindow(w.startsAt, w.endsAt)),
                    selected:
                        chosen?.windowId == w.id && chosen?.date == day.date,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onSelected: (_) => vm.selectSlot(
                      SlotChoice(date: day.date, windowId: w.id),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return DymContentWidth.form(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: CartCard(
          color: c.tintPeche,
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: c.textPrimary),
              const SizedBox(width: DymTokenSpace.s2),
              Expanded(child: Text(label, style: context.dym.text.label)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartContent extends StatelessWidget {
  const new({required this.vm, required this.onDelivery});

  final CartViewModel vm;
  final VoidCallback onDelivery;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final cart = vm.cart;
    final progress = vm.freeDeliveryProgress;
    final remaining = vm.money(cart.remainingForFreeMinor);

    final items = <Widget>[
      if (progress != null && remaining != null) ...[
        if (cart.remainingForFreeMinor == 0)
          CartCard(
            child: Row(
              children: [
                Icon(Icons.redeem_rounded, color: c.brand, size: 28),
                const SizedBox(width: DymTokenSpace.s3),
                Expanded(child: Text(l10n.cartFreeReached, style: t.title)),
              ],
            ),
          )
        else
          DymFreeDeliveryGauge(
            lead: l10n.cartFreeLead,
            amount: remaining.format(),
            trail: l10n.cartFreeTrail,
            progress: progress,
          ),
        const SizedBox(height: DymTokenSpace.s3),
      ],
      for (final store in cart.stores) ...[
        _StoreGroup(vm: vm, store: store, locale: locale),
        const SizedBox(height: DymTokenSpace.s3),
      ],
      DymSwitchTile(
        title: l10n.cartSubstitutionTitle,
        subtitle: l10n.cartSubstitutionSubtitle,
        value: vm.substitutionAllowed,
        onChanged: (v) => vm.setSubstitution(allowed: v),
      ),
    ];

    final summary = <Widget>[
      CartCard(
        child: InkWell(
          onTap: onDelivery,
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.tintVertTendre,
                    borderRadius: BorderRadius.circular(DymTokenRadius.field),
                  ),
                  child: Icon(
                    Icons.delivery_dining_outlined,
                    color: c.brandDeep,
                    size: 22,
                  ),
                ),
                const SizedBox(width: DymTokenSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.cartDelivery,
                        style: t.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        l10n.cartDeliveryMeta(
                          cart.pickupCount,
                          cart.deliveryMinutes,
                        ),
                        style: t.label.copyWith(color: c.textSecondary),
                      ),
                      if (cart.hasDelivery)
                        switch (vm.deliveryAddress) {
                          final a? => Text(
                            l10n.cartDeliveryTo(a.zoneName, a.landmark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.label.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          null => Text(
                            l10n.cartAddAddress,
                            style: t.label.copyWith(
                              color: c.pimentStrong,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        },
                    ],
                  ),
                ),
                Text(
                  l10n.cartChange,
                  style: t.label.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.brandDeep,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.brandDeep),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: DymTokenSpace.s3),
      if (vm.slots case final slots? when slots.days.isNotEmpty) ...[
        _SlotCard(vm: vm, slots: slots),
        const SizedBox(height: DymTokenSpace.s3),
      ],
      if (cart.paymentMethods.isNotEmpty) ...[
        CartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.cartPayment,
                style: t.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: DymTokenSpace.s2),
              LayoutBuilder(
                builder: (context, box) {
                  const gap = DymTokenSpace.s2;
                  final columns = box.maxWidth >= 320 ? 2 : 1;
                  final width = (box.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final m in cart.paymentMethods)
                        SizedBox(
                          width: width,
                          child: DymPaymentOption(
                            title: m.label.resolve(locale),
                            icon: m.isCash
                                ? Icons.payments_outlined
                                : Icons.phone_android_outlined,
                            selected: m.id == cart.paymentMethodId,
                            onTap: () => vm.selectPayment(m.id),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: DymTokenSpace.s3),
      ],
      CartCard(
        child: Column(
          children: [
            SumRow(
              label: l10n.cartSubtotal,
              amount: vm.money(cart.subtotalMinor),
            ),
            SumRow(
              label: l10n.cartDelivery,
              amount: vm.money(cart.deliveryFeeMinor),
            ),
            const Divider(height: 16),
            SumRow(
              label: l10n.cartTotal,
              amount: vm.money(cart.totalMinor),
              strong: true,
            ),
          ],
        ),
      ),
    ];

    final error = vm.orderError;
    final order = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null || cart.blocking || vm.missingAddress)
          Padding(
            padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
            child: CartIssue(
              label: error != null
                  ? orderErrorLabel(l10n, error)
                  : cart.blocking
                  ? l10n.cartBlocked
                  : l10n.orderErrorAddressRequired,
            ),
          ),
        DymButton(
          label: l10n.cartOrder(vm.money(cart.totalMinor)?.format() ?? ''),
          icon: Icons.shopping_bag_outlined,
          loading: vm.ordering,
          onPressed: vm.canOrder ? vm.order : null,
        ),
      ],
    );

    // Étendue et au-delà : articles à gauche, récapitulatif à droite.
    if (DymWindowClass.of(context) >= DymWindowClass.expanded) {
      return LayoutBuilder(
        builder: (context, box) {
          final inset = DymLayout.sideInset(
            box.maxWidth,
            gutter: DymLayout.gutter(context),
          );
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    children: items,
                  ),
                ),
                const SizedBox(width: DymTokenSpace.s5),
                SizedBox(
                  width: 400,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    children: [
                      ...summary,
                      const SizedBox(height: DymTokenSpace.s3),
                      order,
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              for (final w in [
                ...items,
                const SizedBox(height: DymTokenSpace.s3),
                ...summary,
              ])
                DymContentWidth.form(child: w),
            ],
          ),
        ),
        DymContentWidth.form(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: order,
          ),
        ),
      ],
    );
  }
}

class _StoreGroup extends StatelessWidget {
  const new({required this.vm, required this.store, required this.locale});

  final CartViewModel vm;
  final CartStoreGroup store;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final origin = originOf(store.origin);
    return CartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: DymTokenSpace.s2,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                store.name,
                style: t.body.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (origin != null)
                DymOriginBadge(
                  origin: origin,
                  label: originLabel(vm.config, store.origin, locale),
                  dense: true,
                ),
              Text(
                store.zoneName,
                style: t.label.copyWith(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          for (final issue in store.issues)
            CartIssue(label: storeIssueLabel(l10n, issue)),
          if (store.longDistance)
            CartIssue(label: l10n.cartLongDistance, blocking: false),
          for (final (i, line) in store.lines.indexed) ...[
            if (i > 0)
              Divider(height: 1, color: c.hairline)
            else
              const SizedBox(height: DymTokenSpace.s1),
            _Line(vm: vm, line: line, locale: locale),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const new({required this.vm, required this.line, required this.locale});

  final CartViewModel vm;
  final CartLine line;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final unit = [
      ?line.variantLabel,
      ?line.unitLabel?.resolve(locale),
    ].join(' · ');
    final amount = vm.money(line.amountMinor);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProductThumb(
                image: switch (line.photoKey) {
                  final key? => vm.service.photo(key),
                  null => null,
                },
              ),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (unit.isNotEmpty)
                      Text(
                        unit,
                        style: t.label.copyWith(
                          color: c.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    if (line.haggled || line.groupPriced)
                      Row(
                        children: [
                          Icon(
                            line.groupPriced
                                ? Icons.groups_outlined
                                : Icons.handshake_outlined,
                            size: 16,
                            color: c.brand,
                          ),
                          const SizedBox(width: DymTokenSpace.s1),
                          Flexible(
                            child: Text(
                              line.groupPriced
                                  ? l10n.groupBuyCartBadge
                                  : l10n.haggleCartBadge,
                              style: t.label.copyWith(color: c.brandDeep),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: DymTokenSpace.s1),
                    Row(
                      children: [
                        DymQuantityStepper(
                          quantity: line.quantity,
                          dense: true,
                          max: line.stockQuantity ?? 99,
                          decreaseLabel: l10n.productStockDecrease,
                          increaseLabel: l10n.productStockIncrease,
                          onChanged: (q) => vm.setQuantity(line.variantId, q),
                        ),
                        const Spacer(),
                        if (amount != null)
                          MoneyText(amount, size: 15, color: c.textPrimary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          for (final issue in line.issues)
            CartIssue(
              label: lineIssueLabel(l10n, line, issue),
              blocking: issue != CartLineIssue.priceChanged,
            ),
        ],
      ),
    );
  }
}
