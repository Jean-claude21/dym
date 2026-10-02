import 'package:dym_admin/app/app.locator.dart';
import 'package:dym_admin/ui/navigation.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:stacked/stacked.dart';

/// Connexion de l'équipe : Google Workspace uniquement ; un compte sans rôle
/// admin est refusé (la session est fermée par le service).
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
