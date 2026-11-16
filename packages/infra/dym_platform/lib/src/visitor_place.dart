import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lieu d'une visiteuse sans compte (spec 093) : quartier et pays choisis
/// pour découvrir l'app. Gardé sur l'appareil seulement.
@immutable
class VisitorPlace {
  const new({required this.zoneId, required this.countryCode});

  final String zoneId;
  final String countryCode;

  @override
  bool operator ==(Object other) =>
      other is VisitorPlace &&
      other.zoneId == zoneId &&
      other.countryCode == countryCode;

  @override
  int get hashCode => Object.hash(zoneId, countryCode);
}

/// Lieu de la visiteuse, écouté par l'app ; nul : pas de visite en cours.
class VisitorPlaceStore extends ValueNotifier<VisitorPlace?> {
  new({FlutterSecureStorage? storage, this.persist = true})
    : _storage = storage ?? const FlutterSecureStorage(),
      super(null);

  /// Faux en test : rien n'est écrit sur l'appareil.
  final bool persist;
  final FlutterSecureStorage _storage;

  static const _key = 'dym.visitor.place';

  /// Relit le lieu enregistré (au démarrage) ; illisible : rien.
  Future<VisitorPlace?> load() async {
    if (!persist) return value;
    try {
      final raw = await _storage.read(key: _key);
      final parts = raw?.split('|');
      if (parts != null && parts.length == 2) {
        value = VisitorPlace(zoneId: parts[0], countryCode: parts[1]);
      }
    } on Object {
      // Stockage indisponible : la visiteuse rechoisira son quartier.
    }
    return value;
  }

  /// Retient le lieu choisi.
  Future<void> save(VisitorPlace place) async {
    value = place;
    if (!persist) return;
    try {
      await _storage.write(
        key: _key,
        value: '${place.zoneId}|${place.countryCode}',
      );
    } on Object {
      // Gardé en mémoire pour la session.
    }
  }
}
