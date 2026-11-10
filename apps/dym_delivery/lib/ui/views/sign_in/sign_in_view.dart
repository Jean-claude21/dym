import 'package:dym_auth/dym_auth.dart';
import 'package:dym_delivery/app/app.locator.dart';
import 'package:dym_delivery/ui/navigation.dart';
import 'package:flutter/widgets.dart';

/// Connexion (parcours partagé `dym_auth`), puis démarrage.
class SignInView extends StatelessWidget {
  const new({super.key, this.startWithProfile = false});

  /// Session déjà ouverte, profil à compléter.
  final bool startWithProfile;

  @override
  Widget build(BuildContext context) => AuthFlowView(
    service: locator<AuthService>(),
    variant: AuthVariant.delivery,
    startWithProfile: startWithProfile,
    onReady: (_) => StackedAppNavigator().toStartup(),
  );
}
