import 'dart:math';

/// Identifiants UUID v4 (RFC 9562), générés sur l'appareil : clés
/// d'idempotence et identifiants d'événements client.
abstract final class Uuid {
  static final Random _random = Random.secure();

  /// Nouvel UUID v4 aléatoire, en minuscules.
  static String v4([Random? random]) {
    final r = random ?? _random;
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return [
      hex.substring(0, 8),
      hex.substring(8, 12),
      hex.substring(12, 16),
      hex.substring(16, 20),
      hex.substring(20),
    ].join('-');
  }

  /// Vrai si [value] est un UUID bien formé.
  static bool isValid(String value) => RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value);
}
