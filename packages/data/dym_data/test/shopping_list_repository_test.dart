import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';
import 'package:neon_kit/testing.dart';
import 'package:test/test.dart';

void main() {
  late FakeServer server;
  late ShoppingListRepository repository;

  setUp(() async {
    server = FakeServer();
    final now = DateTime.utc(2026, 11, 10);
    final store = InMemorySessionStore();
    await store.write(
      NeonSession(
        sessionToken: 's',
        accessToken: fakeJwt(
          sub: 'u1',
          expiresAt: now.add(const Duration(hours: 1)),
        ),
        accessTokenExpiresAt: now.add(const Duration(hours: 1)),
        userId: 'u1',
      ),
    );
    final neon = NeonClient(
      config: NeonConfig(
        authUrl: Uri.parse('https://auth.test/auth'),
        dataApiUrl: Uri.parse('https://data.test/rest/v1'),
        functionsUrl: Uri.parse('https://fn.test'),
      ),
      sessionStore: store,
      adapter: server.dioAdapter,
      httpClient: server.httpClient,
      clock: () => now,
    );
    await neon.auth.restore();
    repository = ShoppingListRepository(
      data: neon.data,
      functions: neon.functions,
    );
  });

  test('enregistrement : articles, période et premier rappel', () async {
    Map<Object?, Object?>? sent;
    server.on('POST', '/rest/v1/rpc/save_shopping_list', (r) {
      sent = (r.body! as Map)['p'] as Map;
      return const FakeResponse(200, {
        'id': 'l1',
        'name': 'Samedi',
        'items': [
          {'label': 'Tomates', 'query': 'tomate', 'quantity': 2},
        ],
        'every_days': 7,
        'next_due_on': '2026-11-14',
        'zone_id': null,
      });
    });
    final saved = await repository.save(
      name: 'Samedi',
      items: const [
        ShoppingItem(label: 'Tomates', query: 'tomate', quantity: 2),
      ],
      period: ShoppingPeriod.weekly,
      startsOn: DateTime(2026, 11, 14),
    );
    final list = saved.valueOrNull!;
    expect(list.period, ShoppingPeriod.weekly);
    expect(list.nextDueOn, DateTime(2026, 11, 14));
    expect(list.items.single.quantity, 2);
    expect(sent!['every_days'], 7);
    expect(sent!['starts_on'], '2026-11-14');
    expect(sent!.containsKey('id'), isFalse, reason: 'création');
  });

  test('sans rappel : ni période ni date envoyées', () async {
    Map<Object?, Object?>? sent;
    server.on('POST', '/rest/v1/rpc/save_shopping_list', (r) {
      sent = (r.body! as Map)['p'] as Map;
      return const FakeResponse(200, {
        'id': 'l1',
        'name': 'Fête',
        'items': [
          {'label': 'Riz', 'query': 'Riz', 'quantity': 1},
        ],
        'every_days': null,
        'next_due_on': null,
      });
    });
    final list = (await repository.save(
      id: 'l1',
      name: 'Fête',
      items: const [ShoppingItem(label: 'Riz')],
      startsOn: DateTime(2026, 11, 14),
    )).valueOrNull!;
    expect(list.period, isNull);
    expect(sent!['every_days'], isNull);
    expect(sent!.containsKey('starts_on'), isFalse);
    expect(sent!['id'], 'l1');
  });

  test('proposition : panier chiffré par la base', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/shopping_list_proposal',
      (_) => const FakeResponse(200, {
        'currency_code': 'XOF',
        'total_minor': 1000,
        'item_count': 1,
        'stores': [
          {
            'id': 's1',
            'name': 'Étal de Kodjo',
            'items': [
              {
                'variant_id': 'v1',
                'product_id': 'p1',
                'name': 'Tomates',
                'quantity': 2,
                'unit_price_minor': 500,
                'line_minor': 1000,
                'need': 'Tomates',
                'reason': 'nearby',
              },
            ],
          },
        ],
        'missing': ['Licorne'],
        'list_id': 'l1',
        'list_name': 'Samedi',
      }),
    );
    final p = (await repository.proposal('l1')).valueOrNull!;
    expect(p.totalMinor, 1000);
    expect(p.lines.single.quantity, 2);
    expect(p.missing, ['Licorne']);
  });

  test('IA : articles proposés', () async {
    server.on(
      'POST',
      '/v1/agent/list',
      (_) => const FakeResponse(200, {
        'items': [
          {'label': 'Riz', 'query': 'riz', 'quantity': 2},
        ],
      }),
    );
    final items = (await repository.suggest('la semaine')).valueOrNull!;
    expect(items.single.toJson(), {
      'label': 'Riz',
      'query': 'riz',
      'quantity': 2,
    });
  });

  test('quantité bornée en édition', () {
    const item = ShoppingItem(label: 'Riz');
    expect(item.withQuantity(40).quantity, ShoppingItem.maxQuantity);
    expect(item.withQuantity(0).quantity, ShoppingItem.minQuantity);
  });
}
