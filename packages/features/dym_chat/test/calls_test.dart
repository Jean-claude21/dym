import 'dart:async';
import 'dart:typed_data';

import 'package:dym_chat/dym_chat.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorder implements VoiceRecorder {
  Duration length = const Duration(seconds: 4);
  bool cancelled = false;

  @override
  Stream<double> get level => const Stream.empty();

  @override
  Future<Result<void>> start() async => const Ok(null);

  @override
  Future<Result<RecordedAudio?>> stop() async => Ok(
    RecordedAudio(
      bytes: Uint8List(8),
      contentType: 'audio/wav',
      duration: length,
    ),
  );

  @override
  Future<void> cancel() async => cancelled = true;

  @override
  Future<void> dispose() async {}
}

class _Calls implements CallService {
  CallSession session = const CallSession(
    id: 'call1',
    conversationId: 'c1',
    kind: CallKind.video,
    status: CallStatus.ringing,
    outgoing: true,
    callerName: 'Awa',
  );
  final joined = <String>[];

  CallSession _with(CallStatus status) => session = CallSession(
    id: session.id,
    conversationId: session.conversationId,
    kind: session.kind,
    status: status,
    outgoing: session.outgoing,
    callerName: session.callerName,
  );

  @override
  final CallProvider provider = const SimulatedCallProvider();

  @override
  Future<Result<CallSession>> start(
    String conversationId,
    CallKind kind,
  ) async => Ok(session);

  @override
  Future<Result<CallSession>> answer(
    String callId, {
    required bool accept,
  }) async => Ok(_with(accept ? CallStatus.ongoing : CallStatus.declined));

  @override
  Future<Result<CallSession>> end(String callId) async =>
      Ok(_with(CallStatus.ended));

  @override
  Future<Result<CallSession>> state(String callId) async => Ok(session);

  @override
  Future<Result<CallSession?>> incoming() async => Ok(session);
}

void main() {
  final config = CountryConfig(
    country: Country.fromJson(const {
      'code': 'TG',
      'name': {'fr': 'Pays test', 'en': 'Test country'},
      'currency_code': 'XOF',
      'dial_code': '+228',
      'default_locale': 'fr',
      'timezone': 'UTC',
    }),
    currency: Currency.xof,
    cities: const [],
    zones: const [],
    categories: const [],
    storeOrigins: const [],
    units: const [],
    paymentMethods: const [],
    deliveryFees: const [],
    featureFlags: const [],
  );

  group('vocaux et appels (spec 035)', () {
    test('vocal : enregistré puis envoyé ; trop court : rien', () async {
      final recorder = _Recorder();
      final service = MemoryChatService.demo(
        role: ChatRole.client,
        config: config,
      )..recorder = recorder;
      final vm = ChatViewModel(
        service: service,
        conversationId: 'c1',
        refreshEvery: null,
      );
      await vm.load();
      final before = vm.messages.length;
      expect(vm.canRecord, isTrue);
      await vm.startRecording();
      expect(vm.recording, isTrue);
      expect(await vm.stopAndSendRecording(), isTrue);
      expect(vm.messages.length, before + 1);
      expect(vm.messages.last.kind, MessageKind.audio);

      recorder.length = const Duration(milliseconds: 200);
      await vm.startRecording();
      expect(await vm.stopAndSendRecording(), isFalse);
      await vm.startRecording();
      await vm.cancelRecording();
      expect(recorder.cancelled, isTrue);
      vm.dispose();
    });

    test('appel : sonne, décroché, raccroché ; simulation signalée', () async {
      final calls = _Calls()
        ..session = const CallSession(
          id: 'call1',
          conversationId: 'c1',
          kind: CallKind.audio,
          status: CallStatus.ringing,
          callerName: 'Kodjo',
        );
      final vm = CallViewModel(
        service: calls,
        session: calls.session,
        pollEvery: const Duration(hours: 1),
      );
      await vm.init();
      expect(vm.simulated, isTrue);
      await vm.answer(accept: true);
      expect(vm.call!.status, CallStatus.ongoing);
      expect(vm.joined, isTrue);
      await vm.hangUp();
      expect(vm.finished, isTrue);
      vm.dispose();
    });

    test('appel sortant : session créée par la base', () async {
      final vm = CallViewModel(
        service: _Calls(),
        conversationId: 'c1',
        kind: CallKind.video,
        pollEvery: const Duration(hours: 1),
      );
      await vm.init();
      expect(vm.call!.outgoing, isTrue);
      expect(vm.call!.kind, CallKind.video);
      vm.dispose();
    });

    test("résumé d'appel lu dans le message", () {
      final summary = CallSummary.maybeFromJson(const {
        'kind': 'video',
        'status': 'ended',
        'duration_s': 125,
      });
      expect(summary!.kind, CallKind.video);
      expect(summary.durationS, 125);
      expect(CallSummary.maybeFromJson(null), isNull);
    });
  });
}
