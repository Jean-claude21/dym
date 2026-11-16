import 'package:dym_platform/src/push_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('boutons par type de notification (spec 097)', () {
    expect(pushActionsFor('new_order'), ['accept', 'view']);
    expect(pushActionsFor('mission_available'), ['accept', 'view']);
    expect(pushActionsFor('incoming_call_vendor'), ['answer', 'decline']);
    expect(pushActionsFor('new_message_vendor'), ['reply', 'view']);
    expect(pushActionsFor('order_delivered'), isEmpty);
  });

  test('libellés gardés et relus', () {
    const labels = PushLabels(accept: 'Accept', decline: 'Decline');
    final back = PushLabels.fromJson(labels.toJson());
    expect(back.accept, 'Accept');
    expect(back.decline, 'Decline');
    const channels = PushChannels(calls: 'Calls');
    expect(PushChannels.fromJson(channels.toJson()).calls, 'Calls');
    expect(channels.nameOf(PushChannels.callsId), 'Calls');
  });
}
