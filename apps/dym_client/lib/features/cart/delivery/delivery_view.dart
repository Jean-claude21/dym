import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/cart/cart_viewmodels.dart';
import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Écran 34 : livraison (adresse, livraison ou retrait par boutique,
/// remplacement). Enregistre `checkout_started` à l'ouverture.
class DeliveryView extends StackedView<DeliveryViewModel> {
  const new({
    required this.service,
    required this.onBack,
    required this.onAddAddress,
    super.key,
  });

  final CartService service;
  final VoidCallback onBack;

  /// Écran 36 ; `true` si une adresse a été enregistrée.
  final Future<bool> Function() onAddAddress;

  @override
  DeliveryViewModel viewModelBuilder(BuildContext context) =>
      DeliveryViewModel(service: service);

  @override
  void onViewModelReady(DeliveryViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    DeliveryViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final vm = viewModel;
    final cart = vm.cart;
    final header = CartHeader(
      title: l10n.deliveryTitle,
      subtitle: l10n.cartSummary(cart.storeCount, cart.itemCount),
      onBack: onBack,
    );
    if (!vm.ready) {
      return Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Column(
            children: [
              header,
              Expanded(
                child: DiscoveryState(
                  failure: vm.isBusy ? null : vm.failure,
                  onRetry: vm.load,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Future<void> addAddress() async {
      if (await onAddAddress()) await vm.reloadAddresses();
    }

    final children = <Widget>[
      Text(l10n.deliveryWhere, style: t.title.copyWith(fontSize: 20)),
      const SizedBox(height: DymTokenSpace.s2),
      if (vm.addresses.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
          child: Text(
            l10n.deliveryNoAddress,
            style: t.label.copyWith(color: c.textSecondary, fontSize: 15),
          ),
        ),
      for (final a in vm.addresses) ...[
        _AddressChoice(
          address: a,
          selected: a.id == vm.addressId,
          onTap: () => vm.selectAddress(a.id),
        ),
        const SizedBox(height: DymTokenSpace.s2),
      ],
      CartCard(
        child: InkWell(
          onTap: addAddress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Icon(Icons.add_rounded, color: c.brand),
                const SizedBox(width: DymTokenSpace.s3),
                Expanded(
                  child: Text(
                    l10n.deliveryAddAddress,
                    style: t.title.copyWith(fontSize: 17, color: c.brandDeep),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: DymTokenSpace.s5),
      Text(l10n.deliveryModes, style: t.title.copyWith(fontSize: 20)),
      const SizedBox(height: DymTokenSpace.s2),
      for (final store in cart.stores) ...[
        _StoreMode(
          store: store,
          originText: originLabel(vm.config, store.origin, locale),
          onMode: (mode) => vm.setMode(store.id, mode),
        ),
        const SizedBox(height: DymTokenSpace.s2),
      ],
      Text(
        l10n.cartDeliveryMeta(cart.pickupCount, cart.deliveryMinutes),
        style: t.label.copyWith(color: c.textSecondary),
      ),
      const SizedBox(height: DymTokenSpace.s4),
      DymSwitchTile(
        title: l10n.cartSubstitutionTitle,
        subtitle: l10n.cartSubstitutionSubtitle,
        value: vm.substitutionAllowed,
        onChanged: (v) => vm.setSubstitution(allowed: v),
      ),
      const SizedBox(height: DymTokenSpace.s3),
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

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            header,
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
                child: DymButton(
                  label: l10n.deliveryConfirm,
                  onPressed: onBack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressChoice extends StatelessWidget {
  const new({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final CustomerAddress address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final title = addressTitle(l10n, address.kind, address.label);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          side: BorderSide(color: c.hairline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          child: Container(
            padding: const EdgeInsets.all(DymTokenSpace.s3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DymTokenRadius.tile),
              border: Border.all(
                color: selected ? c.brand : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(addressIcon(address.kind), color: c.brand, size: 28),
                const SizedBox(width: DymTokenSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: t.title.copyWith(fontSize: 17)),
                      Text(
                        '${address.zoneName}, ${address.cityName}',
                        style: t.label.copyWith(color: c.textSecondary),
                      ),
                      Text(
                        address.landmark,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.label.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? c.brand : c.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreMode extends StatelessWidget {
  const new({
    required this.store,
    required this.originText,
    required this.onMode,
  });

  final CartStoreGroup store;
  final String originText;
  final ValueChanged<Fulfillment> onMode;

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final origin = originOf(store.origin);
    return CartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DymAvatar(
                image: storeFallback(store.origin),
                size: 44,
                ring: false,
              ),
              const SizedBox(width: DymTokenSpace.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name, style: t.title.copyWith(fontSize: 17)),
                    if (origin != null)
                      DymOriginBadge(origin: origin, label: originText),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s2),
          Wrap(
            spacing: DymTokenSpace.s2,
            runSpacing: DymTokenSpace.s2,
            children: [
              DymFilterChip(
                label: l10n.deliveryModeDelivery,
                icon: Icons.two_wheeler_rounded,
                selected: store.fulfillment == Fulfillment.delivery,
                onTap: () => onMode(Fulfillment.delivery),
              ),
              if (store.offersPickup)
                DymFilterChip(
                  label: l10n.deliveryModePickup,
                  icon: Icons.shopping_bag_outlined,
                  selected: store.fulfillment == Fulfillment.pickup,
                  onTap: () => onMode(Fulfillment.pickup),
                ),
            ],
          ),
          for (final issue in store.issues)
            CartIssue(label: storeIssueLabel(l10n, issue)),
        ],
      ),
    );
  }
}
