// Fakes repris des tests d'écran : certaines aides n'y servent pas.
@Tags(['golden'])
library;

import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/haggle/haggling_view.dart';
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

class _Haggling implements HagglingService {
  HagglingSettings state = const HagglingSettings();
  final calls = <String>[];

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(_togo());

  @override
  Future<Result<HagglingSettings>> settings() async => Ok(state);

  @override
  Future<Result<HagglingSettings>> setLimit(
    int? percent, {
    String? productId,
  }) async {
    calls.add('${productId ?? 'store'}:$percent');
    if (productId == null) {
      state = HagglingSettings(
        storePercent: percent,
        products: const [(id: 'p1', name: 'Igname', percent: null)],
        recent: [
          Haggle(
            id: 'h1',
            productName: 'Igname',
            quantity: 2,
            listPriceMinor: 1000,
            offerMinor: 950,
            priceMinor: 950,
            status: 'used',
            expiresAt: DateTime(2026, 11, 10),
          ),
        ],
        concludedWeek: 1,
      );
    }
    return Ok(state);
  }
}

Future<void> _capture(WidgetTester tester, String name, Widget child) async {
  const size = Size(412, 915);
  tester.view
    ..physicalSize = size * 2
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: DymTheme.light(),
      locale: const Locale('fr'),
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: 2,
          disableAnimations: true,
          padding: EdgeInsets.only(top: 24, bottom: 16),
        ),
        child: child,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 600));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  testWidgets('haggling', (tester) async {
    final service = _Haggling();
    await _capture(
      tester,
      'v_haggling',
      HagglingView(service: service, onBack: () {}),
    );
  });
}
