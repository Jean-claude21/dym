import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// État de validation affiché sous un champ.
enum DymFieldStatus { none, valid, error }

/// Champ de saisie DYM : grand, blanc, coins 20, bordure verte au focus,
/// message de validation sous le champ (icône + texte, jamais la couleur
/// seule).
class DymTextField extends StatelessWidget {
  /// Crée le champ. [label] est lu par les lecteurs d'écran.
  const new({
    required this.label,
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hint,
    this.icon,
    this.status = DymFieldStatus.none,
    this.message,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.autofocus = false,
    this.enabled = true,
    this.maxLength,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.minLines,
    this.maxLines = 1,
    this.suffixText,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? hint;
  final IconData? icon;
  final DymFieldStatus status;

  /// Message sous le champ (validité ou erreur).
  final String? message;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool autofocus;
  final bool enabled;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  /// Lignes affichées (champ multiligne : `maxLines` > 1).
  final int? minLines;
  final int? maxLines;

  /// Texte après la saisie (« F CFA »).
  final String? suffixText;

  /// Saisie masquée (mot de passe).
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(DymTokenRadius.field),
      borderSide: BorderSide(color: color, width: width),
    );
    final errorColor = c.pimentStrong;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          autofocus: autofocus,
          enabled: enabled,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          minLines: minLines,
          maxLines: maxLines,
          style: t.body.copyWith(fontSize: 16, color: c.textPrimary),
          cursorColor: c.brand,
          decoration: InputDecoration(
            labelText: label,
            // Libellé visible pendant la saisie (lecteurs d'écran compris).
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            hintText: hint,
            suffixText: suffixText,
            suffixStyle: t.price.copyWith(fontSize: 16, color: c.textPrimary),
            counterText: '',
            filled: true,
            fillColor: c.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DymTokenSpace.s4,
              vertical: 16,
            ),
            prefixIcon: icon == null
                ? null
                : Icon(icon, color: c.textSecondary, size: 22),
            enabledBorder: border(
              status == DymFieldStatus.error ? errorColor : c.lineStrong,
              1,
            ),
            focusedBorder: border(
              status == DymFieldStatus.error ? errorColor : c.brand,
              2,
            ),
            disabledBorder: border(c.hairline, 1),
          ),
        ),
        if (message != null && status != DymFieldStatus.none) ...[
          const SizedBox(height: DymTokenSpace.s2),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(
                  status == DymFieldStatus.valid
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  size: 20,
                  color: status == DymFieldStatus.valid ? c.brand : errorColor,
                ),
                const SizedBox(width: DymTokenSpace.s2),
                Expanded(
                  child: Text(
                    message!,
                    style: t.label.copyWith(
                      fontSize: 14,
                      color: status == DymFieldStatus.valid
                          ? c.brandDeep
                          : errorColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
