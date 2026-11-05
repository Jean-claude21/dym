import 'package:dym_admin/ui/views/home/admin_home_view.dart';
import 'package:dym_admin/ui/views/sign_in/admin_sign_in_view.dart';
import 'package:dym_admin/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';

/// Routes et injection de l'app (générés : `melos run generate`).
@StackedApp(
  routes: [
    MaterialRoute(page: StartupView, initial: true),
    MaterialRoute(page: AdminSignInView),
    MaterialRoute(page: AdminHomeView),
  ],
  dependencies: [
    LazySingleton<NavigationService>(classType: NavigationService),
  ],
)
class App;
