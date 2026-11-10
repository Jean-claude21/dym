import 'package:dym_data/dym_data.dart';
import 'package:neon_kit/neon_kit.dart';
import 'package:neon_kit/testing.dart';
import 'package:test/test.dart';

void main() {
  late FakeServer server;
  late SpaceRepository repository;

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
    repository = SpaceRepository(neon.data);
  });

  const space = {
    'id': 'sp1',
    'name': 'Maison',
    'join_code': 'ABCD2345',
    'my_role': 'member',
    'is_owner': false,
    'currency_code': 'XOF',
    'monthly_budget_minor': 3000,
    'spent_month_minor': 1000,
    'total_minor': 2500,
    'members': [
      {'user_id': 'u1', 'first_name': 'Awa', 'role': 'payer', 'is_owner': true},
      {'user_id': 'u2', 'first_name': 'Kofi', 'role': 'member', 'is_me': true},
    ],
    'items': [
      {
        'variant_id': 'v1',
        'product_id': 'p1',
        'name': 'Tomates',
        'quantity': 5,
        'unit_price_minor': 500,
        'available': true,
        'added_by': 'Kofi',
      },
    ],
  };

  test('espace : rôles, budget et panier commun', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/space_detail',
      (_) => const FakeResponse(200, space),
    );
    final s = (await repository.space('sp1')).valueOrNull!;
    expect(s.canValidate, isFalse);
    expect(s.remainingMinor, 2000);
    expect(s.overBudget, isTrue);
    expect(s.members.first.isOwner, isTrue);
    expect(s.items.single.addedBy, 'Kofi');
  });

  test('rejoindre : code transmis', () async {
    Map<Object?, Object?>? sent;
    server.on('POST', '/rest/v1/rpc/join_space', (r) {
      sent = r.body! as Map;
      return const FakeResponse(200, space);
    });
    await repository.join('abcd2345');
    expect(sent!['p_code'], 'abcd2345');
  });

  test('valider : articles passés au panier', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/validate_space',
      (_) => const FakeResponse(200, {'added': 1, 'skipped': <String>[]}),
    );
    expect((await repository.validate('sp1')).valueOrNull!.added, 1);
  });
}
