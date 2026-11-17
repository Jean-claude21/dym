import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Petit stockage JSON sur l'appareil (spec 107, décision 0023) : premier
/// écran depuis le cache, file hors ligne des gestes. Jamais de secret ici
/// (les jetons restent dans `flutter_secure_storage`).
abstract interface class LocalJsonStore {
  Future<Object?> read(String key);
  Future<void> write(String key, Object? value);
  Future<void> delete(String key);
}

/// Fichiers dans le dossier de l'app ; web : rien n'est gardé.
class FileJsonStore implements LocalJsonStore {
  new({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;
  static final _safe = RegExp('[^a-zA-Z0-9_.-]');

  Future<File?> _file(String key) async {
    if (kIsWeb) return null;
    try {
      final dir = Directory('${(await _directory()).path}/dym_cache');
      if (!dir.existsSync()) await dir.create(recursive: true);
      return File('${dir.path}/${key.replaceAll(_safe, '_')}.json');
    } on Object {
      return null;
    }
  }

  @override
  Future<Object?> read(String key) async {
    final file = await _file(key);
    if (file == null || !file.existsSync()) return null;
    try {
      return jsonDecode(await file.readAsString());
    } on Object {
      return null; // illisible : comme absent
    }
  }

  @override
  Future<void> write(String key, Object? value) async {
    final file = await _file(key);
    if (file == null) return;
    try {
      // Écriture atomique : fichier temporaire puis renommage.
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonEncode(value), flush: true);
      await tmp.rename(file.path);
    } on Object {
      // Disque plein ou indisponible : on continue sans cache.
    }
  }

  @override
  Future<void> delete(String key) async {
    final file = await _file(key);
    try {
      if (file != null && file.existsSync()) await file.delete();
    } on Object {
      // Rien à faire.
    }
  }
}

/// En mémoire (tests, galerie).
class MemoryJsonStore implements LocalJsonStore {
  final values = <String, Object?>{};

  @override
  Future<Object?> read(String key) async => values[key];

  @override
  Future<void> write(String key, Object? value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Un geste gardé hors ligne, rejoué au retour du réseau.
@immutable
class OfflineGesture {
  const new({required this.id, required this.kind, required this.payload});

  factory fromJson(Map<String, dynamic> j) => OfflineGesture(
    id: j['id'] as String,
    kind: j['kind'] as String,
    payload: (j['payload'] as Map).cast<String, dynamic>(),
  );

  /// Clé du geste : un nouveau geste sur la même chose remplace l'ancien.
  final String id;
  final String kind;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'payload': payload};
}

/// Issue du rejeu d'un geste.
enum ReplayOutcome {
  /// Accepté : retiré de la file.
  done,

  /// Toujours pas de réseau : gardé.
  retry,

  /// Refusé par la base : retiré (l'écran affiche l'état réel).
  dropped,
}

/// File hors ligne (PARCOURS §5 : « geste gardé hors ligne, envoyé au retour
/// du réseau ») : gardée sur l'appareil, rejouée à intervalles et au retour
/// de l'app au premier plan.
class OfflineQueue extends ChangeNotifier {
  new(this._store, {this.name = 'offline_queue'});

  final LocalJsonStore _store;
  final String name;
  List<OfflineGesture> _items = const [];
  bool _loaded = false;
  bool _replaying = false;

  List<OfflineGesture> get items => _items;
  bool get isEmpty => _items.isEmpty;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final raw = await _store.read(name);
    _items = [
      for (final g in raw is List ? raw : const [])
        if (g is Map) OfflineGesture.fromJson(g.cast<String, dynamic>()),
    ];
    notifyListeners();
  }

  Future<void> add(OfflineGesture gesture) async {
    await load();
    _items = [
      for (final g in _items)
        if (g.id != gesture.id) g,
      gesture,
    ];
    await _save();
  }

  bool has(String id) => _items.any((g) => g.id == id);

  /// Rejoue les gestes dans l'ordre ; s'arrête au premier « pas de réseau ».
  Future<void> replay(
    Future<ReplayOutcome> Function(OfflineGesture gesture) handler,
  ) async {
    await load();
    if (_replaying || _items.isEmpty) return;
    _replaying = true;
    try {
      for (final g in List.of(_items)) {
        final outcome = await handler(g);
        if (outcome == ReplayOutcome.retry) break;
        _items = [
          for (final x in _items)
            if (x.id != g.id) x,
        ];
      }
      await _save();
    } finally {
      _replaying = false;
    }
  }

  Future<void> _save() async {
    await _store.write(name, [for (final g in _items) g.toJson()]);
    notifyListeners();
  }
}
