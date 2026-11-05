import 'package:dym_vendor/ui/views/home/home_view.dart';
import 'package:dym_vendor/ui/views/sign_in/sign_in_view.dart';
import 'package:dym_vendor/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';

/// Routes et injection de l'app (générés : `melos run generate`).
@StackedApp(
  routes: [
    MaterialRoute(page: StartupView, initial: true),
    MaterialRoute(page: SignInView),
    MaterialRoute(page: HomeView),
  ],
  dependencies: [
    LazySingleton<NavigationService>(classType: NavigationService),
  ],
)
class App;
