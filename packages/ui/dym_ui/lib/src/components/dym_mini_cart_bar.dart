import 'package:dym_core/dym_core.dart';
import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Mini-panier flottant vert profond, borné à `layout.floating-max`.
///
/// Caché à 0 article (glisse vers le bas), visible sinon (glisse vers le
/// haut). Le compteur rebondit à chaque changement du nombre d'articles.
class DymMiniCartBar extends StatefulWidget {
  /// Crée le mini-panier. [summary] est construit par l'appelant
  /// (ex. « 3 articles · 2 boutiques · 1 800 F CFA »).
  const new({
    required this.itemCount,
    required this.total,
    required this.summary,
    required this.actionLabel,
    required this.onTap,
    super.key,
    this.thumbnail,
  });

  /// Nombre d'articles (0 : caché).
  final int itemCount;

  /// Total affiché.
  final Money total;

  /// Résumé affiché.
  final String summary;

  /// Libellé de l'action (« Voir le panier »).
  final String actionLabel;

  /// Ouvre le panier.
  final VoidCallback onTap;

  /// Vignette (panier tressé).
  final ImageProvider? thumbnail;

  @override
  State<DymMiniCartBar> createState() => _DymMiniCartBarState();
}

class _DymMiniCartBarState extends State<DymMiniCartBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: DymMotion.medium,
  );

  @override
  void didUpdateWidget(DymMiniCartBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount &&
        widget.itemCount > 0 &&
        DymMotion.enabled(context)) {
      _bump.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.itemCount > 0;
    final duration = DymMotion.of(context, DymMotion.medium);
    // Ne s'étire pas sur grand écran : borné et centré (spec 002, FR-006).
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DymTokenLayout.floatingMax),
        child: _bar(context, visible, duration),
      ),
    );
  }

  Widget _bar(BuildContext context, bool visible, Duration duration) {
    final c = context.dym.colors;
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1.4),
      duration: duration,
      curve: visible ? DymMotion.emphasized : DymMotion.standard,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        child: IgnorePointer(
          ignoring: !visible,
          child: Semantics(
            button: true,
            label: '${widget.summary}. ${widget.actionLabel}',
            excludeSemantics: true,
            child: Material(
              color: c.brand,
              borderRadius: BorderRadius.circular(DymTokenRadius.tile),
              elevation: 2,
              shadowColor: c.textPrimary.withValues(alpha: 0.3),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                  child: Row(
                    children: [
                      _Thumb(
                        animation: _bump,
                        count: widget.itemCount,
                        image: widget.thumbnail,
                      ),
                      const SizedBox(width: DymTokenSpace.s3),
                      Expanded(
                        child: Text(
                          widget.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.dym.text.label.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: c.onBrand,
                          ),
                        ),
                      ),
                      const SizedBox(width: DymTokenSpace.s2),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.only(left: 12, right: 6),
                        decoration: BoxDecoration(
                          color: c.plantain,
                          borderRadius: BorderRadius.circular(
                            DymTokenRadius.chip,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.actionLabel,
                              style: context.dym.text.title.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: c.textPrimary,
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
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const new({required this.animation, required this.count, this.image});

  final Animation<double> animation;
  final int count;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Rebond : 1 → 1,25 → 1.
        final t = animation.value;
        final scale = 1 + 0.25 * (t < 0.5 ? t * 2 : (1 - t) * 2);
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        width: 46,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (image != null)
              Positioned.fill(
                child: Image(image: image!, fit: BoxFit.contain),
              )
            else
              Icon(Icons.shopping_basket_rounded, color: c.onBrand, size: 40),
            Positioned(
              right: -2,
              top: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 22),
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.pimentStrong,
                  borderRadius: BorderRadius.circular(DymTokenRadius.chip),
                  border: Border.all(color: c.onBrand, width: 1.5),
                ),
                child: Text(
                  '$count',
                  style: context.dym.text.label.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.onBrand,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
