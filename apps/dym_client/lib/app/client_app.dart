import 'package:dym_auth/dym_auth.dart';
import 'package:dym_client/app/app.locator.dart';
import 'package:dym_client/app/app.router.dart';
import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/ui/navigation.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';

/// Racine de l'app : thème DYM, textes localisés, routes Stacked, panier
/// partagé par les écrans (s'il est enregistré).
class ClientApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale?>(
    // Langue du profil (« Moi ») ; nulle : celle de l'appareil.
    valueListenable: locator.isRegistered<LocalePreference>()
        ? locator<LocalePreference>()
        : _deviceLocale,
    builder: (context, locale, _) => MaterialApp(
      locale: locale,
      onGenerateTitle: (context) => DymLocalizations.of(context).appNameClient,
      theme: DymTheme.light(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: [StackedService.routeObserver],
      onGenerateRoute: StackedRouter().onGenerateRoute,
      initialRoute: Routes.startupView,
      builder: (context, child) => locator.isRegistered<CartService>()
          ? CartScope(
              service: locator<CartService>(),
              onOpenCart: () => StackedAppNavigator().toCart(),
              child: child!,
            )
          : child!,
    ),
  );
}

final _deviceLocale = ValueNotifier<Locale?>(null);
