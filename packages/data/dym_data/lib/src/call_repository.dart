import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Appels d'une conversation (spec 035) : états tenus en base.
class CallRepository {
  new(this._data, {this._functions});

  final NeonDataClient _data;
  final NeonFunctionsClient? _functions;

  /// Accès au média d'un appel décroché (LiveKit, spec 084) : adresse du
  /// serveur et jeton de la salle, émis par la Function.
  Future<Result<({String url, String token})>> mediaCredentials(
    String callId,
  ) async {
    final functions = _functions;
    if (functions == null) {
      return const Err(ServerFailure('appels non configurés', statusCode: 503));
    }
    return await functions.post<({String url, String token})>(
      '/v1/calls/$callId/media',
      body: const <String, Object?>{},
      decode: (json) {
        final map = json! as Map<String, dynamic>;
        return (url: map['url'] as String, token: map['token'] as String);
      },
    );
  }

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
