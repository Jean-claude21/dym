import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';
import 'package:neon_kit/testing.dart';
import 'package:test/test.dart';

const _user = '6f1c2a3b-0000-4000-8000-000000000003';

const Map<String, Object?> _productJson = {
  'id': 'p1',
  'name': 'Jus de bissap',
  'description': null,
  'category_id': 'c1',
  'unit_id': null,
  'price_minor': 500,
  'currency_code': 'XOF',
  'status': 'draft',
  'is_available': true,
  'suggestion_id': 's1',
  'variants': [
    {'id': 'v1', 'label': null, 'price_minor': null, 'stock_quantity': 12},
  ],
  'photo_keys': ['stores/s/products/a.jpg'],
  'store_category_ids': <String>[],
  'missing': <String>[],
};

void main() {
  late FakeServer server;
  late CatalogRepository catalog;
  late CatalogMediaRepository media;

  setUp(() async {
    server = FakeServer();
    final now = DateTime.utc(2026, 10, 2);
    final session = InMemorySessionStore();
    await session.write(
      NeonSession(
        sessionToken: 's',
        accessToken: fakeJwt(
          sub: _user,
          expiresAt: now.add(const Duration(hours: 1)),
        ),
        accessTokenExpiresAt: now.add(const Duration(hours: 1)),
        userId: _user,
      ),
    );
    final neon = NeonClient(
      config: NeonConfig(
        authUrl: Uri.parse('https://auth.test/auth'),
        dataApiUrl: Uri.parse('https://data.test/rest/v1'),
        functionsUrl: Uri.parse('https://fn.test'),
      ),
      sessionStore: session,
      adapter: server.dioAdapter,
      httpClient: server.httpClient,
      clock: () => now,
      sleep: (_) async {},
    );
    await neon.auth.restore();
    catalog = CatalogRepository(neon.data);
    media = CatalogMediaRepository(
      functions: neon.functions,
      uploads: neon.uploads,
    );
  });

  test('saveProduct : fiche complète transmise en un appel', () async {
    Map<Object?, Object?>? sent;
    server.on('POST', '/rest/v1/rpc/save_product', (r) {
      sent = r.body! as Map;
      return const FakeResponse(200, _productJson);
    });
    final result = await catalog.saveProduct(
      id: 'p1',
      name: 'Jus de bissap',
      categoryId: 'c1',
      priceMinor: 500,
      suggestionId: 's1',
      photoKeys: const ['stores/s/products/a.jpg'],
      variants: const [ProductVariant(id: 'v1', stockQuantity: 12)],
    );
    expect(result.valueOrNull?.suggestionId, 's1');
    final payload = sent!['p_product']! as Map;
    expect(payload['id'], 'p1');
    expect(payload['price_minor'], 500);
    expect(payload.containsKey('currency_code'), isFalse);
    expect(payload['variants'], [
      {'id': 'v1', 'label': null, 'price_minor': null, 'stock_quantity': 12},
    ]);
  });

  test('publish incomplet : ValidationFailure', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/publish_product',
      (_) => const FakeResponse(400, {
        'code': 'P0001',
        'message': 'produit incomplet : photo',
      }),
    );
    expect(
      (await catalog.publish('p1')).failureOrNull,
      isA<ValidationFailure>(),
    );
  });

  test('catégories : liste avec le nombre de produits', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/save_store_category',
      (_) => const FakeResponse(200, [
        {
          'id': 'c1',
          'name': 'Jus',
          'sort': 0,
          'is_archived': false,
          'product_count': 4,
        },
      ]),
    );
    final result = await catalog.saveStoreCategory('c1', 'Jus');
    expect(result.valueOrNull?.single.productCount, 4);
  });

  test('nom de catégorie en double : ConflictFailure', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/save_store_category',
      (_) => const FakeResponse(409, {'code': '23505', 'message': 'doublon'}),
    );
    expect(
      (await catalog.saveStoreCategory('c2', 'jus')).failureOrNull,
      isA<ConflictFailure>(),
    );
  });

  test('photo : URL présignée puis envoi direct', () async {
    server
      ..on(
        'POST',
        '/v1/catalog/photo-uploads',
        (_) => const FakeResponse(200, {
          'object_key': 'stores/s/products/a.jpg',
          'upload_url':
              'https://s3.test/product-photos/stores/s/products/a.jpg?sig',
          'public_url':
              'https://s3.test/product-photos/stores/s/products/a.jpg',
          'expires_in': 300,
        }),
      )
      ..on(
        'PUT',
        '/product-photos/stores/s/products/a.jpg',
        (_) => const FakeResponse(200, ''),
      );
    final result = await media.uploadPhoto([
      1,
      2,
      3,
    ], contentType: 'image/jpeg');
    expect(result.valueOrNull?.objectKey, 'stores/s/products/a.jpg');
    expect(server.count('PUT', '/product-photos/stores/s/products/a.jpg'), 1);
  });

  test('photo : envoi refusé, aucune clé renvoyée', () async {
    server
      ..on(
        'POST',
        '/v1/catalog/photo-uploads',
        (_) => const FakeResponse(200, {
          'object_key': 'k',
          'upload_url': 'https://s3.test/b/k.jpg',
          'public_url': 'https://s3.test/b/k.jpg',
        }),
      )
      ..on('PUT', '/b/k.jpg', (_) => const FakeResponse(403, 'expirée'));
    final result = await media.uploadPhoto([1], contentType: 'image/jpeg');
    expect(result.failureOrNull, isA<ForbiddenFailure>());
  });

  test('proposition indisponible (503) : échec, une seule tentative', () async {
    server.on(
      'POST',
      '/v1/catalog/suggestions',
      (_) => const FakeResponse(503, {
        'error': {'code': 'unavailable', 'message': 'proposition désactivée'},
      }),
    );
    final result = await media.suggest('stores/s/products/a.jpg');
    expect(result.failureOrNull, isNotNull);
    expect(server.count('POST', '/v1/catalog/suggestions'), 1);
  });

  test('proposition reçue', () async {
    server.on(
      'POST',
      '/v1/catalog/suggestions',
      (_) => const FakeResponse(200, {
        'suggestion_id': 's1',
        'name': 'Jus de bissap 50 cl',
        'category_id': 'c1',
        'description': 'Frais.',
      }),
    );
    final result = await media.suggest('stores/s/products/a.jpg');
    expect(result.valueOrNull?.name, 'Jus de bissap 50 cl');
  });
}
