/// Parcours de connexion DYM (bienvenue, email + code, Google, profil),
/// partagé par les apps.
library;

export 'src/auth_flow_view.dart';
export 'src/auth_flow_viewmodel.dart'
    show AuthError, AuthFlowViewModel, AuthStep;
export 'src/auth_service.dart';
export 'src/widgets/step_scaffold.dart' show AuthErrorBanner;
