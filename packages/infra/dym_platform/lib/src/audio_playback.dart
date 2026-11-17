import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:dym_core/dym_core.dart';

/// Lecture d'un vocal à partir de son lien signé (spec 035).
abstract interface class AudioPlayback {
  /// Lien en cours de lecture (nul : rien).
  Stream<String?> get playing;

  Future<Result<void>> play(String url);

  Future<void> stop();

  /// Position de lecture (vocal en cours, spec 111).
  Stream<Duration> get position;

  /// Pause et reprise du vocal en cours.
  Future<void> pause();
  Future<void> resume();

  /// Vitesse : 1, 1.5 ou 2.
  Future<void> setSpeed(double speed);

  Future<void> dispose();
}

/// Implémentation `audioplayers` (Android, iOS et web).
class PluginAudioPlayback implements AudioPlayback {
  new([ap.AudioPlayer? player]) : _injected = player;

  final ap.AudioPlayer? _injected;
  ap.AudioPlayer? _created;
  ap.AudioPlayer get _player {
    final player = _created ??= _injected ?? ap.AudioPlayer();
    _completion ??= player.onPlayerComplete.listen((_) => _emit(null));
    _positions ??= player.onPositionChanged.listen((p) {
      if (!_position.isClosed) _position.add(p);
    });
    return player;
  }

  StreamSubscription<void>? _completion;
  StreamSubscription<Duration>? _positions;
  final _playing = StreamController<String?>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  double _speed = 1;

  void _emit(String? url) {
    if (!_playing.isClosed) _playing.add(url);
  }

  @override
  Stream<String?> get playing => _playing.stream;

  @override
  Future<Result<void>> play(String url) async {
    try {
      await _player.stop();
      await _player.play(ap.UrlSource(url));
      if (_speed != 1) await _player.setPlaybackRate(_speed);
      _emit(url);
      return const Ok(null);
    } on Object catch (error) {
      _emit(null);
      return Err(ServerFailure('lecture impossible : $error'));
    }
  }

  @override
  Future<void> stop() async {
    await _created?.stop();
    _emit(null);
  }

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Future<void> pause() async => await _created?.pause();

  @override
  Future<void> resume() async => await _created?.resume();

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _created?.setPlaybackRate(speed);
  }

  @override
  Future<void> dispose() async {
    await _completion?.cancel();
    await _positions?.cancel();
    await _position.close();
    await _created?.dispose();
    await _playing.close();
  }
}
