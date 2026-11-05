import 'package:meta/meta.dart';

/// Chemins des routes Better Auth, relatifs à [NeonConfig.authUrl].
///
/// Valeurs par défaut : API REST standard de Better Auth, gérée par Neon Auth.
/// Configurables pour absorber un écart constaté sur Neon (spec 003, US5).
@immutable
class NeonAuthPaths {
  const new({
    this.sendEmailOtp = '/email-otp/send-verification-otp',
    this.signInEmailOtp = '/sign-in/email-otp',
    this.signInSocial = '/sign-in/social',
    this.session = '/get-session',
    this.token = '/token',
    this.anonymousToken = '/token/anonymous',
    this.signOut = '/sign-out',
  });

  final String sendEmailOtp;
  final String signInEmailOtp;
  final String signInSocial;
  final String session;
  final String token;

  /// JWT anonyme (rôle `anonymous` de la Data API, sans session).
  final String anonymousToken;
  final String signOut;
}

/// Configuration d'un client Neon : URLs de l'environnement et politique
/// réseau.
@immutable
class NeonConfig {
  const new({
    required this.authUrl,
    required this.dataApiUrl,
    required this.functionsUrl,
    this.authPaths = const NeonAuthPaths(),
    this.refreshMargin = const Duration(seconds: 60),
    this.maxRetries = 3,
    this.retryBaseDelay = const Duration(milliseconds: 300),
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
  });

  /// Base de Neon Auth (ex. `https://…/neondb/auth`).
  final Uri authUrl;

  /// Base de la Data API.
  final Uri dataApiUrl;

  /// Base des Functions.
  final Uri functionsUrl;

  /// Routes d'authentification.
  final NeonAuthPaths authPaths;

  /// Renouvellement anticipé du jeton d'accès avant son expiration.
  final Duration refreshMargin;

  /// Nombre maximal de nouvelles tentatives (erreur réseau ou 5xx).
  final int maxRetries;

  /// Délai de base des nouvelles tentatives (doublé à chaque tentative).
  final Duration retryBaseDelay;

  /// Délai de connexion.
  final Duration connectTimeout;

  /// Délai de réception.
  final Duration receiveTimeout;
}
