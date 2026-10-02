import 'dart:convert';

import 'package:meta/meta.dart';

/// Session Neon Auth : jeton de session (Better Auth) et jeton d'accès (JWT)
/// pour la Data API et les Functions.
@immutable
class NeonSession {
  const new({
    required this.sessionToken,
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.userId,
    this.email,
    this.sessionCookie,
  });

  /// Restaure une session sérialisée par [toJson].
  factory fromJson(Map<String, Object?> json) => NeonSession(
    sessionToken: json['sessionToken']! as String,
    accessToken: json['accessToken']! as String,
    accessTokenExpiresAt: DateTime.parse(
      json['accessTokenExpiresAt']! as String,
    ),
    userId: json['userId']! as String,
    email: json['email'] as String?,
    sessionCookie: json['sessionCookie'] as String?,
  );

  /// Jeton de session Better Auth (longue durée).
  final String sessionToken;

  /// JWT d'accès (courte durée).
  final String accessToken;

  /// Expiration du JWT d'accès (UTC).
  final DateTime accessTokenExpiresAt;

  /// Identifiant de l'utilisateur (`sub`).
  final String userId;

  /// Email de l'utilisateur, s'il est connu.
  final String? email;

  /// Cookie de session (`nom=valeur`) rejoué en en-tête `Cookie` quand Neon
  /// Auth n'accepte pas le jeton en `Bearer` (plugin bearer inactif). Nul sur
  /// le web : le navigateur gère le cookie.
  final String? sessionCookie;

  /// Copie avec un nouveau jeton d'accès.
  NeonSession withAccessToken(String token, DateTime expiresAt) => NeonSession(
    sessionToken: sessionToken,
    accessToken: token,
    accessTokenExpiresAt: expiresAt,
    userId: userId,
    email: email,
    sessionCookie: sessionCookie,
  );

  Map<String, Object?> toJson() => {
    'sessionToken': sessionToken,
    'accessToken': accessToken,
    'accessTokenExpiresAt': accessTokenExpiresAt.toUtc().toIso8601String(),
    'userId': userId,
    'email': email,
    'sessionCookie': sessionCookie,
  };

  /// Sérialisation pour un stockage sécurisé.
  String encode() => jsonEncode(toJson());

  /// Inverse de [encode]. Renvoie `null` si le contenu est illisible.
  static NeonSession? decode(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;
      return NeonSession.fromJson(json);
    } on Object {
      return null;
    }
  }

  @override
  String toString() => 'NeonSession(userId: $userId)';
}

/// Stockage de la session. L'implémentation de l'appareil est sécurisée
/// (`dym_platform`) ; rien n'est journalisé.
abstract interface class SessionStore {
  Future<NeonSession?> read();

  Future<void> write(NeonSession session);

  Future<void> clear();
}

/// Stockage en mémoire (tests, web sans persistance).
class InMemorySessionStore implements SessionStore {
  NeonSession? _session;

  @override
  Future<NeonSession?> read() async => _session;

  @override
  Future<void> write(NeonSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
