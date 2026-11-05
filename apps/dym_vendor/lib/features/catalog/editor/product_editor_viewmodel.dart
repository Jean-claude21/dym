import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:stacked/stacked.dart';

/// État de la proposition « photo → fiche ».
enum SuggestionState { idle, loading, received, unavailable }

/// Variante en cours de saisie.
class VariantDraft {
  new({required this.id, this.label = '', this.priceText = '', this.stock = 0});

  final String id;
  String label;
  String priceText;
  int stock;
}

/// Création ou modification d'un produit en 2 étapes (écrans 25 et 26) :
/// 1. photos, proposition, nom, rayon, description ;
/// 2. prix, unité, variantes et stock, catégories de la boutique.
///
/// L'identifiant est fixé à l'ouverture : chaque enregistrement réécrit la
/// même fiche (idempotence, FR-003).
class ProductEditorViewModel extends BaseViewModel {
  new({
    required this._service,
    required this._onDone,
    this.product,
    this.initialSource,
    this.initialStep = 1,
    this._onClosed,
  });

  /// Fiche supprimée (brouillon).
  final void Function()? _onClosed;

  final CatalogService _service;

  /// Fiche enregistrée (publiée, ou modifiée).
  final void Function(Product product) _onDone;

  /// Produit modifié (`null` : nouveau).
  final Product? product;

  /// Nouveau produit : ouvre directement l'appareil photo (un geste de
  /// moins, parcours 10).
  final PhotoSource? initialSource;

  /// Produit existant : ouvre directement l'étape « Prix et stock ».
  final int initialStep;

  static const maxPhotos = 5;
  static const maxVariants = 10;
  static const nameMin = 2;
  static const nameMax = 80;
  static const descriptionMax = 500;
  static const maxStock = 9999;

  late final String id = product?.id ?? _service.newId();
  int _step = 1;
  CountryConfig? _config;
  List<StoreCategory> _storeCategories = const [];
  Failure? _loadFailure;
  Failure? _saveFailure;
  bool _uploading = false;
  bool _uploadFailed = false;
  SuggestionState _suggestion = SuggestionState.idle;
  String? _suggestionId;

  final List<String> photoKeys = [];
  String name = '';
  String description = '';
  String? categoryId;
  String? unitId;
  String priceText = '';
  bool trackStock = true;
  final List<VariantDraft> variants = [];
  final Set<String> storeCategoryIds = {};

  bool get isNew => product == null;
  int get step => _step;
  CountryConfig? get config => _config;
  List<StoreCategory> get storeCategories =>
      _storeCategories.where((c) => !c.isArchived).toList();
  Failure? get loadFailure => _loadFailure;
  Failure? get saveFailure => _saveFailure;
  bool get offline => (_loadFailure ?? _saveFailure) is NetworkFailure;
  bool get ready => _config != null;
  bool get uploading => _uploading;
  bool get uploadFailed => _uploadFailed;
  SuggestionState get suggestion => _suggestion;
  CatalogService get service => _service;

  Currency? get currency => _config?.currency;

  bool get nameValid {
    final length = name.trim().length;
    return length >= nameMin && length <= nameMax;
  }

  int? get priceMinor {
    final c = currency;
    if (c == null) return null;
    final value = Money.parseMajor(priceText, c);
    return value == null || value <= 0 ? null : value;
  }

  bool get priceValid => priceMinor != null;

  /// Rayons de premier niveau.
  List<Category> get topCategories => _config?.topCategories ?? const [];

  /// Rayon de premier niveau du rayon choisi.
  String? get topCategoryId {
    final chosen = _config?.categories
        .where((c) => c.id == categoryId)
        .firstOrNull;
    return chosen?.parentId ?? chosen?.id;
  }

  /// Sous-rayons du rayon choisi.
  List<Category> get subCategories {
    final top = topCategoryId;
    return top == null ? const [] : _config?.subCategoriesOf(top) ?? const [];
  }

  bool get variantLabelsValid =>
      variants.length <= 1 || variants.every((v) => v.label.trim().isNotEmpty);

  bool get variantPricesValid => variants.every(
    (v) => v.priceText.trim().isEmpty || _parse(v.priceText) != null,
  );

  bool get canContinue =>
      nameValid && categoryId != null && description.length <= descriptionMax;

  bool get canPublish =>
      canContinue &&
      photoKeys.isNotEmpty &&
      priceValid &&
      variantLabelsValid &&
      variantPricesValid &&
      !_uploading;

  bool get canGoBack => _step == 2;

  Future<void> load() async {
    _loadFailure = null;
    setBusy(true);
    final config = await _service.countryConfig();
    final categories = await _service.storeCategories();
    switch ((config, categories)) {
      case (Ok(value: final cfg), Ok(value: final list)):
        _config = cfg;
        _storeCategories = list;
        _apply(cfg);
        if (product != null && initialStep == 2) _step = 2;
      case (Err(:final failure), _) || (_, Err(:final failure)):
        _loadFailure = failure;
    }
    setBusy(false);
    final source = initialSource;
    if (ready && isNew && source != null && photoKeys.isEmpty) {
      await addPhoto(source);
    }
  }

  void _apply(CountryConfig cfg) {
    final p = product;
    if (p == null) {
      variants
        ..clear()
        ..add(VariantDraft(id: _service.newId()));
      return;
    }
    photoKeys
      ..clear()
      ..addAll(p.photoKeys);
    name = p.name;
    description = p.description ?? '';
    categoryId = p.categoryId;
    unitId = p.unitId;
    priceText = p.priceMinor == null ? '' : _format(p.priceMinor!, cfg);
    _suggestionId = p.suggestionId;
    trackStock = p.variants.any((v) => v.stockQuantity != null);
    variants
      ..clear()
      ..addAll([
        for (final v in p.variants)
          VariantDraft(
            id: v.id,
            label: v.label ?? '',
            priceText: v.priceMinor == null ? '' : _format(v.priceMinor!, cfg),
            stock: v.stockQuantity ?? 0,
          ),
      ]);
    if (variants.isEmpty) variants.add(VariantDraft(id: _service.newId()));
    storeCategoryIds
      ..clear()
      ..addAll(p.storeCategoryIds);
  }

  /// Montant en unités principales, sans séparateur (saisie).
  static String _format(int minor, CountryConfig cfg) {
    final units = cfg.currency.minorUnits;
    if (units == 0) return '$minor';
    final text = minor.toString().padLeft(units + 1, '0');
    return '${text.substring(0, text.length - units)},'
        '${text.substring(text.length - units)}';
  }

  int? _parse(String text) {
    final c = currency;
    if (c == null) return null;
    final value = Money.parseMajor(text, c);
    return value == null || value <= 0 ? null : value;
  }

  // ---------------------------------------------------------------- photos

  /// Prend ou choisit une photo, l'envoie, puis demande une proposition pour
  /// la première photo d'un nouveau produit.
  Future<void> addPhoto(PhotoSource source) async {
    if (photoKeys.length >= maxPhotos || _uploading) return;
    final picked = await _service.pickPhoto(source);
    final PickedPhoto photo;
    switch (picked) {
      case Ok(value: final value?):
        photo = value;
      case Ok():
        return;
      case Err():
        _uploadFailed = true;
        notifyListeners();
        return;
    }
    _uploading = true;
    _uploadFailed = false;
    notifyListeners();
    final uploaded = await _service.uploadPhoto(photo);
    _uploading = false;
    switch (uploaded) {
      case Ok(:final value):
        photoKeys.add(value);
        notifyListeners();
        if (isNew &&
            photoKeys.length == 1 &&
            _suggestion == SuggestionState.idle) {
          await _requestSuggestion(value);
        }
      case Err():
        _uploadFailed = true;
        notifyListeners();
    }
  }

  void removePhoto(String key) {
    photoKeys.remove(key);
    notifyListeners();
  }

  Future<void> _requestSuggestion(String key) async {
    _suggestion = SuggestionState.loading;
    notifyListeners();
    final result = await _service.suggest(key);
    switch (result) {
      case Ok(:final value):
        _suggestionId = value.suggestionId;
        // Ce que la vendeuse a déjà saisi n'est jamais écrasé.
        if (name.trim().isEmpty) name = value.name;
        if (categoryId == null && _isKnownCategory(value.categoryId)) {
          categoryId = value.categoryId;
        }
        if (description.trim().isEmpty) description = value.description ?? '';
        _suggestion = SuggestionState.received;
        _service.suggestionShown();
      case Err():
        _suggestion = SuggestionState.unavailable;
    }
    notifyListeners();
  }

  bool _isKnownCategory(String? id) =>
      id != null && (_config?.categories.any((c) => c.id == id) ?? false);

  // ---------------------------------------------------------------- saisie

  void setName(String value) => _set(() => name = value);
  void setDescription(String value) => _set(() => description = value);
  void selectCategory(String id) => _set(() => categoryId = id);
  void selectUnit(String? id) => _set(() => unitId = unitId == id ? null : id);
  void setPrice(String value) => _set(() => priceText = value);
  void setTrackStock({required bool value}) => _set(() => trackStock = value);
  void toggleStoreCategory(String id) => _set(
    () => storeCategoryIds.contains(id)
        ? storeCategoryIds.remove(id)
        : storeCategoryIds.add(id),
  );

  void addVariant() {
    if (variants.length >= maxVariants) return;
    _set(() => variants.add(VariantDraft(id: _service.newId())));
  }

  void removeVariant(String id) {
    if (variants.length <= 1) return;
    _set(() => variants.removeWhere((v) => v.id == id));
  }

  void setVariantLabel(String id, String value) =>
      _set(() => _variant(id).label = value);
  void setVariantPrice(String id, String value) =>
      _set(() => _variant(id).priceText = value);
  void setStock(String id, int value) =>
      _set(() => _variant(id).stock = value.clamp(0, maxStock));

  VariantDraft _variant(String id) => variants.firstWhere((v) => v.id == id);

  void _set(void Function() change) {
    change();
    _saveFailure = null;
    notifyListeners();
  }

  /// Crée une catégorie de la boutique et la sélectionne.
  Future<bool> createStoreCategory(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return false;
    final newId = _service.newId();
    final result = await _service.saveStoreCategory(newId, trimmed);
    switch (result) {
      case Ok(:final value):
        _storeCategories = value;
        storeCategoryIds.add(newId);
        notifyListeners();
        return true;
      case Err(:final failure):
        _saveFailure = failure;
        notifyListeners();
        return false;
    }
  }

  // ---------------------------------------------------------------- navigation

  ProductInput get _input => ProductInput(
    id: id,
    name: name.trim(),
    description: description.trim().isEmpty ? null : description.trim(),
    categoryId: categoryId,
    unitId: unitId,
    priceMinor: priceMinor,
    suggestionId: _suggestionId,
    photoKeys: List.of(photoKeys),
    storeCategoryIds: storeCategoryIds.toList(),
    variants: [
      for (final v in variants)
        ProductVariant(
          id: v.id,
          label: v.label.trim().isEmpty ? null : v.label.trim(),
          priceMinor: v.priceText.trim().isEmpty ? null : _parse(v.priceText),
          stockQuantity: trackStock ? v.stock : null,
        ),
    ],
  );

  /// Étape 1 → 2 : le brouillon est enregistré (reprise possible).
  Future<void> next() async {
    if (!canContinue || isBusy) return;
    _saveFailure = null;
    setBusy(true);
    final result = await _service.saveProduct(_input);
    setBusy(false);
    switch (result) {
      case Ok():
        _step = 2;
      case Err(:final failure):
        _saveFailure = failure;
    }
    notifyListeners();
  }

  void back() {
    if (!canGoBack) return;
    _step = 1;
    _saveFailure = null;
    notifyListeners();
  }

  /// Archive le produit existant (il reste restaurable).
  Future<void> archive() => _close(() => _service.archive(id, archived: true));

  /// Supprime un brouillon jamais publié.
  Future<void> deleteDraft() async {
    if (isBusy) return;
    _saveFailure = null;
    setBusy(true);
    final result = await _service.deleteDraft(id);
    setBusy(false);
    switch (result) {
      case Ok():
        _onClosed?.call();
      case Err(:final failure):
        _saveFailure = failure;
        notifyListeners();
    }
  }

  Future<void> _close(Future<Result<Product>> Function() action) async {
    if (isBusy) return;
    _saveFailure = null;
    setBusy(true);
    final result = await action();
    setBusy(false);
    switch (result) {
      case Ok(:final value):
        _onDone(value);
      case Err(:final failure):
        _saveFailure = failure;
        notifyListeners();
    }
  }

  /// Brouillon : supprimable plutôt qu'archivable.
  bool get isDraft => product != null && product!.status == ProductStatus.draft;

  /// Enregistre puis publie (une nouvelle tentative réécrit la même fiche).
  Future<void> publish() async {
    if (!canPublish || isBusy) return;
    _saveFailure = null;
    setBusy(true);
    final saved = await _service.saveProduct(_input);
    final result = switch (saved) {
      Ok(:final value) when !value.isPublished && !value.isArchived =>
        await _service.publish(id),
      _ => saved,
    };
    setBusy(false);
    switch (result) {
      case Ok(:final value):
        _onDone(value);
      case Err(:final failure):
        _saveFailure = failure;
        notifyListeners();
    }
  }
}
