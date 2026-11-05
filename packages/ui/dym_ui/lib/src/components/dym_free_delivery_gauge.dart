import 'package:dym_ui/src/theme/dym_motion.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Jauge « Plus que X pour la livraison offerte ».
class DymFreeDeliveryGauge extends StatelessWidget {
  /// Crée la jauge. [lead] et [trail] encadrent [amount] mis en valeur
  /// (ex. « Plus que » · « 600 F CFA » · « pour la livraison offerte »).
  const new({
    required this.lead,
    required this.amount,
    required this.trail,
    required this.progress,
    super.key,
  });

  /// Texte avant le montant.
  final String lead;

  /// Montant restant, formaté.
  final String amount;

  /// Texte après le montant.
  final String trail;

  /// Progression de 0 à 1.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Container(
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.tintVertTendre,
              borderRadius: BorderRadius.circular(DymTokenSpace.s3),
            ),
            child: Icon(Icons.redeem_rounded, color: c.brand),
          ),
          const SizedBox(width: DymTokenSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: t.label.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(text: '$lead '),
                      TextSpan(
                        text: amount,
                        style: TextStyle(color: c.brandDeep),
                      ),
                      TextSpan(text: ' $trail'),
                    ],
                  ),
                ),
                const SizedBox(height: DymTokenSpace.s2),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: progress.clamp(0, 1)),
                  duration: DymMotion.of(context, DymMotion.slow),
                  curve: DymMotion.standard,
                  builder: (context, value, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(DymTokenRadius.chip),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      color: c.plantain,
                      backgroundColor: c.textSecondary.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
