import 'dart:async';

import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Marchandage (spec 050) : remplaçable en test.
abstract interface class HaggleService {
  /// Conclu : la ligne est mise au panier par la base, puis le panier relu.
  Future<Result<Haggle>> propose(
    String variantId,
    int quantity,
    int offerMinor,
  );

  Future<Result<Haggle>> accept(Haggle haggle);
}

class NeonHaggleService implements HaggleService {
  new({required this._repository, required this._cart});

  final HaggleRepository _repository;
  final CartService _cart;

  Future<Result<Haggle>> _refreshed(Result<Haggle> result) async {
    if (result case Ok(:final value) when value.accepted) {
      await _cart.refresh();
    }
    return result;
  }

  @override
  Future<Result<Haggle>> propose(
    String variantId,
    int quantity,
    int offerMinor,
  ) => _repository.propose(variantId, quantity, offerMinor).then(_refreshed);

  @override
  Future<Result<Haggle>> accept(Haggle haggle) =>
      _repository.accept(haggle.id).then(_refreshed);
}

String haggleProblem(DymLocalizations l10n, String code) => switch (code) {
  'too_many_attempts' => l10n.haggleErrorTooMany,
  'offer_not_lower' => l10n.haggleErrorNotLower,
  'haggle_off' => l10n.haggleErrorOff,
  'haggle_expired' => l10n.haggleErrorExpired,
  'other_country' => l10n.cartOtherCountry,
  'invalid_amount' => l10n.walletErrorAmount,
  'offline' => l10n.errorOffline,
  _ => l10n.errorGeneric,
};

class HaggleViewModel extends BaseViewModel {
  new({
    required this.service,
    required this.currency,
    required this.variantId,
    required this.quantity,
  });

  final HaggleService service;
  final Currency currency;
  final String variantId;
  final int quantity;
  Haggle? haggle;
  String? problem;

  bool get done => haggle?.accepted ?? false;

  Future<void> _run(Future<Result<Haggle>> work) async {
    problem = null;
    setBusy(true);
    switch (await work) {
      case Ok(:final value):
        haggle = value;
      case Err(failure: final f):
        problem = f is NetworkFailure ? 'offline' : f.message;
    }
    setBusy(false);
  }

  Future<void> propose(String text) {
    final offer = Money.parseMajor(text, currency);
    if (offer == null || offer <= 0) {
      problem = 'invalid_amount';
      notifyListeners();
      return Future.value();
    }
    return _run(service.propose(variantId, quantity, offer));
  }

  Future<void> acceptCounter() async {
    final current = haggle;
    if (current == null || !current.countered) return;
    await _run(service.accept(current));
  }
}

/// Feuille « Marchander » de la fiche produit.
Future<void> showHaggleSheet(
  BuildContext context, {
  required HaggleService service,
  required CountryConfig config,
  required String variantId,
  required int quantity,
  required String productName,
  required int priceMinor,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => HaggleSheet(
    service: service,
    config: config,
    variantId: variantId,
    quantity: quantity,
    productName: productName,
    priceMinor: priceMinor,
  ),
);

class HaggleSheet extends StatefulWidget {
  const new({
    required this.service,
    required this.config,
    required this.variantId,
    required this.quantity,
    required this.productName,
    required this.priceMinor,
    super.key,
  });

  final HaggleService service;
  final CountryConfig config;
  final String variantId;
  final int quantity;
  final String productName;
  final int priceMinor;

  @override
  State<HaggleSheet> createState() => _HaggleSheetState();
}

class _HaggleSheetState extends State<HaggleSheet> {
  final _offer = TextEditingController();
  late final HaggleViewModel _vm = HaggleViewModel(
    service: widget.service,
    currency: widget.config.currency,
    variantId: widget.variantId,
    quantity: widget.quantity,
  );

  @override
  void dispose() {
    _offer.dispose();
    _vm.dispose();
    super.dispose();
  }

  String _money(int minor) => widget.config.money(minor).format();

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final haggle = _vm.haggle;
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
                  Text(l10n.haggleTitle, style: t.title),
                  const SizedBox(height: DymTokenSpace.s1),
                  Text(widget.productName, style: t.body),
                  Text(
                    l10n.haggleCurrent(_money(widget.priceMinor)),
                    style: t.label.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  if (_vm.done && haggle != null) ...[
                    Row(
                      children: [
                        Icon(Icons.handshake_rounded, color: c.brand),
                        const SizedBox(width: DymTokenSpace.s2),
                        Expanded(
                          child: Text(
                            l10n.haggleAccepted(_money(haggle.priceMinor)),
                            style: t.title.copyWith(color: c.brandDeep),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DymTokenSpace.s3),
                    DymButton(
                      label: l10n.haggleClose,
                      icon: Icons.check_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ] else ...[
                    Text(l10n.haggleHint(widget.quantity)),
                    const SizedBox(height: DymTokenSpace.s2),
                    if (haggle != null && haggle.countered) ...[
                      Text(
                        l10n.haggleCountered(_money(haggle.priceMinor)),
                        style: t.title,
                      ),
                      const SizedBox(height: DymTokenSpace.s3),
                      DymButton(
                        label: l10n.haggleAcceptCounter,
                        icon: Icons.handshake_rounded,
                        loading: _vm.isBusy,
                        onPressed: _vm.isBusy ? null : _vm.acceptCounter,
                      ),
                      Text(
                        l10n.haggleAttemptsLeft(haggle.attemptsLeft),
                        style: t.label.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: DymTokenSpace.s3),
                    ],
                    if (_vm.problem case final p?)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: DymTokenSpace.s2,
                        ),
                        child: Text(
                          haggleProblem(l10n, p),
                          style: t.body.copyWith(color: c.pimentStrong),
                        ),
                      ),
                    DymTextField(
                      label: l10n.haggleOfferField,
                      controller: _offer,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: DymTokenSpace.s4),
                    DymButton(
                      label: l10n.haggleSubmit,
                      icon: Icons.sell_rounded,
                      variant: haggle?.countered ?? false
                          ? DymButtonVariant.secondary
                          : DymButtonVariant.primary,
                      loading: _vm.isBusy,
                      onPressed: _vm.isBusy
                          ? null
                          : () => unawaited(_vm.propose(_offer.text)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
