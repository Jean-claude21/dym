import 'dart:async';
import 'dart:typed_data';

import 'package:dym_auth/dym_auth.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';

/// Recherche augmentée (spec 018) : historique, suggestions, voix et photo.
/// Voix et photo n'existent que si le flag `ai_search` est actif pour le pays.
abstract interface class SearchAiService {
  /// Voix et photo proposées (flag `ai_search` du pays).
  Future<bool> aiEnabled();

  /// Historique : seulement avec une session.
  bool get hasHistory;

  Future<Result<List<SearchHistoryEntry>>> history();

  Future<void> remember(String query, SearchSource source);

  Future<Result<void>> forget();

  /// Complétions dans le quartier choisi.
  Future<Result<List<SearchSuggestion>>> suggestions(String prefix);

  VoiceRecorder get recorder;

  Future<Result<PickedPhoto?>> pickPhoto(PhotoSource source);

  /// `Ok(null)` : rien compris.
  Future<Result<String?>> transcribe(RecordedAudio audio);

  /// `Ok(null)` : rien de reconnaissable.
  Future<Result<String?>> describePhoto(PickedPhoto photo);
}

/// Implémentation Neon.
class NeonSearchAiService implements SearchAiService {
  new({
    required this._repository,
    required this._discovery,
    required this._auth,
    required this.recorder,
    required this._photos,
  });

  final SearchAiRepository _repository;
  final DiscoveryService _discovery;
  final AuthService _auth;
  final PhotoPicker _photos;

  @override
  final VoiceRecorder recorder;

  @override
  Future<bool> aiEnabled() async =>
      (await _discovery.countryConfig()).valueOrNull?.isEnabled('ai_search') ??
      false;

  @override
  bool get hasHistory => _auth.me != null;

  @override
  Future<Result<List<SearchHistoryEntry>>> history() =>
      hasHistory ? _repository.history() : Future.value(const Ok([]));

  @override
  Future<void> remember(String query, SearchSource source) async {
    if (hasHistory) await _repository.remember(query, source);
  }

  @override
  Future<Result<void>> forget() => _repository.forget();

  @override
  Future<Result<List<SearchSuggestion>>> suggestions(String prefix) =>
      _repository.suggestions(prefix, zoneId: _discovery.zone.value);

  @override
  Future<Result<PickedPhoto?>> pickPhoto(PhotoSource source) =>
      _photos.pick(source);

  @override
  Future<Result<String?>> transcribe(RecordedAudio audio) =>
      _repository.transcribe(audio.bytes, audio.contentType);

  @override
  Future<Result<String?>> describePhoto(PickedPhoto photo) =>
      _repository.describePhoto(photo.bytes, photo.contentType);
}

/// Enregistreur de démonstration : une onde, puis un message.
class MemoryVoiceRecorder implements VoiceRecorder {
  new({this.fail = false, this.script = const []});

  final bool fail;

  /// Niveaux émis au démarrage (galerie).
  final List<double> script;
  final _level = StreamController<double>.broadcast();
  bool listening = false;

  @override
  Stream<double> get level => _level.stream;

  @override
  Future<Result<void>> start() async {
    if (fail) return const Err(ForbiddenFailure('micro refusé'));
    listening = true;
    scheduleMicrotask(() => script.forEach(_level.add));
    return const Ok(null);
  }

  /// Simule la voix (tests).
  void speak(double value) => _level.add(value);

  @override
  Future<Result<RecordedAudio?>> stop() async {
    listening = false;
    return Ok(
      RecordedAudio(
        bytes: Uint8List(8),
        contentType: 'audio/wav',
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Future<void> cancel() async => listening = false;

  @override
  Future<void> dispose() => _level.close();
}

/// Recherche augmentée en mémoire (tests, galerie).
class MemorySearchAiService implements SearchAiService {
  new({
    this.enabled = true,
    this.heard = 'des tomates et du gombo pour ce soir',
    this.seen = 'gombo frais',
    this.photo,
    List<SearchHistoryEntry>? history,
    VoiceRecorder? recorder,
    this.hasHistory = true,
  }) : recorder = recorder ?? MemoryVoiceRecorder(),
       _history =
           history ??
           [
             for (final q in ['tomates fraîches', 'jus de bissap', 'piment'])
               SearchHistoryEntry(
                 query: q,
                 source: SearchSource.text,
                 searchedAt: DateTime.utc(2026, 10, 4),
               ),
           ];

  final bool enabled;
  final String? heard;
  final String? seen;
  final PickedPhoto? photo;
  final List<SearchHistoryEntry> _history;
  final remembered = <(String, SearchSource)>[];

  @override
  final bool hasHistory;

  @override
  final VoiceRecorder recorder;

  @override
  Future<bool> aiEnabled() async => enabled;

  @override
  Future<Result<List<SearchHistoryEntry>>> history() async =>
      Ok(List.of(_history));

  @override
  Future<void> remember(String query, SearchSource source) async {
    remembered.add((query, source));
    _history
      ..removeWhere((e) => e.query.toLowerCase() == query.toLowerCase())
      ..insert(
        0,
        SearchHistoryEntry(
          query: query,
          source: source,
          searchedAt: DateTime.utc(2026, 10, 5),
        ),
      );
  }

  @override
  Future<Result<void>> forget() async {
    _history.clear();
    return const Ok(null);
  }

  @override
  Future<Result<List<SearchSuggestion>>> suggestions(String prefix) async {
    final p = prefix.toLowerCase();
    return Ok([
      for (final (label, category) in const [
        ('Tomates', 'c-tomates'),
        ('Tomates fraîches', null),
        ('Tomates cerises', null),
        ('Gombo frais', null),
        ('Jus de bissap', null),
      ])
        if (label.toLowerCase().split(' ').any((w) => w.startsWith(p)))
          SearchSuggestion(
            label: LocalizedText({'fr': label}),
            categoryId: category,
          ),
    ]);
  }

  @override
  Future<Result<PickedPhoto?>> pickPhoto(PhotoSource source) async =>
      Ok(photo ?? PickedPhoto(bytes: Uint8List(0), contentType: 'image/jpeg'));

  @override
  Future<Result<String?>> transcribe(RecordedAudio audio) async => Ok(heard);

  @override
  Future<Result<String?>> describePhoto(PickedPhoto photo) async => Ok(seen);
}
