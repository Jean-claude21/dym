import 'package:dym_auth/dym_auth.dart';
import 'package:dym_delivery/app/app.locator.dart';
import 'package:dym_delivery/app/app.router.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';

/// Racine de l'app : thème DYM, textes localisés, routes Stacked.
class DeliveryApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale?>(
    // Langue du profil (« Moi ») ; nulle : celle de l'appareil.
    valueListenable: locator.isRegistered<LocalePreference>()
        ? locator<LocalePreference>()
        : _deviceLocale,
    builder: (context, locale, _) => MaterialApp(
      locale: locale,
      onGenerateTitle: (context) =>
          DymLocalizations.of(context).appNameDelivery,
      theme: DymTheme.light(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: [StackedService.routeObserver],
      onGenerateRoute: StackedRouter().onGenerateRoute,
      initialRoute: Routes.startupView,
    ),
  );
}

final _deviceLocale = ValueNotifier<Locale?>(null);
