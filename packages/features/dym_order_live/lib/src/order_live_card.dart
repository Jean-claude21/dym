import 'dart:async';

import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_map/dym_map.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_order_live/src/order_live.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Carte de la livraison en direct (spec 109), la même pour la cliente, la
/// vendeuse et le livreur : boutique, porte, livreur, itinéraire tracé,
/// étape en clair et minutes restantes ; [actions] sous la carte (fil de
/// commande, partage du suivi…).
class OrderLiveCard extends StackedView<OrderLiveViewModel> {
  const new({
    required this.service,
    required this.orderId,
    super.key,
    this.actions = const [],
    this.height = 240,
  });

  final OrderLiveService service;
  final String orderId;
  final List<Widget> actions;
  final double height;

  static Map<String, DymPinStyle> styles(DymColors c) => {
    'store': DymPinStyle(
      icon: Icons.storefront_rounded,
      background: c.originBoutiqueBg,
      foreground: c.originBoutiqueFg,
    ),
    'door': DymPinStyle(
      icon: Icons.home_rounded,
      background: c.tintVertTendre,
      foreground: c.brandDeep,
    ),
    'courier': DymPinStyle(
      icon: Icons.two_wheeler_rounded,
      background: c.plantain,
      foreground: c.textPrimary,
    ),
  };

  @override
  OrderLiveViewModel viewModelBuilder(BuildContext context) =>
      OrderLiveViewModel(service: service, orderId: orderId);

  @override
  void onViewModelReady(OrderLiveViewModel viewModel) =>
      unawaited(viewModel.start());

  @override
  Widget builder(BuildContext context, OrderLiveViewModel vm, Widget? child) {
    final live = vm.tracking;
    if (live == null) return const SizedBox.shrink();
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    DymLatLng? at(TrackPoint? p) =>
        p == null ? null : DymLatLng(p.latitude, p.longitude);
    final store = at(live.store);
    final door = at(live.destination);
    final courier = vm.phase == LivePhase.delivered
        ? null
        : at(live.courier?.position);
    final pins = [
      if (store != null) DymMapPin(id: 'store', point: store, style: 'store'),
      if (door != null) DymMapPin(id: 'door', point: door, style: 'door'),
      if (courier != null)
        DymMapPin(id: 'courier', point: courier, style: 'courier'),
    ];
    final route = vm.route;
    final routes = [
      if (route != null)
        DymMapRoute(
          id: 'route',
          points: [for (final p in route.points) ?at(p)],
          dashed: route.approximate,
        ),
    ];
    final bounds = DymBounds.around([
      for (final p in pins) p.point,
      for (final r in routes) ...r.points,
    ]);
    final eta = vm.etaMinutes;
    final (icon, label) = switch (vm.phase) {
      LivePhase.waiting => (Icons.hourglass_top_rounded, l10n.orderLiveWaiting),
      LivePhase.toStore => (Icons.storefront_rounded, l10n.orderLiveToStore),
      LivePhase.toDoor => (Icons.two_wheeler_rounded, l10n.orderLiveToDoor),
      LivePhase.delivered => (Icons.verified_rounded, l10n.orderLiveDelivered),
    };
    final name = live.courier?.name;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        border: Border.all(color: c.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DymTokenSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: c.brand),
                const SizedBox(width: DymTokenSpace.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: t.title),
                      if (name != null && name.isNotEmpty)
                        Text(
                          name,
                          style: t.label.copyWith(color: c.textSecondary),
                        ),
                    ],
                  ),
                ),
                if (eta != null && eta > 0)
                  Text(
                    l10n.orderLiveEta(eta),
                    style: t.title.copyWith(color: c.brand),
                  ),
              ],
            ),
            if (pins.isNotEmpty) ...[
              const SizedBox(height: DymTokenSpace.s2),
              ClipRRect(
                borderRadius: BorderRadius.circular(DymTokenRadius.card),
                child: SizedBox(
                  height: height,
                  child: DymMap(
                    initialCenter: courier ?? store ?? door!,
                    initialZoom: 14,
                    pins: pins,
                    pinStyles: styles(c),
                    routes: routes,
                    semanticLabel: l10n.orderLiveTitle,
                    onReady: (controls) {
                      if (bounds != null && pins.length > 1) {
                        unawaited(controls.fit(bounds));
                      }
                    },
                  ),
                ),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: DymTokenSpace.s2),
              ...actions,
            ],
          ],
        ),
      ),
    );
  }
}
