import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Caisse de la vendeuse (spec 045) : ventes hors app, « Ma caisse »,
/// versements. Montants, stock et soldes décidés en base.
class TillRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<Till>> till() async =>
      (await _data.rpc<Object?>('my_till')).map(_till);

  /// Texte dicté ou tapé → vente à confirmer.
  Future<Result<TillDraft>> parse(String text) async =>
      (await _data.rpc<Object?>('till_parse', params: {'p_text': text})).map(
        (json) => TillDraft.fromJson((json! as Map).cast<String, dynamic>()),
      );

  Future<Result<Till>> record({
    required String label,
    required int amountMinor,
    required TillMethod method,
    required String key,
    String? variantId,
    int quantity = 1,
  }) async => (await _data.rpc<Object?>(
    'record_till_sale',
    params: {
      'p_label': label,
      'p_amount_minor': amountMinor,
      'p_method': method.code,
      'p_key': key,
      'p_variant': variantId,
      'p_quantity': quantity,
    },
  )).map(_till);

  Future<Result<Till>> voidSale(String saleId) async =>
      (await _data.rpc<Object?>(
        'void_till_sale',
        params: {'p_sale': saleId},
      )).map(_till);

  /// Versement simulé du solde.
  Future<Result<Till>> payout(int amountMinor, String key) async =>
      (await _data.rpc<Object?>(
        'store_payout_simulated',
        params: {'p_amount_minor': amountMinor, 'p_key': key},
      )).map(_till);

  static Till _till(Object? json) =>
      Till.fromJson((json! as Map).cast<String, dynamic>());
}
