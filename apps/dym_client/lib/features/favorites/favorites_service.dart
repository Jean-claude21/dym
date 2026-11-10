import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/foundation.dart';

/// Carnet de la cliente (spec 030) : favoris et paniers enregistrés.
abstract interface class FavoritesService {
  /// État des cœurs, partagé entre les écrans.
  ValueListenable<FavoriteIds> get ids;

  Future<void> refreshIds();

  /// Ajoute ou retire ; met à jour [ids] quand le serveur confirme.
  Future<Result<bool>> toggle(FavoriteKind kind, String id);

  Future<Result<Favorites>> favorites();

  Future<Result<List<SavedBasket>>> baskets();

  Future<Result<SavedBasket>> saveCart(String name);

  Future<Result<SavedBasket>> rename(String id, String name);

  Future<Result<void>> delete(String id);

  /// Remet au panier ; nomme ce qui n'a pas été ajouté.
  Future<Result<ReorderResult>> toCart(String id);
}

/// Implémentation Neon.
class NeonFavoritesService implements FavoritesService {
  new(this._repository);

  final FavoritesRepository _repository;
  final ValueNotifier<FavoriteIds> _ids = ValueNotifier(const FavoriteIds());
  bool _loaded = false;

  @override
  ValueListenable<FavoriteIds> get ids {
    if (!_loaded) {
      _loaded = true;
      refreshIds().ignore();
    }
    return _ids;
  }

  @override
  Future<void> refreshIds() async {
    if (await _repository.ids() case Ok(:final value)) _ids.value = value;
  }

  @override
  Future<Result<bool>> toggle(FavoriteKind kind, String id) async {
    final result = await _repository.toggle(kind, id);
    if (result case Ok(:final value)) {
      _ids.value = _ids.value.withState(kind, id, on: value);
    }
    return result;
  }

  @override
  Future<Result<Favorites>> favorites() => _repository.favorites();

  @override
  Future<Result<List<SavedBasket>>> baskets() => _repository.baskets();

  @override
  Future<Result<SavedBasket>> saveCart(String name) =>
      _repository.saveCart(name);

  @override
  Future<Result<SavedBasket>> rename(String id, String name) =>
      _repository.rename(id, name);

  @override
  Future<Result<void>> delete(String id) => _repository.delete(id);

  @override
  Future<Result<ReorderResult>> toCart(String id) => _repository.toCart(id);
}
