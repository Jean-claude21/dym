import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:flutter/widgets.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

/// Accès au média d'un appel, émis par la Function (spec 084).
typedef CallMediaCredentials = ({String url, String token});

/// Demande l'accès au média d'un appel décroché.
typedef CallCredentialsFetcher = Future<Result<CallMediaCredentials>> Function(
  String callId,
);

/// Fournisseur média d'un appel (spec 035). La base tient l'état de l'appel ;
/// le fournisseur transporte la voix et l'image.
abstract interface class CallProvider {
  /// `true` : aucun média réel ne circule (affiché à l'écran).
  bool get simulated;

  /// Change quand le média change (vidéo reçue, micro coupé…).
  Listenable get changes;

  bool get microphoneOn;
  bool get speakerOn;

  /// Rejoint le canal média de l'appel décroché.
  Future<Result<void>> join(String callId, {required bool video});

  Future<void> setMicrophone({required bool on});
  Future<void> setSpeaker({required bool on});

  /// Vidéo de l'autre personne et la sienne ; `null` sans vidéo.
  Widget? remoteVideo();
  Widget? localVideo();

  Future<void> leave();
}

/// Simulation : l'appel « se connecte » sans média réel.
class SimulatedCallProvider implements CallProvider {
  new();

  final _changes = _Changes();
  bool _mic = true;
  bool _speaker = false;

  @override
  bool get simulated => true;

  @override
  Listenable get changes => _changes;

  @override
  bool get microphoneOn => _mic;

  @override
  bool get speakerOn => _speaker;

  @override
  Future<Result<void>> join(String callId, {required bool video}) async =>
      const Ok(null);

  @override
  Future<void> setMicrophone({required bool on}) async {
    _mic = on;
    _changes.ping();
  }

  @override
  Future<void> setSpeaker({required bool on}) async {
    _speaker = on;
    _changes.ping();
  }

  @override
  Widget? remoteVideo() => null;

  @override
  Widget? localVideo() => null;

  @override
  Future<void> leave() async {}
}

/// Appels réels par LiveKit (spec 084) : voix (Opus, faible débit, pauses
/// non transmises) et vidéo adaptée au réseau. Le jeton vient de la Function,
/// jamais de l'app.
class LiveKitCallProvider implements CallProvider {
  new({required this._credentials});

  final CallCredentialsFetcher _credentials;
  final _changes = _Changes();
  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _events;
  bool _mic = true;
  bool _speaker = false;

  @override
  bool get simulated => false;

  @override
  Listenable get changes => _changes;

  @override
  bool get microphoneOn => _mic;

  @override
  bool get speakerOn => _speaker;

  @override
  Future<Result<void>> join(String callId, {required bool video}) async {
    final access = await _credentials(callId);
    switch (access) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final room = lk.Room(
          roomOptions: const lk.RoomOptions(
            adaptiveStream: true,
            dynacast: true,
            // Voix : Opus avec pauses non transmises (dtx, par défaut).
            defaultCameraCaptureOptions: lk.CameraCaptureOptions(
              params: lk.VideoParametersPresets.h360_169,
            ),
          ),
        );
        try {
          await room.connect(value.url, value.token);
          _room = room;
          _events = room.createListener()..listen((_) => _changes.ping());
          await room.localParticipant?.setMicrophoneEnabled(true);
          if (video) await room.localParticipant?.setCameraEnabled(true);
          _speaker = video;
          await lk.AudioManager.instance.setSpeakerOutputPreferred(_speaker);
          _changes.ping();
          return const Ok(null);
        } on Object catch (error) {
          await room.dispose();
          return Err(NetworkFailure('appel : $error'));
        }
    }
  }

  @override
  Future<void> setMicrophone({required bool on}) async {
    _mic = on;
    await _room?.localParticipant?.setMicrophoneEnabled(on);
    _changes.ping();
  }

  @override
  Future<void> setSpeaker({required bool on}) async {
    _speaker = on;
    await lk.AudioManager.instance.setSpeakerOutputPreferred(on);
    _changes.ping();
  }

  lk.VideoTrack? _track(lk.Participant? participant) {
    if (participant == null) return null;
    for (final publication in participant.videoTrackPublications) {
      final track = publication.track;
      if (track is lk.VideoTrack && !publication.muted) return track;
    }
    return null;
  }

  @override
  Widget? remoteVideo() {
    final remote = _room?.remoteParticipants.values;
    final track = remote == null || remote.isEmpty
        ? null
        : _track(remote.first);
    return track == null
        ? null
        : lk.VideoTrackRenderer(track, fit: lk.VideoViewFit.cover);
  }

  @override
  Widget? localVideo() {
    final track = _track(_room?.localParticipant);
    return track == null
        ? null
        : lk.VideoTrackRenderer(
            track,
            fit: lk.VideoViewFit.cover,
            mirrorMode: lk.VideoViewMirrorMode.mirror,
          );
  }

  @override
  Future<void> leave() async {
    final room = _room;
    _room = null;
    await _events?.dispose();
    _events = null;
    if (room != null) {
      await room.disconnect();
      await room.dispose();
    }
    _changes.ping();
  }
}

class _Changes extends ChangeNotifier {
  void ping() => notifyListeners();
}
