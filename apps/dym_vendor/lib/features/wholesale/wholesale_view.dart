import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Achat de gros (spec 049) : remplaçable en test.
abstract interface class WholesaleService {
  Future<Result<CountryConfig>> countryConfig();

  Future<Result<WholesaleBoard>> board();

  Future<Result<WholesaleBoard>> setWholesaler({required bool on});

  /// Produits publiés de la boutique (offre de la grossiste).
  Future<Result<List<Product>>> products();

  Future<Result<WholesaleOffer>> create({
    required String productId,
    required int unitPriceMinor,
    required int minQuantity,
    int days,
    String? note,
  });

  Future<Result<WholesaleOffer>> commit(WholesaleOffer offer, int quantity);

  Future<Result<WholesaleOffer>> decide(
    WholesaleOffer offer, {
    required bool confirm,
  });
}

class NeonWholesaleService implements WholesaleService {
  new({
    required this._repository,
    required this._config,
    required this._products,
  });

  final WholesaleRepository _repository;
  final Future<Result<CountryConfig>> Function() _config;
  final Future<Result<List<Product>>> Function() _products;

  @override
  Future<Result<CountryConfig>> countryConfig() => _config();

  @override
  Future<Result<WholesaleBoard>> board() => _repository.board();

  @override
  Future<Result<WholesaleBoard>> setWholesaler({required bool on}) =>
      _repository.setWholesaler(on: on);

  @override
  Future<Result<List<Product>>> products() => _products();

  @override
  Future<Result<WholesaleOffer>> create({
    required String productId,
    required int unitPriceMinor,
    required int minQuantity,
    int days = 7,
    String? note,
  }) => _repository.create(
    productId: productId,
    unitPriceMinor: unitPriceMinor,
    minQuantity: minQuantity,
    days: days,
    note: note,
  );

  @override
  Future<Result<WholesaleOffer>> commit(WholesaleOffer offer, int quantity) =>
      _repository.commit(offer.id, quantity);

  @override
  Future<Result<WholesaleOffer>> decide(
    WholesaleOffer offer, {
    required bool confirm,
  }) => _repository.decide(offer.id, confirm: confirm);
}

String wholesaleProblem(DymLocalizations l10n, String code) => switch (code) {
  'minimum_not_reached' => l10n.wholesaleMinimumNotReached,
  'offer_closed' => l10n.wholesaleClosed,
  'invalid_amount' || 'invalid_quantity' => l10n.walletErrorAmount,
  'offline' => l10n.errorOffline,
  _ => l10n.errorGeneric,
};

class WholesaleViewModel extends BaseViewModel {
  new({required this.service});

  final WholesaleService service;
  CountryConfig? config;
  WholesaleBoard? board;
  Failure? failure;
  String? problem;

  Future<void> load() async {
    failure = null;
    config ??= (await service.countryConfig()).valueOrNull;
    switch (await service.board()) {
      case Ok(:final value):
        board = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  String money(int minor) => config?.money(minor).format() ?? '';

  String _code(Failure f) => f is NetworkFailure ? 'offline' : f.message;

  Future<bool> _run<T>(Future<Result<T>> work) async {
    problem = null;
    final result = await work;
    if (result case Err(failure: final f)) {
      problem = _code(f);
      notifyListeners();
      return false;
    }
    await load();
    return true;
  }

  Future<bool> becomeWholesaler() => _run(service.setWholesaler(on: true));

  Future<bool> commit(WholesaleOffer offer, String quantityText) {
    final quantity = int.tryParse(quantityText.trim());
    if (quantity == null || quantity < 0) {
      problem = 'invalid_quantity';
      notifyListeners();
      return Future.value(false);
    }
    return _run(service.commit(offer, quantity));
  }

  Future<bool> decide(WholesaleOffer offer, {required bool confirm}) =>
      _run(service.decide(offer, confirm: confirm));

  Future<bool> create({
    required Product product,
    required String priceText,
    required String minText,
    required int days,
    String? note,
  }) {
    final currency = config?.currency;
    final price = currency == null
        ? null
        : Money.parseMajor(priceText, currency);
    final min = int.tryParse(minText.trim());
    if (price == null || price <= 0 || min == null || min <= 0) {
      problem = 'invalid_amount';
      notifyListeners();
      return Future.value(false);
    }
    return _run(
      service.create(
        productId: product.id,
        unitPriceMinor: price,
        minQuantity: min,
        days: days,
        note: note,
      ),
    );
  }
}

class WholesaleView extends StackedView<WholesaleViewModel> {
  const new({required this.service, required this.onBack, super.key});

  final WholesaleService service;
  final VoidCallback onBack;

  @override
  WholesaleViewModel viewModelBuilder(BuildContext context) =>
      WholesaleViewModel(service: service);

  @override
  void onViewModelReady(WholesaleViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, WholesaleViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final board = vm.board;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(l10n.wholesaleTitle),
        leading: IconButton(
          tooltip: l10n.authBack,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      floatingActionButton: board?.isWholesaler ?? false
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => _NewOffer(vm: vm),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.wholesaleNewOffer),
            )
          : null,
      body: SafeArea(
        child: board == null
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
                    DymContentWidth(child: Text(l10n.wholesaleHint)),
                    if (vm.problem case final p?)
                      DymContentWidth(
                        child: Text(
                          wholesaleProblem(l10n, p),
                          style: t.body.copyWith(color: c.pimentStrong),
                        ),
                      ),
                    const SizedBox(height: DymTokenSpace.s3),
                    DymContentWidth(
                      child: DymSectionHeader(title: l10n.wholesaleOpen),
                    ),
                    if (board.open.isEmpty)
                      DymContentWidth(
                        child: Text(
                          l10n.wholesaleNoOffer,
                          style: t.body.copyWith(color: c.textSecondary),
                        ),
                      ),
                    for (final o in board.open)
                      DymContentWidth(
                        child: _OfferCard(vm: vm, offer: o),
                      ),
                    const SizedBox(height: DymTokenSpace.s4),
                    DymContentWidth(
                      child: DymSectionHeader(title: l10n.wholesaleMine),
                    ),
                    if (!board.isWholesaler)
                      DymContentWidth(
                        child: DymButton(
                          label: l10n.wholesaleBecome,
                          icon: Icons.warehouse_rounded,
                          variant: DymButtonVariant.secondary,
                          onPressed: vm.becomeWholesaler,
                        ),
                      ),
                    for (final o in board.mine)
                      DymContentWidth(
                        child: _OfferCard(vm: vm, offer: o),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

String _status(BuildContext context, WholesaleOffer o) {
  final l10n = DymLocalizations.of(context);
  return switch (o.status) {
    'confirmed' => l10n.wholesaleConfirmed,
    'cancelled' => l10n.wholesaleCancelled,
    'closed' => l10n.wholesaleClosed,
    _ => l10n.wholesaleUntil(
      MaterialLocalizations.of(context).formatShortDate(o.closesAt.toLocal()),
    ),
  };
}

class _OfferCard extends StatelessWidget {
  const new({required this.vm, required this.offer});

  final WholesaleViewModel vm;
  final WholesaleOffer offer;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: DymTokenSpace.s3),
      child: Padding(
        padding: const EdgeInsets.all(DymTokenSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(offer.productName, style: t.title),
            Text(
              [
                offer.storeName,
                l10n.wholesaleUnitPrice(vm.money(offer.unitPriceMinor)),
              ].join(' · '),
              style: t.label.copyWith(color: c.textSecondary),
            ),
            if (offer.note case final note?) Text(note),
            const SizedBox(height: DymTokenSpace.s2),
            LinearProgressIndicator(value: offer.progress, minHeight: 8),
            const SizedBox(height: DymTokenSpace.s1),
            Text(
              l10n.wholesaleProgress(
                offer.committed,
                offer.minQuantity,
                offer.buyers,
              ),
            ),
            Text(_status(context, offer), style: t.label),
            if (offer.myQuantity case final q?)
              Text(l10n.wholesaleMyQuantity(q), style: t.body),
            for (final b in offer.commitments)
              Text('${b.storeName} · ${b.quantity}'),
            if (offer.open && !offer.mine) ...[
              const SizedBox(height: DymTokenSpace.s2),
              DymButton(
                label: offer.myQuantity == null
                    ? l10n.wholesaleCommit
                    : l10n.wholesaleChange,
                icon: Icons.shopping_cart_checkout_rounded,
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => _Quantity(vm: vm, offer: offer),
                ),
              ),
            ],
            if (offer.open && offer.mine) ...[
              const SizedBox(height: DymTokenSpace.s2),
              Row(
                children: [
                  Expanded(
                    child: DymButton(
                      label: l10n.wholesaleConfirm,
                      icon: Icons.check_rounded,
                      onPressed: offer.reached
                          ? () => vm.decide(offer, confirm: true)
                          : null,
                    ),
                  ),
                  const SizedBox(width: DymTokenSpace.s2),
                  Expanded(
                    child: DymButton(
                      label: l10n.wholesaleCancel,
                      variant: DymButtonVariant.secondary,
                      onPressed: () => vm.decide(offer, confirm: false),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Quantity extends StatefulWidget {
  const new({required this.vm, required this.offer});

  final WholesaleViewModel vm;
  final WholesaleOffer offer;

  @override
  State<_Quantity> createState() => _QuantityState();
}

class _QuantityState extends State<_Quantity> {
  late final _quantity = TextEditingController(
    text: '${widget.offer.myQuantity ?? ''}',
  );

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return _Sheet(
      title: widget.offer.productName,
      fields: [
        Text(l10n.wholesaleQuantityHint),
        DymTextField(
          label: l10n.wholesaleQuantity,
          controller: _quantity,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
      ],
      action: l10n.wholesaleCommit,
      onConfirm: () => widget.vm.commit(widget.offer, _quantity.text),
    );
  }
}

class _NewOffer extends StatefulWidget {
  const new({required this.vm});

  final WholesaleViewModel vm;

  @override
  State<_NewOffer> createState() => _NewOfferState();
}

class _NewOfferState extends State<_NewOffer> {
  final _price = TextEditingController();
  final _min = TextEditingController();
  final _note = TextEditingController();
  List<Product> _products = const [];
  Product? _product;
  int _days = 7;

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
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return _Sheet(
      title: l10n.wholesaleNewOffer,
      fields: [
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
        DymTextField(
          label: l10n.wholesaleUnitPriceField,
          controller: _price,
          keyboardType: TextInputType.number,
        ),
        DymTextField(
          label: l10n.wholesaleMinQuantity,
          controller: _min,
          keyboardType: TextInputType.number,
        ),
        Wrap(
          spacing: DymTokenSpace.s2,
          children: [
            for (final d in const [3, 7, 14])
              ChoiceChip(
                label: Text(l10n.wholesaleDays(d)),
                selected: _days == d,
                onSelected: (_) => setState(() => _days = d),
              ),
          ],
        ),
        DymTextField(label: l10n.creditNote, controller: _note),
      ],
      action: l10n.wholesalePublish,
      onConfirm: () async {
        final product = _product;
        if (product == null) return false;
        return await widget.vm.create(
          product: product,
          priceText: _price.text,
          minText: _min.text,
          days: _days,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
      },
    );
  }
}

class _Sheet extends StatefulWidget {
  const new({
    required this.title,
    required this.fields,
    required this.action,
    required this.onConfirm,
  });

  final String title;
  final List<Widget> fields;
  final String action;
  final Future<bool> Function() onConfirm;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => SafeArea(
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
            Text(widget.title, style: context.dym.text.title),
            for (final w in widget.fields) ...[
              const SizedBox(height: DymTokenSpace.s3),
              w,
            ],
            const SizedBox(height: DymTokenSpace.s3),
            DymButton(
              label: widget.action,
              loading: _busy,
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      final ok = await widget.onConfirm();
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
