import 'package:dym_client/features/favorites/favorites_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/foundation.dart';

/// Carnet en mémoire (tests, galerie). Jamais en production.
class MemoryFavoritesService implements FavoritesService {
  new({
    this.favoriteStores = const [],
    this.favoriteProducts = const [],
    List<SavedBasket> baskets = const [],
    this.cartEmpty = false,
    this.skipped = const [],
  }) : stored = [...baskets];

  final List<PublicStore> favoriteStores;
  final List<CatalogItem> favoriteProducts;
  final List<SavedBasket> stored;

  /// Panier en cours vide : enregistrement refusé.
  bool cartEmpty;

  /// Articles nommés comme non ajoutés à la remise au panier.
  final List<String> skipped;
  final reordered = <String>[];
  final ValueNotifier<FavoriteIds> _ids = ValueNotifier(const FavoriteIds());

  @override
  ValueListenable<FavoriteIds> get ids => _ids;

  @override
  Future<void> refreshIds() async {}

  @override
  Future<Result<bool>> toggle(FavoriteKind kind, String id) async {
    final on = !_ids.value.contains(kind, id);
    _ids.value = _ids.value.withState(kind, id, on: on);
    return Ok(on);
  }

  @override
  Future<Result<Favorites>> favorites() async =>
      Ok(Favorites(stores: favoriteStores, products: favoriteProducts));

  @override
  Future<Result<List<SavedBasket>>> baskets() async =>
      Ok(List.unmodifiable(stored));

  @override
  Future<Result<SavedBasket>> saveCart(String name) async {
    if (cartEmpty) return const Err(ValidationFailure('cart_empty'));
    final basket = SavedBasket(id: 'b${stored.length}', name: name.trim());
    stored.add(basket);
    return Ok(basket);
  }

  @override
  Future<Result<SavedBasket>> rename(String id, String name) async {
    final i = stored.indexWhere((b) => b.id == id);
    final old = stored[i];
    stored[i] = SavedBasket(
      id: id,
      name: name.trim(),
      currencyCode: old.currencyCode,
      totalMinor: old.totalMinor,
      availableCount: old.availableCount,
      items: old.items,
    );
    return Ok(stored[i]);
  }

  @override
  Future<Result<void>> delete(String id) async {
    stored.removeWhere((b) => b.id == id);
    return const Ok(null);
  }

  @override
  Future<Result<ReorderResult>> toCart(String id) async {
    reordered.add(id);
    final basket = stored.firstWhere((b) => b.id == id);
    return Ok(
      ReorderResult(
        added: basket.items.length - skipped.length,
        skipped: skipped,
      ),
    );
  }
}
