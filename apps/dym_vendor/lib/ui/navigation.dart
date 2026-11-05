import 'package:dym_vendor/app/app.locator.dart';
import 'package:dym_vendor/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';

/// Navigation de l'app, remplaçable en test.
abstract interface class AppNavigator {
  void toSignIn({bool startWithProfile = false});

  void toHome();
}

/// Navigation Stacked (pile vidée : on ne revient pas en arrière après la
/// connexion ou la déconnexion).
class StackedAppNavigator implements AppNavigator {
  new([NavigationService? navigation])
    : _navigation = navigation ?? locator<NavigationService>();

  final NavigationService _navigation;

  @override
  void toSignIn({bool startWithProfile = false}) =>
      _navigation.clearStackAndShow<void>(
        Routes.signInView,
        arguments: SignInViewArguments(startWithProfile: startWithProfile),
      );

  @override
  void toHome() => _navigation.clearStackAndShow<void>(Routes.homeView);
}
