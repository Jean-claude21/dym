import 'dart:async';

import 'package:dym_client/features/orders/order_texts.dart';
import 'package:dym_client/features/orders/orders_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Bandeau « Commande en cours » (design « Épuré », PARCOURS §4.1) : la
/// commande active la plus récente, son statut et l'heure prévue ; un toucher
/// ouvre le suivi. Rien n'est affiché sans commande active ni en cas d'échec.
class ActiveOrderBanner extends StatefulWidget {
  const new({required this.service, required this.onOpen, super.key});

  final OrdersService service;
  final ValueChanged<String> onOpen;

  @override
  State<ActiveOrderBanner> createState() => _ActiveOrderBannerState();
}

class _ActiveOrderBannerState extends State<ActiveOrderBanner> {
  CustomerOrder? _order;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final result = await widget.service.orders();
    if (!mounted) return;
    if (result case Ok(:final value)) {
      final active = value.where((o) => o.status.isActive).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() => _order = active.firstOrNull);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    if (order == null) return const SizedBox.shrink();
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final start = order.scheduledStart;
    final eta = start ?? order.etaAt;
    final status = orderStatusLabel(
      l10n,
      order.status,
      fulfillment: order.fulfillment,
    );
    final meta = [
      order.store.name,
      status,
      if (eta != null) l10n.orderEtaAt(shortTime(context, eta)),
    ].join(' · ');
    final enRoute = order.status == OrderStatus.outForDelivery;
    return Semantics(
      button: true,
      container: true,
      label: '${l10n.homeActiveOrder}. $meta',
      excludeSemantics: true,
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DymTokenRadius.card),
          side: BorderSide(color: c.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => widget.onOpen(order.id),
          child: Padding(
            padding: const EdgeInsets.all(DymTokenSpace.s3),
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
                    enRoute
                        ? Icons.two_wheeler_rounded
                        : Icons.schedule_rounded,
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
                        l10n.homeActiveOrder,
                        style: t.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        meta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
