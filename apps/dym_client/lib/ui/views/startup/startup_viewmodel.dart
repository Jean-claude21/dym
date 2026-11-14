import 'dart:async';

import 'package:dym_auth/dym_auth.dart';
import 'package:dym_client/app/app.locator.dart';
import 'package:dym_client/ui/navigation.dart';
import 'package:dym_core/dym_core.dart';
import 'package:stacked/stacked.dart';

/// Démarrage : restaure la session puis oriente vers la connexion, le profil
/// à compléter ou l'accueil. Hors ligne sans profil connu : écran de reprise.
class StartupViewModel extends BaseViewModel {
  new({
    AuthService? auth,
    DymEnvironment? environment,
    AppNavigator? navigator,
    this._introDelay = defaultIntro,
  }) : _auth = auth ?? locator<AuthService>(),
       _environment = environment ?? locator<DymEnvironment>(),
       _navigator = navigator ?? StackedAppNavigator();

  /// Attente maximale de l'entrée animée du splash au premier lancement :
  /// l'écran change quand elle est jouée ([introFinished]), au plus tard
  /// après ce délai (téléphone lent, animation illisible).
  static const defaultIntro = Duration(seconds: 7);

  Duration _introDelay;

  /// Splash joué une seule fois, au lancement : le retour au démarrage après
  /// la connexion passe directement à la page suivante.
  static bool _launched = false;

  /// Splash affiché (premier démarrage de l'app seulement).
  final bool showSplash = !_launched;
  final _intro = Completer<void>();

  /// Entrée du splash jouée (appelé par la vue).
  void introFinished() {
    if (!_intro.isCompleted) _intro.complete();
  }

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
    _launched = true;
    final intro = _introDelay == Duration.zero || !showSplash
        ? null
        : Future.any([_intro.future, Future<void>.delayed(_introDelay)]);
    _introDelay = Duration.zero;
    final result = await runBusyFuture(_auth.bootstrap());
    await intro;
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
