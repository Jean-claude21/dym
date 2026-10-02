import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:meta/meta.dart';
import 'package:neon_kit/neon_kit.dart';

/// Où en est la personne.
enum AuthStatus {
  /// Aucune session : bienvenue et connexion.
  signedOut,

  /// Session ouverte, profil à compléter (prénom, quartier).
  needsProfile,

  /// Prête : profil complet et rôle de l'app.
  ready,
}

/// État d'authentification et utilisateur connecté.
@immutable
class AuthState {
  const new(this.status, [this.me]);

  const new signedOut() : status = AuthStatus.signedOut, me = null;

  final AuthStatus status;
  final Me? me;
}

/// Opérations d'authentification utilisées par les écrans. Interface : les
/// tests de vues et de viewmodels la remplacent par une version simulée.
abstract interface class AuthService {
  /// App qui ouvre la session (rôle donné, trace de connexion).
  AccountApp get app;

  /// Vrai si la connexion Google est disponible ici.
  bool get googleAvailable;

  /// Utilisateur connecté, s'il est connu.
  Me? get me;

  /// Email de la session (affiché à sa propriétaire seulement).
  String? get email;

  /// Au démarrage : session enregistrée → état.
  Future<Result<AuthState>> bootstrap();

  Future<Result<void>> sendEmailCode(String email);

  Future<Result<AuthState>> verifyEmailCode(String email, String code);

  /// `Ok(null)` : la personne a annulé le choix du compte Google.
  Future<Result<AuthState?>> signInWithGoogle();

  /// Connexion avec un `idToken` Google déjà obtenu (bouton Google du web).
  Future<Result<AuthState>> signInWithGoogleIdToken(String idToken);

  Future<Result<List<Country>>> countries();

  Future<Result<CountryConfig>> countryConfig(String countryCode);

  Future<Result<AuthState>> completeProfile({
    required String firstName,
    required String zoneId,
    required String locale,
  });

  Future<Result<void>> signOut();

  Future<Result<void>> deleteAccount();
}

/// Implémentation sur Neon (`neon_kit`) et les dépôts `dym_data`.
class NeonAuthService implements AuthService {
  new({
    required this._neon,
    required this._account,
    required this._reference,
    required this._google,
    required this.app,
  });

  final NeonClient _neon;
  final AccountRepository _account;
  final ReferenceRepository _reference;
  final GoogleIdTokenProvider _google;

  @override
  final AccountApp app;

  @override
  Me? me;

  @override
  bool get googleAvailable => _google.isAvailable;

  @override
  String? get email => _neon.auth.currentSession?.email;

  @override
  Future<Result<AuthState>> bootstrap() async {
    switch (await _neon.auth.restore()) {
      case Ok(value: null):
        return const Ok(AuthState.signedOut());
      case Ok():
        return await _afterSession(recordSignIn: false);
      case Err(:final failure):
        return Err(failure);
    }
  }

  @override
  Future<Result<void>> sendEmailCode(String email) =>
      _neon.auth.sendEmailOtp(email);

  @override
  Future<Result<AuthState>> verifyEmailCode(String email, String code) async {
    final session = await _neon.auth.verifyEmailOtp(email, code);
    if (session case Err(:final failure)) return Err(failure);
    return await _afterSession(recordSignIn: true);
  }

  @override
  Future<Result<AuthState?>> signInWithGoogle() async {
    final token = await _google.obtainIdToken();
    switch (token) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: null):
        return const Ok(null);
      case Ok(:final value?):
        return await signInWithGoogleIdToken(value);
    }
  }

  @override
  Future<Result<AuthState>> signInWithGoogleIdToken(String idToken) async {
    final session = await _neon.auth.signInWithGoogleIdToken(idToken);
    if (session case Err(:final failure)) return Err(failure);
    return await _afterSession(recordSignIn: true);
  }

  @override
  Future<Result<List<Country>>> countries() => _reference.countries();

  @override
  Future<Result<CountryConfig>> countryConfig(String countryCode) =>
      _reference.countryConfig(countryCode);

  @override
  Future<Result<AuthState>> completeProfile({
    required String firstName,
    required String zoneId,
    required String locale,
  }) async {
    final result = await _account.completeProfile(
      firstName: firstName,
      zoneId: zoneId,
      app: app,
      locale: locale,
    );
    return result.map(_stateFor);
  }

  @override
  Future<Result<void>> signOut() async {
    await _google.signOut();
    me = null;
    return await _neon.auth.signOut();
  }

  @override
  Future<Result<void>> deleteAccount() async {
    final deleted = await _account.deleteMyAccount();
    if (deleted case Err(:final failure)) return Err(failure);
    return await signOut();
  }

  /// Après l'ouverture d'une session : trace de connexion (ou simple lecture
  /// au redémarrage), puis état. L'admin sans rôle admin est refusé et
  /// déconnecté ; la vendeuse déjà cliente reçoit le rôle vendeuse.
  Future<Result<AuthState>> _afterSession({required bool recordSignIn}) async {
    final result = recordSignIn
        ? await _account.recordSignIn(app)
        : await _account.me();
    switch (result) {
      case Err(:final failure):
        if (failure is ForbiddenFailure || failure is UnauthenticatedFailure) {
          await signOut();
        }
        return Err(failure);
      case Ok(:final value):
        if (app == AccountApp.admin && !value.hasRole(UserRole.admin)) {
          await signOut();
          return const Err(ForbiddenFailure('rôle admin requis'));
        }
        final profile = value.profile;
        if (app == AccountApp.vendor &&
            profile != null &&
            profile.zoneId != null &&
            !value.hasRole(UserRole.vendor)) {
          final upgraded = await _account.completeProfile(
            firstName: profile.firstName,
            zoneId: profile.zoneId!,
            app: app,
            locale: profile.locale,
          );
          return upgraded.map(_stateFor);
        }
        return Ok(_stateFor(value));
    }
  }

  AuthState _stateFor(Me value) {
    me = value;
    return AuthState(
      value.needsProfile ? AuthStatus.needsProfile : AuthStatus.ready,
      value,
    );
  }
}
