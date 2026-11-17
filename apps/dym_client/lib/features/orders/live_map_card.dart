import 'dart:async';

import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/content/share_content.dart';
import 'package:dym_client/features/orders/orders_viewmodels.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_map/dym_map.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Suivi en direct (spec 096) : boutique, porte et livreur sur la carte,
/// minutes restantes, partage du lien par n'importe quelle messagerie.
class LiveMapCard extends StatelessWidget {
  const new({required this.vm, super.key});

  final TrackingViewModel vm;

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
  Widget build(BuildContext context) {
    final live = vm.live;
    if (live == null || !vm.showMap) return const SizedBox.shrink();
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    DymLatLng? at(TrackPoint? p) =>
        p == null ? null : DymLatLng(p.latitude, p.longitude);
    final store = at(live.store);
    final door = at(live.destination);
    final courier = at(live.courier?.position);
    final pins = [
      if (store != null) DymMapPin(id: 'store', point: store, style: 'store'),
      if (door != null) DymMapPin(id: 'door', point: door, style: 'door'),
      if (courier != null)
        DymMapPin(id: 'courier', point: courier, style: 'courier'),
    ];
    final bounds = DymBounds.around([for (final p in pins) p.point]);
    final eta = live.etaMinutes;
    final name = live.courier?.name;
    return CartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, color: c.brand),
              const SizedBox(width: DymTokenSpace.s2),
              Expanded(
                child: Text(
                  courier == null
                      ? l10n.trackLiveWaiting
                      : (name == null || name.isEmpty
                            ? l10n.trackLiveTitle
                            : l10n.trackLiveCourier(name)),
                  style: t.title,
                ),
              ),
              if (eta != null && eta > 0)
                Text(
                  l10n.trackLiveEta(eta),
                  style: t.title.copyWith(color: c.brand),
                ),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(DymTokenRadius.card),
            child: SizedBox(
              height: 220,
              child: DymMap(
                initialCenter: courier ?? store ?? door!,
                initialZoom: 14,
                pins: pins,
                pinStyles: styles(c),
                semanticLabel: l10n.trackLiveTitle,
                onReady: (controls) {
                  if (bounds != null && pins.length > 1) {
                    unawaited(controls.fit(bounds));
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: DymTokenSpace.s1),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: vm.sharing ? null : () => _share(context),
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(l10n.trackShare),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context) => shareLiveTracking(context, vm);
}

/// WhatsApp s'ouvre avec le lien du suivi ; sinon le texte est copié, prêt à
/// coller dans n'importe quelle messagerie.
Future<void> shareLiveTracking(
  BuildContext context,
  TrackingViewModel vm,
) async {
  final l10n = DymLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final url = await vm.shareTracking();
  if (url == null) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    return;
  }
  if (!context.mounted) return;
  await shareTextOrCopy(context, l10n.trackShareText(url.toString()));
}
