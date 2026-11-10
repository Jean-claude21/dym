import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/orders/courier_cash_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CountryConfig _togo() => CountryConfig(
  country: Country.fromJson(const {
    'code': 'TG',
    'name': {'fr': 'Togo'},
    'currency_code': 'XOF',
    'dial_code': '+228',
    'default_locale': 'fr',
    'timezone': 'Africa/Lome',
  }),
  currency: Currency.xof,
  cities: const [],
  zones: const [],
  categories: const [],
  storeOrigins: const [],
  units: const [],
  paymentMethods: const [],
  deliveryFees: const [],
  featureFlags: const [],
);

void main() {
  testWidgets(
    'cash des livreurs : reçu, puis plus rien à recevoir (spec 043)',
    (tester) async {
      final service = MemoryCourierCashService(
        config: _togo(),
        lines: [
          const StoreCourierCash(
            courierId: 'c1',
            courierName: 'Kofi',
            amountMinor: 4000,
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: CourierCashView(service: service, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kofi'), findsOneWidget);
      await tester.tap(find.text('Reçu'));
      await tester.pumpAndSettle();
      expect(find.text('Aucun cash à recevoir'), findsOneWidget);
    },
  );
}
