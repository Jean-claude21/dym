import 'dart:async';

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
    this._introDelay = defaultIntro,
  }) : _auth = auth ?? locator<AuthService>(),
       _environment = environment ?? locator<DymEnvironment>(),
       _navigator = navigator ?? StackedAdminNavigator();

  /// Attente maximale de l'entrée animée du splash au premier lancement :
  /// l'écran change quand elle est jouée ([introFinished]), au plus tard
  /// après ce délai (téléphone lent, animation illisible).
  static const defaultIntro = Duration(seconds: 7);

  Duration _introDelay;
  final _intro = Completer<void>();

  /// Entrée du splash jouée (appelé par la vue).
  void introFinished() {
    if (!_intro.isCompleted) _intro.complete();
  }

  final AuthService _auth;
  final DymEnvironment _environment;
  final AdminNavigator _navigator;

  String? get environmentName =>
      _environment.isProduction ? null : _environment.name.name;

  Future<void> runStartupLogic() async {
    final intro = _introDelay == Duration.zero
        ? null
        : Future.any([_intro.future, Future<void>.delayed(_introDelay)]);
    _introDelay = Duration.zero;
    final result = await runBusyFuture(_auth.bootstrap());
    await intro;
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
