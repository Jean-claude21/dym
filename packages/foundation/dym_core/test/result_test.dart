import 'package:dym_core/dym_core.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('Ok expose sa valeur', () {
      const r = Ok(3);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull, 3);
      expect(r.failureOrNull, isNull);
    });

    test('Err expose son échec', () {
      const Result<int> r = Err(NotFoundFailure('absent'));
      expect(r.isOk, isFalse);
      expect(r.valueOrNull, isNull);
      expect(r.failureOrNull, isA<NotFoundFailure>());
    });

    test('map et fold', () {
      expect(const Ok(2).map((v) => v * 2), const Ok(4));
      const Result<int> err = Err(NetworkFailure('hors ligne'));
      expect(err.map((v) => v * 2).failureOrNull, isA<NetworkFailure>());
      expect(err.fold((v) => 'ok', (f) => f.message), 'hors ligne');
    });

    test('then enchaîne seulement sur Ok', () async {
      final ok = await const Ok(1).then((v) async => Ok('$v!'));
      expect(ok, const Ok('1!'));
      const Result<int> err = Err(ConflictFailure('doublon'));
      final chained = await err.then((v) async => Ok('$v'));
      expect(chained.failureOrNull, isA<ConflictFailure>());
    });

    test('échecs transitoires : réseau, 429, serveur', () {
      expect(const NetworkFailure('').isTransient, isTrue);
      expect(const RateLimitedFailure('').isTransient, isTrue);
      expect(const ServerFailure('', statusCode: 503).isTransient, isTrue);
      expect(const ValidationFailure('').isTransient, isFalse);
      expect(const UnauthenticatedFailure('').isTransient, isFalse);
    });
  });
}
