import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Élément de [DymBottomNav].
@immutable
class DymNavItem {
  /// Crée un élément.
  const new({required this.icon, required this.label});

  /// Icône.
  final IconData icon;

  /// Libellé.
  final String label;
}

/// Barre de navigation basse : icône + libellé, élément actif en vert profond
/// avec un trait dessous.
class DymBottomNav extends StatelessWidget {
  /// Crée la barre.
  const new({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  /// Éléments.
  final List<DymNavItem> items;

  /// Index actif.
  final int currentIndex;

  /// Sélection d'un élément.
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(
          top: BorderSide(color: c.textSecondary.withValues(alpha: 0.12)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          // 70 à taille de texte normale ; suit le réglage du téléphone.
          height: 50 + MediaQuery.textScalerOf(context).scale(20),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == currentIndex,
                    label: items[i].label,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => onTap(i),
                      child: _NavTile(
                        item: items[i],
                        active: i == currentIndex,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const new({required this.item, required this.active});

  final DymNavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final color = active ? c.brand : c.textSecondary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(item.icon, color: color, size: 26),
        const SizedBox(height: 2),
        Text(
          item.label,
          style: context.dym.text.label.copyWith(
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        AnimatedContainer(
          duration: DymMotion.of(context, DymMotion.fast),
          width: active ? 28 : 0,
          height: 3,
          decoration: BoxDecoration(
            color: c.brand,
            borderRadius: BorderRadius.circular(DymTokenRadius.chip),
          ),
        ),
      ],
    );
  }
}
