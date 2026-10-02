import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';
import 'package:neon_kit/testing.dart';
import 'package:test/test.dart';

const _user = '6f1c2a3b-0000-4000-8000-000000000001';

void main() {
  late FakeServer server;
  late AccountRepository account;

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
    account = AccountRepository(neon.data);
  });

  const meJson = {
    'user_id': _user,
    'profile': {
      'user_id': _user,
      'first_name': 'Fatou',
      'country_code': 'TG',
      'zone_id': 'z1',
      'locale': 'fr',
    },
    'roles': ['vendor'],
  };

  test('completeProfile : paramètres de la fonction SQL', () async {
    Map<Object?, Object?>? sent;
    server.on('POST', '/rest/v1/rpc/complete_profile', (r) {
      sent = r.body! as Map;
      return const FakeResponse(200, meJson);
    });
    final result = await account.completeProfile(
      firstName: ' Fatou ',
      zoneId: 'z1',
      app: AccountApp.vendor,
    );
    expect(result.valueOrNull?.hasRole(UserRole.vendor), isTrue);
    expect(sent, {
      'p_first_name': 'Fatou',
      'p_zone_id': 'z1',
      'p_app': 'vendor',
      'p_locale': 'fr',
    });
  });

  test('recordSignIn admin refusé : ForbiddenFailure', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/record_sign_in',
      (_) => const FakeResponse(403, {
        'code': '42501',
        'message': 'accès réservé aux admins',
      }),
    );
    final result = await account.recordSignIn(AccountApp.admin);
    expect(result.failureOrNull, isA<ForbiddenFailure>());
  });

  test(
    'me sans session côté serveur (null) : UnauthenticatedFailure',
    () async {
      server.on(
        'POST',
        '/rest/v1/rpc/me',
        (_) => const FakeResponse(200, 'null'),
      );
      final result = await account.me();
      expect(result.failureOrNull, isNotNull);
    },
  );

  test('suppression : RPC sans paramètre', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/delete_my_account',
      (_) => const FakeResponse(204, ''),
    );
    expect((await account.deleteMyAccount()).isOk, isTrue);
    expect(server.count('POST', '/rest/v1/rpc/delete_my_account'), 1);
  });
}
