import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Carnet de la cliente (spec 030) : favoris et paniers enregistrés. Les
/// règles (bornes, disponibilité, prix du jour, ajout au panier) sont en base.
class FavoritesRepository {
  new(this._data);

  final NeonDataClient _data;

  /// Ajoute ou retire ; renvoie l'état final.
  Future<Result<bool>> toggle(FavoriteKind kind, String id) async {
    final result = await _data.rpc<Object?>(
      'toggle_favorite',
      params: {'p_kind': kind.code, 'p_id': id},
    );
    return result.map((json) => json == true);
  }

  Future<Result<FavoriteIds>> ids() async {
    final result = await _data.rpc<Object?>('my_favorite_ids');
    return result.map((json) => FavoriteIds.fromJson(_map(json)));
  }

  Future<Result<Favorites>> favorites() async {
    final result = await _data.rpc<Object?>('my_favorites');
    return result.map((json) => Favorites.fromJson(_map(json)));
  }

  Future<Result<List<SavedBasket>>> baskets() async {
    final result = await _data.rpc<Object?>('my_baskets');
    return result.map(
      (json) => [
        for (final b in json as List? ?? const [])
          SavedBasket.fromJson(b as Map<String, dynamic>),
      ],
    );
  }

  /// Enregistre le panier en cours ; refus `cart_empty`, `too_many_baskets`.
  Future<Result<SavedBasket>> saveCart(String name) async {
    final result = await _data.rpc<Object?>(
      'save_cart_as_basket',
      params: {'p_name': name},
    );
    return result.map((json) => SavedBasket.fromJson(_map(json)));
  }

  Future<Result<SavedBasket>> rename(String id, String name) async {
    final result = await _data.rpc<Object?>(
      'rename_basket',
      params: {'p_id': id, 'p_name': name},
    );
    return result.map((json) => SavedBasket.fromJson(_map(json)));
  }

  Future<Result<void>> delete(String id) =>
      _data.rpc<void>('delete_basket', params: {'p_id': id});

  /// Remet le panier enregistré au panier ; nomme ce qui n'a pas été ajouté.
  Future<Result<ReorderResult>> toCart(String id) async {
    final result = await _data.rpc<Object?>(
      'basket_to_cart',
      params: {'p_id': id},
    );
    return result.map((json) => ReorderResult.fromJson(_map(json)));
  }

  static Map<String, dynamic> _map(Object? json) =>
      (json as Map?)?.cast<String, dynamic>() ?? const {};
}
