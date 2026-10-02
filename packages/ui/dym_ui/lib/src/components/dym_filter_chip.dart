import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Puce de filtre ou de sous-rayon (« Tous », « Au marché », « Tomates »…).
class DymFilterChip extends StatelessWidget {
  /// Crée une puce.
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.multiple = false,
  });

  /// Libellé.
  final String label;

  /// Puce active.
  final bool selected;

  /// Action au toucher.
  final VoidCallback onTap;

  /// Choix multiple : puce active teintée avec une coche (icône + couleur).
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final tinted = multiple && selected;
    final fill = tinted ? c.tintVertTendre : (selected ? c.brand : c.card);
    final ink = tinted ? c.brandDeep : (selected ? c.onBrand : c.textPrimary);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      // Zone tactile de 48 dp ; la pastille dessinée fait 40 dp.
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DymTokenRadius.chip),
          child: SizedBox(
            height: DymTokenSize.touchMin,
            child: Center(
              widthFactor: 1,
              child: AnimatedContainer(
                duration: DymMotion.of(context, DymMotion.fast),
                curve: DymMotion.standard,
                height: 40,
                padding: const EdgeInsets.symmetric(
                  horizontal: DymTokenSpace.s4,
                ),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(DymTokenRadius.chip),
                  border: Border.all(
                    color: selected
                        ? c.brand
                        : c.textSecondary.withValues(alpha: 0.25),
                    width: tinted ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tinted) ...[
                        Icon(Icons.check_rounded, size: 20, color: ink),
                        const SizedBox(width: DymTokenSpace.s1),
                      ],
                      Flexible(
                        child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.dym.text.label.copyWith(
                          fontSize: 15,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: ink,
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
