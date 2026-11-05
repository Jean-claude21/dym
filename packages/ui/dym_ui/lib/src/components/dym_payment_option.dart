import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Option de paiement (« Cash à la livraison », « Mobile Money »).
class DymPaymentOption extends StatelessWidget {
  /// Crée une option.
  const new({
    required this.title,
    required this.selected,
    required this.onTap,
    super.key,
    this.subtitle,
    this.icon,
  });

  /// Icône facultative.
  final IconData? icon;

  /// Titre.
  final String title;

  /// Sous-titre (« T-Money, Flooz »).
  final String? subtitle;

  /// Option choisie.
  final bool selected;

  /// Sélectionne l'option.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: [title, ?subtitle].join(', '),
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: DymMotion.of(context, DymMotion.fast),
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          color: selected ? c.tintVertTendre : c.card,
          borderRadius: BorderRadius.circular(DymTokenRadius.button),
          border: Border.all(
            color: selected ? c.brand : c.textSecondary.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DymTokenRadius.button),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DymTokenSpace.s3,
                vertical: DymTokenSpace.s2,
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected ? c.brand : c.textSecondary,
                  ),
                  const SizedBox(width: DymTokenSpace.s2),
                  if (icon != null) ...[
                    Icon(icon, color: c.textPrimary, size: 20),
                    const SizedBox(width: DymTokenSpace.s2),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: context.dym.text.label.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: context.dym.text.label.copyWith(
                              fontSize: 12,
                              color: c.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
