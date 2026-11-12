import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Variantes de [DymButton].
enum DymButtonVariant {
  /// Vert profond : l'action principale unique de l'écran.
  primary,

  /// Contour fin, texte encre : action secondaire.
  secondary,

  /// Soleil : action sur fond vert (rare).
  plantain,

  /// Contour blanc : action secondaire sur fond vert.
  onBrand,

  /// Blanc avec bordure fine : connexion par un tiers (Google).
  surface,

  /// Rouge piment foncé : action destructrice confirmée (suppression).
  destructive,
}

/// Bouton DYM « Épuré ». Hauteur 52 (48 en compact), coins 12, libellé Inter
/// SemiBold 16. Une seule variante [DymButtonVariant.primary] par écran.
class DymButton extends StatefulWidget {
  /// Crée un bouton. [onPressed] nul : bouton désactivé.
  const new({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = DymButtonVariant.primary,
    this.trailing,
    this.icon,
    this.leading,
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

  /// Élément graphique à gauche du libellé (ex. logo Google) ; prime sur
  /// [icon].
  final Widget? leading;

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
    final (bg0, fg0, border0) = switch (widget.variant) {
      DymButtonVariant.primary => (c.brand, c.onBrand, null),
      DymButtonVariant.secondary => (c.card, c.textPrimary, c.lineStrong),
      DymButtonVariant.plantain => (c.plantain, c.textPrimary, null),
      DymButtonVariant.onBrand => (Colors.transparent, c.onBrand, c.onBrand),
      DymButtonVariant.surface => (c.card, c.textPrimary, c.lineStrong),
      DymButtonVariant.destructive => (c.pimentStrong, c.onBrand, null),
    };
    // Désactivé : fond discret et texte gris, lisible au soleil (pas de
    // couleur délavée).
    final filled = border0 == null && bg0 != Colors.transparent;
    final disabled = !enabled && !widget.loading;
    final bg = disabled && filled ? c.muted : bg0;
    final fg = disabled ? c.textSecondary : fg0;
    final border = disabled && !filled ? c.hairline : border0;
    final label = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.dym.text.body.copyWith(
        fontSize: widget.compact ? 15 : 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
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
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: DymTokenSpace.s3),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, color: fg, size: 20),
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
      container: true,
      onTap: enabled ? widget.onPressed : null,
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: DymMotion.of(context, DymMotion.fast),
        curve: DymMotion.standard,
        child: AnimatedOpacity(
          opacity: enabled || widget.loading || filled ? 1 : 0.7,
          duration: DymMotion.of(context, DymMotion.fast),
          child: Material(
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DymTokenRadius.button),
              side: border == null
                  ? BorderSide.none
                  : BorderSide(color: border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? widget.onPressed : null,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: widget.compact
                      ? DymTokenSize.touchMin
                      : DymTokenSize.buttonHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact
                        ? DymTokenSpace.s3
                        : DymTokenSpace.s4 + DymTokenSpace.s1,
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
