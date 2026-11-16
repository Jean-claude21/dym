import 'package:dym_core/src/result/failure.dart';

/// Destination des échecs inattendus (suivi d'erreurs).
typedef FailureSink = void Function(
  Failure failure,
  String where,
  StackTrace stack,
);

/// Échecs inattendus remontés au suivi d'erreurs (constitution IX).
///
/// Les erreurs prévues (réseau absent, saisie refusée, accès refusé…) sont
/// montrées à l'écran et ne sont pas envoyées : seules les erreurs du serveur
/// (5xx), les réponses illisibles et les erreurs inconnues le sont. Le lieu
/// (`where`, par exemple `rpc/place_order`) ne contient aucune donnée
/// personnelle ; le message d'un [Failure] est technique par contrat.
abstract final class FailureReports {
  /// Branchée par l'app au démarrage quand le suivi d'erreurs est actif.
  static FailureSink? sink;

  /// Vrai pour un échec à signaler (bug probable, pas un cas prévu).
  static bool isUnexpected(Failure failure) =>
      failure is ServerFailure || failure is UnknownFailure;

  /// Signale [failure] s'il est inattendu ; ne lève jamais.
  static void report(Failure failure, String where, StackTrace stack) {
    final target = sink;
    if (target == null || !isUnexpected(failure)) return;
    try {
      target(failure, _clean(where), stack);
    } on Object {
      // Le suivi d'erreurs ne doit jamais casser l'app.
    }
  }

  /// Identifiants retirés du lieu : regroupement stable des erreurs.
  static String _clean(String where) => where
      .replaceAll(
        RegExp(
          '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
          caseSensitive: false,
        ),
        ':id',
      )
      .split('?')
      .first;
}
