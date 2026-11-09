import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Squelette de chargement (spec 026) : la forme de l'écran qui arrive, à la
/// place d'un cercle qui tourne. Pulsation douce, coupée si le système
/// désactive les animations.
class DymSkeleton extends StatefulWidget {
  /// Une carte large suivie de [rows] lignes, la forme la plus courante.
  const new({super.key, this.rows = 4, this.label});

  /// Nombre de lignes sous la carte.
  final int rows;

  /// Annonce pour les lecteurs d'écran (« Chargement… »).
  final String? label;

  @override
  State<DymSkeleton> createState() => _DymSkeletonState();
}

class _DymSkeletonState extends State<DymSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    Widget box({required double height, double? width, double radius = 12}) =>
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: c.textSecondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(radius),
          ),
        );
    return Semantics(
      label: widget.label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.55).animate(_pulse),
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(DymTokenSpace.s4),
            children: [
              box(height: 120, radius: DymTokenRadius.tile),
              const SizedBox(height: DymTokenSpace.s5),
              for (var i = 0; i < widget.rows; i++) ...[
                Row(
                  children: [
                    box(width: 56, height: 56),
                    const SizedBox(width: DymTokenSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          box(height: 14),
                          const SizedBox(height: DymTokenSpace.s2),
                          FractionallySizedBox(
                            widthFactor: 0.6,
                            child: box(height: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DymTokenSpace.s4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
