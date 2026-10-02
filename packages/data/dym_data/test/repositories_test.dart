import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:neon_kit/neon_kit.dart';
import 'package:neon_kit/testing.dart';
import 'package:test/test.dart';

const _user = '6f1c2a3b-0000-4000-8000-000000000001';

void main() {
  late FakeServer server;
  late NeonClient neon;

  setUp(() async {
    server = FakeServer();
    final now = DateTime.utc(2026, 10, 2);
    final store = InMemorySessionStore();
    await store.write(
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
    neon = NeonClient(
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
  });

  void serveTogo() {
    server
      ..on('GET', '/rest/v1/countries', (r) {
        expect(r.uri.queryParameters['code'], 'eq.TG');
        return const FakeResponse(200, {
          'code': 'TG',
          'name': {'fr': 'Togo', 'en': 'Togo'},
          'currency_code': 'XOF',
          'dial_code': '+228',
          'default_locale': 'fr',
          'timezone': 'Africa/Lome',
          'sort': 1,
          'currency': {
            'code': 'XOF',
            'minor_units': 0,
            'symbol': 'F CFA',
            'format_locale': 'fr',
          },
        });
      })
      ..on(
        'GET',
        '/rest/v1/cities',
        (_) => const FakeResponse(200, [
          {
            'id': 'lome',
            'country_code': 'TG',
            'slug': 'lome',
            'name': 'Lomé',
            'sort': 1,
          },
        ]),
      )
      ..on('GET', '/rest/v1/zones', (r) {
        expect(r.uri.queryParameters['city.country_code'], 'eq.TG');
        return const FakeResponse(200, [
          {
            'id': 'z1',
            'city_id': 'lome',
            'slug': 'be',
            'name': 'Bè',
            'sort': 1,
          },
        ]);
      })
      ..on(
        'GET',
        '/rest/v1/categories',
        (_) => const FakeResponse(200, [
          {
            'id': 'c1',
            'parent_id': null,
            'slug': 'legumes',
            'label': {'fr': 'Légumes', 'en': 'Vegetables'},
            'icon': 'legumes',
            'sort': 1,
          },
        ]),
      )
      ..on(
        'GET',
        '/rest/v1/store_origins',
        (_) => const FakeResponse(200, [
          {
            'code': 'marche',
            'label': {'fr': 'Au marché'},
            'description': null,
            'sort': 1,
          },
        ]),
      )
      ..on(
        'GET',
        '/rest/v1/units',
        (_) => const FakeResponse(200, [
          {
            'id': 'u1',
            'country_code': 'TG',
            'code': 'tas',
            'label': {'fr': 'le tas'},
            'kind': 'bundle',
            'indicative_grams': 500,
            'indicative_ml': null,
            'sort': 1,
          },
        ]),
      )
      ..on(
        'GET',
        '/rest/v1/payment_methods',
        (_) => const FakeResponse(200, [
          {
            'id': 'p1',
            'country_code': 'TG',
            'provider_code': 'cash',
            'operator_code': null,
            'label': {'fr': 'Cash à la livraison'},
            'sort': 1,
          },
        ]),
      )
      ..on('GET', '/rest/v1/delivery_fee_defaults', (r) {
        expect(r.uri.queryParameters['valid_to'], 'is.null');
        return const FakeResponse(200, [
          {
            'country_code': 'TG',
            'city_id': null,
            'currency_code': 'XOF',
            'base_fee_minor': 500,
            'extra_pickup_fee_minor': 200,
            'free_threshold_minor': 4000,
          },
        ]);
      })
      ..on(
        'GET',
        '/rest/v1/feature_flags',
        (_) => const FakeResponse(200, [
          {'key': 'momo_payments', 'country_code': null, 'is_enabled': false},
          {'key': 'momo_payments', 'country_code': 'GH', 'is_enabled': true},
        ]),
      );
  }

  group('ReferenceRepository', () {
    test('configuration complète du Togo (SC-005)', () async {
      serveTogo();
      final result = await ReferenceRepository(neon.data).countryConfig('TG');
      final config = result.valueOrNull!;
      expect(config.currency.code, 'XOF');
      expect(config.currency.minorUnits, 0);
      expect(config.zonesOf('lome').single.name, 'Bè');
      expect(config.topCategories.single.label.resolve('en'), 'Vegetables');
      expect(config.paymentMethods.single.isCash, isTrue);
      expect(config.deliveryFeeFor(null)?.freeThresholdMinor, 4000);
      expect(config.featureFlags.length, 1, reason: 'flag du Ghana écarté');
      expect(config.isEnabled('momo_payments'), isFalse);
    });

    test('pays inactif ou inconnu : NotFoundFailure', () async {
      server.on(
        'GET',
        '/rest/v1/countries',
        (_) => const FakeResponse(200, <Object>[]),
      );
      final result = await ReferenceRepository(neon.data).countryConfig('GH');
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test(
      'une lecture en échec : échec typé, pas de configuration partielle',
      () async {
        serveTogo();
        server.on(
          'GET',
          '/rest/v1/units',
          (_) => const FakeResponse(403, {
            'code': '42501',
            'message': 'permission denied',
          }),
        );
        final result = await ReferenceRepository(neon.data).countryConfig('TG');
        expect(result.failureOrNull, isA<ForbiddenFailure>());
      },
    );

    test('ligne illisible : ServerFailure', () async {
      server.on(
        'GET',
        '/rest/v1/countries',
        (_) => const FakeResponse(200, [
          {'code': 'TG'},
        ]),
      );
      final result = await ReferenceRepository(neon.data).countries();
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('EventsRepository', () {
    test('track : RPC avec identifiant client et app', () async {
      Map<Object?, Object?>? sent;
      server.on('POST', '/rest/v1/rpc/track_event', (r) {
        sent = r.body! as Map;
        return const FakeResponse(204, '');
      });
      final events = EventsRepository(
        neon.data,
        app: EventApp.client,
        newId: () => '00000000-0000-4000-8000-000000000009',
      );
      final result = await events.track(
        'search_performed',
        countryCode: 'TG',
        props: {'query': 'tomates', 'results': 12},
      );
      expect(result.isOk, isTrue);
      expect(sent?['p_name'], 'search_performed');
      expect(sent?['p_app'], 'client');
      expect(
        sent?['p_client_event_id'],
        '00000000-0000-4000-8000-000000000009',
      );
      expect((sent?['p_props'] as Map?)?['results'], 12);
    });

    test('refus serveur (donnée personnelle) : ValidationFailure', () async {
      server.on(
        'POST',
        '/rest/v1/rpc/track_event',
        (_) => const FakeResponse(400, {
          'code': '22023',
          'message': 'propriété personnelle interdite : email',
        }),
      );
      final result = await EventsRepository(
        neon.data,
        app: EventApp.client,
      ).track('cart_item_added', props: {'email': 'x@y.z'});
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });
}
