import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Pastille jaune plantain de délai de livraison, avec l'illustration du zem.
class DymDeliveryPill extends StatelessWidget {
  /// Crée la pastille. [zem] : illustration du zem fournie par l'app.
  const new({required this.label, required this.zem, super.key});

  /// Libellé (« Livré en 35 min »).
  final String label;

  /// Illustration du zem (image).
  final ImageProvider zem;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        height: 44,
        padding: const EdgeInsets.only(left: 6, right: DymTokenSpace.s4),
        decoration: BoxDecoration(
          color: c.plantain,
          borderRadius: BorderRadius.circular(DymTokenRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(image: zem, width: 36, height: 36, fit: BoxFit.contain),
            const SizedBox(width: DymTokenSpace.s1),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.dym.text.title.copyWith(
                  fontSize: 16,
                  color: c.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
