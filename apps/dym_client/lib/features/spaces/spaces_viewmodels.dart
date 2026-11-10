import 'dart:math' as math;

import 'package:dym_client/features/spaces/spaces_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:stacked/stacked.dart';

/// Erreurs affichées par les espaces.
enum SpaceError {
  name,
  budget,
  unknownCode,
  otherCountry,
  full,
  tooMany,
  cartEmpty,
  budgetExceeded,
  notPayer,
  pocketInsufficient,
  walletInsufficient,
  spaceBalance,
  amount,
  offline,
  generic,
}

SpaceError spaceErrorOf(Failure failure) => switch (failure) {
  NetworkFailure() => SpaceError.offline,
  NotFoundFailure(message: 'unknown_code') => SpaceError.unknownCode,
  ValidationFailure(message: 'invalid_name') => SpaceError.name,
  ValidationFailure(message: 'invalid_budget') => SpaceError.budget,
  ValidationFailure(message: 'other_country') => SpaceError.otherCountry,
  ValidationFailure(message: 'space_full') => SpaceError.full,
  ValidationFailure(message: 'too_many_spaces') => SpaceError.tooMany,
  ValidationFailure(message: 'cart_empty' || 'space_empty') =>
    SpaceError.cartEmpty,
  ValidationFailure(message: 'budget_exceeded') => SpaceError.budgetExceeded,
  ValidationFailure(message: 'space_pocket_insufficient') =>
    SpaceError.pocketInsufficient,
  ValidationFailure(message: 'wallet_insufficient') =>
    SpaceError.walletInsufficient,
  ValidationFailure(message: 'wallet_amount_invalid') => SpaceError.amount,
  ValidationFailure(message: 'space_balance') => SpaceError.spaceBalance,
  ForbiddenFailure() => SpaceError.notPayer,
  _ => SpaceError.generic,
};

/// Montant saisi en unités (« 30 000 ») vers unités mineures de la devise du
/// pays ; `null` si vide ou invalide.
int? amountFromText(CountryConfig? config, String text) {
  if (config == null) return null;
  final value = num.tryParse(
    text.trim().replaceAll(' ', '').replaceAll(',', '.'),
  );
  if (value == null || value <= 0) return null;
  final minor = (value * math.pow(10, config.currency.minorUnits)).round();
  return minor > 0 ? minor : null;
}

/// « Mes espaces » : liste, création, adhésion par code.
class SpacesViewModel extends BaseViewModel {
  new({required this.service});

  final SpacesService service;
  List<SpaceSummary> spaces = const [];
  CountryConfig? config;
  bool ready = false;
  Failure? failure;
  SpaceError? problem;
  bool acting = false;

  String? money(int? minor) =>
      minor == null ? null : config?.money(minor).format();

  Future<void> load() async {
    failure = null;
    setBusy(true);
    config = (await service.countryConfig()).valueOrNull;
    switch (await service.spaces()) {
      case Ok(:final value):
        spaces = value;
        ready = true;
      case Err(failure: final f):
        failure = f;
    }
    setBusy(false);
  }

  Future<Space?> _act(Future<Result<Space>> Function() call) async {
    if (acting) return null;
    acting = true;
    problem = null;
    notifyListeners();
    final result = await call();
    acting = false;
    Space? space;
    switch (result) {
      case Ok(:final value):
        space = value;
      case Err(failure: final f):
        problem = spaceErrorOf(f);
    }
    notifyListeners();
    return space;
  }

  /// Budget vide : sans budget ; budget illisible : refusé à l'écran.
  Future<Space?> create(String name, String budgetText) async {
    if (name.trim().isEmpty) {
      problem = SpaceError.name;
      notifyListeners();
      return null;
    }
    final budget = budgetText.trim().isEmpty
        ? null
        : amountFromText(config, budgetText);
    if (budgetText.trim().isNotEmpty && budget == null) {
      problem = SpaceError.budget;
      notifyListeners();
      return null;
    }
    return await _act(() => service.create(name, monthlyBudgetMinor: budget));
  }

  Future<Space?> join(String code) => _act(() => service.join(code));
}

/// Un espace : membres, budget, panier commun, validation.
class SpaceViewModel extends BaseViewModel {
  new({required this.service, required this.spaceId});

  final SpacesService service;
  final String spaceId;
  Space? space;
  CountryConfig? config;
  Failure? failure;
  SpaceError? problem;
  bool acting = false;

  /// Articles non ajoutés à la dernière validation.
  List<String> skipped = const [];

  /// Payer avec la poche commune (spec 032).
  bool usePocket = false;

  /// Montant financé par la poche à la dernière validation.
  int fundedMinor = 0;

  void setUsePocket({required bool value}) {
    usePocket = value;
    notifyListeners();
  }

  /// Versement saisi en unités de la devise ; `false` si refusé.
  Future<bool> contribute(String amountText) async {
    final amount = amountFromText(config, amountText);
    if (amount == null) {
      problem = SpaceError.amount;
      notifyListeners();
      return false;
    }
    return await _apply(() => service.contribute(spaceId, amount));
  }

  String? money(int? minor) =>
      minor == null ? null : config?.money(minor).format();

  Future<void> load() async {
    failure = null;
    setBusy(true);
    config = (await service.countryConfig()).valueOrNull;
    switch (await service.space(spaceId)) {
      case Ok(:final value):
        space = value;
      case Err(failure: final f):
        failure = f;
    }
    setBusy(false);
  }

  Future<bool> _apply(Future<Result<Space>> Function() call) async {
    if (acting) return false;
    acting = true;
    problem = null;
    notifyListeners();
    final result = await call();
    acting = false;
    switch (result) {
      case Ok(:final value):
        space = value;
      case Err(failure: final f):
        problem = spaceErrorOf(f);
    }
    notifyListeners();
    return result.isOk;
  }

  Future<bool> setQuantity(SpaceItem item, int quantity) =>
      _apply(() => service.setItem(spaceId, item.variantId, quantity));

  Future<bool> setRole(SpaceMember member, SpaceRole role) =>
      _apply(() => service.setRole(spaceId, member.userId, role));

  Future<bool> sendCart() => _apply(() => service.sendCart(spaceId));

  /// Retire un membre (ou soi-même : quitter).
  Future<bool> remove(SpaceMember member) async {
    problem = null;
    final result = await service.removeMember(spaceId, member.userId);
    if (result case Err(:final failure)) problem = spaceErrorOf(failure);
    if (result.isOk && !member.isMe) await load();
    notifyListeners();
    return result.isOk;
  }

  Future<bool> delete() async {
    final result = await service.delete(spaceId);
    if (result case Err(:final failure)) {
      problem = spaceErrorOf(failure);
      notifyListeners();
    }
    return result.isOk;
  }

  /// `true` : au moins un article est passé au panier.
  Future<bool> validate() async {
    if (acting) return false;
    acting = true;
    problem = null;
    skipped = const [];
    notifyListeners();
    final funding = usePocket && (space?.pocketBalanceMinor ?? 0) > 0;
    final total = space?.totalMinor ?? 0;
    final result = await service.validate(spaceId, usePocket: funding);
    acting = false;
    var ok = false;
    fundedMinor = 0;
    switch (result) {
      case Ok(:final value):
        skipped = value.skipped;
        if (funding && value.added > 0) fundedMinor = total;
        ok = value.added > 0;
        if (await service.space(spaceId) case Ok(:final value)) {
          space = value;
        }
      case Err(failure: final f):
        problem = spaceErrorOf(f);
    }
    notifyListeners();
    return ok;
  }
}
