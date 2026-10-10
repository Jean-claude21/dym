import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';
import 'package:neon_kit/testing.dart';
import 'package:test/test.dart';

void main() {
  late FakeServer server;
  late VendorDashboardRepository repository;
  setUp(() async {
    server = FakeServer();
    final now = DateTime.utc(2026, 10, 5);
    final session = InMemorySessionStore();
    await session.write(
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
      sessionStore: session,
      adapter: server.dioAdapter,
      httpClient: server.httpClient,
      clock: () => now,
    );
    await neon.auth.restore();
    repository = VendorDashboardRepository(neon.data);
  });
  test(
    'période envoyée et bigint reçu sans calcul ni arrondi dans Dart',
    () async {
      Map<Object?, Object?>? body;
      server.on('POST', '/rest/v1/rpc/my_vendor_dashboard', (request) {
        body = request.body! as Map;
        return const FakeResponse(200, {
          'period': 'month',
          'currency_code': 'GHS',
          'revenue_minor': '12345',
          'order_count': 6,
          'pending_payments': 2,
          'pending_orders': 1,
          'active_orders': 3,
          'out_of_stock': 2,
          'critical_notifications': 1,
        });
      });
      final result = await repository.summary(DashboardPeriod.month);
      expect(body, {'p_period': 'month'});
      expect(result.valueOrNull?.revenueMinor, 12345);
      expect(result.valueOrNull?.currencyCode, 'GHS');
    },
  );
  test('réponse incomplète : échec, aucune valeur fictive', () async {
    server.on(
      'POST',
      '/rest/v1/rpc/my_vendor_dashboard',
      (_) => const FakeResponse(200, {}),
    );
    final result = await repository.summary(DashboardPeriod.day);
    expect(result.failureOrNull, isA<ServerFailure>());
    expect(result.valueOrNull, isNull);
  });
  test('refus serveur propagé et aucune nouvelle tentative sur 403', () async {
    var calls = 0;
    server.on('POST', '/rest/v1/rpc/my_vendor_dashboard', (_) {
      calls++;
      return const FakeResponse(403, {'code': '42501', 'message': 'forbidden'});
    });
    expect(
      (await repository.summary(DashboardPeriod.day)).failureOrNull,
      isA<ForbiddenFailure>(),
    );
    expect(calls, 1);
  });
}
