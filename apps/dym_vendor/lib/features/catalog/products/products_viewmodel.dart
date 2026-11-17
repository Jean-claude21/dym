import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:stacked/stacked.dart';

/// « Mes produits » (écran 24) : filtres par catégorie, stock en un geste
/// (US2), archivage.
class ProductsViewModel extends BaseViewModel {
  new({
    required this._service,
    required this._onEdit,
    required this._onCategories,
    this._onImport,
    this._offline,
  });

  /// File hors ligne (spec 107) : rupture gardée sans réseau, envoyée au
  /// retour du réseau. Nulle : pas de file (échec affiché).
  final OfflineQueue? _offline;
  Timer? _replayTimer;

  /// Gestes en attente du réseau.
  int get offlineCount => _offline?.items.length ?? 0;

  /// Import en masse (spec 081) ; nul : pas de bouton.
  final Future<void> Function()? _onImport;
  bool get canImport => _onImport != null;

  Future<void> importProducts() async {
    final open = _onImport;
    if (open == null) return;
    await open();
    await load();
  }

  final CatalogService _service;

  /// Ouvre l'éditeur (`null` : nouveau produit) ; se termine au retour.
  final Future<void> Function(Product? product) _onEdit;

  /// Ouvre « Mes catégories » ; se termine au retour.
  final Future<void> Function() _onCategories;

  List<Product> _products = const [];
  List<StoreCategory> _categories = const [];
  CountryConfig? _config;
  Failure? _loadFailure;
  Failure? _actionFailure;
  final Set<String> _pending = {};

  /// Catégorie filtrée (`null` : tout).
  String? filter;

  /// Affiche les archivés.
  bool showArchived = false;

  CatalogService get service => _service;
  CountryConfig? get config => _config;
  Failure? get loadFailure => _loadFailure;
  Failure? get actionFailure => _actionFailure;
  bool get offline => _loadFailure is NetworkFailure;
  bool get ready => _config != null && _loadFailure == null;
  bool get isEmpty => _products.where((p) => !p.isArchived).isEmpty;
  bool get hasArchived => _products.any((p) => p.isArchived);
  bool isPending(String id) => _pending.contains(id);

  /// Catégories actives (filtres).
  List<StoreCategory> get categories =>
      _categories.where((c) => !c.isArchived).toList();

  List<Product> get visible => [
    for (final p in _products)
      if (showArchived
          ? p.isArchived
          : !p.isArchived &&
                (filter == null || p.storeCategoryIds.contains(filter)))
        p,
  ];

  Future<void> load() async {
    _loadFailure = null;
    unawaited(replayOffline());
    setBusy(true);
    final results = await Future.wait<Result<Object>>([
      _service.countryConfig(),
      _service.products(),
      _service.storeCategories(),
    ]);
    switch (results) {
      case [
        Ok(value: final CountryConfig config),
        Ok(value: final List<Product> products),
        Ok(value: final List<StoreCategory> categories),
      ]:
        _config = config;
        _products = products;
        _categories = categories;
        if (filter != null && !categories.any((c) => c.id == filter)) {
          filter = null;
        }
      default:
        _loadFailure = results
            .whereType<Err<Object>>()
            .map((e) => e.failure)
            .first;
    }
    setBusy(false);
  }

  void selectFilter(String? categoryId) {
    filter = categoryId;
    showArchived = false;
    notifyListeners();
  }

  void selectArchived() {
    filter = null;
    showArchived = true;
    notifyListeners();
  }

  /// Rupture ou réactivation ; l'interrupteur suit l'état renvoyé.
  /// Rupture en un geste, optimiste (PARCOURS §8) : l'interrupteur bascule
  /// tout de suite ; il revient si la base refuse.
  final _optimistic = <String, bool>{};

  /// Disponibilité affichée : le geste en cours, sinon celle de la base.
  bool available(Product product) =>
      _optimistic[product.id] ?? product.isAvailable;

  Future<void> setAvailable(Product product, {required bool available}) async {
    if (_pending.contains(product.id)) return;
    _optimistic[product.id] = available;
    _pending.add(product.id);
    _actionFailure = null;
    notifyListeners();
    final result = await _service.setAvailable(
      product.id,
      available: available,
    );
    final queue = _offline;
    switch (result) {
      case Ok(:final value):
        _replace(value);
        _optimistic.remove(product.id);
      case Err(failure: NetworkFailure()) when queue != null:
        // Sans réseau : l'interrupteur garde le geste, envoyé plus tard.
        await queue.add(
          OfflineGesture(
            id: 'stock:${product.id}',
            kind: 'stock',
            payload: {'product': product.id, 'available': available},
          ),
        );
        _scheduleReplay();
      case Err(:final failure):
        _actionFailure = failure;
        _optimistic.remove(product.id);
    }
    _pending.remove(product.id);
    notifyListeners();
  }

  void _replace(Product value) {
    _products = [
      for (final p in _products)
        if (p.id == value.id) value else p,
    ];
  }

  void _scheduleReplay() {
    _replayTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(replayOffline()),
    );
  }

  /// Rejoue les gestes gardés hors ligne (au chargement, puis toutes les
  /// 30 s tant qu'il en reste).
  Future<void> replayOffline() async {
    final queue = _offline;
    if (queue == null) return;
    await queue.replay((g) async {
      if (g.kind != 'stock') return ReplayOutcome.dropped;
      final id = g.payload['product'] as String;
      final available = g.payload['available'] as bool;
      final result = await _service.setAvailable(id, available: available);
      switch (result) {
        case Ok(:final value):
          _replace(value);
          _optimistic.remove(id);
          return ReplayOutcome.done;
        case Err(failure: NetworkFailure()):
          _optimistic[id] = available;
          return ReplayOutcome.retry;
        case Err(:final failure):
          _actionFailure = failure;
          _optimistic.remove(id);
          return ReplayOutcome.dropped;
      }
    });
    if (queue.isEmpty) {
      _replayTimer?.cancel();
      _replayTimer = null;
    } else {
      _scheduleReplay();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _replayTimer?.cancel();
    super.dispose();
  }

  /// Date d'arrivage (spec 033) ; nulle : retirée.
  Future<void> setArrival(Product product, DateTime? arrivalOn) =>
      _apply(product.id, () => _service.setArrival(product.id, arrivalOn));

  Future<void> archive(Product product, {required bool archived}) => _apply(
    product.id,
    () => _service.archive(product.id, archived: archived),
  );

  Future<void> deleteDraft(Product product) async {
    _pending.add(product.id);
    _actionFailure = null;
    notifyListeners();
    final result = await _service.deleteDraft(product.id);
    if (result case Err(:final failure)) {
      _actionFailure = failure;
    } else {
      _products = [
        for (final p in _products)
          if (p.id != product.id) p,
      ];
    }
    _pending.remove(product.id);
    notifyListeners();
  }

  Future<void> _apply(
    String id,
    Future<Result<Product>> Function() action,
  ) async {
    if (_pending.contains(id)) return;
    _pending.add(id);
    _actionFailure = null;
    notifyListeners();
    final result = await action();
    switch (result) {
      case Ok(:final value):
        _products = [
          for (final p in _products)
            if (p.id == id) value else p,
        ];
      case Err(:final failure):
        _actionFailure = failure;
    }
    _pending.remove(id);
    notifyListeners();
  }

  Future<void> add() async {
    await _onEdit(null);
    await load();
  }

  Future<void> edit(Product product) async {
    await _onEdit(product);
    await load();
  }

  Future<void> manageCategories() async {
    await _onCategories();
    await load();
  }

  /// Unité lisible d'un produit (« la pièce »).
  String? unitLabel(Product product, String locale) => _config?.units
      .where((u) => u.id == product.unitId)
      .firstOrNull
      ?.label
      .resolve(locale);

  /// Prix de base en devise du pays.
  Money? price(Product product) {
    final config = _config;
    final amount = product.priceMinor;
    if (config == null || amount == null) return null;
    return config.money(amount);
  }
}
