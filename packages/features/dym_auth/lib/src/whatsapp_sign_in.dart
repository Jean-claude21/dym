import 'package:dym_auth/src/auth_service.dart';
import 'package:dym_core/dym_core.dart';

/// Connexion par WhatsApp (spec 105) : code envoyé au numéro, puis session.
/// Facultative : sans elle, le parcours ne propose que l'email et Google.
abstract interface class WhatsAppSignIn {
  /// Disponible ici ; simulée (le code revient à l'app, affiché « simulé »).
  Future<({bool available, bool simulated})> status();

  /// Envoie le code au numéro international ; mode simulé : le code.
  Future<Result<String?>> send(String phone);

  Future<Result<AuthState>> verify(String phone, String code);
}

/// Implémentation Neon (Functions `/v1/auth/whatsapp`).
class NeonWhatsAppSignIn implements WhatsAppSignIn {
  new(this._auth);

  final NeonAuthService _auth;

  @override
  Future<({bool available, bool simulated})> status() async =>
      (await _auth.whatsAppStatus()).valueOrNull ??
      (available: false, simulated: false);

  @override
  Future<Result<String?>> send(String phone) => _auth.whatsAppStart(phone);

  @override
  Future<Result<AuthState>> verify(String phone, String code) =>
      _auth.signInWithWhatsApp(phone, code);
}
