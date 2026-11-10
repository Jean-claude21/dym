import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';
import 'package:neon_kit/testing.dart';
import 'package:test/test.dart';

void main() {
  late FakeServer server;
  late FavoritesRepository repository;

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
    repository = FavoritesRepository(neon.data);
  });

  test('favori : geste et état', () async {
    Map<Object?, Object?>? sent;
    server
      ..on('POST', '/rest/v1/rpc/toggle_favorite', (r) {
        sent = r.body! as Map;
        return const FakeResponse(200, true);
      })
      ..on(
        'POST',
        '/rest/v1/rpc/my_favorite_ids',
        (_) => const FakeResponse(200, {
          'store_ids': ['s1'],
          'product_ids': <String>[],
        }),
      );
    expect(
      (await repository.toggle(FavoriteKind.store, 's1')).valueOrNull,
      isTrue,
    );
    expect(sent!['p_kind'], 'store');
    final ids = (await repository.ids()).valueOrNull!;
    expect(ids.contains(FavoriteKind.store, 's1'), isTrue);
    final off = ids.withState(FavoriteKind.store, 's1', on: false);
    expect(off.contains(FavoriteKind.store, 's1'), isFalse);
  });

  test('panier enregistré : prix du jour et disponibilité', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/my_baskets',
      (_) => const FakeResponse(200, [
        {
          'id': 'b1',
          'name': 'Petit-déjeuner',
          'currency_code': 'XOF',
          'total_minor': 1000,
          'available_count': 1,
          'items': [
            {
              'variant_id': 'v1',
              'product_id': 'p1',
              'name': 'Tomates',
              'quantity': 2,
              'unit_price_minor': 500,
              'available': true,
            },
            {
              'variant_id': 'v2',
              'product_id': 'p2',
              'name': 'Piment',
              'quantity': 1,
              'unit_price_minor': 200,
              'available': false,
            },
          ],
        },
      ]),
    );
    final basket = (await repository.baskets()).valueOrNull!.single;
    expect(basket.totalMinor, 1000);
    expect(basket.items.last.available, isFalse);
  });

  test('remise au panier : articles non ajoutés nommés', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/basket_to_cart',
      (_) => const FakeResponse(200, {
        'added': 1,
        'skipped': ['Piment'],
        'cart': <String, Object?>{},
      }),
    );
    final result = (await repository.toCart('b1')).valueOrNull!;
    expect(result.added, 1);
    expect(result.skipped, ['Piment']);
  });
}
