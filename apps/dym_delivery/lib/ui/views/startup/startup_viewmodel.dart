import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_delivery/app/app.locator.dart';
import 'package:dym_delivery/features/missions/missions_service.dart';
import 'package:dym_delivery/ui/navigation.dart';
import 'package:stacked/stacked.dart';

/// Démarrage : restaure la session puis oriente vers la connexion, le profil
/// à compléter, l'inscription comme livreur ou les missions.
class StartupViewModel extends BaseViewModel {
  new({
    AuthService? auth,
    MissionsService? missions,
    DymEnvironment? environment,
    AppNavigator? navigator,
  }) : _auth = auth ?? locator<AuthService>(),
       _missions = missions ?? locator<MissionsService>(),
       _environment = environment ?? locator<DymEnvironment>(),
       _navigator = navigator ?? StackedAppNavigator();

  final AuthService _auth;
  final MissionsService _missions;
  final DymEnvironment _environment;
  final AppNavigator _navigator;
  Failure? _failure;

  String? get environmentName =>
      _environment.isProduction ? null : _environment.name.name;

  bool get offline => _failure is NetworkFailure;
  bool get failed => _failure != null;

  Future<void> runStartupLogic() async {
    _failure = null;
    final result = await runBusyFuture(_auth.bootstrap());
    switch (result) {
      case Ok(value: AuthState(status: AuthStatus.ready)):
        await _routeByCourier();
      case Ok(value: AuthState(status: AuthStatus.needsProfile)):
        _navigator.toSignIn(startWithProfile: true);
      case Ok():
        _navigator.toSignIn();
      case Err(:final failure):
        if (failure is UnauthenticatedFailure || failure is ForbiddenFailure) {
          _navigator.toSignIn();
        } else {
          _fail(failure);
        }
    }
  }

  Future<void> _routeByCourier() async {
    switch (await runBusyFuture(_missions.profile())) {
      case Ok(:final value):
        _navigator.toHome(onboarding: value == null);
      case Err(:final failure) when failure is UnauthenticatedFailure:
        _navigator.toSignIn();
      case Err(:final failure):
        _fail(failure);
    }
  }

  void _fail(Failure failure) {
    _failure = failure;
    notifyListeners();
  }
}
