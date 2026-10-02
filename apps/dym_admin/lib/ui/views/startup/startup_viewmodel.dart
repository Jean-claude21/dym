import 'package:dym_admin/app/app.locator.dart';
import 'package:dym_admin/ui/navigation.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:stacked/stacked.dart';

/// Démarrage de l'admin : session admin valide → tableau de bord ; sinon
/// connexion (avec « accès réservé » si le compte n'est pas admin).
class StartupViewModel extends BaseViewModel {
  new({
    AuthService? auth,
    DymEnvironment? environment,
    AdminNavigator? navigator,
  }) : _auth = auth ?? locator<AuthService>(),
       _environment = environment ?? locator<DymEnvironment>(),
       _navigator = navigator ?? StackedAdminNavigator();

  final AuthService _auth;
  final DymEnvironment _environment;
  final AdminNavigator _navigator;

  String? get environmentName =>
      _environment.isProduction ? null : _environment.name.name;

  Future<void> runStartupLogic() async {
    final result = await runBusyFuture(_auth.bootstrap());
    switch (result) {
      case Ok(value: AuthState(status: AuthStatus.ready)):
        _navigator.toHome();
      case Ok():
        _navigator.toSignIn();
      case Err(failure: ForbiddenFailure()):
        _navigator.toSignIn(notice: AdminNotice.accessDenied);
      case Err(failure: NetworkFailure()):
        _navigator.toSignIn(notice: AdminNotice.offline);
      case Err():
        _navigator.toSignIn();
    }
  }
}
