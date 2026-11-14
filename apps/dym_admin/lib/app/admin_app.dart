import 'package:dym_admin/app/app.router.dart';
import 'package:dym_admin/ui/admin_theme.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';

/// Racine de l'app : thème DYM, textes localisés, routes Stacked.
class AdminApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => DymLocalizations.of(context).appNameAdmin,
    theme: adminTheme(),
    debugShowCheckedModeBanner: false,
    localizationsDelegates: DymLocalizations.localizationsDelegates,
    supportedLocales: DymLocalizations.supportedLocales,
    navigatorKey: StackedService.navigatorKey,
    navigatorObservers: [StackedService.routeObserver],
    onGenerateRoute: StackedRouter().onGenerateRoute,
    initialRoute: Routes.startupView,
  );
}
