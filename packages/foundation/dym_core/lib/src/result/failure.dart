import 'package:meta/meta.dart';

/// Échec typé d'une opération. Le [message] est technique (journaux) ; le
/// texte montré à l'utilisateur est choisi par l'app selon la catégorie.
@immutable
sealed class Failure {
  const new(this.message);

  /// Description technique, sans donnée personnelle ni jeton.
  final String message;

  /// Vrai si une nouvelle tentative a du sens (réseau, débit, serveur).
  bool get isTransient => false;

  @override
  String toString() => 'Failure($message)';
}

/// Pas de réseau, délai dépassé, connexion interrompue.
final class NetworkFailure extends Failure {
  const new(super.message);

  @override
  bool get isTransient => true;
}

/// Session absente, expirée ou révoquée (401).
final class UnauthenticatedFailure extends Failure {
  const new(super.message);
}

/// Action refusée par les règles d'accès (403, RLS).
final class ForbiddenFailure extends Failure {
  const new(super.message);
}

/// Ressource introuvable (404).
final class NotFoundFailure extends Failure {
  const new(super.message);
}

/// Conflit avec l'état courant : doublon, version périmée (409).
final class ConflictFailure extends Failure {
  const new(super.message);
}

/// Entrée refusée (400, 422), avec les champs en cause.
final class ValidationFailure extends Failure {
  const new(super.message, {this.fields = const {}});

  /// Champ → raison.
  final Map<String, String> fields;
}

/// Trop de requêtes (429).
final class RateLimitedFailure extends Failure {
  const new(super.message);

  @override
  bool get isTransient => true;
}

/// Erreur du serveur (5xx) ou réponse illisible.
final class ServerFailure extends Failure {
  const new(super.message, {this.statusCode});

  /// Code HTTP, s'il existe.
  final int? statusCode;

  @override
  bool get isTransient => true;
}

/// Toute autre erreur inattendue.
final class UnknownFailure extends Failure {
  const new(super.message);
}
