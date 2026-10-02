import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Carte avec interrupteur : titre, sous-titre, état. [large] : grand
/// interrupteur d'ouverture de la boutique (un geste, parcours 13).
class DymSwitchTile extends StatelessWidget {
  /// Crée la carte. Toute la carte bascule l'interrupteur (cible ≥ 48 dp).
  const new({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
    this.large = false,
  });

  final String title;
  final String? subtitle;
  final bool value;

  /// Nul : désactivé.
  final ValueChanged<bool>? onChanged;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final toggle = onChanged == null ? null : () => onChanged!(!value);
    return MergeSemantics(
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        child: InkWell(
          onTap: toggle,
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: large ? 88 : 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DymTokenSpace.s4,
                vertical: DymTokenSpace.s3,
              ),
              child: Row(
                children: [
                  if (large) ...[
                    Transform.scale(
                      scale: 1.35,
                      child: Switch(
                        value: value,
                        onChanged: onChanged,
                        activeTrackColor: c.brand,
                      ),
                    ),
                    const SizedBox(width: DymTokenSpace.s4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: large
                              ? t.display.copyWith(fontSize: 26)
                              : t.title.copyWith(fontSize: 17),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: t.label.copyWith(
                              fontSize: 14,
                              color: c.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!large) ...[
                    const SizedBox(width: DymTokenSpace.s3),
                    Switch(
                      value: value,
                      onChanged: onChanged,
                      activeTrackColor: c.brand,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
