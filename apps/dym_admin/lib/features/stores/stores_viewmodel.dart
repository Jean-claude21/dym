import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';

/// Boutiques (écran 55) : liste par statut, recherche, profil, suspension,
/// réactivation et corrections.
class AdminStoresViewModel extends AdminViewModel {
  new({required this.service});

  final AdminService service;

  AdminStoreStatus _status = AdminStoreStatus.active;
  String _query = '';
  AdminStorePage? _page;
  String? _selectedId;
  AdminStore? _store;
  bool _loadingStore = false;
  bool _acting = false;
  Failure? _actionFailure;
  List<AdminZone> _zones = const [];

  AdminStoreStatus get status => _status;
  AdminStorePage? get page => _page;
  bool get ready => _page != null && !failed;
  String? get selectedId => _selectedId;
  AdminStore? get store => _store;
  bool get loadingStore => _loadingStore;
  bool get acting => _acting;
  Failure? get actionFailure => _actionFailure;

  /// Quartiers actifs du pays de la boutique (corrections).
  List<AdminZone> get zones => _zones;

  Future<void> load() => run(service.currencies, () async {
    final result = await service.stores(
      status: _status,
      query: _query.isEmpty ? null : _query,
    );
    if (result case Ok(:final value)) _page = value;
    return result.failureOrNull;
  });

  Future<void> selectStatus(AdminStoreStatus value) async {
    _status = value;
    await load();
  }

  Future<void> search(String value) async {
    _query = value.trim();
    await load();
  }

  Future<void> select(String id) async {
    _selectedId = id;
    _store = null;
    _loadingStore = true;
    _actionFailure = null;
    notifyListeners();
    final result = await service.store(id);
    if (_selectedId != id) return;
    _loadingStore = false;
    switch (result) {
      case Ok(:final value):
        _store = value;
      case Err(:final failure):
        _actionFailure = failure;
    }
    notifyListeners();
  }

  void close() {
    _selectedId = null;
    _store = null;
    notifyListeners();
  }

  /// Quartiers proposés à la correction.
  Future<void> loadZones() async {
    final country = _store?.row.countryCode;
    if (country == null) return;
    if (await service.geography(country) case Ok(:final value)) {
      _zones = [
        for (final city in value)
          for (final z in city.zones)
            if (z.isActive) z,
      ];
      notifyListeners();
    }
  }

  Future<bool> setSuspended(String reason, {required bool suspended}) => _act(
    (id) => service.setStoreStatus(id, suspended: suspended, reason: reason),
  );

  Future<bool> update(Map<String, Object?> patch, String reason) =>
      _act((id) => service.updateStore(id, patch, reason));

  /// Vue de la vendeuse (A-VEN-06), consultation journalisée.
  Future<Result<AdminVendorView>> vendorView() {
    final current = _store;
    if (current == null) {
      return Future.value(const Err(ValidationFailure('no_store')));
    }
    return service.vendorView(current.id);
  }

  /// Suppression du compte vendeuse (A-VEN-07) : refusée si la boutique a
  /// déjà des commandes.
  Future<bool> deleteVendor(String reason) async {
    final current = _store;
    if (current == null || _acting) return false;
    _acting = true;
    _actionFailure = null;
    notifyListeners();
    final result = await service.deleteVendor(current.id, reason);
    _acting = false;
    switch (result) {
      case Ok():
        _selectedId = null;
        _store = null;
        if (await service.stores(status: _status) case Ok(:final value)) {
          _page = value;
        }
      case Err(:final failure):
        _actionFailure = failure;
    }
    notifyListeners();
    return result.isOk;
  }

  Future<bool> _act(
    Future<Result<AdminStore>> Function(String id) gesture,
  ) async {
    final current = _store;
    if (current == null || _acting) return false;
    _acting = true;
    _actionFailure = null;
    notifyListeners();
    final result = await gesture(current.id);
    switch (result) {
      case Ok(:final value):
        _store = value;
        if (await service.stores(status: _status) case Ok(:final value)) {
          _page = value;
        }
      case Err(:final failure):
        _actionFailure = failure;
    }
    _acting = false;
    notifyListeners();
    return result.isOk;
  }
}
