import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/widgets.dart';

/// Espaces partagés (spec 031) : remplir à plusieurs, un seul valide.
abstract interface class SpacesService {
  Future<Result<List<SpaceSummary>>> spaces();

  Future<Result<Space>> space(String id);

  Future<Result<Space>> create(String name, {int? monthlyBudgetMinor});

  Future<Result<Space>> join(String code);

  Future<Result<Space>> setRole(String id, String userId, SpaceRole role);

  Future<Result<void>> removeMember(String id, String userId);

  Future<Result<void>> delete(String id);

  /// Envoie le panier dans l'espace (le panier se vide).
  Future<Result<Space>> sendCart(String id);

  Future<Result<Space>> setItem(String id, String variantId, int quantity);

  /// Articles passés au panier de la personne qui valide.
  Future<Result<ReorderResult>> validate(String id);

  Future<Result<CountryConfig>> countryConfig();

  ImageProvider photo(String objectKey);
}

/// Implémentation Neon.
class NeonSpacesService implements SpacesService {
  new({
    required this._repository,
    required this._discovery,
    required this._cart,
  });

  final SpaceRepository _repository;
  final DiscoveryService _discovery;
  final CartService _cart;

  @override
  Future<Result<List<SpaceSummary>>> spaces() => _repository.spaces();

  @override
  Future<Result<Space>> space(String id) => _repository.space(id);

  @override
  Future<Result<Space>> create(String name, {int? monthlyBudgetMinor}) =>
      _repository.create(name, monthlyBudgetMinor: monthlyBudgetMinor);

  @override
  Future<Result<Space>> join(String code) => _repository.join(code);

  @override
  Future<Result<Space>> setRole(String id, String userId, SpaceRole role) =>
      _repository.setRole(id, userId, role);

  @override
  Future<Result<void>> removeMember(String id, String userId) =>
      _repository.removeMember(id, userId);

  @override
  Future<Result<void>> delete(String id) => _repository.delete(id);

  @override
  Future<Result<Space>> sendCart(String id) async {
    final result = await _repository.sendCart(id);
    if (result.isOk) _cart.refresh().ignore();
    return result;
  }

  @override
  Future<Result<Space>> setItem(String id, String variantId, int quantity) =>
      _repository.setItem(id, variantId, quantity);

  @override
  Future<Result<ReorderResult>> validate(String id) async {
    final result = await _repository.validate(id);
    if (result.isOk) await _cart.refresh();
    return result;
  }

  @override
  Future<Result<CountryConfig>> countryConfig() => _discovery.countryConfig();

  @override
  ImageProvider photo(String objectKey) => _discovery.photo(objectKey);
}
