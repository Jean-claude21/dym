import 'dart:convert';

/// Lecture (sans vérification) des champs d'un JWT. La signature est vérifiée
/// par le serveur ; le client n'en lit que l'expiration et le sujet.
abstract final class JwtClaims {
  /// Charge utile décodée, ou `null` si le jeton est illisible.
  static Map<String, Object?>? payload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final json = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return json is Map<String, Object?> ? json : null;
    } on FormatException {
      return null;
    }
  }

  /// Expiration (`exp`), en UTC.
  static DateTime? expiresAt(String token) {
    final exp = payload(token)?['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      (exp * 1000).toInt(),
      isUtc: true,
    );
  }

  /// Sujet (`sub`).
  static String? subject(String token) => payload(token)?['sub'] as String?;
}
