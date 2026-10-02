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
  });

  /// Libellé.
  final String label;

  /// Puce active.
  final bool selected;

  /// Action au toucher.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
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
                  color: selected ? c.brand : c.card,
                  borderRadius: BorderRadius.circular(DymTokenRadius.chip),
                  border: Border.all(
                    color: selected
                        ? c.brand
                        : c.textSecondary.withValues(alpha: 0.25),
                  ),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    style: context.dym.text.label.copyWith(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? c.onBrand : c.textPrimary,
                    ),
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
