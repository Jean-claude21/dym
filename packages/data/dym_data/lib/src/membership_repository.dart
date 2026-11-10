import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Formules payées depuis le wallet (spec 052). Prix, durée et avantages en
/// base. Refus (`ValidationFailure.message`) : `wallet_insufficient`,
/// `other_country`.
class MembershipRepository {
  new(this._data);

  final NeonDataClient _data;

  /// [audience] : `client` ou `vendor`.
  Future<Result<MembershipOffer>> offer(String audience) =>
      _offer('membership_offer', {'p_audience': audience});

  /// Achète ou prolonge ; [key] rend la demande rejouable sans double paiement.
  Future<Result<MembershipOffer>> subscribe(String planId, String key) =>
      _offer('subscribe_plan', {'p_plan': planId, 'p_key': key});

  Future<Result<MembershipOffer>> _offer(
    String fn,
    Map<String, Object?> params,
  ) async => (await _data.rpc<Object?>(fn, params: params)).map(
    (json) => MembershipOffer.fromJson((json! as Map).cast<String, dynamic>()),
  );
}
