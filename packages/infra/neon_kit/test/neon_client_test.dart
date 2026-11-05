import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:neon_kit/neon_kit.dart';
import 'package:neon_kit/testing.dart';
import 'package:test/test.dart';

const _user = '6f1c2a3b-0000-4000-8000-000000000001';

void main() {
  late FakeServer server;
  late InMemorySessionStore store;
  late DateTime now;
  late NeonClient neon;

  final config = NeonConfig(
    authUrl: Uri.parse('https://auth.test/neondb/auth'),
    dataApiUrl: Uri.parse('https://data.test/rest/v1'),
    functionsUrl: Uri.parse('https://fn.test'),
    retryBaseDelay: Duration.zero,
  );

  String jwtValidFor(Duration d) => fakeJwt(sub: _user, expiresAt: now.add(d));

  void authRoutes({Duration tokenLifetime = const Duration(minutes: 15)}) {
    server
      ..on(
        'POST',
        '/neondb/auth/email-otp/send-verification-otp',
        (_) => const FakeResponse(200, {'success': true}),
      )
      ..on('POST', '/neondb/auth/sign-in/email-otp', (r) {
        final body = r.body! as Map;
        if (body['otp'] != '123456') {
          return const FakeResponse(400, {'message': 'INVALID_OTP'});
        }
        return const FakeResponse(
          200,
          {
            'user': {'id': _user, 'email': 'awa@example.com'},
          },
          {'set-auth-token': 'session-1'},
        );
      })
      ..on('POST', '/neondb/auth/sign-in/social', (r) {
        final body = r.body! as Map;
        expect(body['provider'], 'google');
        return const FakeResponse(200, {
          'token': 'session-g',
          'user': {'id': _user, 'email': 'awa@gmail.com'},
        });
      })
      ..on('GET', '/neondb/auth/token', (r) {
        if (r.bearer == 'revoquee') {
          return const FakeResponse(401, {'message': 'UNAUTHORIZED'});
        }
        return FakeResponse(200, {'token': jwtValidFor(tokenLifetime)});
      })
      ..on(
        'POST',
        '/neondb/auth/sign-out',
        (_) => const FakeResponse(200, {'success': true}),
      );
  }

  setUp(() {
    server = FakeServer();
    store = InMemorySessionStore();
    now = DateTime.utc(2026, 10, 2, 10);
    neon = NeonClient(
      config: config,
      sessionStore: store,
      adapter: server.dioAdapter,
      httpClient: server.httpClient,
      clock: () => now,
      sleep: (_) async {},
    );
  });

  Future<void> signIn() async {
    authRoutes();
    await neon.auth.sendEmailOtp('awa@example.com');
    final result = await neon.auth.verifyEmailOtp('awa@example.com', '123456');
    expect(result.isOk, isTrue, reason: '$result');
  }

  group('authentification (US2)', () {
    test('OTP email : envoi puis vérification ouvrent une session', () async {
      authRoutes();
      expect((await neon.auth.sendEmailOtp(' Awa@Example.com ')).isOk, isTrue);
      final sent = server.requests.first.body! as Map;
      expect(sent['email'], 'awa@example.com');

      final emitted = <NeonSession?>[];
      final sub = neon.auth.sessionChanges.listen(emitted.add);
      final result = await neon.auth.verifyEmailOtp(
        'awa@example.com',
        '123456',
      );
      final session = result.valueOrNull!;
      expect(session.userId, _user);
      expect(session.sessionToken, 'session-1');
      expect(
        session.accessTokenExpiresAt,
        now.add(const Duration(minutes: 15)),
      );
      expect(await store.read(), isNotNull);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.single?.userId, _user);
      await sub.cancel();
    });

    test('OTP faux : échec de validation, pas de session', () async {
      authRoutes();
      final result = await neon.auth.verifyEmailOtp('awa@example.com', '000');
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(await store.read(), isNull);
    });

    test('Google : idToken → session', () async {
      authRoutes();
      final result = await neon.auth.signInWithGoogleIdToken('google-id');
      expect(result.valueOrNull?.email, 'awa@gmail.com');
      final body = server.requests.first.body! as Map;
      expect((body['idToken'] as Map)['token'], 'google-id');
    });

    test('restauration : session révoquée → déconnectée', () async {
      authRoutes();
      await store.write(
        NeonSession(
          sessionToken: 'revoquee',
          accessToken: jwtValidFor(const Duration(minutes: -5)),
          accessTokenExpiresAt: now.subtract(const Duration(minutes: 5)),
          userId: _user,
        ),
      );
      final result = await neon.auth.restore();
      expect(result, const Ok<NeonSession?>(null));
      expect(await store.read(), isNull);
    });

    test('restauration hors ligne : session conservée', () async {
      server.on('GET', '/neondb/auth/token', (_) => const NetworkDown());
      final stored = NeonSession(
        sessionToken: 's',
        accessToken: jwtValidFor(const Duration(minutes: -1)),
        accessTokenExpiresAt: now.subtract(const Duration(minutes: 1)),
        userId: _user,
      );
      await store.write(stored);
      final result = await neon.auth.restore();
      expect(result.valueOrNull?.userId, _user);
    });

    test('déconnexion : session effacée même hors ligne', () async {
      await signIn();
      server.on('POST', '/neondb/auth/sign-out', (_) => const NetworkDown());
      await neon.auth.signOut();
      expect(neon.auth.currentSession, isNull);
      expect(await store.read(), isNull);
    });
  });

  group("jeton d'accès (SC-003)", () {
    test('renouvelé avant expiration (marge 60 s)', () async {
      await signIn();
      now = now.add(const Duration(minutes: 14, seconds: 30));
      final token = await neon.auth.validAccessToken();
      expect(token.isOk, isTrue);
      expect(server.count('GET', '/neondb/auth/token'), 2);
    });

    test("pas de renouvellement tant qu'il est frais", () async {
      await signIn();
      await neon.auth.validAccessToken();
      await neon.auth.validAccessToken();
      expect(server.count('GET', '/neondb/auth/token'), 1);
    });

    test('deux requêtes simultanées : un seul renouvellement', () async {
      await signIn();
      now = now.add(const Duration(minutes: 20));
      final gate = Completer<void>();
      server.on('GET', '/neondb/auth/token', (_) async {
        await gate.future;
        return FakeResponse(200, {
          'token': jwtValidFor(const Duration(minutes: 15)),
        });
      });
      final a = neon.auth.validAccessToken();
      final b = neon.auth.validAccessToken();
      gate.complete();
      expect((await a).isOk && (await b).isOk, isTrue);
      expect(server.count('GET', '/neondb/auth/token'), 2); // connexion + 1
    });
  });

  group('Data API', () {
    test('lecture avec le jeton courant', () async {
      await signIn();
      server.on('GET', '/rest/v1/countries', (r) {
        expect(r.bearer, isNotNull);
        return const FakeResponse(200, [
          {'code': 'TG'},
        ]);
      });
      final result = await neon.data.run((db) => db.from('countries').select());
      expect(result.valueOrNull, [
        {'code': 'TG'},
      ]);
    });

    test('401 : renouvellement puis une seule nouvelle tentative', () async {
      await signIn();
      var calls = 0;
      server.on('GET', '/rest/v1/profiles', (_) {
        calls++;
        return calls == 1
            ? const FakeResponse(401, {'code': 'PGRST301', 'message': 'JWT'})
            : const FakeResponse(200, <Object>[]);
      });
      final result = await neon.data.run((db) => db.from('profiles').select());
      expect(result.isOk, isTrue);
      expect(calls, 2);
      expect(server.count('GET', '/neondb/auth/token'), 2);
    });

    test('RLS : 403 → ForbiddenFailure, sans nouvelle tentative', () async {
      await signIn();
      server.on(
        'POST',
        '/rest/v1/stores',
        (_) => const FakeResponse(403, {
          'code': '42501',
          'message': 'new row violates row-level security policy',
        }),
      );
      final result = await neon.data.run(
        (db) => db.from('stores').insert({'name': 'x'}),
      );
      expect(result.failureOrNull, isA<ForbiddenFailure>());
      expect(server.count('POST', '/rest/v1/stores'), 1);
    });

    test('doublon : 409/23505 → ConflictFailure', () async {
      await signIn();
      server.on(
        'POST',
        '/rest/v1/rpc/create_thing',
        (_) => const FakeResponse(409, {'code': '23505', 'message': 'dup'}),
      );
      final result = await neon.data.rpc<Object?>('create_thing');
      expect(result.failureOrNull, isA<ConflictFailure>());
    });

    test('sans session : UnauthenticatedFailure, aucune requête', () async {
      final result = await neon.data.run((db) => db.from('x').select());
      expect(result.failureOrNull, isA<UnauthenticatedFailure>());
      expect(server.requests, isEmpty);
    });

    test("page HTML d'un proxy : ServerFailure", () async {
      await signIn();
      server.on(
        'GET',
        '/rest/v1/countries',
        (_) => const FakeResponse(200, '<html>maintenance</html>'),
      );
      final result = await neon.data.run((db) => db.from('countries').select());
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('Functions et nouvelles tentatives (SC-002)', () {
    test("POST avec clé d'idempotence : retenté sur 503, ≤ 3 fois", () async {
      await signIn();
      server.on(
        'POST',
        '/orders',
        (_) => const FakeResponse(503, {
          'error': {'code': 'internal', 'message': 'occupé'},
        }),
      );
      final result = await neon.functions.post<Object?>(
        '/orders',
        body: {'a': 1},
        idempotencyKey: 'k-1',
        decode: (j) => j,
      );
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(server.count('POST', '/orders'), 4); // 1 + 3 nouvelles tentatives
      expect(server.requests.last.headers['Idempotency-Key'], 'k-1');
    });

    test('POST sans clé : jamais retenté', () async {
      await signIn();
      server.on('POST', '/notify', (_) => const NetworkDown());
      final result = await neon.functions.post<Object?>(
        '/notify',
        decode: (j) => j,
      );
      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(server.count('POST', '/notify'), 1);
    });

    test('GET : réseau coupé puis rétabli', () async {
      await signIn();
      var calls = 0;
      server.on('GET', '/health', (_) {
        calls++;
        return calls < 3
            ? const NetworkDown()
            : const FakeResponse(200, {'status': 'ok'});
      });
      final result = await neon.functions.get<Map<Object?, Object?>>(
        '/health',
        decode: (j) => j! as Map,
      );
      expect(result.valueOrNull?['status'], 'ok');
      expect(calls, 3);
    });

    test('4xx : aucune nouvelle tentative, champs remontés', () async {
      await signIn();
      server.on(
        'POST',
        '/orders',
        (_) => const FakeResponse(422, {
          'error': {
            'code': 'validation',
            'message': 'invalide',
            'fields': {'items': 'vide'},
          },
        }),
      );
      final result = await neon.functions.post<Object?>(
        '/orders',
        idempotencyKey: 'k-2',
        decode: (j) => j,
      );
      final failure = result.failureOrNull! as ValidationFailure;
      expect(failure.fields, {'items': 'vide'});
      expect(server.count('POST', '/orders'), 1);
    });

    test(
      '401 sur une Function : renouvellement et nouvelle tentative',
      () async {
        await signIn();
        var calls = 0;
        server.on('GET', '/me', (_) {
          calls++;
          return calls == 1
              ? const FakeResponse(401, {
                  'error': {'code': 'unauthenticated', 'message': 'expiré'},
                })
              : const FakeResponse(200, {'id': _user});
        });
        final result = await neon.functions.get<Object?>(
          '/me',
          decode: (j) => j,
        );
        expect(result.isOk, isTrue);
        expect(calls, 2);
      },
    );
  });

  test('NeonSession : encodage aller-retour, contenu illisible ignoré', () {
    final session = NeonSession(
      sessionToken: 's',
      accessToken: 'a',
      accessTokenExpiresAt: DateTime.utc(2026),
      userId: _user,
      email: 'awa@example.com',
    );
    expect(NeonSession.decode(session.encode())?.email, 'awa@example.com');
    expect(NeonSession.decode('{pas du json'), isNull);
  });
}
