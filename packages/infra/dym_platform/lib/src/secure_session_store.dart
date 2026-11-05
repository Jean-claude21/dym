import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neon_kit/neon_kit.dart';

/// Session Neon dans le stockage sécurisé de l'appareil (Keystore Android,
/// Keychain iOS). Une valeur illisible est effacée, jamais journalisée.
class SecureSessionStore implements SessionStore {
  new({FlutterSecureStorage? storage, this.key = 'dym.neon.session'})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Clé de stockage (une par app si besoin).
  final String key;

  @override
  Future<NeonSession?> read() async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    final session = NeonSession.decode(raw);
    if (session == null) await clear();
    return session;
  }

  @override
  Future<void> write(NeonSession session) =>
      _storage.write(key: key, value: session.encode());

  @override
  Future<void> clear() => _storage.delete(key: key);
}
