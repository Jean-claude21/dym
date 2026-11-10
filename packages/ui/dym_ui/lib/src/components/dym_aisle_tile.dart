import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Tuile de rayon : contenant vu de dessus sur une teinte, libellé dessous
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

  /// Teinte de fond (tokens `color.tint.*`).
  final Color tint;

  /// Badge en haut à droite (« Nouveau »).
  final Widget? badge;

  /// Ouvre le rayon.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: tint,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                child: Column(
                  children: [
                    Expanded(
                      child: Image(
                        image: image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: context.dym.text.label.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) Positioned(top: 4, right: 4, child: badge!),
            ],
          ),
        ),
      ),
    );
  }
}
