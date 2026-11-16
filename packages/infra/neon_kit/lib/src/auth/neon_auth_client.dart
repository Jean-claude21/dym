import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dym_core/dym_core.dart';
import 'package:neon_kit/src/config.dart';
import 'package:neon_kit/src/errors.dart';
import 'package:neon_kit/src/jwt.dart';
import 'package:neon_kit/src/session.dart';

/// Authentification Neon Auth (Better Auth managé), en REST.
///
/// - OTP email et connexion Google par `idToken` ;
/// - session : jeton `set-auth-token` (plugin bearer) envoyé en
///   `Authorization: Bearer`, et cookie de session rejoué en en-tête `Cookie`
///   (Neon Auth n'active pas le plugin bearer) ; sur le web, le navigateur
///   envoie lui-même le cookie ;
/// - JWT d'accès obtenu par la route `token`, renouvelé avant expiration, un
///   seul renouvellement à la fois.
class NeonAuthClient {
  new({
    required this._dio,
    required this._config,
    required this._store,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Dio _dio;
  final NeonConfig _config;
  final SessionStore _store;
  final DateTime Function() _clock;
  final _changes = StreamController<NeonSession?>.broadcast();

  NeonSession? _session;
  Future<Result<NeonSession>>? _refreshing;
  (String, DateTime)? _anonymous;
  Future<Result<String>>? _anonymousFetch;

  NeonAuthPaths get _paths => _config.authPaths;

  /// Session courante (mémoire).
  NeonSession? get currentSession => _session;

  /// Émet la session à chaque connexion, renouvellement ou déconnexion.
  Stream<NeonSession?> get sessionChanges => _changes.stream;

  /// Envoie un code de connexion à usage unique par email.
  Future<Result<void>> sendEmailOtp(String email) => _guard(() async {
    await _dio.post<Object?>(
      _paths.sendEmailOtp,
      data: {'email': email.trim().toLowerCase(), 'type': 'sign-in'},
    );
  });

  /// Vérifie le code reçu par email et ouvre une session.
  Future<Result<NeonSession>> verifyEmailOtp(String email, String otp) =>
      _signIn(_paths.signInEmailOtp, {
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      });

  /// Ouvre une session avec un email et un mot de passe.
  Future<Result<NeonSession>> signInWithPassword(
    String email,
    String password,
  ) => _signIn(_paths.signInEmail, {
    'email': email.trim().toLowerCase(),
    'password': password,
  });

  /// Ouvre une session avec un `idToken` Google obtenu sur l'appareil.
  Future<Result<NeonSession>> signInWithGoogleIdToken(String idToken) =>
      _signIn(_paths.signInSocial, {
        'provider': 'google',
        'idToken': {'token': idToken},
      });

  /// Restaure la session enregistrée au démarrage de l'app.
  ///
  /// Session révoquée → `Ok(null)` (déconnecté). Réseau indisponible → la
  /// session enregistrée est conservée : l'app démarre hors ligne.
  Future<Result<NeonSession?>> restore() async {
    final stored = await _store.read();
    if (stored == null) return const Ok(null);
    _session = stored;
    if (_isFresh(stored)) {
      _changes.add(stored);
      return Ok(stored);
    }
    final refreshed = await refresh();
    return switch (refreshed) {
      Ok(:final value) => Ok(value),
      Err(failure: UnauthenticatedFailure()) => const Ok(null),
      Err(:final failure) when failure.isTransient => Ok(stored),
      Err(:final failure) => Err(failure),
    };
  }

  /// JWT d'accès valide, renouvelé s'il expire dans moins de
  /// [NeonConfig.refreshMargin].
  Future<Result<String>> validAccessToken() async {
    final session = _session;
    if (session == null) {
      return const Err(UnauthenticatedFailure('aucune session'));
    }
    if (_isFresh(session)) return Ok(session.accessToken);
    return (await refresh()).map((s) => s.accessToken);
  }

  /// JWT anonyme (visiteuse sans session) : la Data API exige toujours un
  /// jeton, le rôle `anonymous` n'a que les droits de lecture publics. Mis en
  /// cache jusqu'à [NeonConfig.refreshMargin] avant son expiration.
  Future<Result<String>> anonymousAccessToken() {
    final cached = _anonymous;
    if (cached != null &&
        cached.$2.isAfter(_clock().toUtc().add(_config.refreshMargin))) {
      return Future.value(Ok(cached.$1));
    }
    return _anonymousFetch ??= _guard(() async {
      final response = await _dio.get<Object?>(_paths.anonymousToken);
      final data = response.data;
      final jwt = data is Map ? data['token'] : null;
      if (jwt is! String) throw const FormatException('JWT anonyme absent');
      final expiresAt = JwtClaims.expiresAt(jwt);
      if (expiresAt == null) throw const FormatException('JWT illisible');
      _anonymous = (jwt, expiresAt);
      return jwt;
    }).whenComplete(() => _anonymousFetch = null);
  }

  /// Renouvelle le JWT d'accès. Les appels simultanés partagent le même
  /// renouvellement.
  Future<Result<NeonSession>> refresh() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  /// Ferme la session (côté serveur si possible, toujours côté appareil).
  Future<Result<void>> signOut() async {
    final session = _session;
    if (session != null) {
      try {
        await _dio.post<Object?>(
          _paths.signOut,
          options: _credentials(session.sessionToken, session.sessionCookie),
        );
      } on DioException {
        // La session locale est effacée même hors ligne.
      }
    }
    await _clear();
    return const Ok(null);
  }

  /// Libère les ressources.
  Future<void> dispose() => _changes.close();

  // ------------------------------------------------------------------ interne

  bool _isFresh(NeonSession session) => session.accessTokenExpiresAt.isAfter(
    _clock().toUtc().add(_config.refreshMargin),
  );

  Options _credentials(String token, String? cookie) =>
      Options(headers: {'Authorization': 'Bearer $token', 'Cookie': ?cookie});

  /// Cookie de session (`nom=valeur`) d'une réponse de connexion.
  String? _sessionCookie(Response<Object?> response) {
    for (final header in response.headers['set-cookie'] ?? const <String>[]) {
      final pair = header.split(';').first.trim();
      final name = pair.split('=').first;
      if (name.endsWith('session_token') && pair.length > name.length + 1) {
        return pair;
      }
    }
    return null;
  }

  Future<Result<NeonSession>> _signIn(String path, Object body) =>
      _guard(() async {
        final response = await _dio.post<Object?>(path, data: body);
        final sessionToken = _sessionToken(response);
        if (sessionToken == null) {
          throw const FormatException('jeton de session absent');
        }
        final user = _user(response.data);
        final session = await _fetchAccessToken(
          sessionToken: sessionToken,
          sessionCookie: _sessionCookie(response),
          userId: user.$1,
          email: user.$2,
        );
        await _save(session);
        return session;
      });

  Future<Result<NeonSession>> _doRefresh() async {
    final session = _session;
    if (session == null) {
      return const Err(UnauthenticatedFailure('aucune session'));
    }
    final result = await _guard(
      () => _fetchAccessToken(
        sessionToken: session.sessionToken,
        sessionCookie: session.sessionCookie,
        userId: session.userId,
        email: session.email,
      ),
    );
    switch (result) {
      case Ok(:final value):
        await _save(value);
      case Err(failure: UnauthenticatedFailure()):
        await _clear();
      case Err():
        break;
    }
    return result;
  }

  Future<NeonSession> _fetchAccessToken({
    required String sessionToken,
    required String? sessionCookie,
    required String? userId,
    required String? email,
  }) async {
    final response = await _dio.get<Object?>(
      _paths.token,
      options: _credentials(sessionToken, sessionCookie),
    );
    final data = response.data;
    final jwt = data is Map ? data['token'] : null;
    if (jwt is! String) throw const FormatException('JWT absent');
    final expiresAt = JwtClaims.expiresAt(jwt);
    final subject = JwtClaims.subject(jwt) ?? userId;
    if (expiresAt == null || subject == null) {
      throw const FormatException('JWT illisible');
    }
    return NeonSession(
      sessionToken: sessionToken,
      accessToken: jwt,
      accessTokenExpiresAt: expiresAt,
      userId: subject,
      email: email,
      sessionCookie: sessionCookie,
    );
  }

  String? _sessionToken(Response<Object?> response) {
    final header = response.headers.value('set-auth-token');
    if (header != null && header.isNotEmpty) return header;
    final data = response.data;
    final token = data is Map ? data['token'] : null;
    return token is String && token.isNotEmpty ? token : null;
  }

  (String?, String?) _user(Object? data) {
    final user = data is Map ? data['user'] : null;
    if (user is! Map) return (null, null);
    return (user['id'] as String?, user['email'] as String?);
  }

  Future<void> _save(NeonSession session) async {
    _session = session;
    await _store.write(session);
    _changes.add(session);
  }

  Future<void> _clear() async {
    _session = null;
    await _store.clear();
    _changes.add(null);
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Object catch (error, stack) {
      final failure = failureFrom(error);
      FailureReports.report(failure, 'auth', stack);
      return Err(failure);
    }
  }
}
