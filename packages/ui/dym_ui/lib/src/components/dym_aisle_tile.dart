import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Tuile de rayon : photo dans un cercle menthe, libellé dessous
/// (deux lignes au plus : « Céréales et farines »).
class DymAisleTile extends StatelessWidget {
  /// Crée une tuile.
  const new({
    required this.image,
    required this.label,
    required this.tint,
    super.key,
    this.badge,
    this.onTap,
  });

  /// Contenant vu de dessus (fond transparent).
  final ImageProvider image;

  /// Libellé (« Légumes »).
  final String label;

  /// Ignorée depuis le design « Épuré » (toujours menthe) ; gardée pour la
  /// compatibilité des appels.
  final Color tint;

  /// Badge en haut à droite (« Nouveau »).
  final Widget? badge;

  /// Ouvre le rayon.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Semantics(
      container: true,
      onTap: onTap,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s1),
          child: Column(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.tintVertTendre,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(DymTokenSpace.s2),
                            child: Image(
                              image: image,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                      if (badge != null)
                        Positioned(top: -4, right: -4, child: badge!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DymTokenSpace.s1 + 2),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.dym.text.label.copyWith(
                  fontSize: 13,
                  height: 1.2,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
