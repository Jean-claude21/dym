import 'package:dym_ui/src/components/dym_nav_tile.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
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
                      child: DymNavTile(
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
