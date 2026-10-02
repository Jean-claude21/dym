import 'package:dym_auth/dym_auth.dart';
import 'package:dym_client/app/app.locator.dart';
import 'package:dym_client/ui/navigation.dart';
import 'package:dym_core/dym_core.dart';
import 'package:stacked/stacked.dart';

/// Démarrage : restaure la session puis oriente vers la connexion, le profil
/// à compléter ou l'accueil. Hors ligne sans profil connu : écran de reprise.
class StartupViewModel extends BaseViewModel {
  new({AuthService? auth, DymEnvironment? environment, AppNavigator? navigator})
    : _auth = auth ?? locator<AuthService>(),
      _environment = environment ?? locator<DymEnvironment>(),
      _navigator = navigator ?? StackedAppNavigator();

  final AuthService _auth;
  final DymEnvironment _environment;
  final AppNavigator _navigator;
  Failure? _failure;

  /// Nom de l'environnement, affiché hors production seulement.
  String? get environmentName =>
      _environment.isProduction ? null : _environment.name.name;

  /// Démarrage impossible (réseau) : la vue propose de réessayer.
  bool get offline => _failure is NetworkFailure;
  bool get failed => _failure != null;

  Future<void> runStartupLogic() async {
    _failure = null;
    final result = await runBusyFuture(_auth.bootstrap());
    switch (result) {
      case Ok(value: AuthState(status: AuthStatus.ready)):
        _navigator.toHome();
      case Ok(value: AuthState(status: AuthStatus.needsProfile)):
        _navigator.toSignIn(startWithProfile: true);
      case Ok():
        _navigator.toSignIn();
      case Err(:final failure):
        if (failure is UnauthenticatedFailure || failure is ForbiddenFailure) {
          _navigator.toSignIn();
        } else {
          _failure = failure;
          notifyListeners();
        }
    }
  }
}
