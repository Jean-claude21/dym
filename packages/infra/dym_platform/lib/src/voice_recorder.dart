import 'dart:async';
import 'dart:typed_data';

import 'package:dym_core/dym_core.dart';
import 'package:meta/meta.dart';
import 'package:record/record.dart' as rec;

/// Message vocal prêt à l'envoi.
@immutable
class RecordedAudio {
  const new({
    required this.bytes,
    required this.contentType,
    required this.duration,
  });

  final Uint8List bytes;

  /// `audio/wav`.
  final String contentType;
  final Duration duration;
}

/// Enregistrement d'un court message vocal (recherche à la voix, spec 018).
abstract interface class VoiceRecorder {
  /// Niveau sonore entre 0 et 1, pendant l'écoute (onde de l'écran 71).
  Stream<double> get level;

  /// Refus : [ForbiddenFailure] si le micro est refusé.
  Future<Result<void>> start();

  /// Fin de l'écoute ; `Ok(null)` : rien d'enregistré.
  Future<Result<RecordedAudio?>> stop();

  Future<void> cancel();

  Future<void> dispose();
}

/// Implémentation `record` : PCM 16 bits mono à 16 kHz, en mémoire, emballé
/// en WAV (le seul format de flux pris en charge partout). 15 secondes font
/// environ 480 Ko.
class PluginVoiceRecorder implements VoiceRecorder {
  new([rec.AudioRecorder? recorder])
    : _recorder = recorder ?? rec.AudioRecorder();

  static const sampleRate = 16000;

  final rec.AudioRecorder _recorder;
  final _level = StreamController<double>.broadcast();
  final _pcm = BytesBuilder(copy: false);
  StreamSubscription<rec.Amplitude>? _amplitude;
  StreamSubscription<Uint8List>? _chunks;
  DateTime? _startedAt;

  @override
  Stream<double> get level => _level.stream;

  @override
  Future<Result<void>> start() async {
    try {
      if (!await _recorder.hasPermission()) {
        return const Err(ForbiddenFailure('micro refusé'));
      }
      _pcm.clear();
      final stream = await _recorder.startStream(
        const rec.RecordConfig(
          encoder: rec.AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
        ),
      );
      _chunks = stream.listen(_pcm.add);
      _startedAt = DateTime.now();
      _amplitude = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((a) => _level.add(((a.current + 50) / 50).clamp(0.0, 1.0)));
      return const Ok(null);
    } on Object catch (error) {
      return Err(UnknownFailure('micro indisponible : ${error.runtimeType}'));
    }
  }

  @override
  Future<Result<RecordedAudio?>> stop() async {
    try {
      await _recorder.stop();
      await _chunks?.cancel();
      await _amplitude?.cancel();
      final started = _startedAt;
      _startedAt = null;
      final pcm = _pcm.takeBytes();
      if (started == null || pcm.isEmpty) return const Ok(null);
      return Ok(
        RecordedAudio(
          bytes: wav(pcm, sampleRate: sampleRate),
          contentType: 'audio/wav',
          duration: DateTime.now().difference(started),
        ),
      );
    } on Object catch (error) {
      return Err(UnknownFailure('micro indisponible : ${error.runtimeType}'));
    }
  }

  @override
  Future<void> cancel() async {
    await _amplitude?.cancel();
    await _chunks?.cancel();
    _startedAt = null;
    _pcm.clear();
    try {
      await _recorder.cancel();
    } on Object {
      // Déjà arrêté.
    }
  }

  @override
  Future<void> dispose() async {
    await cancel();
    await _level.close();
    await _recorder.dispose();
  }
}

/// En-tête WAV (RIFF, PCM 16 bits mono) devant des échantillons bruts.
Uint8List wav(Uint8List pcm, {required int sampleRate}) {
  final header = ByteData(44)
    ..setUint32(0, 0x52494646) // RIFF
    ..setUint32(4, 36 + pcm.length, Endian.little)
    ..setUint32(8, 0x57415645) // WAVE
    ..setUint32(12, 0x666d7420) // fmt
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little)
    ..setUint32(36, 0x64617461) // data
    ..setUint32(40, pcm.length, Endian.little);
  return (BytesBuilder(copy: false)
        ..add(header.buffer.asUint8List())
        ..add(pcm))
      .takeBytes();
}
