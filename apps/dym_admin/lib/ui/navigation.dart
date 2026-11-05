import 'package:dym_admin/app/app.locator.dart';
import 'package:dym_admin/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';

/// Message affiché à l'écran de connexion de l'admin.
enum AdminNotice {
  accessDenied,
  inactive,
  offline,
  generic,
  codeWrong,
  emailInvalid,
}

/// Navigation de l'admin, remplaçable en test.
abstract interface class AdminNavigator {
  void toSignIn({AdminNotice? notice});

  void toHome();
}

/// Navigation Stacked (pile vidée).
class StackedAdminNavigator implements AdminNavigator {
  new([NavigationService? navigation])
    : _navigation = navigation ?? locator<NavigationService>();

  final NavigationService _navigation;

  @override
  void toSignIn({AdminNotice? notice}) => _navigation.clearStackAndShow<void>(
    Routes.adminSignInView,
    arguments: AdminSignInViewArguments(notice: notice),
  );

  @override
  void toHome() => _navigation.clearStackAndShow<void>(Routes.adminHomeView);
}
