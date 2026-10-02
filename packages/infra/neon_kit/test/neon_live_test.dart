@Tags(['neon'])
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dym_core/dym_core.dart';
import 'package:neon_kit/neon_kit.dart';
import 'package:test/test.dart';

/// Essai réel contre une branche Neon (décision 0013). Ignoré sans
/// `NEON_LIVE_AUTH_URL`, `NEON_LIVE_DATA_API_URL`, `NEON_LIVE_FUNCTIONS_URL`,
/// `NEON_LIVE_EMAIL`, `NEON_LIVE_PASSWORD` (compte de test de la branche).
///
/// La connexion du compte de test passe par email et mot de passe (le parcours
/// de l'app est l'OTP email) : la réponse a la même forme (jeton dans le
/// corps, cookie de session signé), c'est ce que ce test vérifie.
void main() {
  final env = Platform.environment;
  final authUrl = env['NEON_LIVE_AUTH_URL'];
  final skip = [
    authUrl,
    env['NEON_LIVE_DATA_API_URL'],
    env['NEON_LIVE_FUNCTIONS_URL'],
    env['NEON_LIVE_EMAIL'],
    env['NEON_LIVE_PASSWORD'],
  ].any((v) => v == null || v.isEmpty);

  NeonClient client(SessionStore store) => NeonClient(
    config: NeonConfig(
      authUrl: Uri.parse(authUrl!),
      dataApiUrl: Uri.parse(env['NEON_LIVE_DATA_API_URL']!),
      functionsUrl: Uri.parse(env['NEON_LIVE_FUNCTIONS_URL']!),
    ),
    sessionStore: store,
  );

  test('visiteuse : JWT anonyme, référentiel lisible', () async {
    final neon = client(InMemorySessionStore());
    final result = await neon.data.run(
      (db) => db.from('countries').select('code'),
    );
    expect(result.isOk, isTrue, reason: '$result');
    expect(result.valueOrNull, isNotEmpty);
    final me = await neon.data.rpc<Object?>('me');
    expect(me.failureOrNull, isA<ForbiddenFailure>(), reason: 'anonyme');
  }, skip: skip);

  test('session par cookie : JWT, Data API et Function', () async {
    final signIn = await Dio().post<Map<String, dynamic>>(
      '$authUrl/sign-in/email',
      data: {
        'email': env['NEON_LIVE_EMAIL'],
        'password': env['NEON_LIVE_PASSWORD'],
      },
      options: Options(headers: {'Origin': 'http://localhost'}),
    );
    final cookie = signIn.headers['set-cookie']!
        .map((h) => h.split(';').first)
        .firstWhere((c) => c.split('=').first.endsWith('session_token'));
    final user = signIn.data!['user'] as Map<String, dynamic>;

    final store = InMemorySessionStore();
    await store.write(
      NeonSession(
        sessionToken: signIn.data!['token'] as String,
        // JWT expiré : la restauration doit le renouveler avec le cookie.
        accessToken: 'expiré',
        accessTokenExpiresAt: DateTime.utc(2000),
        userId: user['id'] as String,
        sessionCookie: cookie,
      ),
    );
    final neon = client(store);
    final restored = await neon.auth.restore();
    expect(restored.valueOrNull?.userId, user['id'], reason: '$restored');

    final me = await neon.data.rpc<Map<String, dynamic>>('me');
    expect(me.valueOrNull?['user_id'], user['id'], reason: '$me');

    final fn = await neon.functions.get<Map<Object?, Object?>>(
      '/me',
      decode: (json) => json! as Map,
    );
    expect(fn.valueOrNull?['userId'], user['id'], reason: '$fn');
  }, skip: skip);
}
