import 'package:dym_client/features/wallet/wallet_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Payer par QR (spec 046) : scan ou code, aperçu, confirmation.
class QrPayViewModel extends BaseViewModel {
  new({required this.service});

  final WalletService service;
  CountryConfig? config;
  String? code;
  PaymentRequest? preview;
  PaymentRequest? paid;
  String? problem;

  Future<void> init() async {
    config = (await service.countryConfig()).valueOrNull;
    notifyListeners();
  }

  String money(int minor) => config?.money(minor).format() ?? '';

  String _code(Failure f) => f is NetworkFailure ? 'offline' : f.message;

  Future<void> read(String value) async {
    if (value.trim().isEmpty) return;
    problem = null;
    setBusy(true);
    switch (await service.qrPreview(value.trim())) {
      case Ok(value: final r):
        code = value.trim();
        preview = r;
      case Err(failure: final f):
        problem = _code(f);
    }
    setBusy(false);
  }

  Future<void> pay() async {
    final current = code;
    if (current == null || isBusy) return;
    problem = null;
    setBusy(true);
    switch (await service.qrPay(current)) {
      case Ok(:final value):
        paid = value;
      case Err(failure: final f):
        problem = _code(f);
    }
    setBusy(false);
  }
}

String qrPayProblem(DymLocalizations l10n, String code) => switch (code) {
  'invalid_code' => l10n.qrPayInvalidCode,
  'wallet_insufficient' => l10n.walletErrorInsufficient,
  'own_store' => l10n.qrPayOwnStore,
  'currency_mismatch' => l10n.qrPayCurrency,
  'offline' => l10n.errorOffline,
  _ => l10n.errorGeneric,
};

class QrPayView extends StackedView<QrPayViewModel> {
  const new({required this.service, required this.onDone, super.key});

  final WalletService service;
  final VoidCallback onDone;

  @override
  QrPayViewModel viewModelBuilder(BuildContext context) =>
      QrPayViewModel(service: service);

  @override
  void onViewModelReady(QrPayViewModel viewModel) => viewModel.init();

  @override
  Widget builder(BuildContext context, QrPayViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final preview = vm.preview;
    final paid = vm.paid;
    final manual = _CodeEntry(onSubmit: vm.read);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(l10n.qrPayTitle),
        leading: IconButton(
          tooltip: l10n.authBack,
          onPressed: onDone,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(DymLayout.gutter(context)),
          children: [
            if (paid != null)
              DymContentWidth.form(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_rounded, color: c.brand, size: 72),
                    Text(
                      l10n.qrPayDone(
                        vm.money(paid.amountMinor),
                        paid.storeName,
                      ),
                      textAlign: TextAlign.center,
                      style: t.title,
                    ),
                    const SizedBox(height: DymTokenSpace.s3),
                    DymButton(label: l10n.qrPayClose, onPressed: onDone),
                  ],
                ),
              )
            else if (preview != null)
              DymContentWidth.form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(preview.storeName, style: t.title),
                    if (preview.label case final label?) Text(label),
                    const SizedBox(height: DymTokenSpace.s2),
                    Text(vm.money(preview.amountMinor), style: t.display),
                    const SizedBox(height: DymTokenSpace.s3),
                    DymButton(
                      label: l10n.qrPayConfirm(vm.money(preview.amountMinor)),
                      icon: Icons.account_balance_wallet_rounded,
                      loading: vm.isBusy,
                      onPressed: vm.pay,
                    ),
                  ],
                ),
              )
            else ...[
              DymContentWidth.form(child: Text(l10n.qrPayHint)),
              const SizedBox(height: DymTokenSpace.s3),
              DymContentWidth.form(
                child: SizedBox(
                  height: 260,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DymTokenRadius.card),
                    child: QrScanView(onCode: vm.read, fallback: manual),
                  ),
                ),
              ),
              const SizedBox(height: DymTokenSpace.s3),
              DymContentWidth.form(child: manual),
            ],
            if (vm.problem case final p?)
              DymContentWidth.form(
                child: Padding(
                  padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                  child: Text(
                    qrPayProblem(l10n, p),
                    style: t.body.copyWith(color: c.pimentStrong),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CodeEntry extends StatefulWidget {
  const new({required this.onSubmit});

  final Future<void> Function(String code) onSubmit;

  @override
  State<_CodeEntry> createState() => _CodeEntryState();
}

class _CodeEntryState extends State<_CodeEntry> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DymTextField(
          label: l10n.qrPayCode,
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onSubmitted: widget.onSubmit,
        ),
        DymButton(
          label: l10n.qrPayContinue,
          variant: DymButtonVariant.secondary,
          onPressed: () => widget.onSubmit(_code.text),
        ),
      ],
    );
  }
}
