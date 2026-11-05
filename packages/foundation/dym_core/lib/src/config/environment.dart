import 'package:meta/meta.dart';

/// Nom d'environnement, choisi à la compilation (`--dart-define=DYM_ENV=…`).
enum DymEnvironmentName { dev, staging, production }

/// Configuration d'environnement résolue à la compilation. Aucune URL en dur
/// hors des valeurs locales de développement.
@immutable
class DymEnvironment {
  const new({
    required this.name,
    required this.authUrl,
    required this.dataApiUrl,
    required this.functionsUrl,
    required this.mediaUrl,
  });

  /// Lit `DYM_ENV`, `DYM_AUTH_URL`, `DYM_DATA_API_URL`, `DYM_FUNCTIONS_URL`,
  /// `DYM_MEDIA_URL`.
  ///
  /// En `staging` et `production`, chaque URL est obligatoire : une valeur
  /// manquante lève [DymConfigurationException] (l'app refuse de démarrer).
  /// En `dev`, les valeurs locales par défaut s'appliquent.
  factory fromDefines() => DymEnvironment.resolve(
    env: const String.fromEnvironment('DYM_ENV', defaultValue: 'dev'),
    authUrl: const String.fromEnvironment('DYM_AUTH_URL'),
    dataApiUrl: const String.fromEnvironment('DYM_DATA_API_URL'),
    functionsUrl: const String.fromEnvironment('DYM_FUNCTIONS_URL'),
    mediaUrl: const String.fromEnvironment('DYM_MEDIA_URL'),
  );

  /// Résolution testable de [DymEnvironment.fromDefines].
  factory resolve({
    required String env,
    String? authUrl,
    String? dataApiUrl,
    String? functionsUrl,
    String? mediaUrl,
  }) {
    final name = DymEnvironmentName.values.asNameMap()[env];
    if (name == null) {
      throw DymConfigurationException('DYM_ENV inconnu : « $env »');
    }
    Uri url(String key, String? value, String devDefault) {
      if (value == null || value.isEmpty) {
        if (name != DymEnvironmentName.dev) {
          throw DymConfigurationException('$key manquant pour ${name.name}');
        }
        return Uri.parse(devDefault);
      }
      final uri = Uri.tryParse(value);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        throw DymConfigurationException('$key invalide');
      }
      if (name == DymEnvironmentName.production && uri.scheme != 'https') {
        throw DymConfigurationException(
          '$key doit être en https en production',
        );
      }
      return uri;
    }

    return DymEnvironment(
      name: name,
      authUrl: url('DYM_AUTH_URL', authUrl, 'http://localhost:4000/auth'),
      dataApiUrl: url('DYM_DATA_API_URL', dataApiUrl, 'http://localhost:3000'),
      functionsUrl: url(
        'DYM_FUNCTIONS_URL',
        functionsUrl,
        'http://localhost:8787',
      ),
      mediaUrl: url(
        'DYM_MEDIA_URL',
        mediaUrl,
        'http://localhost:9000/product-photos',
      ),
    );
  }

  /// Nom de l'environnement.
  final DymEnvironmentName name;

  /// URL de base de Neon Auth.
  final Uri authUrl;

  /// URL de la Data API.
  final Uri dataApiUrl;

  /// URL de base des Functions.
  final Uri functionsUrl;

  /// Base publique des photos (bucket `product-photos` en lecture publique).
  final Uri mediaUrl;

  /// URL publique d'un objet du stockage (clé `stores/…`).
  Uri media(String objectKey) => Uri.parse(
    '${mediaUrl.toString().replaceAll(RegExp(r'/+$'), '')}/$objectKey',
  );

  /// Vrai en production.
  bool get isProduction => name == DymEnvironmentName.production;
}

/// Configuration d'environnement invalide : l'app ne doit pas démarrer.
class DymConfigurationException implements Exception {
  /// Crée l'exception.
  new(this.message);

  /// Cause.
  final String message;

  @override
  String toString() => 'DymConfigurationException: $message';
}
