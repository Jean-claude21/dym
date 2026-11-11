import 'package:dym_ui/src/components/dym_bottom_nav.dart';
import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:flutter/material.dart';

/// Tuile de navigation partagée par [DymBottomNav] et le rail : icône,
/// libellé, trait sous l'élément actif. Interne à dym_ui.
class DymNavTile extends StatelessWidget {
  /// Crée la tuile.
  const new({required this.item, required this.active, super.key});

  /// Élément affiché.
  final DymNavItem item;

  /// Élément actif.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final color = active ? c.brand : c.textSecondary;
    // Indicateur au-dessus de l'icône (design « Épuré »).
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: DymMotion.of(context, DymMotion.fast),
          width: active ? 22 : 0,
          height: 3,
          decoration: BoxDecoration(
            color: c.brand,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 6),
        Icon(item.icon, color: color, size: 24),
        const SizedBox(height: 3),
        Text(
          item.label,
          textAlign: TextAlign.center,
          style: context.dym.text.label.copyWith(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
