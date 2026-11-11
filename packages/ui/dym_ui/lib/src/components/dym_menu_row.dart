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
    final color = destructive ? c.pimentStrong : c.textPrimary;
    return Semantics(
      container: true,
      onTap: onTap,
      button: true,
      enabled: onTap != null,
      label: value == null ? label : '$label, $value',
      excludeSemantics: true,
      // Ligne plate (design « Épuré ») : posée dans un DymMenuGroup ou sur le
      // fond, séparée par des filets.
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DymTokenSpace.s4,
                vertical: DymTokenSpace.s3,
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: DymTokenSpace.s3 + 2),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: label,
                        style: t.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: destructive ? c.pimentStrong : c.textPrimary,
                        ),
                        children: [
                          if (value != null)
                            TextSpan(
                              text: ' · $value',
                              style: t.body.copyWith(color: c.textSecondary),
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

/// Groupe de [DymMenuRow] : carte blanche à filet, lignes séparées par des
/// filets alignés sur le texte (design « Épuré »).
class DymMenuGroup extends StatelessWidget {
  /// Crée un groupe ; les éléments nuls sont ignorés.
  const new({required this.children, super.key});

  /// Lignes du groupe.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    if (children.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        border: Border.all(color: c.hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        child: Column(
          children: [
            for (final (i, row) in children.indexed) ...[
              if (i > 0)
                Divider(
                  indent: DymTokenSpace.s4 + 22 + DymTokenSpace.s3 + 2,
                  color: c.hairline,
                ),
              row,
            ],
          ],
        ),
      ),
    );
  }
}
