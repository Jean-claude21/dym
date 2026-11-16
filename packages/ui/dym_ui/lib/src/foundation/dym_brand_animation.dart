import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dym_ui/src/theme/dym_colors.dart';
import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

/// Couleurs du splash selon l'app (spec 093), assorties à son icône.
enum DymSplashTone {
  /// Fond clair, sac vert (cliente).
  light,

  /// Fond vert de la marque, sac blanc, anse et feuilles plantain (vendeuse).
  brand,

  /// Fond plantain, sac vert profond (livreur).
  plantain,
}

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
    this.tone = DymSplashTone.light,
  });

  final String tagline;
  final Widget? footer;

  /// Couleurs de l'app (fond, sac, texte).
  final DymSplashTone tone;

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

  /// Animation chargée (recolorée selon l'app) ; nulle pendant le chargement.
  LottieComposition? _composition;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) return;
    _loading = true;
    final (_, bag, accent, _) = _palette(context.dym.colors);
    unawaited(
      loadSplashComposition(bag: bag, accent: accent).then(
        (composition) {
          if (!mounted) return;
          setState(() => _composition = composition);
          unawaited(_play(composition));
        },
        onError: (Object _) {
          if (mounted) widget.onIntroComplete?.call();
        },
      ),
    );
  }

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

  /// Fond, couleur du sac et du nom, anse et feuilles, texte.
  (Color, Color?, Color?, Color) _palette(DymColors c) => switch (widget.tone) {
    DymSplashTone.light => (c.background, null, null, c.textSecondary),
    DymSplashTone.brand => (
      c.brand,
      Colors.white,
      c.plantain,
      Colors.white.withValues(alpha: 0.85),
    ),
    DymSplashTone.plantain => (c.plantain, c.brandDeep, c.brand, c.brandDeep),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final (background, bag, accent, text) = _palette(c);
    return ColoredBox(
      color: background,
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
                  child: switch (_composition) {
                    final composition? => Lottie(
                      composition: composition,
                      controller: _controller,
                      fit: BoxFit.fill,
                    ),
                    null => const SizedBox.shrink(),
                  },
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
                              color: text,
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

/// Animation du splash, recolorée en mémoire pour l'app (sac et nom, anse et
/// feuilles) : un seul fichier pour toutes les apps (spec 093). Sans couleur,
/// l'animation d'origine.
Future<LottieComposition> loadSplashComposition({
  Color? bag,
  Color? accent,
}) async {
  // Lu une fois par lancement : pas de cache du paquet de ressources.
  final text = await rootBundle.loadString(
    'packages/dym_ui/assets/brand/splash.json',
    cache: false,
  );
  if (bag == null) return await LottieComposition.fromBytes(utf8.encode(text));
  final data = jsonDecode(text) as Map<String, dynamic>;
  for (final layer in data['layers'] as List) {
    final map = layer as Map<String, dynamic>;
    final color = switch (map['nm']) {
      'sac' || 'nom' => bag,
      'anse' || 'feuilles' => accent ?? bag,
      _ => null,
    };
    if (color != null) _paint(map['shapes'], color);
  }
  return await LottieComposition.fromBytes(utf8.encode(jsonEncode(data)));
}

/// Remplissages et contours d'un groupe de formes, récursivement.
void _paint(Object? node, Color color) {
  if (node is List) {
    for (final n in node) {
      _paint(n, color);
    }
  } else if (node is Map<String, dynamic>) {
    if ((node['ty'] == 'fl' || node['ty'] == 'st') && node['c'] is Map) {
      final c = node['c'] as Map<String, dynamic>;
      c['k'] = [color.r, color.g, color.b, 1];
    }
    _paint(node['it'], color);
  }
}
