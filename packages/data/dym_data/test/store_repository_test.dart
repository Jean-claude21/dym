import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';
import 'package:neon_kit/testing.dart';
import 'package:test/test.dart';

const _user = '6f1c2a3b-0000-4000-8000-000000000002';

const Map<String, Object?> _storeJson = {
  'id': 's1',
  'name': 'Chez Afi',
  'description': null,
  'origin': 'marche',
  'zone_id': 'z1',
  'country_code': 'TG',
  'currency_code': 'XOF',
  'main_category_id': 'c1',
  'prep_time_minutes': 30,
  'offers_pickup': false,
  'delivery_fee_minor': 500,
  'status': 'draft',
  'is_open': false,
  'onboarding_step': 3,
  'published_at': null,
  'pickup_address': null,
  'delivery_zone_ids': <String>[],
  'payment_method_ids': <String>[],
  'hours': <Object>[],
  'missing': ['pickup_address', 'delivery_zones', 'payment_methods', 'hours'],
};

void main() {
  late FakeServer server;
  late StoreRepository stores;

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
    );
    await neon.auth.restore();
    stores = StoreRepository(neon.data);
  });

  test('myStore : aucune boutique → null', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/my_store',
      (_) => const FakeResponse(200, 'null'),
    );
    final result = await stores.myStore();
    expect(result.isOk, isTrue);
    expect(result.valueOrNull, isNull);
  });

  test('myStore : boutique lue avec ce qui manque', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/my_store',
      (_) => const FakeResponse(200, _storeJson),
    );
    final store = (await stores.myStore()).valueOrNull!;
    expect(store.onboardingStep, 3);
    expect(store.deliveryFeeMinor, 500);
    expect(store.missing, contains('hours'));
  });

  test('update : le patch est transmis tel quel', () async {
    Map<Object?, Object?>? sent;
    server.on('POST', '/rest/v1/rpc/update_store', (r) {
      sent = r.body! as Map;
      return const FakeResponse(200, _storeJson);
    });
    await stores.update({'origin': 'marche', 'onboarding_step': 3});
    expect(sent, {
      'p_patch': {'origin': 'marche', 'onboarding_step': 3},
    });
  });

  test('setHours : jours au format HH:MM', () async {
    Map<Object?, Object?>? sent;
    server.on('POST', '/rest/v1/rpc/set_store_hours', (r) {
      sent = r.body! as Map;
      return const FakeResponse(200, _storeJson);
    });
    await stores.setHours(const [
      StoreHours(weekday: 1, opensAt: '07:00', closesAt: '19:00'),
    ]);
    expect(sent, {
      'p_hours': [
        {'weekday': 1, 'opens_at': '07:00', 'closes_at': '19:00'},
      ],
    });
  });

  test('publish incomplète : ValidationFailure', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/publish_store',
      (_) => const FakeResponse(400, {
        'code': 'P0001',
        'message': 'boutique incomplète',
      }),
    );
    expect((await stores.publish()).failureOrNull, isA<ValidationFailure>());
  });

  test('sans boutique : NotFoundFailure', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/set_store_open',
      (_) => const FakeResponse(404, {
        'code': 'P0002',
        'message': 'aucune boutique',
      }),
    );
    expect(
      (await stores.setOpen(open: true)).failureOrNull,
      isA<NotFoundFailure>(),
    );
  });
}
