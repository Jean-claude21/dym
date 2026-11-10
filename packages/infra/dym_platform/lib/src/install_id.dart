import 'package:dym_core/dym_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Identifiant d'installation de l'app : un UUID aléatoire tiré une fois et
/// gardé sur l'appareil. Jamais un identifiant matériel ; il sert à
/// l'antifraude de l'affiliation (spec 039) et disparaît avec l'app.
abstract interface class InstallIdProvider {
  Future<String?> installId();
}

/// Identifiant gardé dans le stockage sécurisé ; illisible : `null`.
class SecureInstallIdProvider implements InstallIdProvider {
  new({FlutterSecureStorage? storage, this.key = 'dym.install.id'})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final String key;
  String? _cached;

  @override
  Future<String?> installId() async {
    if (_cached case final id?) return id;
    try {
      final stored = await _storage.read(key: key);
      if (stored != null) return _cached = stored;
      final id = Uuid.v4();
      await _storage.write(key: key, value: id);
      return _cached = id;
    } on Object {
      return null;
    }
  }
}
