import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Marchandage (spec 050). Plancher, contre-prix et panier décidés en base.
/// Refus (`ValidationFailure.message`) : `haggle_off`, `offer_not_lower`,
/// `too_many_attempts`, `haggle_expired`, `own_store`, `other_country`.
class HaggleRepository {
  new(this._data);

  final NeonDataClient _data;

  /// Prix unitaire proposé pour [quantity] ; conclu : la ligne est au panier.
  Future<Result<Haggle>> propose(
    String variantId,
    int quantity,
    int offerMinor,
  ) => _haggle('propose_haggle', {
    'p_variant': variantId,
    'p_quantity': quantity,
    'p_offer_minor': offerMinor,
  });

  Future<Result<Haggle>> accept(String haggleId) =>
      _haggle('accept_haggle', {'p_id': haggleId});

  Future<Result<HagglingSettings>> settings() =>
      _settings('my_haggling', const {});

  /// [productId] nul : limite de la boutique (nulle : pas de marchandage) ;
  /// sinon limite du produit (nulle : celle de la boutique, 0 : jamais).
  Future<Result<HagglingSettings>> setLimit(
    int? percent, {
    String? productId,
  }) => _settings('set_haggle_limit', {
    'p_percent': percent,
    'p_product': productId,
  });

  Future<Result<Haggle>> _haggle(
    String fn,
    Map<String, Object?> params,
  ) async => (await _data.rpc<Object?>(
    fn,
    params: params,
  )).map((json) => Haggle.fromJson((json! as Map).cast<String, dynamic>()));

  Future<Result<HagglingSettings>> _settings(
    String fn,
    Map<String, Object?> params,
  ) async => (await _data.rpc<Object?>(fn, params: params)).map(
    (json) => HagglingSettings.fromJson((json! as Map).cast<String, dynamic>()),
  );
}
