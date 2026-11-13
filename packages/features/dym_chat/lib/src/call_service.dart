import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';

/// Appels d'une conversation (spec 035) : états en base, média par le
/// fournisseur choisi par la base pour chaque appel (spec 084 : LiveKit, ou
/// simulé).
abstract interface class CallService {
  /// Fournisseur d'un appel (`CallSession.provider`).
  CallProvider providerFor(CallSession call);

  Future<Result<CallSession>> start(String conversationId, CallKind kind);

  Future<Result<CallSession>> answer(String callId, {required bool accept});

  Future<Result<CallSession>> end(String callId);

  Future<Result<CallSession>> state(String callId);

  Future<Result<CallSession?>> incoming();
}

class NeonCallService implements CallService {
  new({required this._repository, CallProvider? simulated, this._livekit})
    : _simulated = simulated ?? SimulatedCallProvider();

  final CallRepository _repository;
  final CallProvider _simulated;
  final CallProvider? _livekit;

  @override
  CallProvider providerFor(CallSession call) => switch (call.provider) {
    'livekit' => _livekit ?? _simulated,
    _ => _simulated,
  };

  @override
  Future<Result<CallSession>> start(String conversationId, CallKind kind) =>
      _repository.start(conversationId, kind);

  @override
  Future<Result<CallSession>> answer(String callId, {required bool accept}) =>
      _repository.answer(callId, accept: accept);

  @override
  Future<Result<CallSession>> end(String callId) => _repository.end(callId);

  @override
  Future<Result<CallSession>> state(String callId) => _repository.state(callId);

  @override
  Future<Result<CallSession?>> incoming() => _repository.incoming();
}
