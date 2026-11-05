import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Copilote d'intention (spec 019) : proposition par la Function (flag
/// `intent_copilot`), rechiffrage par la Data API. Aucun prix n'est calculé
/// dans l'app.
class CopilotRepository {
  new({required this._data, required this._functions});

  final NeonDataClient _data;
  final NeonFunctionsClient _functions;

  /// Refus : `feature_disabled` ; 503 si l'IA ne répond pas.
  Future<Result<CopilotProposal>> propose(String text, {String? zoneId}) =>
      _functions.post(
        '/v1/copilot/propose',
        body: {'text': text, 'zone_id': zoneId},
        decode: (json) =>
            CopilotProposal.fromJson(json! as Map<String, dynamic>),
      );

  /// Rechiffre [proposal] sans la ligne [removedVariantId] ; les besoins non
  /// trouvés sont conservés.
  Future<Result<CopilotProposal>> quote(
    CopilotProposal proposal, {
    String? removedVariantId,
  }) async {
    final result = await _data.rpc<Object?>(
      'copilot_quote',
      params: {'p_items': proposal.itemsWithout(removedVariantId)},
    );
    return result.map(
      (json) => CopilotProposal.fromJson(
        json! as Map<String, dynamic>,
        missing: proposal.missing,
      ),
    );
  }
}
