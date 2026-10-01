import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Barre de recherche avec micro et appareil photo.
class DymSearchBar extends StatelessWidget {
  /// Crée la barre. Les libellés d'accessibilité sont fournis par l'appelant.
  const new({
    required this.hint,
    required this.onTap,
    super.key,
    this.onMic,
    this.onCamera,
    this.micLabel = '',
    this.cameraLabel = '',
  });

  /// Texte indicatif.
  final String hint;

  /// Ouvre la recherche.
  final VoidCallback onTap;

  /// Recherche vocale (masqué si nul).
  final VoidCallback? onMic;

  /// Recherche par photo (masqué si nul).
  final VoidCallback? onCamera;

  /// Libellé d'accessibilité du micro.
  final String micLabel;

  /// Libellé d'accessibilité de l'appareil photo.
  final String cameraLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [DymTokenShadows.card],
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: hint,
              excludeSemantics: true,
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DymTokenSpace.s4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: c.textPrimary,
                        size: 26,
                      ),
                      const SizedBox(width: DymTokenSpace.s3),
                      Expanded(
                        child: Text(
                          hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.dym.text.body.copyWith(
                            color: c.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onMic != null)
            IconButton(
              tooltip: micLabel,
              onPressed: onMic,
              icon: Icon(Icons.mic_rounded, color: c.textPrimary),
            ),
          if (onMic != null && onCamera != null)
            Container(
              width: 1,
              height: 28,
              color: c.textSecondary.withValues(alpha: 0.2),
            ),
          if (onCamera != null)
            IconButton(
              tooltip: cameraLabel,
              onPressed: onCamera,
              icon: Icon(Icons.photo_camera_rounded, color: c.textPrimary),
            ),
          const SizedBox(width: DymTokenSpace.s1),
        ],
      ),
    );
  }
}
