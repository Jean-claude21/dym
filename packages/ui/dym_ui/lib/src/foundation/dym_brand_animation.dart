import 'dart:math' as math;

import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Écran de démarrage, identique à `docs/design/marque/splash-anime.gif` :
/// le sac se dessine, les légumes arrivent des coins, le nom monte, puis
/// l'accroche et la signature apparaissent (images 50 à 62) et le logo
/// respire. L'animation se joue en entier, à sa vitesse (120 images à
/// 30 i/s, 4 s) ; si l'app charge encore, la respiration (60–120) continue.
///
/// L'animation (390 × 844) couvre l'écran en portrait ; en paysage elle est
/// contenue. [tagline] et [footer] sont placés comme dans l'aperçu (550 et
/// 640 dans le repère de l'animation).
class DymSplash extends StatefulWidget {
  const new({
    required this.tagline,
    super.key,
    this.footer,
    this.onIntroComplete,
  });

  final String tagline;
  final Widget? footer;

  /// Appelé quand l'animation a été jouée en entier (tout de suite si les
  /// animations sont réduites ou si l'animation ne peut pas être lue).
  final VoidCallback? onIntroComplete;

  @override
  State<DymSplash> createState() => _DymSplashState();
}

class _DymSplashState extends State<DymSplash>
    with SingleTickerProviderStateMixin {
  static const _size = Size(390, 844);
  static const _frames = 120.0;
  static const _taglineTop = 550.0;
  static const _footerTop = 640.0;
  static const _loopStart = 0.5;

  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _play(LottieComposition composition) async {
    _controller.duration = composition.duration;
    if (!DymMotion.enabled(context)) {
      _controller.value = _loopStart;
      widget.onIntroComplete?.call();
      return;
    }
    await _controller.forward(from: 0);
    if (!mounted) return;
    widget.onIntroComplete?.call();
    await _controller.repeat(
      min: _loopStart,
      max: 1,
      period: composition.duration * (1 - _loopStart),
    );
  }

  /// Accroche et signature : fondu entre les images 50 et 62.
  double get _textOpacity {
    if (!DymMotion.enabled(context)) return 1;
    return ((_controller.value * _frames - 50) / 12).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return ColoredBox(
      color: c.background,
      child: LayoutBuilder(
        builder: (context, box) {
          final portrait = box.maxHeight >= box.maxWidth;
          final sx = box.maxWidth / _size.width;
          final sy = box.maxHeight / _size.height;
          final scale = portrait ? math.max(sx, sy) : math.min(sx, sy);
          final dy = (box.maxHeight - _size.height * scale) / 2;
          final dx = (box.maxWidth - _size.width * scale) / 2;
          return Stack(
            children: [
              Positioned(
                left: dx,
                top: dy,
                width: _size.width * scale,
                height: _size.height * scale,
                child: ExcludeSemantics(
                  child: Lottie.asset(
                    'assets/brand/splash.json',
                    package: 'dym_ui',
                    controller: _controller,
                    fit: BoxFit.fill,
                    onLoaded: _play,
                    errorBuilder: (_, _, _) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => widget.onIntroComplete?.call(),
                      );
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final o = _textOpacity;
                  return Stack(
                    children: [
                      Positioned(
                        left: 40,
                        right: 40,
                        top: math.min(
                          dy + _taglineTop * scale,
                          box.maxHeight - 120,
                        ),
                        child: Opacity(
                          opacity: o,
                          child: Text(
                            widget.tagline,
                            textAlign: TextAlign.center,
                            style: t.body.copyWith(
                              fontSize: 17,
                              height: 1.4,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      if (widget.footer != null)
                        Positioned(
                          left: 24,
                          right: 24,
                          top: math.min(
                            dy + _footerTop * scale,
                            box.maxHeight - 48,
                          ),
                          child: Opacity(
                            opacity: o,
                            child: DefaultTextStyle(
                              style: t.label.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: c.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                              child: widget.footer!,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
