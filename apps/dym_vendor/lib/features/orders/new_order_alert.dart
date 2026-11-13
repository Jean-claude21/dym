import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart' show VendorOrderScope;
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/orders/orders_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Guette les nouvelles commandes, quel que soit l'onglet ouvert (spec 075) :
/// temps réel d'abord, relecture toutes les [refreshEvery] en filet.
class NewOrderWatcher extends ChangeNotifier {
  new({
    required this.service,
    this.refreshEvery = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  final OrdersService service;
  final Duration refreshEvery;
  final DateTime Function() clock;

  List<VendorOrder> _pending = const [];
  final _seen = <String>{};
  VendorOrder? _alert;
  Timer? _timer;
  StreamSubscription<LiveSignal>? _live;
  bool _disposed = false;

  /// Commandes en attente de réponse, la plus ancienne d'abord.
  List<VendorOrder> get pending => _pending;

  /// Commande à annoncer (nulle : rien de nouveau).
  VendorOrder? get alert => _alert;

  /// Autres commandes en attente que celle annoncée.
  int get othersWaiting => _pending.where((o) => o.id != _alert?.id).length;

  Future<void> start() async {
    await check();
    _timer ??= Timer.periodic(refreshEvery, (_) => unawaited(check()));
    _live ??= watchLive(
      service.live,
      when: (s) => s.kind == 'order_status' || s.kind == 'notification',
      reload: () => unawaited(check()),
    );
  }

  /// Relit les commandes nouvelles ; la première jamais vue est annoncée.
  Future<void> check() async {
    final result = await service.orders(scope: VendorOrderScope.newOrders);
    if (_disposed) return;
    final orders = result.valueOrNull;
    if (orders == null) return;
    _pending = [...orders]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final fresh = _pending.where((o) => !_seen.contains(o.id)).toList();
    // Annoncée mais déjà traitée ailleurs (acceptée, refusée) : on retire.
    if (_alert case final a? when !_pending.any((o) => o.id == a.id)) {
      _alert = null;
    }
    if (fresh.isNotEmpty && _alert == null) _alert = fresh.last;
    notifyListeners();
  }

  /// La vendeuse a vu l'alerte (ouverte ou « plus tard »).
  void acknowledge() {
    final a = _alert;
    if (a == null) return;
    _seen.addAll(_pending.map((o) => o.id));
    _alert = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_live?.cancel());
    super.dispose();
  }
}

/// Affiche l'alerte plein écran au-dessus de l'app quand [watcher] annonce
/// une commande ; son et vibration répétés jusqu'à la réponse.
class NewOrderAlertHost extends StatefulWidget {
  const new({
    required this.watcher,
    required this.onOpen,
    required this.child,
    required this.money,
    super.key,
  });

  final NewOrderWatcher watcher;
  final ValueChanged<String> onOpen;
  final String? Function(VendorOrder order) money;
  final Widget child;

  @override
  State<NewOrderAlertHost> createState() => _NewOrderAlertHostState();
}

class _NewOrderAlertHostState extends State<NewOrderAlertHost> {
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    widget.watcher.addListener(_changed);
  }

  @override
  void dispose() {
    widget.watcher.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final order = widget.watcher.alert;
    if (order == null || _showing || !mounted) return;
    _showing = true;
    unawaited(_show(order));
  }

  Future<void> _show(VendorOrder order) async {
    final open = await showGeneralDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      pageBuilder: (context, _, _) => NewOrderAlert(
        order: order,
        amount: widget.money(order),
        othersWaiting: widget.watcher.othersWaiting,
        clock: widget.watcher.clock,
      ),
    );
    widget.watcher.acknowledge();
    _showing = false;
    if (open ?? false) widget.onOpen(order.id);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Alerte plein écran d'une nouvelle commande : qui, combien, avant quelle
/// heure répondre ; « Voir la commande » ou « Plus tard ».
class NewOrderAlert extends StatefulWidget {
  const new({
    required this.order,
    required this.amount,
    required this.othersWaiting,
    required this.clock,
    super.key,
    this.ring = true,
  });

  final VendorOrder order;
  final String? amount;
  final int othersWaiting;
  final DateTime Function() clock;

  /// Son et vibration répétés (coupés en test).
  final bool ring;

  @override
  State<NewOrderAlert> createState() => _NewOrderAlertState();
}

class _NewOrderAlertState extends State<NewOrderAlert> {
  Timer? _ring;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    if (widget.ring) {
      _alarm();
      _ring = Timer.periodic(const Duration(seconds: 8), (_) => _alarm());
    }
    // Compte à rebours relu chaque minute.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  void _alarm() {
    unawaited(SystemSound.play(SystemSoundType.alert));
    unawaited(HapticFeedback.heavyImpact());
  }

  @override
  void dispose() {
    _ring?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final o = widget.order;
    final now = widget.clock();
    final left = o.minutesToRespond(now);
    final urgent = left != null && left <= 5;
    final mode = o.fulfillment == Fulfillment.delivery
        ? l10n.deliveryModeDelivery
        : l10n.deliveryModePickup;
    final by = o.respondBy;
    return Material(
      color: c.brandDeep,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DymTokenSpace.s4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: c.onBrand.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        size: 52,
                        color: c.plantain,
                      ),
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  Semantics(
                    liveRegion: true,
                    header: true,
                    child: Text(
                      l10n.vendorAlertTitle,
                      textAlign: TextAlign.center,
                      style: t.display.copyWith(fontSize: 34, color: c.onBrand),
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s2),
                  Text(
                    [
                      o.customerFirstName ?? '…',
                      l10n.orderItems(o.itemCount),
                      mode,
                    ].join(' · '),
                    textAlign: TextAlign.center,
                    style: t.body.copyWith(color: c.onBrand),
                  ),
                  if (widget.amount case final a?) ...[
                    const SizedBox(height: DymTokenSpace.s2),
                    Text(
                      a,
                      textAlign: TextAlign.center,
                      style: t.display.copyWith(
                        fontSize: 40,
                        color: c.plantain,
                      ),
                    ),
                  ],
                  if (by != null) ...[
                    const SizedBox(height: DymTokenSpace.s3),
                    Container(
                      padding: const EdgeInsets.all(DymTokenSpace.s3),
                      decoration: BoxDecoration(
                        color: urgent ? c.tintPimentClair : c.card,
                        borderRadius: BorderRadius.circular(
                          DymTokenRadius.tile,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: urgent ? c.pimentStrong : c.brandDeep,
                          ),
                          const SizedBox(width: DymTokenSpace.s2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.vendorRespondBefore(
                                    TimeOfDay.fromDateTime(by.toLocal())
                                        .format(context),
                                  ),
                                  style: t.title.copyWith(
                                    fontSize: 18,
                                    color: urgent
                                        ? c.pimentStrong
                                        : c.textPrimary,
                                  ),
                                ),
                                if (left != null)
                                  Text(
                                    l10n.vendorMinutesLeft(left),
                                    style: t.label.copyWith(
                                      color: urgent
                                          ? c.pimentStrong
                                          : c.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (widget.othersWaiting > 0) ...[
                    const SizedBox(height: DymTokenSpace.s2),
                    Text(
                      l10n.vendorAlertMore(widget.othersWaiting),
                      textAlign: TextAlign.center,
                      style: t.label.copyWith(color: c.onBrand),
                    ),
                  ],
                  const SizedBox(height: DymTokenSpace.s4),
                  DymButton(
                    label: l10n.vendorAlertOpen,
                    icon: Icons.receipt_long_rounded,
                    variant: DymButtonVariant.plantain,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                  const SizedBox(height: DymTokenSpace.s2),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: c.onBrand,
                      minimumSize: const Size.fromHeight(DymTokenSize.touchMin),
                    ),
                    child: Text(l10n.vendorAlertLater),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
