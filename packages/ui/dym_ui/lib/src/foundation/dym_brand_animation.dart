import 'dart:math' as math;

import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Scènes animées de la marque (Lottie, `assets/brand/`), dessinées aux
/// couleurs du thème « Épuré » (`docs/design/marque/`).
enum DymBrandScene {
  /// Le sac se remplit de légumes : le marché près de chez toi.
  market('onb_marche'),

  /// Plusieurs boutiques, un seul panier.
  cart('onb_panier'),

  /// Paiement validé, la moto suit la route jusqu'à la maison.
  delivery('onb_livraison'),

  /// L'étal de la vendeuse et les commandes qui arrivent.
  vendor('onb_vendeuse'),

  /// Le livreur entre deux points.
  courier('onb_livreur');

  new(this.file);

  final String file;
}

/// Une scène de la marque, jouée une fois puis figée sur sa dernière image.
///
/// Animations réduites : la dernière image s'affiche directement (la scène
/// complète, jamais un cadre vide).
class DymBrandSceneView extends StatefulWidget {
  const new(this.scene, {super.key, this.fit = BoxFit.contain});

  final DymBrandScene scene;
  final BoxFit fit;

  @override
  State<DymBrandSceneView> createState() => _DymBrandSceneViewState();
}

class _DymBrandSceneViewState extends State<DymBrandSceneView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Lottie.asset(
        'assets/brand/${widget.scene.file}.json',
        package: 'dym_ui',
        controller: _controller,
        fit: widget.fit,
        onLoaded: (composition) {
          _controller.duration = composition.duration;
          if (DymMotion.enabled(context)) {
            _controller.forward(from: 0);
          } else {
            _controller.value = 1;
          }
        },
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

/// Écran de démarrage animé : le sac se dessine, les légumes arrivent des
/// coins, le nom monte, puis le logo « respire » tant que l'app charge.
///
/// L'animation (390 × 844) couvre l'écran en portrait ; en paysage elle est
/// contenue pour garder le logo à taille raisonnable. [tagline] s'affiche
/// sous le nom, [footer] en bas (signature du réalisateur), [below] sous
/// l'accroche (état de chargement, environnement).
class DymSplash extends StatefulWidget {
  const new({
    required this.tagline,
    super.key,
    this.footer,
    this.below,
    this.onIntroComplete,
  });

  final String tagline;
  final Widget? footer;
  final Widget? below;

  /// Appelé quand l'entrée est jouée (tout de suite si les animations sont
  /// réduites ou si l'animation ne peut pas être lue) : l'app peut alors
  /// changer d'écran sans couper le logo.
  final VoidCallback? onIntroComplete;

  @override
  State<DymSplash> createState() => _DymSplashState();
}

class _DymSplashState extends State<DymSplash>
    with SingleTickerProviderStateMixin {
  // Composition : 120 images, entrée 0–60, boucle de respiration 60–120.
  static const _size = Size(390, 844);
  static const _taglineTop = 550.0;
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
    await _controller.animateTo(
      _loopStart,
      duration: composition.duration * _loopStart,
    );
    if (!mounted) return;
    widget.onIntroComplete?.call();
    await _controller.repeat(
      min: _loopStart,
      max: 1,
      period: composition.duration * (1 - _loopStart),
    );
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
              Positioned(
                left: 24,
                right: 24,
                top: math.min(dy + _taglineTop * scale, box.maxHeight - 160),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.tagline,
                      textAlign: TextAlign.center,
                      style: t.title.copyWith(color: c.textSecondary),
                    ),
                    if (widget.below != null) ...[
                      const SizedBox(height: 20),
                      widget.below!,
                    ],
                  ],
                ),
              ),
              if (widget.footer != null)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: DefaultTextStyle(
                        style: t.label.copyWith(color: c.textSecondary),
                        textAlign: TextAlign.center,
                        child: widget.footer!,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Signature « Réalisé par Kete » : [prefix] discret, [maker] en vert.
class DymMadeBy extends StatelessWidget {
  const new({required this.prefix, required this.maker, super.key});

  final String prefix;
  final String maker;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Text.rich(
      TextSpan(
        text: '$prefix ',
        children: [
          TextSpan(
            text: maker,
            style: TextStyle(fontWeight: FontWeight.w700, color: c.brand),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
