import 'package:dym_client/app/app.router.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';

/// Racine de l'app : thème DYM, textes localisés, routes Stacked.
class ClientApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => DymLocalizations.of(context).appNameClient,
    theme: DymTheme.light(),
    debugShowCheckedModeBanner: false,
    localizationsDelegates: DymLocalizations.localizationsDelegates,
    supportedLocales: DymLocalizations.supportedLocales,
    navigatorKey: StackedService.navigatorKey,
    navigatorObservers: [StackedService.routeObserver],
    onGenerateRoute: StackedRouter().onGenerateRoute,
    initialRoute: Routes.startupView,
  );
}
