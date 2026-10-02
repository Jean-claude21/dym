import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Ligne de menu (écran « Moi », réglages) : icône, libellé, valeur
/// facultative, chevron. [destructive] : libellé et icône en rouge piment
/// foncé.
class DymMenuRow extends StatelessWidget {
  /// Crée la ligne.
  const new({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
    this.value,
    this.destructive = false,
  });

  final IconData icon;
  final String label;

  /// Valeur affichée après le libellé (ex. « Français »).
  final String? value;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final color = destructive ? c.pimentStrong : c.brand;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: value == null ? label : '$label, $value',
      excludeSemantics: true,
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DymTokenSpace.s4,
                vertical: DymTokenSpace.s3,
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 26),
                  const SizedBox(width: DymTokenSpace.s4),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: label,
                        style: t.title.copyWith(
                          fontSize: 17,
                          color: destructive ? c.pimentStrong : c.textPrimary,
                        ),
                        children: [
                          if (value != null)
                            TextSpan(
                              text: ' · $value',
                              style: t.body.copyWith(
                                fontSize: 16,
                                color: c.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: c.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
