import 'package:dym_admin/app/app.locator.dart';
import 'package:dym_core/dym_core.dart';
import 'package:neon_kit/neon_kit.dart';
import 'package:stacked/stacked.dart';

/// Démarrage : restaure la session enregistrée. La suite du parcours
/// (connexion, accueil) arrive avec la spec `auth`.
class StartupViewModel extends BaseViewModel {
  new({NeonClient? neon, DymEnvironment? environment})
    : _neon = neon ?? locator<NeonClient>(),
      _environment = environment ?? locator<DymEnvironment>();

  final NeonClient _neon;
  final DymEnvironment _environment;

  /// Nom de l'environnement, affiché hors production seulement.
  String? get environmentName =>
      _environment.isProduction ? null : _environment.name.name;

  /// Vrai si une session a été restaurée.
  bool get hasSession => _neon.auth.currentSession != null;

  Future<void> runStartupLogic() => runBusyFuture(_neon.auth.restore());
}
