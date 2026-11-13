import 'package:dym_core/dym_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Fournit un `idToken` Google obtenu sur l'appareil, à échanger contre une
/// session Neon Auth. `Ok(null)` = la personne a annulé.
abstract interface class GoogleIdTokenProvider {
  /// Vrai si la connexion Google est configurée et possible ici.
  bool get isAvailable;

  Future<Result<String?>> obtainIdToken();

  Future<void> signOut();
}

/// Google indisponible (identifiants non configurés pour l'environnement).
class UnavailableGoogleIdTokenProvider implements GoogleIdTokenProvider {
  const new();

  @override
  bool get isAvailable => false;

  @override
  Future<Result<String?>> obtainIdToken() async =>
      const Err(ValidationFailure('connexion Google non configurée'));

  @override
  Future<void> signOut() async {}
}

/// Aucun compte Google sur l'appareil : message dédié côté écran.
const googleNoAccount = 'google_no_account';

/// Implémentation `google_sign_in` 7. Les identifiants OAuth viennent de la
/// compilation (`DYM_GOOGLE_SERVER_CLIENT_ID`, `DYM_GOOGLE_CLIENT_ID`), jamais
/// du dépôt.
class PluginGoogleIdTokenProvider implements GoogleIdTokenProvider {
  new({required this.serverClientId, this.clientId});

  /// Fournisseur configuré selon la compilation, ou indisponible.
  static GoogleIdTokenProvider fromDefines() {
    const server = String.fromEnvironment('DYM_GOOGLE_SERVER_CLIENT_ID');
    const client = String.fromEnvironment('DYM_GOOGLE_CLIENT_ID');
    if (server.isEmpty) return const UnavailableGoogleIdTokenProvider();
    return PluginGoogleIdTokenProvider(
      serverClientId: server,
      clientId: client.isEmpty ? null : client,
    );
  }

  final String serverClientId;
  final String? clientId;
  Future<void>? _initialized;

  Future<void> _init() => _initialized ??= GoogleSignIn.instance.initialize(
    serverClientId: serverClientId,
    clientId: clientId,
  );

  @override
  bool get isAvailable => GoogleSignIn.instance.supportsAuthenticate();

  @override
  Future<Result<String?>> obtainIdToken() async {
    try {
      await _init();
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null) {
        return const Err(ServerFailure('Google : jeton absent'));
      }
      return Ok(token);
    } on GoogleSignInException catch (error) {
      return switch (error.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted => const Ok(null),
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError => const Err(
          ValidationFailure('connexion Google mal configurée'),
        ),
        // Android sans compte Google : le gestionnaire d'identifiants n'a
        // rien à proposer (« No credential available »).
        GoogleSignInExceptionCode.unknownError
            when (error.description ?? '').contains('No credential') =>
          const Err(NotFoundFailure(googleNoAccount)),
        _ => Err(UnknownFailure('Google : ${error.code.name}')),
      };
    } on Object {
      return const Err(NetworkFailure('Google indisponible'));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _init();
      await GoogleSignIn.instance.signOut();
    } on Object {
      // La session DYM est fermée de toute façon.
    }
  }
}
