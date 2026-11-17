import 'dart:async';

import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Achats groupés de la cliente (spec 051) : remplaçable en test.
abstract interface class GroupBuyService {
  Future<Result<CountryConfig>> countryConfig();

  /// Offres des boutiques qui livrent son quartier, et ses groupes actifs.
  Future<Result<List<GroupOffer>>> near();

  Future<Result<GroupOffer>> join(GroupOffer offer, int quantity);
}

class NeonGroupBuyService implements GroupBuyService {
  new({required this._repository, required this._discovery});

  final GroupBuyRepository _repository;
  final DiscoveryService _discovery;

  @override
  Future<Result<CountryConfig>> countryConfig() => _discovery.countryConfig();

  @override
  Future<Result<List<GroupOffer>>> near() =>
      _repository.near(zoneId: _discovery.zone.value);

  @override
  Future<Result<GroupOffer>> join(GroupOffer offer, int quantity) =>
      _repository.join(offer.id, quantity);
}

String groupBuyProblem(DymLocalizations l10n, String code) => switch (code) {
  'offer_closed' => l10n.groupBuyClosed,
  'group_locked' => l10n.groupBuyLocked,
  'invalid_quantity' => l10n.walletErrorAmount,
  'offline' => l10n.errorOffline,
  _ => l10n.errorGeneric,
};

class GroupBuysViewModel extends BaseViewModel {
  new({required this.service});

  final GroupBuyService service;
  CountryConfig? config;
  List<GroupOffer>? offers;
  Failure? failure;
  String? problem;

  Future<void> load() async {
    failure = null;
    config ??= (await service.countryConfig()).valueOrNull;
    switch (await service.near()) {
      case Ok(:final value):
        offers = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  String money(int minor) => config?.money(minor).format() ?? '';

  Future<bool> join(GroupOffer offer, String text) async {
    problem = null;
    final quantity = int.tryParse(text.trim());
    if (quantity == null || quantity < 0 || quantity > 99) {
      problem = 'invalid_quantity';
      notifyListeners();
      return false;
    }
    final result = await service.join(offer, quantity);
    if (result case Err(failure: final f)) {
      problem = f is NetworkFailure ? 'offline' : f.message;
      notifyListeners();
      return false;
    }
    await load();
    return true;
  }
}

/// « Achats groupés » : prix de groupe et livraison partagée entre voisins.
class GroupBuysView extends StackedView<GroupBuysViewModel> {
  const new({
    required this.service,
    required this.onBack,
    super.key,
    this.onDiscuss,
  });

  final GroupBuyService service;
  final VoidCallback onBack;

  /// Fil du groupe (spec 112) ; nul : pas de discussion.
  final ValueChanged<String>? onDiscuss;

  @override
  GroupBuysViewModel viewModelBuilder(BuildContext context) =>
      GroupBuysViewModel(service: service);

  @override
  void onViewModelReady(GroupBuysViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, GroupBuysViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final offers = vm.offers;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(l10n.groupBuyTitle),
        leading: IconButton(
          tooltip: l10n.authBack,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: offers == null
            ? Center(
                child: vm.failure == null
                    ? const CircularProgressIndicator()
                    : TextButton(onPressed: vm.load, child: Text(l10n.retry)),
              )
            : RefreshIndicator(
                onRefresh: vm.load,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    DymLayout.gutter(context),
                    DymTokenSpace.s2,
                    DymLayout.gutter(context),
                    DymTokenSpace.s6,
                  ),
                  children: [
                    DymContentWidth(child: Text(l10n.groupBuyHint)),
                    if (vm.problem case final p?)
                      DymContentWidth(
                        child: Text(
                          groupBuyProblem(l10n, p),
                          style: t.body.copyWith(color: c.pimentStrong),
                        ),
                      ),
                    const SizedBox(height: DymTokenSpace.s3),
                    if (offers.isEmpty)
                      DymContentWidth(
                        child: Text(
                          l10n.groupBuyEmpty,
                          style: t.body.copyWith(color: c.textSecondary),
                        ),
                      ),
                    for (final o in offers)
                      DymContentWidth(
                        child: GroupOfferCard(
                          vm: vm,
                          offer: o,
                          onDiscuss: onDiscuss,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class GroupOfferCard extends StatelessWidget {
  const new({required this.vm, required this.offer, super.key, this.onDiscuss});

  final GroupBuysViewModel vm;
  final GroupOffer offer;
  final ValueChanged<String>? onDiscuss;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final date = MaterialLocalizations.of(context)
        .formatShortDate(offer.closesAt.toLocal());
    return Card(
      margin: const EdgeInsets.only(bottom: DymTokenSpace.s3),
      child: Padding(
        padding: const EdgeInsets.all(DymTokenSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(offer.productName, style: t.title),
            Text(
              offer.storeName,
              style: t.label.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: DymTokenSpace.s1),
            Text(
              l10n.groupBuyPrice(
                vm.money(offer.groupPriceMinor),
                vm.money(offer.priceMinor),
              ),
              style: t.title.copyWith(color: c.brandDeep),
            ),
            if (offer.memberDeliveryFeeMinor case final fee?)
              Text(l10n.groupBuySharedDelivery(vm.money(fee))),
            const SizedBox(height: DymTokenSpace.s2),
            // Jauge déjà dite en texte.
            ExcludeSemantics(
              child: LinearProgressIndicator(
                value: offer.progress,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: DymTokenSpace.s1),
            Text(
              l10n.groupBuyProgress(
                offer.committed,
                offer.minQuantity,
                offer.members,
              ),
            ),
            Text(
              offer.reached ? l10n.groupBuyUnlocked : l10n.groupBuyUntil(date),
              style: t.label.copyWith(
                color: offer.reached ? c.brandDeep : c.textSecondary,
              ),
            ),
            if (offer.myQuantity case final q?)
              Text(l10n.groupBuyMine(q), style: t.body),
            if (onDiscuss case final discuss? when offer.joined)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => discuss(offer.id),
                  icon: const Icon(Icons.forum_rounded),
                  label: Text(l10n.chatGroupDiscuss),
                ),
              ),
            if (offer.canOrder && CartScope.maybeOf(context) != null) ...[
              const SizedBox(height: DymTokenSpace.s2),
              DymButton(
                label: l10n.groupBuyAddToCart,
                icon: Icons.add_shopping_cart_rounded,
                onPressed: () => addToCart(
                  context,
                  offer.variantId,
                  quantity: offer.myQuantity!,
                  confirm: true,
                ),
              ),
            ],
            if (offer.open && !offer.ordered) ...[
              const SizedBox(height: DymTokenSpace.s3),
              DymButton(
                label: offer.joined ? l10n.groupBuyChange : l10n.groupBuyJoin,
                icon: Icons.group_add_rounded,
                variant: offer.canOrder
                    ? DymButtonVariant.secondary
                    : DymButtonVariant.primary,
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => _JoinSheet(vm: vm, offer: offer),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JoinSheet extends StatefulWidget {
  const new({required this.vm, required this.offer});

  final GroupBuysViewModel vm;
  final GroupOffer offer;

  @override
  State<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<_JoinSheet> {
  late final _quantity = TextEditingController(
    text: '${widget.offer.myQuantity ?? ''}',
  );
  bool _busy = false;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          DymTokenSpace.s4,
          0,
          DymTokenSpace.s4,
          DymTokenSpace.s4 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.offer.productName, style: context.dym.text.title),
            const SizedBox(height: DymTokenSpace.s2),
            Text(
              widget.offer.reached
                  ? l10n.groupBuyLockedHint
                  : l10n.groupBuyQuantityHint,
            ),
            const SizedBox(height: DymTokenSpace.s3),
            DymTextField(
              label: l10n.groupBuyQuantity,
              controller: _quantity,
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: DymTokenSpace.s4),
            DymButton(
              label: l10n.groupBuyJoin,
              loading: _busy,
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      final ok = await widget.vm.join(
                        widget.offer,
                        _quantity.text,
                      );
                      if (!context.mounted) return;
                      setState(() => _busy = false);
                      if (ok) Navigator.pop(context);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
