import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/store/onboarding/store_onboarding_viewmodel.dart';
import 'package:dym_vendor/features/store/store_service.dart';
import 'package:stacked/stacked.dart';

/// « Ma boutique » : ouverture en un geste (US4) et accès aux réglages.
class MyStoreViewModel extends BaseViewModel {
  new({required this._service, required this._onEdit});

  final StoreService _service;

  /// Ouvre le réglage d'une étape ; se termine au retour.
  final Future<void> Function(StoreStep step) _onEdit;

  MyStore? _store;
  CountryConfig? _config;
  Failure? _loadFailure;
  Failure? _toggleFailure;
  bool _toggling = false;

  MyStore? get store => _store;
  CountryConfig? get config => _config;
  Failure? get loadFailure => _loadFailure;
  Failure? get toggleFailure => _toggleFailure;
  bool get toggling => _toggling;
  bool get offline => _loadFailure is NetworkFailure;
  bool get ready => _store != null && _config != null;
  bool get suspended => _store?.status == StoreStatus.suspended;

  Future<void> load() async {
    _loadFailure = null;
    setBusy(true);
    final config = await _service.countryConfig();
    final store = await _service.myStore();
    switch ((config, store)) {
      case (Ok(value: final cfg), Ok(value: final current?)):
        _config = cfg;
        _store = current;
      case (Ok(), Ok()):
        _loadFailure = const NotFoundFailure('aucune boutique');
      case (Err(:final failure), _) || (_, Err(:final failure)):
        _loadFailure = failure;
    }
    setBusy(false);
  }

  /// Ouvre ou ferme la boutique ; l'interrupteur suit l'état renvoyé par la
  /// base.
  Future<void> setOpen({required bool open}) async {
    if (_toggling || suspended) return;
    _toggling = true;
    _toggleFailure = null;
    notifyListeners();
    final result = await _service.setOpen(open: open);
    switch (result) {
      case Ok(value: final current?):
        _store = current;
      case Ok():
        _toggleFailure = const NotFoundFailure('aucune boutique');
      case Err(:final failure):
        _toggleFailure = failure;
    }
    _toggling = false;
    notifyListeners();
  }

  /// Réglage d'une étape puis relecture de la boutique.
  Future<void> edit(StoreStep step) async {
    await _onEdit(step);
    final result = await _service.myStore();
    if (result case Ok(value: final current?)) {
      _store = current;
      notifyListeners();
    }
  }
}
