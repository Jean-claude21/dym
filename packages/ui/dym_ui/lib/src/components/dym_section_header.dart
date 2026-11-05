import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Titre de section avec action optionnelle (« Tout voir »).
class DymSectionHeader extends StatelessWidget {
  /// Crée un en-tête.
  const new({required this.title, super.key, this.actionLabel, this.onAction});

  /// Titre.
  final String title;

  /// Libellé de l'action.
  final String? actionLabel;

  /// Action.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(title, maxLines: 1, style: context.dym.text.title),
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: c.brandDeep,
              minimumSize: const Size(0, DymTokenSize.touchMin),
              padding: const EdgeInsets.symmetric(horizontal: DymTokenSpace.s2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: context.dym.text.label.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.brandDeep,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
      ],
    );
  }
}
