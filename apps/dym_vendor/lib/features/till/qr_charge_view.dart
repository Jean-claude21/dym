import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/till/till_service.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Encaisser par QR (spec 046) : montant, QR et code, attente du paiement.
class QrChargeViewModel extends BaseViewModel {
  new({required this.service, this.every = const Duration(seconds: 3)});

  final TillService service;
  final Duration every;
  CountryConfig? config;
  PaymentRequest? request;
  String? problem;
  Timer? _timer;

  Future<void> init() async {
    config = (await service.countryConfig()).valueOrNull;
    notifyListeners();
  }

  String money(int minor) => config?.money(minor).format() ?? '';

  /// Montant tapé au clavier, lu dans la devise du pays (affichage seul).
  String preview(String digits) {
    final currency = config?.currency;
    final minor = currency == null || digits.isEmpty
        ? 0
        : Money.parseMajor(digits, currency) ?? 0;
    return money(minor);
  }

  Future<void> create(String amountText, {String? label}) async {
    final currency = config?.currency;
    final amount = currency == null
        ? null
        : Money.parseMajor(amountText, currency);
    if (amount == null || amount <= 0) {
      problem = 'invalid_amount';
      notifyListeners();
      return;
    }
    problem = null;
    setBusy(true);
    switch (await service.requestPayment(amount, label: label)) {
      case Ok(:final value):
        request = value;
        _timer?.cancel();
        _timer = Timer.periodic(every, (_) => unawaited(poll()));
      case Err(failure: final f):
        problem = f is NetworkFailure ? 'offline' : f.message;
    }
    setBusy(false);
  }

  /// Relecture de l'état ; s'arrête une fois payée, expirée ou annulée.
  Future<void> poll() async {
    final current = request;
    if (current == null) return;
    if (await service.requestStatus(current) case Ok(:final value)) {
      request = value;
      if (value.status != PaymentRequestStatus.open) _timer?.cancel();
      notifyListeners();
    }
  }

  Future<void> cancel() async {
    final current = request;
    if (current == null) return;
    _timer?.cancel();
    if (await service.cancelRequest(current) case Ok(:final value)) {
      request = value;
    }
    notifyListeners();
  }

  void restart() {
    _timer?.cancel();
    request = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class QrChargeView extends StackedView<QrChargeViewModel> {
  const new({required this.service, required this.onDone, super.key});

  final TillService service;
  final VoidCallback onDone;

  @override
  QrChargeViewModel viewModelBuilder(BuildContext context) =>
      QrChargeViewModel(service: service);

  @override
  void onViewModelReady(QrChargeViewModel viewModel) =>
      unawaited(viewModel.init());

  @override
  Widget builder(BuildContext context, QrChargeViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final request = vm.request;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(l10n.qrChargeTitle),
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
            if (request == null)
              _AmountForm(vm: vm)
            else
              DymContentWidth.form(
                child: Column(
                  children: [
                    Text(vm.money(request.amountMinor), style: t.display),
                    const SizedBox(height: DymTokenSpace.s3),
                    switch (request.status) {
                      PaymentRequestStatus.open => Column(
                        children: [
                          DymQrImage(data: request.qr ?? ''),
                          const SizedBox(height: DymTokenSpace.s2),
                          Text(l10n.qrChargeCode, style: t.label),
                          Text(
                            request.code ?? '',
                            style: t.display.copyWith(letterSpacing: 6),
                          ),
                          const SizedBox(height: DymTokenSpace.s2),
                          Text(
                            l10n.qrChargeWaiting,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: DymTokenSpace.s3),
                          DymButton(
                            label: l10n.qrChargeCancel,
                            variant: DymButtonVariant.secondary,
                            onPressed: vm.cancel,
                          ),
                        ],
                      ),
                      PaymentRequestStatus.paid => Column(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: c.brand,
                            size: 72,
                          ),
                          Text(l10n.qrChargePaid, style: t.title),
                          const SizedBox(height: DymTokenSpace.s3),
                          DymButton(
                            label: l10n.qrChargeAnother,
                            icon: Icons.qr_code_rounded,
                            onPressed: vm.restart,
                          ),
                        ],
                      ),
                      _ => Column(
                        children: [
                          Text(l10n.qrChargeExpired, style: t.title),
                          const SizedBox(height: DymTokenSpace.s3),
                          DymButton(
                            label: l10n.qrChargeAnother,
                            icon: Icons.qr_code_rounded,
                            onPressed: vm.restart,
                          ),
                        ],
                      ),
                    },
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AmountForm extends StatefulWidget {
  const new({required this.vm});

  final QrChargeViewModel vm;

  @override
  State<_AmountForm> createState() => _AmountFormState();
}

class _AmountFormState extends State<_AmountForm> {
  final _label = TextEditingController();

  /// Chiffres tapés au clavier géant (planche 04).
  String _digits = '';

  void _key(String key) => setState(() {
    if (key == '<') {
      if (_digits.isNotEmpty) {
        _digits = _digits.substring(0, _digits.length - 1);
      }
    } else if (_digits.length < 9 && !(_digits.isEmpty && key == '0')) {
      _digits += key;
    }
  });

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = widget.vm;
    return DymContentWidth.form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.qrChargeHint),
          const SizedBox(height: DymTokenSpace.s3),
          // Montant en grand, puis clavier géant : une main, au comptoir.
          Semantics(
            label: l10n.tillAmount,
            liveRegion: true,
            child: Container(
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(DymTokenRadius.card),
                border: Border.all(color: c.hairline),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    vm.preview(_digits),
                    style: t.display.copyWith(
                      fontSize: 38,
                      color: _digits.isEmpty ? c.textSecondary : c.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: DymTokenSpace.s3),
          DymKeypad(
            onDigit: _key,
            onErase: () => _key('<'),
            eraseLabel: l10n.tillErase,
          ),
          const SizedBox(height: DymTokenSpace.s2),
          DymTextField(label: l10n.qrChargeLabel, controller: _label),
          const SizedBox(height: DymTokenSpace.s4),
          DymButton(
            label: l10n.qrChargeShow,
            icon: Icons.qr_code_rounded,
            loading: vm.isBusy,
            onPressed: () => vm.create(
              _digits,
              label: _label.text.trim().isEmpty ? null : _label.text.trim(),
            ),
          ),
          if (vm.problem case final p?)
            Padding(
              padding: const EdgeInsets.only(top: DymTokenSpace.s2),
              child: Text(
                p == 'invalid_amount'
                    ? l10n.walletErrorAmount
                    : p == 'offline'
                    ? l10n.errorOffline
                    : l10n.errorGeneric,
              ),
            ),
        ],
      ),
    );
  }
}
