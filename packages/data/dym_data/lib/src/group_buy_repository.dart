import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Achat groupé entre voisins (spec 051). Jauge, déblocage, prix de groupe et
/// frais partagés décidés en base. Refus (`ValidationFailure.message`) :
/// `offer_closed`, `group_locked`, `own_store`, `invalid_amount`.
class GroupBuyRepository {
  new(this._data);

  final NeonDataClient _data;

  /// Cliente : offres des boutiques qui livrent [zoneId] et ses groupes actifs.
  Future<Result<List<GroupOffer>>> near({String? zoneId}) =>
      _list('group_offers_near', {'p_zone': zoneId});

  /// Cliente : quantité dans le groupe ; 0 : retrait (avant le déblocage).
  Future<Result<GroupOffer>> join(String offerId, int quantity) =>
      _offer('join_group_offer', {'p_offer': offerId, 'p_quantity': quantity});

  /// Vendeuse : ses offres.
  Future<Result<List<GroupOffer>>> mine() => _list('my_group_offers', const {});

  Future<Result<GroupOffer>> create({
    required String productId,
    required int groupPriceMinor,
    required int minQuantity,
    int days = 3,
    int? memberDeliveryFeeMinor,
  }) => _offer('create_group_offer', {
    'p_product': productId,
    'p_group_price_minor': groupPriceMinor,
    'p_min_quantity': minQuantity,
    'p_days': days,
    'p_member_delivery_fee_minor': memberDeliveryFeeMinor,
  });

  Future<Result<GroupOffer>> cancel(String offerId) =>
      _offer('cancel_group_offer', {'p_offer': offerId});

  Future<Result<List<GroupOffer>>> _list(
    String fn,
    Map<String, Object?> params,
  ) async => (await _data.rpc<Object?>(fn, params: params)).map(
    (json) => [
      for (final o in json! as List)
        GroupOffer.fromJson((o as Map).cast<String, dynamic>()),
    ],
  );

  Future<Result<GroupOffer>> _offer(
    String fn,
    Map<String, Object?> params,
  ) async => (await _data.rpc<Object?>(
    fn,
    params: params,
  )).map((json) => GroupOffer.fromJson((json! as Map).cast<String, dynamic>()));
}
