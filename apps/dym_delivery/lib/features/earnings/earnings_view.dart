import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_delivery/features/missions/missions_service.dart';
import 'package:dym_delivery/features/missions/missions_views.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Gains du livreur (spec 043) : jour, wallet, cash à remettre, recharge,
/// retrait.
class EarningsViewModel extends BaseViewModel {
  new({required this.service});

  final MissionsService service;
  CountryConfig? config;
  CourierEarnings? earnings;
  Failure? failure;
  String? problem;
  bool acting = false;

  Future<void> load() async {
    failure = null;
    config ??= (await service.countryConfig()).valueOrNull;
    switch (await service.earnings()) {
      case Ok(:final value):
        earnings = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  String money(int minor) => config?.money(minor).format() ?? '';

  /// Montant saisi en unités principales ; nul : invalide.
  int? parse(String text) {
    final currency = config?.currency;
    if (currency == null) return null;
    final minor = Money.parseMajor(text, currency);
    return minor == null || minor <= 0 ? null : minor;
  }

  /// Point de recharge ; `true` : wallet de la cliente crédité.
  Future<bool> topup(String code, String amountText) async {
    final amount = parse(amountText);
    if (acting || amount == null) {
      problem = 'wallet_amount_invalid';
      notifyListeners();
      return false;
    }
    acting = true;
    problem = null;
    notifyListeners();
    final result = await service.cashTopup(code.trim(), amount);
    acting = false;
    switch (result) {
      case Ok(:final value):
        earnings = value;
      case Err(failure: final f):
        problem = f is NetworkFailure ? 'offline' : f.message;
    }
    notifyListeners();
    return result.isOk;
  }

  Future<bool> withdraw(String amountText) async {
    final amount = parse(amountText);
    if (acting || amount == null) {
      problem = 'wallet_amount_invalid';
      notifyListeners();
      return false;
    }
    acting = true;
    problem = null;
    notifyListeners();
    final result = await service.withdraw(amount);
    acting = false;
    if (result case Err(failure: final f)) {
      problem = f is NetworkFailure ? 'offline' : f.message;
    }
    await load();
    return result.isOk;
  }
}

String earningsProblem(DymLocalizations l10n, String code) => switch (code) {
  'invalid_code' => l10n.cashTopupInvalidCode,
  'wallet_insufficient' => l10n.walletErrorInsufficient,
  'wallet_amount_invalid' => l10n.walletErrorAmount,
  'feature_disabled' => l10n.earningsWithdrawDisabled,
  'offline' => l10n.errorOffline,
  _ => l10n.errorGeneric,
};

class EarningsView extends StackedView<EarningsViewModel> {
  const new({required this.service, super.key});

  final MissionsService service;

  @override
  EarningsViewModel viewModelBuilder(BuildContext context) =>
      EarningsViewModel(service: service);

  @override
  void onViewModelReady(EarningsViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, EarningsViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final e = vm.earnings;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            DymLayout.gutter(context),
            DymTokenSpace.s3,
            DymLayout.gutter(context),
            DymTokenSpace.s5,
          ),
          children: [
            DymContentWidth(child: Text(l10n.earningsTitle, style: t.display)),
            const SizedBox(height: DymTokenSpace.s3),
            if (e == null)
              LoadState(failure: vm.failure, onRetry: vm.load)
            else ...[
              // Ce que je gagne, ce que je dois (planche 05).
              DymContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.earningsToday(e.todayCount),
                      style: t.body.copyWith(color: c.textSecondary),
                    ),
                    Text(
                      vm.money(e.todayFeesMinor),
                      style: t.display.copyWith(
                        fontSize: 40,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: DymTokenSpace.s2),
                    Divider(height: 1, color: c.hairline),
                    _Line(
                      icon: Icons.account_balance_wallet_outlined,
                      label: l10n.earningsWallet,
                      value: vm.money(e.walletMinor),
                    ),
                    Divider(height: 1, color: c.hairline),
                  ],
                ),
              ),
              const SizedBox(height: DymTokenSpace.s4),
              DymContentWidth(
                child: Text(
                  l10n.earningsCashTitle,
                  style: t.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (e.cash.isEmpty)
                DymContentWidth(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: DymTokenSpace.s2,
                    ),
                    child: Text(
                      l10n.earningsCashNone,
                      style: t.body.copyWith(color: c.textSecondary),
                    ),
                  ),
                )
              else
                for (final (i, line) in e.cash.indexed)
                  DymContentWidth(
                    child: Column(
                      children: [
                        if (i > 0) Divider(height: 1, color: c.hairline),
                        _Line(
                          icon: line.toPlatform
                              ? Icons.account_balance_outlined
                              : Icons.storefront_outlined,
                          label: line.toPlatform
                              ? l10n.earningsCashToDym
                              : line.storeName ?? '',
                          hint: line.toPlatform
                              ? l10n.earningsCashToDymHint
                              : l10n.earningsCashToStoreHint,
                          value: vm.money(line.amountMinor),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: DymTokenSpace.s4),
              DymContentWidth(
                child: DymButton(
                  label: l10n.earningsWithdraw,
                  icon: Icons.account_balance_outlined,
                  onPressed: e.walletMinor <= 0 || vm.acting
                      ? null
                      : () => _withdrawSheet(context, vm),
                ),
              ),
              const SizedBox(height: DymTokenSpace.s2),
              // Point de recharge : le cash d'une cliente va sur son wallet.
              DymContentWidth(
                child: DymMenuGroup(
                  children: [
                    DymMenuRow(
                      icon: Icons.location_on_outlined,
                      label: l10n.cashTopupTitle,
                      onTap: vm.acting ? null : () => _topupSheet(context, vm),
                    ),
                  ],
                ),
              ),
              if (vm.problem case final p?)
                DymContentWidth(
                  child: Padding(
                    padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                    child: Text(
                      earningsProblem(l10n, p),
                      style: t.body.copyWith(color: c.pimentStrong),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ligne à filet : icône, libellé (et précision), montant à droite.
class _Line extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s2),
        child: Row(
          children: [
            Icon(icon, color: c.textPrimary),
            const SizedBox(width: DymTokenSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: t.body),
                  if (hint case final h?)
                    Text(
                      h,
                      style: t.label.copyWith(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
            Text(value, style: t.body.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

Future<void> _withdrawSheet(BuildContext context, EarningsViewModel vm) async {
  final l10n = DymLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FormSheet(
      title: l10n.earningsWithdraw,
      note: l10n.walletWithdrawSimulated,
      fields: [l10n.earningsAmount],
      action: l10n.earningsWithdraw,
      onConfirm: (values) => vm.withdraw(values[0]),
    ),
  );
}

Future<void> _topupSheet(BuildContext context, EarningsViewModel vm) async {
  final l10n = DymLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FormSheet(
      title: l10n.cashTopupTitle,
      note: l10n.cashTopupHint,
      fields: [l10n.cashTopupCode, l10n.earningsAmount],
      action: l10n.cashTopupConfirm,
      onConfirm: (values) => vm.topup(values[0], values[1]),
    ),
  );
}

/// Feuille de saisie : champs numériques, action, fermeture si réussie.
class _FormSheet extends StatefulWidget {
  const new({
    required this.title,
    required this.note,
    required this.fields,
    required this.action,
    required this.onConfirm,
  });

  final String title;
  final String note;
  final List<String> fields;
  final String action;
  final Future<bool> Function(List<String> values) onConfirm;

  @override
  State<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<_FormSheet> {
  late final List<TextEditingController> _controllers = [
    for (final _ in widget.fields) TextEditingController(),
  ];
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
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
          Text(widget.title, style: context.dym.text.title),
          const SizedBox(height: DymTokenSpace.s2),
          Text(widget.note),
          for (final (i, label) in widget.fields.indexed) ...[
            const SizedBox(height: DymTokenSpace.s3),
            DymTextField(
              label: label,
              controller: _controllers[i],
              keyboardType: TextInputType.number,
              autofocus: i == 0,
            ),
          ],
          const SizedBox(height: DymTokenSpace.s3),
          DymButton(
            label: widget.action,
            loading: _busy,
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    final ok = await widget.onConfirm([
                      for (final c in _controllers) c.text,
                    ]);
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
