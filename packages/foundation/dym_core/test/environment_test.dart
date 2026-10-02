import 'package:dym_core/dym_core.dart';
import 'package:test/test.dart';

void main() {
  group('DymEnvironment', () {
    test('dev : valeurs locales par défaut', () {
      final env = DymEnvironment.resolve(env: 'dev');
      expect(env.name, DymEnvironmentName.dev);
      expect(env.dataApiUrl.host, 'localhost');
      expect(env.isProduction, isFalse);
    });

    test('production sans URL : refus de démarrer', () {
      expect(
        () => DymEnvironment.resolve(env: 'production'),
        throwsA(isA<DymEnvironmentError>()),
      );
    });

    test('production en http : refus', () {
      expect(
        () => DymEnvironment.resolve(
          env: 'production',
          authUrl: 'http://a.example.com',
          dataApiUrl: 'https://b.example.com',
          functionsUrl: 'https://c.example.com',
        ),
        throwsA(isA<DymEnvironmentError>()),
      );
    });

    test('production complète', () {
      final env = DymEnvironment.resolve(
        env: 'production',
        authUrl: 'https://a.example.com/neondb/auth',
        dataApiUrl: 'https://b.example.com/rest/v1',
        functionsUrl: 'https://c.example.com',
      );
      expect(env.isProduction, isTrue);
      expect(env.authUrl.path, '/neondb/auth');
    });

    test('environnement inconnu ou URL invalide : refus', () {
      expect(
        () => DymEnvironment.resolve(env: 'prod'),
        throwsA(isA<DymEnvironmentError>()),
      );
      expect(
        () => DymEnvironment.resolve(env: 'staging', authUrl: 'pas une url'),
        throwsA(isA<DymEnvironmentError>()),
      );
    });
  });
}
