import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Carte de choix avec photo, titre, description et bouton radio
/// (ex. « Où vends-tu ? »).
class DymSelectableCard extends StatelessWidget {
  /// Crée une carte de choix.
  const new({
    required this.image,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    super.key,
    this.footer,
  });

  /// Photo illustrant le choix.
  final ImageProvider image;

  /// Titre.
  final String title;

  /// Description.
  final String description;

  /// Choix actif.
  final bool selected;

  /// Sélectionne le choix.
  final VoidCallback onTap;

  /// Contenu affiché sous la carte quand elle est sélectionnée.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Semantics(
      container: true,
      onTap: onTap,
      button: true,
      selected: selected,
      label: '$title. $description',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: DymMotion.of(context, DymMotion.fast),
        curve: DymMotion.standard,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(DymTokenRadius.card),
          border: Border.all(
            color: selected ? c.brand : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: const [DymTokenShadows.card],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DymTokenRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(DymTokenSpace.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          DymTokenRadius.button,
                        ),
                        child: Image(
                          image: image,
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: DymTokenSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: t.title.copyWith(fontSize: 19)),
                            const SizedBox(height: DymTokenSpace.s1),
                            Text(
                              description,
                              style: t.body.copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected ? c.brandDeep : c.textSecondary,
                        size: 28,
                      ),
                    ],
                  ),
                  _Reveal(
                    child: selected && footer != null
                        ? Padding(
                            padding: const EdgeInsets.only(
                              top: DymTokenSpace.s3,
                            ),
                            child: footer,
                          )
                        : const SizedBox.shrink(),
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

/// Apparition du pied de carte ; sans animation (réglage d'accessibilité),
/// le contenu change directement (`AnimatedSize` ne supporte pas une durée
/// nulle pendant une mise en page).
class _Reveal extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = DymMotion.of(context, DymMotion.medium);
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: DymMotion.standard,
      child: child,
    );
  }
}
