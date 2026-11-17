import 'dart:io';

import 'package:dym_platform/dym_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fichiers JSON : écrire, relire, effacer (spec 107)', () async {
    final dir = await Directory.systemTemp.createTemp('dym_store');
    final store = FileJsonStore(directory: () async => dir);
    await store.write('home/be', {
      'popular': [1, 2],
    });
    expect(await store.read('home/be'), {
      'popular': [1, 2],
    });
    await store.delete('home/be');
    expect(await store.read('home/be'), isNull);
    await dir.delete(recursive: true);
  });

  test('file hors ligne : gardée, remplacée, rejouée dans l’ordre', () async {
    final store = MemoryJsonStore();
    final queue = OfflineQueue(store);
    await queue.add(
      const OfflineGesture(id: 'p1', kind: 'stock', payload: {'on': false}),
    );
    await queue.add(
      const OfflineGesture(id: 'p2', kind: 'stock', payload: {'on': false}),
    );
    // Nouveau geste sur p1 : remplace l'ancien.
    await queue.add(
      const OfflineGesture(id: 'p1', kind: 'stock', payload: {'on': true}),
    );
    expect(queue.items.map((g) => g.id), ['p2', 'p1']);

    // Relue depuis le stockage (redémarrage de l'app).
    final again = OfflineQueue(store);
    await again.load();
    expect(again.items.last.payload['on'], isTrue);

    // Pas de réseau au premier : rien ne part.
    await again.replay((_) async => ReplayOutcome.retry);
    expect(again.items, hasLength(2));
    final seen = <String>[];
    await again.replay((g) async {
      seen.add(g.id);
      return g.id == 'p2' ? ReplayOutcome.done : ReplayOutcome.dropped;
    });
    expect(seen, ['p2', 'p1']);
    expect(again.isEmpty, isTrue);
    expect(await store.read('offline_queue'), isEmpty);
  });
}
