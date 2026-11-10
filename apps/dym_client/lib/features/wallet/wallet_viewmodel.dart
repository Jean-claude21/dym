import 'dart:math' as math;

import 'package:dym_client/features/wallet/wallet_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:stacked/stacked.dart';

/// Refus affichés à l'écran.
enum WalletError {
  insufficient,
  amount,
  topupDisabled,
  pocketLimit,
  offline,
  generic,
}

WalletError walletErrorOf(Failure failure) => switch (failure) {
  NetworkFailure() => WalletError.offline,
  ValidationFailure(message: 'wallet_insufficient') => WalletError.insufficient,
  ValidationFailure(message: 'wallet_amount_invalid') => WalletError.amount,
  ValidationFailure(message: 'feature_disabled') => WalletError.topupDisabled,
  ValidationFailure(message: 'pocket_limit') => WalletError.pocketLimit,
  _ => WalletError.generic,
};

/// Écran « Mon wallet » : solde, poches, mouvements et actions.
class WalletViewModel extends BaseViewModel {
  new({required this.service});

  final WalletService service;

  Wallet? _wallet;
  CountryConfig? _config;
  Failure? _failure;
  WalletError? _walletError;
  bool _acting = false;

  Wallet? get wallet => _wallet;
  Failure? get failure => _failure;
  WalletError? get walletError => _walletError;
  bool get acting => _acting;
  bool get ready => _wallet != null && _config != null;

  Money? money(int? minor) =>
      minor == null || _config == null ? null : _config!.money(minor);

  /// Montant saisi en unités (« 5000 », « 12,50 ») vers unités mineures ;
  /// `null` si invalide. Les décimales viennent de la devise du pays.
  int? parseAmount(String text) {
    final config = _config;
    if (config == null) return null;
    final normalized = text.trim().replaceAll(' ', '').replaceAll(',', '.');
    final value = num.tryParse(normalized);
    if (value == null || value <= 0) return null;
    final minor = (value * math.pow(10, config.currency.minorUnits)).round();
    return minor > 0 ? minor : null;
  }

  Future<void> load() async {
    _failure = null;
    setBusy(true);
    final config = await service.countryConfig();
    final wallet = await service.wallet();
    switch ((config, wallet)) {
      case (Ok(value: final c), Ok(value: final w)):
        _config = c;
        _wallet = w;
      case (Err(:final failure), _) || (_, Err(:final failure)):
        _failure = failure;
    }
    setBusy(false);
  }

  Future<bool> topup(String amountText) =>
      _act(amountText, service.topupSimulated);

  /// Retrait simulé vers le fournisseur (spec 043).
  Future<bool> withdraw(String amountText) =>
      _act(amountText, service.withdrawSimulated);

  /// Code de recharge en cash ; null : indisponible.
  Future<({String code, DateTime expiresAt})?> cashCode() async =>
      (await service.cashTopupCode()).valueOrNull;

  Future<bool> transfer({
    required String amountText,
    String? fromPocket,
    String? toPocket,
  }) => _act(
    amountText,
    (amount) => service.transfer(
      amountMinor: amount,
      fromPocket: fromPocket,
      toPocket: toPocket,
    ),
  );

  Future<bool> createPocket({
    required String name,
    String goalText = '',
    String roundUpText = '',
  }) async {
    final goal = goalText.trim().isEmpty ? null : parseAmount(goalText);
    final roundUp = roundUpText.trim().isEmpty
        ? null
        : parseAmount(roundUpText);
    if (name.trim().isEmpty ||
        (goalText.trim().isNotEmpty && goal == null) ||
        (roundUpText.trim().isNotEmpty && roundUp == null)) {
      _walletError = WalletError.amount;
      notifyListeners();
      return false;
    }
    return await _run(
      () => service.createPocket(
        name: name.trim(),
        goalMinor: goal,
        roundUpMinor: roundUp,
      ),
    );
  }

  Future<bool> archive(String pocketId) =>
      _run(() => service.archivePocket(pocketId));

  void clearError() {
    _walletError = null;
    notifyListeners();
  }

  Future<bool> _act(
    String amountText,
    Future<Result<Wallet>> Function(int amount) write,
  ) async {
    final amount = parseAmount(amountText);
    if (amount == null) {
      _walletError = WalletError.amount;
      notifyListeners();
      return false;
    }
    return await _run(() => write(amount));
  }

  Future<bool> _run(Future<Result<Wallet>> Function() write) async {
    if (_acting) return false;
    _acting = true;
    _walletError = null;
    notifyListeners();
    final result = await write();
    _acting = false;
    switch (result) {
      case Ok(:final value):
        _wallet = value;
        notifyListeners();
        return true;
      case Err(:final failure):
        _walletError = walletErrorOf(failure);
        notifyListeners();
        return false;
    }
  }
}
