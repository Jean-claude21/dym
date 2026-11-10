import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';

/// Appels d'une conversation (spec 035) : états en base, média par le
/// fournisseur (simulé tant que le vrai n'est pas branché).
abstract interface class CallService {
  CallProvider get provider;

  Future<Result<CallSession>> start(String conversationId, CallKind kind);

  Future<Result<CallSession>> answer(String callId, {required bool accept});

  Future<Result<CallSession>> end(String callId);

  Future<Result<CallSession>> state(String callId);

  Future<Result<CallSession?>> incoming();
}

class NeonCallService implements CallService {
  new({
    required this._repository,
    this.provider = const SimulatedCallProvider(),
  });

  final CallRepository _repository;

  @override
  final CallProvider provider;

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
