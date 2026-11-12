import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dym_core/dym_core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:neon_kit/neon_kit.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

void main() {
  late List<Uri> opened;
  late List<StreamChannelController<Object?>> sockets;

  NeonLiveClient client({Future<Result<String>> Function()? token}) {
    opened = [];
    sockets = [];
    return NeonLiveClient(
      functionsUrl: Uri.parse('https://fn.example.com/'),
      token: token ?? () async => const Ok('jeton'),
      random: Random(1),
      connect: (uri) async {
        opened.add(uri);
        final c = StreamChannelController<Object?>();
        sockets.add(c);
        return c.local;
      },
    );
  }

  void serverSends(Map<String, Object?> message) =>
      sockets.last.foreign.sink.add(jsonEncode(message));

  test('URL : wss, jeton frais, sans curseur au départ', () async {
    final live = client()..start();
    await pumpEventQueue();
    expect(opened.single.scheme, 'wss');
    expect(opened.single.path, '/v1/live');
    expect(opened.single.queryParameters, {'access_token': 'jeton'});
    await live.dispose();
  });

  test('prêt puis événements ; le ping est ignoré', () async {
    final live = client();
    final got = <LiveSignal>[];
    live.signals.listen(got.add);
    live.start();
    await pumpEventQueue();
    serverSends({'type': 'ready', 'cursor': 10});
    serverSends({'type': 'ping'});
    serverSends({
      'type': 'event',
      'id': 11,
      'kind': 'notification',
      'entity_id': 'o1',
      'payload': {'kind': 'new_order'},
    });
    await pumpEventQueue();
    expect(got.first.resync, isTrue);
    expect(got.length, 2);
    expect(got.last.notificationKind, 'new_order');
    expect(got.last.entityId, 'o1');
    expect(live.status, LiveStatus.online);
    await live.dispose();
  });

  test('coupure : reconnexion avec le dernier événement reçu', () {
    fakeAsync((async) {
      final live = client()..start();
      async.flushMicrotasks();
      serverSends({'type': 'ready', 'cursor': 10});
      serverSends({'type': 'event', 'id': 12, 'kind': 'message'});
      async.flushMicrotasks();
      unawaited(sockets.last.foreign.sink.close());
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 2));
      expect(opened.length, 2);
      expect(opened.last.queryParameters['after'], '12');
      unawaited(live.dispose());
      async.flushMicrotasks();
    });
  });

  test('sans session : nouvel essai plus tard, pas de connexion', () {
    fakeAsync((async) {
      var calls = 0;
      final live = client(
        token: () async {
          calls++;
          return const Err(UnauthenticatedFailure('hors session'));
        },
      )..start();
      async.flushMicrotasks();
      expect(opened, isEmpty);
      expect(live.status, LiveStatus.waiting);
      async.elapse(const Duration(seconds: 3));
      expect(calls, greaterThan(1));
      unawaited(live.dispose());
      async.flushMicrotasks();
    });
  });

  test('arrêt : plus aucune reprise', () {
    fakeAsync((async) {
      final live = client()..start();
      async.flushMicrotasks();
      unawaited(live.stop());
      async
        ..flushMicrotasks()
        ..elapse(const Duration(minutes: 1));
      expect(opened.length, 1);
      expect(live.status, LiveStatus.idle);
      unawaited(live.dispose());
      async.flushMicrotasks();
    });
  });

  test('watchLive : un seul rechargement pour une rafale', () {
    fakeAsync((async) {
      final source = StreamController<LiveSignal>();
      var reloads = 0;
      watchLive(
        source.stream,
        when: (s) => s.kind == 'order_status',
        reload: () => reloads++,
      );
      source
        ..add(const LiveSignal.event(kind: 'order_status'))
        ..add(const LiveSignal.event(kind: 'order_status'))
        ..add(const LiveSignal.event(kind: 'message'));
      async.elapse(const Duration(seconds: 1));
      expect(reloads, 1);
      source.add(const LiveSignal.resync());
      async.elapse(const Duration(seconds: 1));
      expect(reloads, 2);
      unawaited(source.close());
    });
  });
}
