import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Appels d'une conversation (spec 035) : états tenus en base.
class CallRepository {
  new(this._data);

  final NeonDataClient _data;

  /// Refus : `call_in_progress`, `feature_disabled`.
  Future<Result<CallSession>> start(String conversationId, CallKind kind) =>
      _call('start_call', {
        'p_conversation': conversationId,
        'p_kind': kind.name,
      });

  Future<Result<CallSession>> answer(String callId, {required bool accept}) =>
      _call('answer_call', {'p_call': callId, 'p_accept': accept});

  Future<Result<CallSession>> end(String callId) =>
      _call('end_call', {'p_call': callId});

  Future<Result<CallSession>> state(String callId) =>
      _call('call_state', {'p_call': callId});

  /// Appel qui sonne pour la personne ; `Ok(null)` : aucun.
  Future<Result<CallSession?>> incoming() async {
    final result = await _data.rpc<Object?>('my_incoming_call');
    return result.map(
      (json) => json == null
          ? null
          : CallSession.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  Future<Result<CallSession>> _call(
    String fn,
    Map<String, Object?> params,
  ) async {
    final result = await _data.rpc<Object?>(fn, params: params);
    return result.map(
      (json) => CallSession.fromJson((json! as Map).cast<String, dynamic>()),
    );
  }
}
