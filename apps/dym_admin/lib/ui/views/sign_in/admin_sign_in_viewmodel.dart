import 'package:dym_admin/app/app.locator.dart';
import 'package:dym_admin/ui/navigation.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:stacked/stacked.dart';

/// Connexion de l'équipe : code par email (ou Google s'il est configuré) ; un
/// compte sans rôle admin est refusé (la session est fermée par le service).
class AdminSignInViewModel extends BaseViewModel {
  new({this.notice, AuthService? auth, AdminNavigator? navigator})
    : _auth = auth ?? locator<AuthService>(),
      _navigator = navigator ?? StackedAdminNavigator();

  final AuthService _auth;
  final AdminNavigator _navigator;

  /// Message affiché (accès refusé, inactivité, réseau…).
  AdminNotice? notice;

  /// Connexion Google native (mobile) disponible ; sur le web, le bouton est
  /// rendu par le SDK Google.
  bool get nativeGoogleAvailable => _auth.googleAvailable;

  // --- code par email (les admins par défaut et invités reçoivent le rôle
  // à la première connexion, côté base).

  String email = '';
  String code = '';

  /// Code envoyé : l'écran affiche la saisie du code.
  bool codeSent = false;

  bool _verified = false;

  bool get emailValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

  void setEmail(String value) {
    email = value;
    notifyListeners();
  }

  // Le code est lu à la validation : pas de reconstruction à chaque chiffre.
  // ignore: use_setters_to_change_properties
  void setCode(String value) {
    code = value;
  }

  Future<void> sendCode() async {
    notice = null;
    if (!emailValid) {
      notice = AdminNotice.emailInvalid;
      notifyListeners();
      return;
    }
    final result = await runBusyFuture(
      _auth.sendEmailCode(email.trim().toLowerCase()),
    );
    switch (result) {
      case Ok():
        codeSent = true;
        notifyListeners();
      case Err(:final failure):
        _fail(failure);
    }
  }

  Future<void> verifyCode([String? value]) async {
    if (value != null) code = value;
    // Saisie complète puis bouton : une seule vérification.
    if (code.length != 6 || isBusy || _verified) return;
    notice = null;
    final result = await runBusyFuture(
      _auth.verifyEmailCode(email.trim().toLowerCase(), code),
    );
    switch (result) {
      case Ok(:final value):
        _verified = value.status != AuthStatus.signedOut;
        _handle(value);
      case Err(:final failure):
        if (failure is ForbiddenFailure) {
          codeSent = false;
          _fail(failure);
        } else if (failure is NetworkFailure) {
          _fail(failure);
        } else {
          notice = AdminNotice.codeWrong;
          notifyListeners();
        }
    }
  }

  // --- mot de passe (comptes de test)

  bool usePassword = false;
  String password = '';

  void toggleUsePassword() {
    usePassword = !usePassword;
    notice = null;
    notifyListeners();
  }

  // Lu à la validation : pas de reconstruction à chaque caractère.
  // ignore: use_setters_to_change_properties
  void setPassword(String value) {
    password = value;
  }

  Future<void> signInWithPassword() async {
    if (isBusy || _verified) return;
    notice = null;
    if (!emailValid || password.isEmpty) {
      notice = AdminNotice.emailInvalid;
      notifyListeners();
      return;
    }
    final result = await runBusyFuture(
      _auth.signInWithPassword(email.trim().toLowerCase(), password),
    );
    switch (result) {
      case Ok(:final value):
        _verified = value.status != AuthStatus.signedOut;
        _handle(value);
      case Err(:final failure):
        if (failure is ForbiddenFailure || failure is NetworkFailure) {
          _fail(failure);
        } else {
          notice = AdminNotice.passwordWrong;
          notifyListeners();
        }
    }
  }

  void changeEmail() {
    codeSent = false;
    code = '';
    notice = null;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    notice = null;
    final result = await runBusyFuture(_auth.signInWithGoogle());
    switch (result) {
      case Ok(value: null):
        notifyListeners();
      case Ok(:final value?):
        _handle(value);
      case Err(:final failure):
        _fail(failure);
    }
  }

  /// `idToken` reçu du bouton Google du web.
  Future<void> signInWithIdToken(String idToken) async {
    notice = null;
    final result = await runBusyFuture(_auth.signInWithGoogleIdToken(idToken));
    switch (result) {
      case Ok(:final value):
        _handle(value);
      case Err(:final failure):
        _fail(failure);
    }
  }

  void _handle(AuthState state) {
    if (state.status == AuthStatus.signedOut) {
      notifyListeners();
      return;
    }
    _navigator.toHome();
  }

  void _fail(Failure failure) {
    notice = switch (failure) {
      ForbiddenFailure() => AdminNotice.accessDenied,
      NetworkFailure() => AdminNotice.offline,
      _ => AdminNotice.generic,
    };
    notifyListeners();
  }
}
