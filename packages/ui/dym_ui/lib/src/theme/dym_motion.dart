import 'package:flutter/widgets.dart';

/// Durées et courbes d'animation DYM.
///
/// Toute animation passe par [of] : si le téléphone demande de réduire les
/// animations, la durée devient nulle et l'état final s'affiche directement.
abstract final class DymMotion {
  /// Micro-interaction rapide (état d'un bouton, puce).
  static const fast = Duration(milliseconds: 180);

  /// Transition standard (compteur, mini-panier).
  static const medium = Duration(milliseconds: 300);

  /// Plus longue micro-interaction autorisée (spec FR-010).
  static const slow = Duration(milliseconds: 450);

  /// Courbe standard : décélération douce.
  static const Curve standard = Curves.easeOutCubic;

  /// Courbe d'emphase : léger dépassement (rebond).
  static const Curve emphasized = Curves.easeOutBack;

  /// Vrai si les animations sont autorisées dans ce contexte.
  static bool enabled(BuildContext context) =>
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  /// [duration], ou zéro si les animations sont réduites.
  static Duration of(BuildContext context, Duration duration) =>
      enabled(context) ? duration : Duration.zero;
}
