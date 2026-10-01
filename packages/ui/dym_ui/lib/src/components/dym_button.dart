import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Variantes de [DymButton].
enum DymButtonVariant {
  /// Vert profond : l'action principale unique de l'écran.
  primary,

  /// Contour vert : action secondaire.
  secondary,

  /// Jaune plantain : action sur fond vert (mini-panier, app vendeuse).
  plantain,

  /// Contour blanc : action secondaire sur fond vert.
  onBrand,
}

/// Bouton DYM. Hauteur 56, coins 16, libellé en Nunito extra-gras.
class DymButton extends StatefulWidget {
  /// Crée un bouton. [onPressed] nul : bouton désactivé.
  const new({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = DymButtonVariant.primary,
    this.trailing,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.compact = false,
  });

  /// Libellé.
  final String label;

  /// Action ; nulle = désactivé.
  final VoidCallback? onPressed;

  /// Variante visuelle.
  final DymButtonVariant variant;

  /// Élément à droite du libellé (ex. chevron).
  final Widget? trailing;

  /// Icône à gauche du libellé.
  final IconData? icon;

  /// Affiche un indicateur de chargement et bloque l'action.
  final bool loading;

  /// Occupe toute la largeur disponible.
  final bool expanded;

  /// Version compacte (hauteur 48, marges réduites) pour les boutons côte à
  /// côte dans une carte.
  final bool compact;

  @override
  State<DymButton> createState() => _DymButtonState();
}

class _DymButtonState extends State<DymButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final enabled = widget.onPressed != null && !widget.loading;
    final (bg, fg, border) = switch (widget.variant) {
      DymButtonVariant.primary => (c.brand, c.onBrand, null),
      DymButtonVariant.secondary => (c.card, c.brandDeep, c.brand),
      DymButtonVariant.plantain => (c.plantain, c.textPrimary, null),
      DymButtonVariant.onBrand => (Colors.transparent, c.onBrand, c.onBrand),
    };
    final label = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.dym.text.title.copyWith(
        fontSize: widget.compact ? 16 : 17,
        color: fg,
      ),
    );
    final content = widget.loading
        ? SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
          )
        : Row(
            mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: fg, size: 22),
                const SizedBox(width: DymTokenSpace.s2),
              ],
              Flexible(child: label),
              if (widget.trailing != null) ...[
                const SizedBox(width: DymTokenSpace.s2),
                IconTheme(
                  data: IconThemeData(color: fg, size: 20),
                  child: widget.trailing!,
                ),
              ],
            ],
          );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: DymMotion.of(context, DymMotion.fast),
        curve: DymMotion.standard,
        child: AnimatedOpacity(
          opacity: enabled || widget.loading ? 1 : 0.45,
          duration: DymMotion.of(context, DymMotion.fast),
          child: Material(
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DymTokenRadius.button),
              side: border == null
                  ? BorderSide.none
                  : BorderSide(color: border, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? widget.onPressed : null,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: widget.compact ? DymTokenSize.touchMin : 56,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact
                        ? DymTokenSpace.s3
                        : DymTokenSpace.s5,
                  ),
                  child: Center(widthFactor: 1, child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
