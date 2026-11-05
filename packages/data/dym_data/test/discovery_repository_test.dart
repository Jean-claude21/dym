import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';
import 'package:neon_kit/testing.dart';
import 'package:test/test.dart';

const Map<String, Object?> _store = {
  'id': 's1',
  'name': "Les jus d'Esi",
  'description': null,
  'origin': 'maison',
  'zone_id': 'z1',
  'zone_name': 'Tokoin',
  'zone_latitude': 6.152,
  'zone_longitude': 1.218,
  'country_code': 'TG',
  'currency_code': 'XOF',
  'prep_time_minutes': 30,
  'offers_pickup': true,
  'open_now': true,
  'closes_at': '19:00',
  'delivery_minutes': 50,
  'cover_key': 'stores/s1/products/p1.jpg',
  'product_count': 2,
};

const Map<String, Object?> _item = {
  'id': 'p1',
  'name': 'Jus de bissap',
  'category_id': 'c1',
  'price_minor': 700,
  'min_price_minor': 400,
  'currency_code': 'XOF',
  'unit_label': {'fr': 'le litre', 'en': 'per litre'},
  'photo_key': 'stores/s1/products/p1.jpg',
  'variant_count': 2,
  'available': true,
  'store': {
    'id': 's1',
    'name': "Les jus d'Esi",
    'origin': 'maison',
    'zone_name': 'Tokoin',
  },
  'store_category_ids': ['sc1'],
};

void main() {
  late FakeServer server;
  late DiscoveryRepository discovery;

  setUp(() {
    server = FakeServer();
    final neon = NeonClient(
      config: NeonConfig(
        authUrl: Uri.parse('https://auth.test/auth'),
        dataApiUrl: Uri.parse('https://data.test/rest/v1'),
        functionsUrl: Uri.parse('https://fn.test'),
      ),
      sessionStore: InMemorySessionStore(),
      adapter: server.dioAdapter,
      httpClient: server.httpClient,
    );
    discovery = DiscoveryRepository(neon.data);
  });

  test('accueil sans session : boutiques et estimation', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/discover_stores',
      (_) => const FakeResponse(200, {
        'estimate_minutes': 50,
        'stores': [_store],
      }),
    );
    final result = (await discovery.discover('z1')).valueOrNull!;
    expect(result.estimateMinutes, 50);
    expect(result.openStores.single.closesAt, '19:00');
    expect(result.stores.single.zoneLatitude, 6.152);
  });

  test('recherche : paramètres et résultats', () async {
    Map<Object?, Object?>? sent;
    server.on('POST', '/rest/v1/rpc/search_catalog', (r) {
      sent = r.body! as Map;
      return const FakeResponse(200, {
        'total': 1,
        'products': [_item],
        'stores': [_store],
      });
    });
    final result = await discovery.search(
      const SearchQuery(
        text: 'biss',
        zoneId: 'z1',
        origin: 'maison',
        availableOnly: true,
        sort: SearchSort.priceAsc,
      ),
    );
    final item = result.valueOrNull!.products.single;
    expect(item.displayPriceMinor, 400, reason: 'plusieurs variantes : dès');
    expect(item.unitLabel?.resolve('fr'), 'le litre');
    expect(sent!['p_sort'], 'price_asc');
    expect(sent!['p_available_only'], true);
    expect(sent!['p_origin'], 'maison');
  });

  test('page boutique et fiche', () async {
    server
      ..on(
        'POST',
        '/rest/v1/rpc/store_page',
        (_) => const FakeResponse(200, {
          ..._store,
          'hours': [
            {'weekday': 1, 'opens_at': '07:00', 'closes_at': '19:00'},
          ],
          'categories': [
            {'id': 'sc1', 'name': 'Jus'},
          ],
          'products': [_item],
        }),
      )
      ..on(
        'POST',
        '/rest/v1/rpc/product_page',
        (_) => FakeResponse(200, <String, Object?>{
          ...Map.of(_item)..remove('store'),
          'description': 'Frais.',
          'photo_keys': ['a', 'b'],
          'variants': [
            {
              'id': 'v1',
              'label': '50 cl',
              'price_minor': 400,
              'available': true,
            },
            {
              'id': 'v2',
              'label': '1 L',
              'price_minor': 700,
              'available': false,
            },
          ],
          'store': _store,
          'zone_name': 'Bè',
          'serves_zone': true,
        }),
      );
    final page = (await discovery.storePage('s1')).valueOrNull!;
    expect(page.categories.single.name, 'Jus');
    expect(page.hours.single.closesAt, '19:00');
    final product = (await discovery.productPage(
      'p1',
      zoneId: 'z2',
    )).valueOrNull!;
    expect(product.variants.last.available, isFalse);
    expect(product.store.deliveryMinutes, 50);
    expect(product.zoneName, 'Bè');
  });

  test('fiche retirée : NotFoundFailure', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/product_page',
      (_) => const FakeResponse(200, 'null'),
    );
    expect(
      (await discovery.productPage('p9')).failureOrNull,
      isA<NotFoundFailure>(),
    );
  });

  test('quartier le plus proche', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/nearest_zone',
      (_) => const FakeResponse(200, {
        'zone_id': 'z1',
        'zone_name': 'Tokoin',
        'city_id': 'c1',
        'city_name': 'Lomé',
        'country_code': 'TG',
        'distance_m': 180,
      }),
    );
    final match = (await discovery.nearestZone(6.151, 1.217)).valueOrNull;
    expect(match?.zoneName, 'Tokoin');
  });

  test('filtres actifs comptés', () {
    expect(const SearchQuery(text: 'x').activeFilters, 0);
    expect(
      const SearchQuery(
        origin: 'maison',
        availableOnly: true,
        sort: SearchSort.priceDesc,
      ).activeFilters,
      3,
    );
  });
}
