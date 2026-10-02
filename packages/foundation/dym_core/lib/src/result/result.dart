import 'package:dym_core/src/result/failure.dart';
import 'package:meta/meta.dart';

/// Résultat d'une opération : [Ok] avec une valeur ou [Err] avec un [Failure].
///
/// Les repositories et clients retournent toujours un `Result` ; aucune
/// exception ne traverse les couches.
@immutable
sealed class Result<T> {
  const new();

  /// Vrai pour [Ok].
  bool get isOk => this is Ok<T>;

  /// Valeur si [Ok], sinon `null`.
  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// Échec si [Err], sinon `null`.
  Failure? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  /// Transforme la valeur d'un [Ok].
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };

  /// Enchaîne une opération qui retourne elle-même un `Result`.
  Future<Result<R>> then<R>(Future<Result<R>> Function(T value) next) =>
      switch (this) {
        Ok(:final value) => next(value),
        Err(:final failure) => Future.value(Err(failure)),
      };

  /// Réduit les deux cas à une valeur.
  R fold<R>(R Function(T value) ok, R Function(Failure failure) err) =>
      switch (this) {
        Ok(:final value) => ok(value),
        Err(:final failure) => err(failure),
      };
}

/// Succès.
final class Ok<T> extends Result<T> {
  const new(this.value);

  /// Valeur produite.
  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ok($value)';
}

/// Échec.
final class Err<T> extends Result<T> {
  const new(this.failure);

  /// Cause.
  final Failure failure;

  @override
  String toString() => 'Err($failure)';
}
