import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:flutter/material.dart';

/// Avatar rond, avec liseré blanc et pastille de présence optionnelle.
class DymAvatar extends StatelessWidget {
  /// Crée un avatar.
  const new({
    required this.image,
    super.key,
    this.size = 56,
    this.presenceDot = false,
    this.ring = true,
    this.semanticLabel,
  });

  /// Photo.
  final ImageProvider image;

  /// Diamètre.
  final double size;

  /// Affiche une pastille verte « présente ».
  final bool presenceDot;

  /// Liseré blanc autour de la photo.
  final bool ring;

  /// Libellé d'accessibilité.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Semantics(
      image: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: ring ? Border.all(color: c.card, width: 3) : null,
                image: DecorationImage(image: image, fit: BoxFit.cover),
              ),
            ),
            if (presenceDot)
              Positioned(
                right: size * 0.02,
                top: size * 0.02,
                child: Container(
                  width: size * 0.22,
                  height: size * 0.22,
                  decoration: BoxDecoration(
                    color: c.brand,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.card, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
