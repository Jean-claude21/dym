import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:dym_core/dym_core.dart';

/// Lecture d'un vocal à partir de son lien signé (spec 035).
abstract interface class AudioPlayback {
  /// Lien en cours de lecture (nul : rien).
  Stream<String?> get playing;

  Future<Result<void>> play(String url);

  Future<void> stop();

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
    return player;
  }

  StreamSubscription<void>? _completion;
  final _playing = StreamController<String?>.broadcast();

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
  Future<void> dispose() async {
    await _completion?.cancel();
    await _created?.dispose();
    await _playing.close();
  }
}
