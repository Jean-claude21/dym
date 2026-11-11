import 'package:dym_ui/src/components/dym_bottom_nav.dart';
import 'package:dym_ui/src/components/dym_nav_tile.dart';
import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Rail de navigation latéral, équivalent de [DymBottomNav] sur tablette et
/// bureau.
///
/// Compact (`extended: false`) : libellé sous l'icône, trait sous l'élément
/// actif, comme la barre basse. Étendu : libellé à côté de l'icône, élément
/// actif sur fond vert tendre avec un trait vertical.
class DymNavRail extends StatelessWidget {
  /// Crée le rail.
  const new({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
    this.extended = false,
    this.leading,
  });

  /// Éléments (mêmes destinations que la barre basse).
  final List<DymNavItem> items;

  /// Index actif.
  final int currentIndex;

  /// Sélection d'un élément.
  final ValueChanged<int> onTap;

  /// Libellés à côté des icônes (classe large).
  final bool extended;

  /// Élément en tête du rail (logo, avatar).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final itemHeight = extended
        ? DymTokenSize.touchMin + 8
        : 54 + MediaQuery.textScalerOf(context).scale(20);
    return Container(
      width: extended
          ? DymTokenLayout.railExtendedWidth
          : DymTokenLayout.railWidth,
      decoration: BoxDecoration(
        color: c.card,
        border: Border(right: BorderSide(color: c.hairline)),
      ),
      child: SafeArea(
        right: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            vertical: DymTokenSpace.s3,
            horizontal: extended ? DymTokenSpace.s3 : 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leading != null) ...[
                Center(child: leading),
                const SizedBox(height: DymTokenSpace.s4),
              ],
              for (var i = 0; i < items.length; i++)
                Semantics(
                  container: true,
                  onTap: () => onTap(i),
                  button: true,
                  selected: i == currentIndex,
                  label: items[i].label,
                  excludeSemantics: true,
                  child: SizedBox(
                    height: itemHeight,
                    child: InkWell(
                      onTap: () => onTap(i),
                      borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                      child: extended
                          ? _ExtendedTile(
                              item: items[i],
                              active: i == currentIndex,
                            )
                          : DymNavTile(
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

class _ExtendedTile extends StatelessWidget {
  const new({required this.item, required this.active});

  final DymNavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final color = active ? c.brand : c.textSecondary;
    return AnimatedContainer(
      duration: DymMotion.of(context, DymMotion.fast),
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: active ? c.tintVertTendre : Colors.transparent,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: DymMotion.of(context, DymMotion.fast),
            width: 3,
            height: active ? 24 : 0,
            decoration: BoxDecoration(
              color: c.brand,
              borderRadius: BorderRadius.circular(DymTokenRadius.chip),
            ),
          ),
          const SizedBox(width: DymTokenSpace.s2),
          Icon(item.icon, color: color, size: 24),
          const SizedBox(width: DymTokenSpace.s3),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.dym.text.label.copyWith(
                fontSize: 15,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? c.brandDeep : c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
