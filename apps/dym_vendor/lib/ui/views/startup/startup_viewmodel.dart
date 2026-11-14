import 'dart:async';

import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/app/app.locator.dart';
import 'package:dym_vendor/features/store/store_service.dart';
import 'package:dym_vendor/ui/navigation.dart';
import 'package:stacked/stacked.dart';

/// Démarrage : restaure la session puis oriente vers la connexion, le profil
/// à compléter, l'onboarding de la boutique (absente ou en brouillon) ou
/// « Ma boutique ». Hors ligne : écran de reprise.
class StartupViewModel extends BaseViewModel {
  new({
    AuthService? auth,
    StoreService? stores,
    DymEnvironment? environment,
    AppNavigator? navigator,
    this._introDelay = defaultIntro,
  }) : _auth = auth ?? locator<AuthService>(),
       _stores = stores ?? locator<StoreService>(),
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
  final StoreService _stores;
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
        await _routeByStore();
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

  Future<void> _routeByStore() async {
    // Invitations du personnel acceptées avant de lire la boutique (spec 087).
    await _stores.myStores();
    final result = await runBusyFuture(_stores.myStore());
    switch (result) {
      case Ok(
        value: MyStore(status: StoreStatus.active || StoreStatus.suspended),
      ):
        _navigator.toHome();
      case Ok():
        _navigator.toStoreOnboarding();
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
