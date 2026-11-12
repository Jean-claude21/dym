import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Pastille de localisation blanche (« Bè, Lomé »).
class LocationPill extends StatelessWidget {
  const new({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
        boxShadow: const [DymTokenShadows.card],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, color: c.brand, size: 20),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.dym.text.label.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: c.textPrimary),
        ],
      ),
    );
  }
}

/// Bouton rond blanc posé sur une photo (retour, partager, favori).
class RoundIconButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    super.key,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        shape: BoxShape.circle,
        boxShadow: const [DymTokenShadows.card],
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed ?? () {},
        icon: Icon(icon, color: c.textPrimary),
      ),
    );
  }
}

/// En-tête d'écran : retour, titre centré, action optionnelle.
class ScreenHeader extends StatelessWidget {
  const new({required this.title, super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour',
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  style: context.dym.text.display.copyWith(fontSize: 24),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: context.dym.text.label.copyWith(
                      color: c.textSecondary,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 48, child: trailing),
        ],
      ),
    );
  }
}

/// Carte blanche arrondie standard.
class WhiteCard extends StatelessWidget {
  const new({required this.child, super.key, this.padding, this.color});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: color ?? context.dym.colors.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: child,
    );
  }
}

/// Avatar de l'utilisatrice connectée (démonstration).
class MeAvatar extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) =>
      DymAvatar(image: DemoImages.person('awa'), size: 48);
}

/// Applique une animation d'entrée seulement si les animations sont permises.
extension MaybeAnimate on Widget {
  Widget enter(
    BuildContext context, {
    Duration delay = Duration.zero,
    Offset slide = const Offset(0, 0.08),
  }) {
    if (!DymMotion.enabled(context)) return this;
    return animate(delay: delay)
        .fadeIn(duration: DymMotion.slow, curve: DymMotion.standard)
        .slide(
          begin: slide,
          duration: DymMotion.slow,
          curve: DymMotion.standard,
        );
  }
}

/// Liste défilante dont le contenu est borné à [maxWidth] et centré, la zone
/// de défilement gardant toute la largeur (spec 002).
///
/// Sur téléphone, les marges latérales de [padding] s'appliquent telles
/// quelles (rendu validé) ; au-delà, la marge de la classe de fenêtre.
class BoundedListView extends StatelessWidget {
  const new({
    required this.padding,
    required this.children,
    super.key,
    this.maxWidth = DymTokenLayout.formMax,
  });

  final EdgeInsets padding;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final compact = DymWindowClass.of(context) == DymWindowClass.compact;
    return LayoutBuilder(
      builder: (context, box) {
        final inset = DymLayout.sideInset(
          box.maxWidth,
          gutter: compact ? padding.left : DymLayout.gutter(context),
          maxWidth: maxWidth,
        );
        return ListView(
          padding: padding.copyWith(left: inset, right: inset),
          children: children,
        );
      },
    );
  }
}
