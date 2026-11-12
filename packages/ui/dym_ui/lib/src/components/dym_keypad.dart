import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Clavier géant (design « Épuré ») : chiffres de 0 à 9 et effacement, touches
/// de 56 px à filet. Une main, au comptoir ou sur la moto.
class DymKeypad extends StatelessWidget {
  /// Crée le clavier. [onDigit] reçoit « 0 » à « 9 » ; [onErase] efface.
  const new({
    required this.onDigit,
    required this.onErase,
    required this.eraseLabel,
    super.key,
  });

  /// Chiffre touché.
  final ValueChanged<String> onDigit;

  /// Effacer le dernier chiffre.
  final VoidCallback onErase;

  /// Libellé lu par le lecteur d'écran pour l'effacement.
  final String eraseLabel;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final row in const [
        ['1', '2', '3'],
        ['4', '5', '6'],
        ['7', '8', '9'],
        ['', '0', '<'],
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
          child: Row(
            children: [
              for (final (i, key) in row.indexed) ...[
                if (i > 0) const SizedBox(width: DymTokenSpace.s2),
                Expanded(
                  child: switch (key) {
                    '' => const SizedBox(height: 56),
                    '<' => _Key(label: eraseLabel, onTap: onErase, erase: true),
                    _ => _Key(label: key, onTap: () => onDigit(key)),
                  },
                ),
              ],
            ],
          ),
        ),
    ],
  );
}

class _Key extends StatelessWidget {
  const new({required this.label, required this.onTap, this.erase = false});

  final String label;
  final VoidCallback onTap;
  final bool erase;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DymTokenRadius.button),
          side: BorderSide(color: c.hairline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DymTokenRadius.button),
          child: SizedBox(
            height: 56,
            child: Center(
              child: erase
                  ? Icon(Icons.backspace_outlined, color: c.textPrimary)
                  : Text(
                      label,
                      style: context.dym.text.display.copyWith(fontSize: 24),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
