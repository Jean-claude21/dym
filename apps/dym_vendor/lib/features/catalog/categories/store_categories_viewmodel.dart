import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:stacked/stacked.dart';

/// « Mes catégories » (écran 27) : créer, renommer, ordonner, archiver.
class StoreCategoriesViewModel extends BaseViewModel {
  new({required this._service});

  final CatalogService _service;

  static const nameMax = 40;

  List<StoreCategory> _categories = const [];
  Failure? _loadFailure;
  Failure? _actionFailure;
  bool _loaded = false;
  String newName = '';

  List<StoreCategory> get active =>
      _categories.where((c) => !c.isArchived).toList();
  List<StoreCategory> get archived =>
      _categories.where((c) => c.isArchived).toList();
  Failure? get loadFailure => _loadFailure;
  Failure? get actionFailure => _actionFailure;
  bool get duplicate => _actionFailure is ConflictFailure;
  bool get offline => (_loadFailure ?? _actionFailure) is NetworkFailure;
  bool get ready => _loaded;
  bool get canAdd =>
      newName.trim().isNotEmpty && newName.trim().length <= nameMax && !isBusy;

  Future<void> load() async {
    _loadFailure = null;
    setBusy(true);
    final result = await _service.storeCategories();
    switch (result) {
      case Ok(:final value):
        _categories = value;
        _loaded = true;
      case Err(:final failure):
        _loadFailure = failure;
    }
    setBusy(false);
  }

  void setNewName(String value) {
    newName = value;
    _actionFailure = null;
    notifyListeners();
  }

  /// Ajoute ; `true` si la catégorie est créée (le champ peut se vider).
  Future<bool> add() async {
    if (!canAdd) return false;
    final ok = await _run(
      () => _service.saveStoreCategory(_service.newId(), newName.trim()),
    );
    if (ok) newName = '';
    notifyListeners();
    return ok;
  }

  Future<bool> rename(StoreCategory category, String name) =>
      _run(() => _service.saveStoreCategory(category.id, name.trim()));

  Future<bool> archive(StoreCategory category, {required bool archived}) =>
      _run(
        () => _service.archiveStoreCategory(category.id, archived: archived),
      );

  /// Déplace une catégorie active de [oldIndex] à [newIndex] (position
  /// finale, `onReorderItem`).
  Future<void> reorder(int oldIndex, int newIndex) async {
    final ids = active.map((c) => c.id).toList();
    if (oldIndex == newIndex) return;
    ids.insert(newIndex, ids.removeAt(oldIndex));
    // Affichage immédiat, puis état serveur.
    final byId = {for (final c in _categories) c.id: c};
    _categories = [...ids.map((id) => byId[id]!), ...archived];
    notifyListeners();
    await _run(() => _service.reorderStoreCategories(ids));
  }

  Future<bool> _run(
    Future<Result<List<StoreCategory>>> Function() action,
  ) async {
    _actionFailure = null;
    setBusy(true);
    final result = await action();
    setBusy(false);
    switch (result) {
      case Ok(:final value):
        _categories = value;
        notifyListeners();
        return true;
      case Err(:final failure):
        _actionFailure = failure;
        notifyListeners();
        return false;
    }
  }
}
