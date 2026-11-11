import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/cart/cart_viewmodels.dart';
import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Écran 35 : mes adresses (par défaut, modifier, supprimer, ajouter).
class AddressesView extends StackedView<AddressesViewModel> {
  const new({
    required this.service,
    required this.onBack,
    required this.onEdit,
    super.key,
  });

  final CartService service;
  final VoidCallback onBack;

  /// Écran 36 (nulle : nouvelle adresse) ; `true` si enregistrée.
  final Future<bool> Function(CustomerAddress? address) onEdit;

  @override
  AddressesViewModel viewModelBuilder(BuildContext context) =>
      AddressesViewModel(service: service);

  @override
  void onViewModelReady(AddressesViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    AddressesViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;

    Future<void> edit(CustomerAddress? address) async {
      if (await onEdit(address)) await vm.load();
    }

    Widget body;
    if (!vm.ready) {
      body = DiscoveryState(
        failure: vm.isBusy ? null : vm.failure,
        onRetry: vm.load,
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          if (vm.addresses.isEmpty)
            DymContentWidth.form(
              child: DymStateView(
                kind: DymStateKind.empty,
                title: l10n.addressesEmptyTitle,
                message: l10n.addressesEmptyMessage,
              ),
            ),
          for (final a in vm.addresses)
            DymContentWidth.form(
              child: Padding(
                padding: const EdgeInsets.only(bottom: DymTokenSpace.s3),
                child: _AddressCard(
                  address: a,
                  onEdit: () => edit(a),
                  onSetDefault: () => vm.setDefault(a.id),
                  onDelete: () => vm.delete(a.id),
                ),
              ),
            ),
          if (vm.actionFailure != null)
            DymContentWidth.form(child: CartIssue(label: l10n.errorGeneric)),
          DymContentWidth.form(
            child: DymButton(
              label: l10n.deliveryAddAddress,
              icon: Icons.add_rounded,
              variant: DymButtonVariant.secondary,
              onPressed: () => edit(null),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(title: l10n.addressesTitle, onBack: onBack),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

enum _Action { edit, setDefault, delete }

class _AddressCard extends StatelessWidget {
  const new({
    required this.address,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  final CustomerAddress address;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return CartCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(addressIcon(address.kind), color: c.brandDeep, size: 32),
          const SizedBox(width: DymTokenSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: DymTokenSpace.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      addressTitle(l10n, address.kind, address.label),
                      style: t.title.copyWith(fontSize: 19),
                    ),
                    if (address.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DymTokenSpace.s2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.brand,
                          borderRadius: BorderRadius.circular(
                            DymTokenRadius.chip,
                          ),
                        ),
                        child: Text(
                          l10n.addressDefault,
                          style: t.label.copyWith(
                            color: c.onBrand,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  '${address.zoneName}, ${address.cityName}',
                  style: t.label.copyWith(color: c.textSecondary, fontSize: 15),
                ),
                Text(
                  address.landmark,
                  style: t.label.copyWith(color: c.textSecondary, fontSize: 15),
                ),
                Text(
                  address.phone,
                  style: t.label.copyWith(color: c.textSecondary, fontSize: 15),
                ),
                if (address.hasPosition)
                  Padding(
                    padding: const EdgeInsets.only(top: DymTokenSpace.s1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.my_location_rounded,
                          size: 18,
                          color: c.brand,
                        ),
                        const SizedBox(width: DymTokenSpace.s1),
                        Flexible(
                          child: Text(
                            l10n.addressPositionSaved,
                            style: t.label.copyWith(
                              color: c.brandDeep,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<_Action>(
            tooltip: l10n.addressMenu,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) => switch (action) {
              _Action.edit => onEdit(),
              _Action.setDefault => onSetDefault(),
              _Action.delete => onDelete(),
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: _Action.edit, child: Text(l10n.addressEdit)),
              if (!address.isDefault)
                PopupMenuItem(
                  value: _Action.setDefault,
                  child: Text(l10n.addressSetDefault),
                ),
              PopupMenuItem(
                value: _Action.delete,
                child: Text(
                  l10n.addressDelete,
                  style: TextStyle(color: c.pimentStrong),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
