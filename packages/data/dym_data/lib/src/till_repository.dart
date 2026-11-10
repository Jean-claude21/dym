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

  /// Fin de marché (spec 048).
  Future<Result<EndOfMarket>> endOfMarket() =>
      _eom('my_end_of_market', const {});

  Future<Result<EndOfMarket>> startEndOfMarket({
    required int percent,
    required int hours,
  }) => _eom('set_end_of_market', {'p_percent': percent, 'p_hours': hours});

  Future<Result<EndOfMarket>> stopEndOfMarket() =>
      _eom('clear_end_of_market', const {});

  Future<Result<EndOfMarket>> _eom(
    String fn,
    Map<String, Object?> params,
  ) async => (await _data.rpc<Object?>(fn, params: params)).map(
    (json) => EndOfMarket.fromJson((json! as Map).cast<String, dynamic>()),
  );

  static Till _till(Object? json) =>
      Till.fromJson((json! as Map).cast<String, dynamic>());
}
