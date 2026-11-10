import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/till/till_service.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Refus affichés à l'écran.
String tillProblem(DymLocalizations l10n, String code) => switch (code) {
  'invalid_amount' => l10n.walletErrorAmount,
  'balance_insufficient' => l10n.tillBalanceInsufficient,
  'feature_disabled' => l10n.tillVoiceDisabled,
  'offline' => l10n.errorOffline,
  'nothing_heard' => l10n.tillNothingHeard,
  _ => l10n.errorGeneric,
};

String tillMethodLabel(DymLocalizations l10n, TillMethod m) => switch (m) {
  TillMethod.cash => l10n.tillMethodCash,
  TillMethod.mobileMoney => l10n.tillMethodMobileMoney,
  TillMethod.other => l10n.tillMethodOther,
};

class TillViewModel extends BaseViewModel {
  new({required this.service});

  final TillService service;
  CountryConfig? config;
  Till? till;
  Failure? failure;
  String? problem;
  bool acting = false;

  Future<void> load() async {
    failure = null;
    config ??= (await service.countryConfig()).valueOrNull;
    switch (await service.till()) {
      case Ok(:final value):
        till = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  String money(int minor) => config?.money(minor).format() ?? '';

  /// Montant en unités principales (« 1 500 », « 12,50 ») ; nul : invalide.
  int? parseAmount(String text) {
    final currency = config?.currency;
    if (currency == null) return null;
    final minor = Money.parseMajor(text, currency);
    return minor == null || minor <= 0 ? null : minor;
  }

  /// Montant mineur → texte à éditer, selon les décimales de la devise.
  String amountText(int minor) {
    final units = config?.currency.minorUnits ?? 0;
    if (units == 0) return '$minor';
    final whole = minor ~/ _pow10(units);
    final rest = (minor % _pow10(units)).toString().padLeft(units, '0');
    return '$whole,$rest';
  }

  static int _pow10(int n) => n == 0 ? 1 : 10 * _pow10(n - 1);

  String _code(Failure f) => f is NetworkFailure ? 'offline' : f.message;

  /// Texte tapé ou dicté → vente à confirmer.
  Future<TillDraft?> read(String text) async {
    if (text.trim().isEmpty) return null;
    switch (await service.parse(text)) {
      case Ok(:final value):
        return value;
      case Err(failure: final f):
        problem = _code(f);
        notifyListeners();
        return null;
    }
  }

  /// Dictée : texte transcrit puis lu ; nul : rien compris ou refus.
  Future<TillDraft?> dictate() async {
    problem = null;
    switch (await service.dictate()) {
      case Ok(value: final text?):
        return await read(text);
      case Ok():
        problem = 'nothing_heard';
      case Err(failure: final f):
        problem = _code(f);
    }
    notifyListeners();
    return null;
  }

  Future<bool> record({
    required String label,
    required String amountText,
    required TillMethod method,
    String? variantId,
    int quantity = 1,
  }) async {
    final amount = parseAmount(amountText);
    if (acting || amount == null || label.trim().isEmpty) {
      problem = 'invalid_amount';
      notifyListeners();
      return false;
    }
    acting = true;
    problem = null;
    notifyListeners();
    final result = await service.record(
      label: label.trim(),
      amountMinor: amount,
      method: method,
      variantId: variantId,
      quantity: quantity,
    );
    acting = false;
    switch (result) {
      case Ok(:final value):
        till = value;
      case Err(failure: final f):
        problem = _code(f);
    }
    notifyListeners();
    return result.isOk;
  }

  Future<void> voidSale(TillSale sale) async {
    switch (await service.voidSale(sale)) {
      case Ok(:final value):
        till = value;
      case Err(failure: final f):
        problem = _code(f);
    }
    notifyListeners();
  }

  Future<bool> payout(String amountText) async {
    final amount = parseAmount(amountText);
    if (acting || amount == null) {
      problem = 'invalid_amount';
      notifyListeners();
      return false;
    }
    acting = true;
    problem = null;
    notifyListeners();
    final result = await service.payout(amount);
    acting = false;
    switch (result) {
      case Ok(:final value):
        till = value;
      case Err(failure: final f):
        problem = _code(f);
    }
    notifyListeners();
    return result.isOk;
  }
}

/// « Ma caisse » : jour (en app, hors app, par moyen), solde, versements,
/// ventes hors app à la main ou à la voix.
class TillView extends StackedView<TillViewModel> {
  const new({required this.service, required this.onBack, super.key});

  final TillService service;
  final VoidCallback onBack;

  @override
  TillViewModel viewModelBuilder(BuildContext context) =>
      TillViewModel(service: service);

  @override
  void onViewModelReady(TillViewModel viewModel) => unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, TillViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final till = vm.till;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(l10n.tillTitle),
        leading: IconButton(
          tooltip: l10n.authBack,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      floatingActionButton: till == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _saleSheet(context, vm),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.tillNewSale),
            ),
      body: SafeArea(
        child: till == null
            ? Center(
                child: vm.failure == null
                    ? const CircularProgressIndicator()
                    : DymStateView(
                        kind: vm.failure is NetworkFailure
                            ? DymStateKind.offline
                            : DymStateKind.error,
                        title: vm.failure is NetworkFailure
                            ? l10n.errorOffline
                            : l10n.errorGeneric,
                        message: l10n.tillLoadError,
                        actionLabel: l10n.retry,
                        onAction: vm.load,
                      ),
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
                    DymContentWidth(
                      child: Text(
                        l10n.tillToday(vm.money(till.todayMinor)),
                        style: t.display,
                      ),
                    ),
                    const SizedBox(height: DymTokenSpace.s2),
                    DymContentWidth(
                      child: Row(
                        children: [
                          Expanded(
                            child: _Tile(
                              label: l10n.tillInApp(till.todayAppCount),
                              value: vm.money(till.todayAppMinor),
                            ),
                          ),
                          const SizedBox(width: DymTokenSpace.s3),
                          Expanded(
                            child: _Tile(
                              label: l10n.tillOffApp(till.todayOffAppCount),
                              value: vm.money(till.todayOffAppMinor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (till.byMethod.isNotEmpty)
                      DymContentWidth(
                        child: Padding(
                          padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                          child: Wrap(
                            spacing: DymTokenSpace.s2,
                            children: [
                              for (final e in till.byMethod.entries)
                                Chip(
                                  label: Text(
                                    '${tillMethodLabel(l10n, e.key)} · '
                                    '${vm.money(e.value)}',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: DymTokenSpace.s4),
                    DymContentWidth(
                      child: _Tile(
                        label: l10n.tillBalance,
                        value: vm.money(till.balanceMinor),
                      ),
                    ),
                    const SizedBox(height: DymTokenSpace.s2),
                    DymContentWidth(
                      child: DymButton(
                        label: l10n.tillPayout,
                        icon: Icons.account_balance_rounded,
                        variant: DymButtonVariant.secondary,
                        onPressed:
                            till.balanceMinor <= 0 ||
                                !till.simulatedPayout ||
                                vm.acting
                            ? null
                            : () => _payoutSheet(context, vm),
                      ),
                    ),
                    if (vm.problem case final p?)
                      DymContentWidth(
                        child: Padding(
                          padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                          child: Text(
                            tillProblem(l10n, p),
                            style: t.body.copyWith(color: c.pimentStrong),
                          ),
                        ),
                      ),
                    const SizedBox(height: DymTokenSpace.s4),
                    DymContentWidth(
                      child: DymSectionHeader(title: l10n.tillSales),
                    ),
                    if (till.sales.isEmpty)
                      DymContentWidth(
                        child: Text(
                          l10n.tillNoSale,
                          style: t.body.copyWith(color: c.textSecondary),
                        ),
                      ),
                    for (final s in till.sales)
                      DymContentWidth(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          minTileHeight: 56,
                          title: Text(
                            s.label,
                            style: s.voided
                                ? t.body.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: c.textSecondary,
                                  )
                                : t.body,
                          ),
                          subtitle: Text(tillMethodLabel(l10n, s.method)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(vm.money(s.amountMinor), style: t.title),
                              if (!s.voided)
                                IconButton(
                                  tooltip: l10n.tillVoid,
                                  onPressed: () => vm.voidSale(s),
                                  icon: const Icon(Icons.undo_rounded),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (till.payouts.isNotEmpty) ...[
                      const SizedBox(height: DymTokenSpace.s4),
                      DymContentWidth(
                        child: DymSectionHeader(title: l10n.tillPayouts),
                      ),
                      for (final p in till.payouts)
                        DymContentWidth(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.account_balance_rounded),
                            title: Text(vm.money(p.amountMinor)),
                            subtitle: Text(
                              MaterialLocalizations.of(context)
                                  .formatShortDate(p.at.toLocal()),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.tintVertTendre,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DymTokenSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.label.copyWith(color: c.textSecondary)),
            Text(value, style: t.title),
          ],
        ),
      ),
    );
  }
}

Future<void> _saleSheet(BuildContext context, TillViewModel vm) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SaleSheet(vm: vm),
    );

Future<void> _payoutSheet(BuildContext context, TillViewModel vm) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PayoutSheet(vm: vm),
    );

/// Nouvelle vente : dictée ou saisie, puis montant et moyen.
class _SaleSheet extends StatefulWidget {
  const new({required this.vm});

  final TillViewModel vm;

  @override
  State<_SaleSheet> createState() => _SaleSheetState();
}

class _SaleSheetState extends State<_SaleSheet> {
  final _label = TextEditingController();
  final _amount = TextEditingController();
  TillMethod _method = TillMethod.cash;
  String? _variantId;
  int _quantity = 1;
  bool _listening = false;
  bool _busy = false;

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _apply(TillDraft? draft) {
    if (draft == null) return;
    setState(() {
      if (draft.label case final label?) _label.text = label;
      if (draft.amountMinor case final amount?) {
        _amount.text = widget.vm.amountText(amount);
      }
      _variantId = draft.variantId;
      _quantity = draft.quantity;
    });
  }

  Future<void> _voice() async {
    if (_listening) {
      setState(() => _listening = false);
      _apply(await widget.vm.dictate());
      return;
    }
    if ((await widget.vm.service.recorder.start()).isOk) {
      setState(() => _listening = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final vm = widget.vm;
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
            Text(l10n.tillNewSale, style: context.dym.text.title),
            const SizedBox(height: DymTokenSpace.s2),
            DymButton(
              label: _listening ? l10n.tillVoiceStop : l10n.tillVoice,
              icon: _listening ? Icons.stop_rounded : Icons.mic_rounded,
              variant: DymButtonVariant.secondary,
              onPressed: _voice,
            ),
            const SizedBox(height: DymTokenSpace.s3),
            DymTextField(
              label: l10n.tillLabel,
              hint: l10n.tillLabelHint,
              controller: _label,
              textInputAction: TextInputAction.next,
              onSubmitted: (text) async => _apply(await vm.read(text)),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            DymTextField(
              label: l10n.tillAmount,
              controller: _amount,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: DymTokenSpace.s3),
            Wrap(
              spacing: DymTokenSpace.s2,
              children: [
                for (final m in TillMethod.values)
                  ChoiceChip(
                    label: Text(tillMethodLabel(l10n, m)),
                    selected: _method == m,
                    onSelected: (_) => setState(() => _method = m),
                  ),
              ],
            ),
            const SizedBox(height: DymTokenSpace.s3),
            DymButton(
              label: l10n.tillSave,
              icon: Icons.check_rounded,
              loading: _busy,
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      final ok = await vm.record(
                        label: _label.text,
                        amountText: _amount.text,
                        method: _method,
                        variantId: _variantId,
                        quantity: _quantity,
                      );
                      if (!context.mounted) return;
                      setState(() => _busy = false);
                      if (ok) Navigator.pop(context);
                    },
            ),
            if (vm.problem case final p?)
              Padding(
                padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                child: Text(tillProblem(l10n, p)),
              ),
          ],
        ),
      ),
    );
  }
}

class _PayoutSheet extends StatefulWidget {
  const new({required this.vm});

  final TillViewModel vm;

  @override
  State<_PayoutSheet> createState() => _PayoutSheetState();
}

class _PayoutSheetState extends State<_PayoutSheet> {
  final _amount = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
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
            Text(l10n.tillPayout, style: context.dym.text.title),
            const SizedBox(height: DymTokenSpace.s2),
            Text(l10n.tillPayoutSimulated),
            const SizedBox(height: DymTokenSpace.s3),
            DymTextField(
              label: l10n.tillAmount,
              controller: _amount,
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: DymTokenSpace.s3),
            DymButton(
              label: l10n.tillPayout,
              loading: _busy,
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      final ok = await widget.vm.payout(_amount.text);
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
