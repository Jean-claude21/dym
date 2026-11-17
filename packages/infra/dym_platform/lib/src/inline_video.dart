import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Vidéo lue directement dans une bulle de conversation (spec 111) : rien
/// n'est chargé avant le premier tap (réseau 3G) ; ensuite lecture, pause,
/// progression et son coupé ou non.
class InlineVideo extends StatefulWidget {
  const new({
    required this.url,
    required this.playLabel,
    required this.pauseLabel,
    required this.muteLabel,
    required this.unmuteLabel,
    super.key,
    this.durationLabel,
    this.width = 240,
    this.height = 180,
    this.background = Colors.black,
    this.foreground = Colors.white,
    this.onFullScreen,
    this.fullScreenLabel,
  });

  /// Lien signé ; nul tant qu'il n'est pas obtenu.
  final String? url;
  final String playLabel;
  final String pauseLabel;
  final String muteLabel;
  final String unmuteLabel;

  /// Durée affichée avant la lecture (« 0:42 »).
  final String? durationLabel;
  final double width;
  final double height;
  final Color background;
  final Color foreground;

  /// Plein écran (même lien) ; nul : pas de bouton.
  final VoidCallback? onFullScreen;
  final String? fullScreenLabel;

  @override
  State<InlineVideo> createState() => _InlineVideoState();
}

class _InlineVideoState extends State<InlineVideo> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;

  Future<void> _start() async {
    final url = widget.url;
    if (url == null || _loading) return;
    final existing = _controller;
    if (existing != null) {
      await (existing.value.isPlaying ? existing.pause() : existing.play());
      return;
    }
    setState(() => _loading = true);
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
    } on Object {
      unawaited(controller.dispose());
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) {
      unawaited(controller.dispose());
      return;
    }
    controller.addListener(_tick);
    _controller = controller;
    setState(() => _loading = false);
    await controller.play();
  }

  void _tick() {
    final value = _controller?.value;
    if (value == null) return;
    // Fin : retour au début, prête à relire.
    if (!value.isPlaying &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      unawaited(_controller?.seekTo(Duration.zero));
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final controller = _controller;
    controller?.removeListener(_tick);
    unawaited(controller?.dispose());
    super.dispose();
  }

  static String _clock(Duration d) {
    final s = d.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final value = controller?.value;
    final playing = value?.isPlaying ?? false;
    final fg = widget.foreground;
    final label = TextStyle(
      color: fg,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      shadows: const [Shadow(blurRadius: 4)],
    );
    final total = value?.duration ?? Duration.zero;
    final position = value?.position ?? Duration.zero;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Material(
        color: widget.background,
        child: InkWell(
          onTap: widget.url == null || _failed ? null : _start,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (controller != null && value!.isInitialized)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: value.size.width,
                    height: value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              if (_loading)
                Center(child: CircularProgressIndicator(color: fg))
              else if (!playing)
                Center(
                  child: Icon(
                    _failed
                        ? Icons.videocam_off_rounded
                        : Icons.play_circle_fill_rounded,
                    color: fg,
                    size: 56,
                    semanticLabel: widget.playLabel,
                  ),
                ),
              if (controller != null && total > Duration.zero)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: fg,
                      bufferedColor: fg.withValues(alpha: 0.4),
                      backgroundColor: fg.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Text(
                  controller == null
                      ? (widget.durationLabel ?? '')
                      : '${_clock(position)} / ${_clock(total)}',
                  style: label,
                ),
              ),
              if (controller != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: value!.volume == 0
                            ? widget.unmuteLabel
                            : widget.muteLabel,
                        color: fg,
                        onPressed: () => unawaited(
                          controller.setVolume(value.volume == 0 ? 1 : 0),
                        ),
                        icon: Icon(
                          value.volume == 0
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                        ),
                      ),
                      if (widget.onFullScreen case final open?)
                        IconButton(
                          tooltip: widget.fullScreenLabel,
                          color: fg,
                          onPressed: () {
                            unawaited(controller.pause());
                            open();
                          },
                          icon: const Icon(Icons.fullscreen_rounded),
                        ),
                    ],
                  ),
                ),
              if (playing)
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    tooltip: widget.pauseLabel,
                    color: fg,
                    onPressed: () => unawaited(controller!.pause()),
                    icon: const Icon(Icons.pause_circle_filled_rounded),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
