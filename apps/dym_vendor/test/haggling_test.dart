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

void main() {
  group('marchandage de la vendeuse (spec 050)', () {
    test('limite de la boutique puis d’un produit', () async {
      final service = _Haggling();
      final vm = HagglingViewModel(service: service);
      await vm.load();
      expect(vm.settings!.storePercent, isNull);
      await vm.setStore(10);
      expect(vm.settings!.storePercent, 10);
      await vm.setProduct('p1', 0);
      expect(service.calls, ['store:10', 'p1:0']);
    });

    testWidgets('écran : limite, produits, derniers marchés', (tester) async {
      final service = _Haggling();
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: HagglingView(service: service, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pas de marchandage'), findsOneWidget);
      await tester.tap(find.text('10 %'));
      await tester.pumpAndSettle();
      expect(find.text('Par produit'), findsOneWidget);
      expect(find.text('Comme la boutique'), findsOneWidget);
      expect(find.text('Commandé'), findsOneWidget);
      expect(find.text('1 marché conclu cette semaine'), findsOneWidget);
    });
  });
}
