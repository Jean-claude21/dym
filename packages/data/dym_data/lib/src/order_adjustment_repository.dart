import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Remplacement validé par photo et garantie fraîcheur (spec 034). Les règles
/// (rôle, délai, limite, crédit au grand livre) sont en base ; les photos
/// sont privées (liens signés courts, deux parties seulement).
class OrderAdjustmentRepository {
  new({required this._data, required this._functions, required this._uploads});

  final NeonDataClient _data;
  final NeonFunctionsClient _functions;
  final NeonObjectUploader _uploads;

  /// Envoie une photo pour la commande ; renvoie sa clé.
  Future<Result<String>> uploadPhoto(
    String orderId,
    List<int> bytes, {
    required String contentType,
  }) async {
    final grant = await _functions.post<Map<String, dynamic>>(
      '/v1/orders/$orderId/photo-uploads',
      body: {'content_type': contentType},
      decode: (json) => json! as Map<String, dynamic>,
    );
    switch (grant) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final sent = await _uploads.put(
          Uri.parse(value['upload_url'] as String),
          bytes,
          contentType: contentType,
        );
        if (sent case Err(:final failure)) return Err(failure);
        return Ok(value['object_key'] as String);
    }
  }

  /// Liens de lecture signés des photos de la commande, par clé.
  Future<Result<Map<String, String>>> photoUrls(String orderId) =>
      _functions.post(
        '/v1/orders/$orderId/photos',
        body: const <String, Object?>{},
        decode: (json) => {
          for (final e in ((json as Map?)?['urls'] as Map? ?? const {}).entries)
            '${e.key}': '${e.value}',
        },
      );

  /// Vendeuse : remplacement d'une ligne par un produit de sa boutique.
  Future<Result<List<OrderAdjustment>>> propose({
    required String orderId,
    required String variantId,
    required String proposedVariantId,
    required String photoKey,
    String? note,
  }) => _adjust('propose_substitution', {
    'p_order': orderId,
    'p_variant': variantId,
    'p_proposed_variant': proposedVariantId,
    'p_photo_key': photoKey,
    'p_note': note,
  });

  /// Cliente : accepte (même prix) ou refuse (montant rendu sur le wallet).
  Future<Result<List<OrderAdjustment>>> answer(
    String adjustmentId, {
    required bool accept,
  }) => _adjust('answer_substitution', {
    'p_adjustment': adjustmentId,
    'p_accept': accept,
  });

  /// Cliente : garantie fraîcheur. Refus : `claim_window_closed`,
  /// `claim_limit_reached`, `already_credited`.
  Future<Result<List<OrderAdjustment>>> claimFreshness({
    required String orderId,
    required String variantId,
    required String photoKey,
    String? note,
  }) => _adjust('claim_freshness', {
    'p_order': orderId,
    'p_variant': variantId,
    'p_photo_key': photoKey,
    'p_note': note,
  });

  Future<Result<List<OrderAdjustment>>> _adjust(
    String fn,
    Map<String, Object?> params,
  ) async {
    final result = await _data.rpc<Object?>(fn, params: params);
    return result.map(adjustmentsFromJson);
  }
}
