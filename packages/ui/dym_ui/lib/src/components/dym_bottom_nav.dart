import 'dart:math' as math;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaler = MediaQuery.textScalerOf(context);
            var labelHeight = scaler.scale(20);
            for (final item in items) {
              final painter = TextPainter(
                text: TextSpan(
                  text: item.label,
                  style: context.dym.text.label.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                textDirection: Directionality.of(context),
                textScaler: scaler,
              )..layout(maxWidth: constraints.maxWidth / items.length);
              labelHeight = math.max(labelHeight, painter.height);
              painter.dispose();
            }
            return SizedBox(
              // Les libellés peuvent occuper deux lignes à cinq destinations.
              height: 50 + labelHeight,
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
            );
          },
        ),
      ),
    );
  }
}
