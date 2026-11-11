import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Offres groupées de la vendeuse (spec 051) : remplaçable en test.
abstract interface class GroupOffersService {
  Future<Result<CountryConfig>> countryConfig();

  Future<Result<List<GroupOffer>>> mine();

  /// Produits publiés de la boutique.
  Future<Result<List<Product>>> products();

  Future<Result<GroupOffer>> create({
    required String productId,
    required int groupPriceMinor,
    required int minQuantity,
    int days,
    int? memberDeliveryFeeMinor,
  });

  Future<Result<GroupOffer>> cancel(GroupOffer offer);
}

class NeonGroupOffersService implements GroupOffersService {
  new({
    required this._repository,
    required this._config,
    required this._products,
  });

  final GroupBuyRepository _repository;
  final Future<Result<CountryConfig>> Function() _config;
  final Future<Result<List<Product>>> Function() _products;

  @override
  Future<Result<CountryConfig>> countryConfig() => _config();

  @override
  Future<Result<List<GroupOffer>>> mine() => _repository.mine();

  @override
  Future<Result<List<Product>>> products() => _products();

  @override
  Future<Result<GroupOffer>> create({
    required String productId,
    required int groupPriceMinor,
    required int minQuantity,
    int days = 3,
    int? memberDeliveryFeeMinor,
  }) => _repository.create(
    productId: productId,
    groupPriceMinor: groupPriceMinor,
    minQuantity: minQuantity,
    days: days,
    memberDeliveryFeeMinor: memberDeliveryFeeMinor,
  );

  @override
  Future<Result<GroupOffer>> cancel(GroupOffer offer) =>
      _repository.cancel(offer.id);
}

class GroupOffersViewModel extends BaseViewModel {
  new({required this.service});

  final GroupOffersService service;
  CountryConfig? config;
  List<GroupOffer>? offers;
  Failure? failure;
  String? problem;

  Future<void> load() async {
    failure = null;
    config ??= (await service.countryConfig()).valueOrNull;
    switch (await service.mine()) {
      case Ok(:final value):
        offers = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  String money(int minor) => config?.money(minor).format() ?? '';

  Future<bool> _run<T>(Future<Result<T>> work) async {
    problem = null;
    final result = await work;
    if (result case Err(failure: final f)) {
      problem = f is NetworkFailure ? 'offline' : f.message;
      notifyListeners();
      return false;
    }
    await load();
    return true;
  }

  Future<bool> cancel(GroupOffer offer) => _run(service.cancel(offer));

  Future<bool> create({
    required Product product,
    required String priceText,
    required String minText,
    required int days,
    String feeText = '',
  }) {
    final currency = config?.currency;
    final price = currency == null
        ? null
        : Money.parseMajor(priceText, currency);
    final min = int.tryParse(minText.trim());
    final fee = feeText.trim().isEmpty || currency == null
        ? null
        : Money.parseMajor(feeText, currency);
    if (price == null ||
        price <= 0 ||
        min == null ||
        min < 2 ||
        (feeText.trim().isNotEmpty && fee == null)) {
      problem = 'invalid_amount';
      notifyListeners();
      return Future.value(false);
    }
    return _run(
      service.create(
        productId: product.id,
        groupPriceMinor: price,
        minQuantity: min,
        days: days,
        memberDeliveryFeeMinor: fee,
      ),
    );
  }
}

String _problem(DymLocalizations l10n, String code) => switch (code) {
  'invalid_amount' || 'invalid_quantity' => l10n.groupOfferInvalid,
  'offer_closed' => l10n.groupBuyClosed,
  'offline' => l10n.errorOffline,
  _ => l10n.errorGeneric,
};

class GroupOffersView extends StackedView<GroupOffersViewModel> {
  const new({required this.service, required this.onBack, super.key});

  final GroupOffersService service;
  final VoidCallback onBack;

  @override
  GroupOffersViewModel viewModelBuilder(BuildContext context) =>
      GroupOffersViewModel(service: service);

  @override
  void onViewModelReady(GroupOffersViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, GroupOffersViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final offers = vm.offers;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(l10n.groupOfferTitle),
        leading: IconButton(
          tooltip: l10n.authBack,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _NewGroupOffer(vm: vm),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.groupOfferNew),
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
                    96,
                  ),
                  children: [
                    DymContentWidth(child: Text(l10n.groupOfferHint)),
                    if (vm.problem case final p?)
                      DymContentWidth(
                        child: Text(
                          _problem(l10n, p),
                          style: t.body.copyWith(color: c.pimentStrong),
                        ),
                      ),
                    const SizedBox(height: DymTokenSpace.s3),
                    if (offers.isEmpty)
                      DymContentWidth(
                        child: Text(
                          l10n.groupOfferEmpty,
                          style: t.body.copyWith(color: c.textSecondary),
                        ),
                      ),
                    for (final o in offers)
                      DymContentWidth(
                        child: Card(
                          margin: const EdgeInsets.only(
                            bottom: DymTokenSpace.s3,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(DymTokenSpace.s3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(o.productName, style: t.title),
                                Text(
                                  l10n.groupBuyPrice(
                                    vm.money(o.groupPriceMinor),
                                    vm.money(o.priceMinor),
                                  ),
                                ),
                                if (o.memberDeliveryFeeMinor case final fee?)
                                  Text(
                                    l10n.groupBuySharedDelivery(vm.money(fee)),
                                  ),
                                const SizedBox(height: DymTokenSpace.s2),
                                // Jauge déjà dite en texte.
                                ExcludeSemantics(
                                  child: LinearProgressIndicator(
                                    value: o.progress,
                                    minHeight: 8,
                                  ),
                                ),
                                Text(
                                  l10n.groupBuyProgress(
                                    o.committed,
                                    o.minQuantity,
                                    o.members,
                                  ),
                                ),
                                Text(switch (o.status) {
                                  'cancelled' => l10n.groupOfferCancelled,
                                  'closed' => l10n.groupBuyClosed,
                                  _ when o.reached => l10n.groupBuyUnlocked,
                                  _ => l10n.groupBuyUntil(
                                    MaterialLocalizations.of(context)
                                        .formatShortDate(o.closesAt.toLocal()),
                                  ),
                                }, style: t.label),
                                if (o.open)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => vm.cancel(o),
                                      child: Text(l10n.groupOfferCancel),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _NewGroupOffer extends StatefulWidget {
  const new({required this.vm});

  final GroupOffersViewModel vm;

  @override
  State<_NewGroupOffer> createState() => _NewGroupOfferState();
}

class _NewGroupOfferState extends State<_NewGroupOffer> {
  final _price = TextEditingController();
  final _min = TextEditingController();
  final _fee = TextEditingController();
  List<Product> _products = const [];
  Product? _product;
  int _days = 3;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.vm.service.products().then((r) {
        if (mounted) setState(() => _products = r.valueOrNull ?? const []);
      }),
    );
  }

  @override
  void dispose() {
    _price.dispose();
    _min.dispose();
    _fee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final product = _product;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          DymTokenSpace.s4,
          0,
          DymTokenSpace.s4,
          DymTokenSpace.s4 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.groupOfferNew, style: context.dym.text.title),
              const SizedBox(height: DymTokenSpace.s3),
              Wrap(
                spacing: DymTokenSpace.s2,
                runSpacing: DymTokenSpace.s1,
                children: [
                  for (final p in _products)
                    ChoiceChip(
                      label: Text(p.name),
                      selected: _product?.id == p.id,
                      onSelected: (_) => setState(() => _product = p),
                    ),
                ],
              ),
              const SizedBox(height: DymTokenSpace.s3),
              DymTextField(
                label: l10n.groupOfferPrice,
                controller: _price,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: DymTokenSpace.s3),
              DymTextField(
                label: l10n.groupOfferMin,
                controller: _min,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: DymTokenSpace.s3),
              DymTextField(
                label: l10n.groupOfferFee,
                controller: _fee,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: DymTokenSpace.s3),
              Wrap(
                spacing: DymTokenSpace.s2,
                children: [
                  for (final d in const [1, 3, 7])
                    ChoiceChip(
                      label: Text(l10n.wholesaleDays(d)),
                      selected: _days == d,
                      onSelected: (_) => setState(() => _days = d),
                    ),
                ],
              ),
              const SizedBox(height: DymTokenSpace.s3),
              DymButton(
                label: l10n.wholesalePublish,
                icon: Icons.groups_rounded,
                loading: _busy,
                onPressed: _busy || product == null
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        final ok = await widget.vm.create(
                          product: product,
                          priceText: _price.text,
                          minText: _min.text,
                          days: _days,
                          feeText: _fee.text,
                        );
                        if (!context.mounted) return;
                        setState(() => _busy = false);
                        if (ok) Navigator.pop(context);
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
