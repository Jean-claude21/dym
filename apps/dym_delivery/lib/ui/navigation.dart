import 'dart:async';

import 'package:dym_delivery/app/app.locator.dart';
import 'package:dym_delivery/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';

/// Navigation de l'app, remplaçable en test.
abstract interface class AppNavigator {
  void toSignIn({bool startWithProfile = false});

  /// Démarrage : session, profil puis profil livreur décident de la suite.
  void toStartup();

  /// Accueil ; [onboarding] : inscription comme livreur d'abord.
  void toHome({bool onboarding = false});
}

class StackedAppNavigator implements AppNavigator {
  new([NavigationService? navigation])
    : _navigation = navigation ?? locator<NavigationService>();

  final NavigationService _navigation;

  @override
  void toSignIn({bool startWithProfile = false}) => unawaited(
    _navigation.clearStackAndShow<void>(
      Routes.signInView,
      arguments: SignInViewArguments(startWithProfile: startWithProfile),
    ),
  );

  @override
  void toStartup() =>
      unawaited(_navigation.clearStackAndShow<void>(Routes.startupView));

  @override
  void toHome({bool onboarding = false}) => unawaited(
    _navigation.clearStackAndShow<void>(
      Routes.homeView,
      arguments: HomeViewArguments(onboarding: onboarding),
    ),
  );
}
