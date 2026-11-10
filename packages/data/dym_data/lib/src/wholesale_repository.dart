import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Achat de gros groupé (spec 049). Jauge, engagements et décisions en base.
class WholesaleRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<WholesaleBoard>> board() => _board('wholesale_board', const {});

  Future<Result<WholesaleBoard>> setWholesaler({required bool on}) =>
      _board('set_wholesaler', {'p_on': on});

  Future<Result<WholesaleOffer>> create({
    required String productId,
    required int unitPriceMinor,
    required int minQuantity,
    int days = 7,
    String? note,
  }) => _offer('create_wholesale_offer', {
    'p_product': productId,
    'p_unit_price_minor': unitPriceMinor,
    'p_min_quantity': minQuantity,
    'p_days': days,
    'p_note': note,
  });

  /// Quantité engagée ; 0 : retrait.
  Future<Result<WholesaleOffer>> commit(String offerId, int quantity) =>
      _offer('commit_wholesale', {'p_offer': offerId, 'p_quantity': quantity});

  Future<Result<WholesaleOffer>> decide(
    String offerId, {
    required bool confirm,
  }) => _offer('decide_wholesale_offer', {
    'p_offer': offerId,
    'p_confirm': confirm,
  });

  Future<Result<WholesaleBoard>> _board(
    String fn,
    Map<String, Object?> params,
  ) async => (await _data.rpc<Object?>(fn, params: params)).map(
    (json) => WholesaleBoard.fromJson((json! as Map).cast<String, dynamic>()),
  );

  Future<Result<WholesaleOffer>> _offer(
    String fn,
    Map<String, Object?> params,
  ) async => (await _data.rpc<Object?>(fn, params: params)).map(
    (json) => WholesaleOffer.fromJson((json! as Map).cast<String, dynamic>()),
  );
}
