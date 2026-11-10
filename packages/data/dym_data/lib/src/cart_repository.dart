import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Panier de la cliente connectée (Data API). Chaque écriture renvoie le
/// panier recalculé par la base. Refus (`ValidationFailure.message`) :
/// `unavailable`, `other_country`.
class CartRepository {
  new(this._data);

  final NeonDataClient _data;

  /// Panier, avec l'adresse, les modes et le moyen de paiement choisis.
  Future<Result<CartView>> cart({
    String? addressId,
    Map<String, Fulfillment> modes = const {},
    String? paymentMethodId,
  }) => _cart('my_cart', {
    'p_address': addressId,
    'p_modes': {for (final e in modes.entries) e.key: e.value.name},
    'p_payment_method': paymentMethodId,
  });

  Future<Result<CartView>> add(String variantId, {int quantity = 1}) =>
      _cart('cart_add', {'p_variant': variantId, 'p_quantity': quantity});

  /// 0 retire la ligne.
  Future<Result<CartView>> setQuantity(String variantId, int quantity) => _cart(
    'cart_set_quantity',
    {'p_variant': variantId, 'p_quantity': quantity},
  );

  Future<Result<CartView>> _cart(String fn, Map<String, Object?> params) =>
      _decode(_data, fn, params, (json) {
        if (json is! Map<String, dynamic>) throw const FormatException();
        return CartView.fromJson(json);
      });
}

/// Adresses de livraison de la cliente (privées).
class AddressRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<List<CustomerAddress>>> addresses() =>
      _list('my_addresses', const {});

  /// Crée ou modifie (identifiant fourni par l'app : rejouable).
  Future<Result<List<CustomerAddress>>> save(AddressInput address) =>
      _list('save_address', {'p_address': address.toJson()});

  Future<Result<List<CustomerAddress>>> delete(String id) =>
      _list('delete_address', {'p_id': id});

  Future<Result<List<CustomerAddress>>> setDefault(String id) =>
      _list('set_default_address', {'p_id': id});

  Future<Result<List<CustomerAddress>>> _list(
    String fn,
    Map<String, Object?> params,
  ) => _decode(_data, fn, params, (json) {
    if (json is! List) throw const FormatException();
    return [
      for (final a in json) CustomerAddress.fromJson(a as Map<String, dynamic>),
    ];
  });
}

/// Commandes : création par la Function (paiement et notifications s'y
/// branchent), lecture par la Data API.
class OrderRepository {
  new({required this._functions, required this._data});

  final NeonFunctionsClient _functions;
  final NeonDataClient _data;

  /// Crée l'achat. La même [idempotencyKey] doit être réutilisée pour toute
  /// nouvelle tentative du même geste : la base rend alors le même achat.
  /// Refus (`ValidationFailure.message`) : `cart_empty`, `cart_blocked`,
  /// `address_required`, `payment_not_accepted`, `payment_unavailable`,
  /// `total_changed`.
  Future<Result<Purchase>> place(
    OrderRequest request, {
    required String idempotencyKey,
  }) => _functions.post<Purchase>(
    '/v1/orders',
    body: request.toJson(),
    idempotencyKey: idempotencyKey,
    decode: (json) => Purchase.fromJson(json! as Map<String, dynamic>),
  );

  /// Créneaux proposés pour le panier (spec 033).
  Future<Result<DeliverySlots>> slots() async {
    final result = await _data.rpc<Object?>('delivery_slots');
    return result.map(
      (json) => DeliverySlots.fromJson((json! as Map).cast<String, dynamic>()),
    );
  }

  /// Nouvelle tentative de paiement (même montant). Refus
  /// (`ValidationFailure.message`) : `already_paid`, `not_online`,
  /// `payment_not_accepted`, `payment_unavailable`.
  Future<Result<Purchase>> retryPayment(
    String purchaseId, {
    required String idempotencyKey,
    String? paymentMethodId,
  }) => _functions.post<Purchase>(
    '/v1/purchases/$purchaseId/payments',
    body: {'payment_method_id': paymentMethodId},
    idempotencyKey: idempotencyKey,
    decode: (json) => Purchase.fromJson(json! as Map<String, dynamic>),
  );

  /// Passage au paiement à la livraison (refus : `already_paid`,
  /// `cash_not_accepted`). Rejouable sans effet.
  Future<Result<Purchase>> payOnDelivery(String purchaseId) =>
      _functions.post<Purchase>(
        '/v1/purchases/$purchaseId/cash',
        body: const <String, Object?>{},
        idempotencyKey: purchaseId,
        decode: (json) => Purchase.fromJson(json! as Map<String, dynamic>),
      );

  Future<Result<Purchase>> purchase(String id) =>
      _decode(_data, 'my_purchase', {'p_id': id}, (json) {
        if (json is! Map<String, dynamic>) throw const FormatException();
        return Purchase.fromJson(json);
      });
}

Future<Result<T>> _decode<T>(
  NeonDataClient data,
  String fn,
  Map<String, Object?> params,
  T Function(Object? json) decode,
) async {
  final result = await data.rpc<Object?>(fn, params: params);
  switch (result) {
    case Err(:final failure):
      return Err(failure);
    case Ok(:final value):
      try {
        return Ok(decode(value));
      } on Object {
        return const Err(ServerFailure('réponse illisible'));
      }
  }
}
