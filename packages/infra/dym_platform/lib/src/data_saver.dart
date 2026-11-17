import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Économie de données (spec 103) : vidéos en version légère gardées sur le
/// téléphone, aucune vidéo préchargée, aperçus animés coupés. Choix gardé sur
/// l'appareil.
class DataSaverPreference extends ValueNotifier<bool> {
  new({FlutterSecureStorage? storage, this.persist = true})
    : _storage = storage ?? const FlutterSecureStorage(),
      super(false);

  /// Faux en test : rien n'est écrit sur l'appareil.
  final bool persist;
  final FlutterSecureStorage _storage;

  static const _key = 'dym.data_saver';

  Future<bool> load() async {
    if (!persist) return value;
    try {
      value = await _storage.read(key: _key) == '1';
    } on Object {
      // Stockage indisponible : réglage par défaut.
    }
    return value;
  }

  Future<void> set({required bool on}) async {
    value = on;
    if (!persist) return;
    try {
      await _storage.write(key: _key, value: on ? '1' : '0');
    } on Object {
      // Gardé en mémoire pour la session.
    }
  }
}
