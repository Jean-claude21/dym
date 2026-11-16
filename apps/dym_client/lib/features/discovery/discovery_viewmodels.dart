import 'dart:async';
import 'dart:typed_data';

import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/search_ai_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:stacked/stacked.dart';

/// Base : chargement, échec, hors ligne.
abstract class _LoadingViewModel extends BaseViewModel {
  Failure? _failure;

  Failure? get failure => _failure;
  bool get offline => _failure is NetworkFailure;
  bool get failed => _failure != null;

  Future<void> load();

  /// Exécute [work] ; tout échec est conservé pour l'écran de reprise.
  Future<void> run(Future<Failure?> Function() work) async {
    _failure = null;
    setBusy(true);
    _failure = await work();
    setBusy(false);
  }
}

// ------------------------------------------------------------------ accueil

/// Accueil (écran 02) : quartier, estimation, boutiques, rayons (US1).
class DiscoveryHomeViewModel extends _LoadingViewModel {
  new({required this._service});

  final DiscoveryService _service;

  CountryConfig? _config;
  DiscoverResult _result = const DiscoverResult();
  bool _locating = false;
  bool _locationUnavailable = false;
  ZoneMatch? _suggestion;

  DiscoveryService get service => _service;
  CountryConfig? get config => _config;
  DiscoverResult get result => _result;

  /// Fil personnel (spec 027) ; vide s'il n'a pas pu être chargé.
  HomeFeed get feed => _feed;
  HomeFeed _feed = const HomeFeed();
  bool get ready => _config != null && !failed;
  bool get locating => _locating;
  bool get locationUnavailable => _locationUnavailable;

  /// Position hors des zones desservies (spec 065).
  bool get locationOutside => _locationOutside;
  bool _locationOutside = false;
  ZoneMatch? get suggestion => _suggestion;

  String? get zoneId => _service.zone.value;

  Zone? get zone => _config?.zones.where((z) => z.id == zoneId).firstOrNull;

  String? get cityName {
    final z = zone;
    return z == null
        ? null
        : _config?.cities.where((c) => c.id == z.cityId).firstOrNull?.name;
  }

  List<Category> get aisles => _config?.topCategories ?? const [];

  /// Marché en carte plutôt qu'en liste (spec 095).
  bool get showMap => _showMap;
  bool _showMap = false;

  void setShowMap({required bool value}) {
    if (_showMap == value) return;
    _showMap = value;
    notifyListeners();
  }

  @override
  Future<void> load() => run(() async {
    final config = await _service.countryConfig();
    if (config case Err(:final failure)) return failure;
    _config = config.valueOrNull;
    final (result, feed) = await (
      _service.discover(),
      _service.homeFeed(),
    ).wait;
    // Fil personnel : un échec n'empêche pas d'afficher boutiques et rayons.
    _feed = feed.valueOrNull ?? const HomeFeed();
    switch (result) {
      case Ok(:final value):
        _result = value;
        return null;
      case Err(:final failure):
        return failure;
    }
  });

  Future<void> selectZone(String zoneId) async {
    _suggestion = null;
    _service.selectZone(zoneId);
    await load();
  }

  /// Propose le quartier le plus proche de la position.
  Future<void> locate() async {
    _locating = true;
    _locationUnavailable = false;
    _locationOutside = false;
    _suggestion = null;
    notifyListeners();
    final result = await _service.locateZone();
    _locating = false;
    switch (result) {
      case Ok(value: final match?) when !match.covered:
        _locationOutside = true;
      case Ok(value: final match?):
        _suggestion = match;
      case Ok() || Err():
        _locationUnavailable = true;
    }
    notifyListeners();
  }

  Future<void> confirmSuggestion() async {
    final match = _suggestion;
    if (match != null) await selectZone(match.zoneId);
  }

  void dismissSuggestion() {
    _suggestion = null;
    _locationUnavailable = false;
    _locationOutside = false;
    notifyListeners();
  }
}

// ------------------------------------------------------------------ rayon

/// Rayon (écran 03) : produits disponibles du quartier, sous-rayons compris,
/// filtres par origine ou sous-rayon (US3).
class AisleViewModel extends _LoadingViewModel {
  new({required this._service, required this.categoryId});

  final DiscoveryService _service;
  final String categoryId;

  static const pageSize = 20;

  CountryConfig? _config;
  SearchResults _results = const SearchResults();
  bool _loadingMore = false;

  /// Origine filtrée (`null` : toutes).
  String? origin;

  /// Sous-rayon filtré (`null` : tout le rayon).
  String? subCategoryId;

  DiscoveryService get service => _service;
  CountryConfig? get config => _config;
  List<CatalogItem> get products => _results.products;
  int get total => _results.total;
  bool get ready => _config != null && !failed;
  bool get hasMore => products.length < total;
  bool get loadingMore => _loadingMore;

  Category? get category =>
      _config?.categories.where((c) => c.id == categoryId).firstOrNull;

  List<Category> get subCategories =>
      _config?.subCategoriesOf(categoryId) ?? const [];

  SearchQuery _query(int offset) => SearchQuery(
    categoryId: subCategoryId ?? categoryId,
    origin: origin,
    availableOnly: true,
    offset: offset,
  );

  @override
  Future<void> load() => run(() async {
    final config = await _service.countryConfig();
    if (config case Err(:final failure)) return failure;
    _config = config.valueOrNull;
    final result = await _service.search(_query(0));
    switch (result) {
      case Ok(:final value):
        _results = value;
        return null;
      case Err(:final failure):
        return failure;
    }
  });

  /// Où acheter (marché, maison, boutique) : filtre sur la vendeuse,
  /// indépendant du sous-rayon.
  Future<void> selectOrigin(String? code) async {
    origin = code;
    await load();
  }

  /// Sous-rayon (Tomates, Feuilles…) : catégorie de produit.
  Future<void> selectSubCategory(String? id) async {
    subCategoryId = id;
    await load();
  }

  Future<void> loadMore() async {
    if (!hasMore || _loadingMore) return;
    _loadingMore = true;
    notifyListeners();
    final result = await _service.search(_query(products.length));
    if (result case Ok(:final value)) {
      _results = SearchResults(
        total: value.total,
        products: [...products, ...value.products],
      );
    }
    _loadingMore = false;
    notifyListeners();
  }
}

// ------------------------------------------------------------------ boutique

/// Page boutique (écran 04) : présentation et produits par catégorie (US3).
class StorePageViewModel extends _LoadingViewModel {
  new({required this._service, required this.storeId});

  final DiscoveryService _service;
  final String storeId;

  CountryConfig? _config;
  StorePageData? _page;

  /// Catégorie de la boutique filtrée (`null` : tout).
  String? category;

  DiscoveryService get service => _service;
  CountryConfig? get config => _config;
  StorePageData? get page => _page;
  bool get ready => _page != null && _config != null && !failed;
  bool get gone => failure is NotFoundFailure;

  List<CatalogItem> get products => [
    for (final p in _page?.products ?? const <CatalogItem>[])
      if (category == null || p.storeCategoryIds.contains(category)) p,
  ];

  @override
  Future<void> load() => run(() async {
    final config = await _service.countryConfig();
    if (config case Err(:final failure)) return failure;
    _config = config.valueOrNull;
    final result = await _service.storePage(storeId);
    switch (result) {
      case Ok(:final value):
        _page = value;
        return null;
      case Err(:final failure):
        return failure;
    }
  });

  void selectCategory(String? id) {
    category = id;
    notifyListeners();
  }
}

// ------------------------------------------------------------------ fiche

/// Fiche produit (écran 28) : photos, variantes, délai, disponibilité (US4).
class ProductPageViewModel extends _LoadingViewModel {
  new({required this._service, required this.productId});

  final DiscoveryService _service;
  final String productId;

  CountryConfig? _config;
  ProductPageData? _page;
  String? _variantId;
  int photoIndex = 0;
  int _quantity = 1;

  /// « De la même boutique » (planche 08) : jusqu'à 4 autres produits.
  List<CatalogItem> related = const [];

  DiscoveryService get service => _service;
  CountryConfig? get config => _config;
  ProductPageData? get page => _page;
  bool get ready => _page != null && _config != null && !failed;
  bool get gone => failure is NotFoundFailure;

  PublicVariant? get variant =>
      _page?.variants.where((v) => v.id == _variantId).firstOrNull;

  /// Prix de la variante choisie (sinon prix de base).
  int? get priceMinor => variant?.priceMinor ?? _page?.item.priceMinor;

  bool get available =>
      (_page?.item.available ?? false) && (variant?.available ?? true);

  @override
  Future<void> load() => run(() async {
    final config = await _service.countryConfig();
    if (config case Err(:final failure)) return failure;
    _config = config.valueOrNull;
    final result = await _service.productPage(productId);
    switch (result) {
      case Ok(:final value):
        _page = value;
        // Première variante disponible, sinon la première.
        _variantId =
            (value.variants.where((v) => v.available).firstOrNull ??
                    value.variants.firstOrNull)
                ?.id;
        _service.productViewed(productId);
        // Facultatif : la fiche s'affiche même si la boutique ne répond pas.
        final store = await _service.storePage(value.store.id);
        related = [
          for (final p in store.valueOrNull?.products ?? const <CatalogItem>[])
            if (p.id != productId) p,
        ].take(4).toList();
        return null;
      case Err(:final failure):
        return failure;
    }
  });

  void selectVariant(String id) {
    _variantId = id;
    notifyListeners();
  }

  /// Quantité à ajouter au panier (1 à 99).
  int get quantity => _quantity;

  void setQuantity(int value) {
    _quantity = value.clamp(1, 99);
    notifyListeners();
  }

  void showPhoto(int index) {
    photoIndex = index;
    notifyListeners();
  }
}

// ------------------------------------------------------------------ recherche

/// Onglet des résultats.
enum SearchTab { all, products, stores }

/// Filtres modifiables (écran 30).
class SearchFilters {
  const new({
    this.sort = SearchSort.relevance,
    this.origin,
    this.categoryId,
    this.minPriceMinor,
    this.maxPriceMinor,
    this.availableOnly = false,
  });

  final SearchSort sort;
  final String? origin;
  final String? categoryId;
  final int? minPriceMinor;
  final int? maxPriceMinor;
  final bool availableOnly;

  bool get priceValid =>
      minPriceMinor == null ||
      maxPriceMinor == null ||
      minPriceMinor! <= maxPriceMinor!;
}

/// Recherche (écrans 29 et 30) : texte, filtres, tris, pagination (US2).
class SearchViewModel extends BaseViewModel {
  new({
    required this._service,
    this.debounce = const Duration(milliseconds: 350),
    this.ai,
  });

  final DiscoveryService _service;
  final Duration debounce;

  /// Recherche augmentée (spec 018) ; absente : recherche texte seule.
  final SearchAiService? ai;

  /// Voix et photo proposées (flag `ai_search` du pays).
  bool aiEnabled = false;
  List<SearchHistoryEntry> history = const [];
  List<SearchSuggestion> suggestions = const [];

  /// Recherche lancée depuis une photo : vignette et texte reconnu (72).
  ({Uint8List bytes, String query})? photo;
  bool analyzingPhoto = false;

  /// Échec de la photo ou rien de reconnu (`Ok(null)`).
  Result<void>? photoOutcome;
  Timer? _suggestTimer;
  int _suggestGeneration = 0;

  static const minLength = 2;
  static const pageSize = 20;

  CountryConfig? _config;
  SearchResults? _results;
  Failure? _failure;
  Timer? _timer;
  bool _loadingMore = false;
  int _generation = 0;

  String text = '';
  SearchTab tab = SearchTab.all;
  SearchFilters filters = const SearchFilters();

  DiscoveryService get service => _service;
  CountryConfig? get config => _config;
  SearchResults? get results => _results;
  Failure? get failure => _failure;
  bool get offline => _failure is NetworkFailure;
  bool get tooShort => text.trim().length < minLength;
  bool get loadingMore => _loadingMore;
  bool get hasMore => (_results?.products.length ?? 0) < (_results?.total ?? 0);

  int get activeFilters => _query(0).activeFilters;

  /// Rayons proposés avant la saisie (design « Épuré »).
  List<Category> get aisles => _config?.topCategories ?? const [];

  Future<void> init({String initialText = '', PhotoSource? photo}) async {
    final config = await _service.countryConfig();
    if (config case Ok(:final value)) _config = value;
    text = initialText;
    final ai = this.ai;
    if (ai != null) {
      aiEnabled = await ai.aiEnabled();
      if (await ai.history() case Ok(:final value)) history = value;
    }
    notifyListeners();
    if (photo != null) return await searchPhoto(photo);
    if (!tooShort) await submit();
  }

  /// Recherche validée (touche Rechercher, voix, photo, historique,
  /// suggestion) : retenue dans l'historique.
  Future<void> searchFor(String value, SearchSource source) async {
    text = value.trim();
    suggestions = const [];
    if (source != SearchSource.photo) photo = null;
    photoOutcome = null;
    notifyListeners();
    await submit();
    await _remember(source);
  }

  /// Touche « Rechercher » du clavier.
  Future<void> submitTyped() => searchFor(text, SearchSource.text);

  /// Produit ouvert depuis les résultats : la recherche est retenue.
  Future<void> openedResult() => _remember(SearchSource.text);

  Future<void> _remember(SearchSource source) async {
    final ai = this.ai;
    if (ai == null || tooShort) return;
    await ai.remember(text.trim(), source);
    if (await ai.history() case Ok(:final value)) history = value;
    notifyListeners();
  }

  Future<void> forgetHistory() async {
    if (await ai?.forget() case Ok()) history = const [];
    notifyListeners();
  }

  /// Photo prise ou choisie, décrite par l'IA, puis cherchée.
  Future<void> searchPhoto(PhotoSource source) async {
    final ai = this.ai;
    if (ai == null) return;
    final picked = await ai.pickPhoto(source);
    switch (picked) {
      case Err(:final failure):
        photoOutcome = Err(failure);
        notifyListeners();
        return;
      case Ok(value: null):
        return;
      case Ok(value: final p?):
        analyzingPhoto = true;
        photoOutcome = null;
        notifyListeners();
        final described = await ai.describePhoto(p);
        analyzingPhoto = false;
        switch (described) {
          case Err(:final failure):
            photoOutcome = Err(failure);
            notifyListeners();
          case Ok(value: null):
            photoOutcome = const Ok(null);
            notifyListeners();
          case Ok(value: final query?):
            photo = (bytes: p.bytes, query: query);
            await searchFor(query, SearchSource.photo);
        }
    }
  }

  /// « Modifier » : le texte reconnu redevient une recherche ordinaire.
  void editPhotoQuery() {
    photo = null;
    notifyListeners();
  }

  void _suggest() {
    _suggestTimer?.cancel();
    final ai = this.ai;
    final prefix = text.trim();
    if (ai == null || prefix.isEmpty) {
      suggestions = const [];
      return;
    }
    _suggestTimer = Timer(debounce ~/ 2, () async {
      final generation = ++_suggestGeneration;
      final result = await ai.suggestions(prefix);
      if (generation != _suggestGeneration || text.trim() != prefix) return;
      suggestions = [
        for (final s in result.valueOrNull ?? const <SearchSuggestion>[])
          if (s.label.resolve('fr').toLowerCase() != prefix.toLowerCase()) s,
      ];
      notifyListeners();
    });
  }

  SearchQuery _query(int offset) => SearchQuery(
    text: text.trim(),
    categoryId: filters.categoryId,
    origin: filters.origin,
    minPriceMinor: filters.minPriceMinor,
    maxPriceMinor: filters.maxPriceMinor,
    availableOnly: filters.availableOnly,
    sort: filters.sort,
    offset: offset,
  );

  /// Saisie : recherche après une courte pause (pas de requête par lettre).
  void setText(String value) {
    text = value;
    photo = null;
    _suggest();
    _timer?.cancel();
    if (tooShort) {
      _results = null;
      _failure = null;
      notifyListeners();
      return;
    }
    _timer = Timer(debounce, submit);
    notifyListeners();
  }

  /// Lance la recherche maintenant.
  Future<void> submit() async {
    _timer?.cancel();
    if (tooShort) return;
    final generation = ++_generation;
    _failure = null;
    setBusy(true);
    final query = _query(0);
    final result = await _service.search(query);
    // Une recherche plus récente a été lancée : ce résultat est périmé.
    if (generation != _generation) return;
    switch (result) {
      case Ok(:final value):
        _results = value;
        _service.searchPerformed(query, value.total);
      case Err(:final failure):
        _failure = failure;
    }
    setBusy(false);
  }

  Future<void> loadMore() async {
    final current = _results;
    if (current == null || !hasMore || _loadingMore) return;
    _loadingMore = true;
    notifyListeners();
    final result = await _service.search(_query(current.products.length));
    if (result case Ok(:final value)) {
      _results = SearchResults(
        total: value.total,
        products: [...current.products, ...value.products],
        stores: current.stores,
        fuzzy: current.fuzzy,
      );
    }
    _loadingMore = false;
    notifyListeners();
  }

  void selectTab(SearchTab value) {
    tab = value;
    notifyListeners();
  }

  Future<void> applyFilters(SearchFilters value) async {
    if (!value.priceValid) return;
    filters = value;
    notifyListeners();
    await submit();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _suggestTimer?.cancel();
    super.dispose();
  }
}
