import 'package:dym_core/dym_core.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => FailureReports.sink = null);

  test('seuls les échecs inattendus sont signalés, lieu sans identifiant', () {
    final seen = <String>[];
    FailureReports.sink = (failure, where, _) =>
        seen.add('${failure.runtimeType} $where');
    const id = '2f1c3a4b-5d6e-4f70-8a9b-0c1d2e3f4a5b';
    FailureReports.report(
      const ServerFailure('boom', statusCode: 500),
      'functions:POST /v1/orders/$id/pay?x=1',
      StackTrace.current,
    );
    FailureReports.report(
      const UnknownFailure('_TypeError'),
      'rpc/f',
      StackTrace.current,
    );
    for (final expected in const <Failure>[
      NetworkFailure('hors ligne'),
      ValidationFailure('saisie'),
      ForbiddenFailure('accès'),
      NotFoundFailure('absent'),
    ]) {
      FailureReports.report(expected, 'rpc/f', StackTrace.current);
    }
    expect(seen, [
      'ServerFailure functions:POST /v1/orders/:id/pay',
      'UnknownFailure rpc/f',
    ]);
  });

  test('sans destination ou si elle échoue : rien ne casse', () {
    FailureReports.report(
      const UnknownFailure('x'),
      'rpc/f',
      StackTrace.current,
    );
    FailureReports.sink = (_, _, _) => throw StateError('suivi en panne');
    expect(
      () => FailureReports.report(
        const UnknownFailure('x'),
        'rpc/f',
        StackTrace.current,
      ),
      returnsNormally,
    );
  });
}
