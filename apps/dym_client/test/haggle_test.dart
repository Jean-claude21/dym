import 'package:dym_client/features/haggle/haggle_sheet.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
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

Haggle _haggle(String status, int price) => Haggle(
  id: 'h1',
  productName: 'Igname',
  quantity: 2,
  listPriceMinor: 1000,
  offerMinor: 800,
  priceMinor: price,
  status: status,
  expiresAt: DateTime(2026, 11, 10, 12),
  attemptsLeft: 1,
);

/// Plancher à 900 : au-dessus conclu, en dessous contre-prix au milieu.
class _Haggling implements HaggleService {
  final calls = <String>[];

  @override
  Future<Result<Haggle>> propose(
    String variantId,
    int quantity,
    int offerMinor,
  ) async {
    calls.add('propose:$quantity:$offerMinor');
    if (offerMinor >= 1000) {
      return const Err(ValidationFailure('offer_not_lower'));
    }
    return Ok(
      offerMinor >= 900
          ? _haggle('accepted', offerMinor)
          : _haggle('countered', (offerMinor + 1000) ~/ 2),
    );
  }

  @override
  Future<Result<Haggle>> accept(Haggle haggle) async {
    calls.add('accept:${haggle.id}');
    return Ok(_haggle('accepted', haggle.priceMinor));
  }
}

void main() {
  group('marchandage (spec 050)', () {
    test('offre invalide, refus, contre-prix accepté', () async {
      final service = _Haggling();
      final vm = HaggleViewModel(
        service: service,
        currency: Currency.xof,
        variantId: 'v1',
        quantity: 2,
      );
      await vm.propose('abc');
      expect(vm.problem, 'invalid_amount');
      await vm.propose('1000');
      expect(vm.problem, 'offer_not_lower');
      await vm.propose('800');
      expect(vm.haggle!.countered, isTrue);
      expect(vm.haggle!.priceMinor, 900);
      await vm.acceptCounter();
      expect(vm.done, isTrue);
      expect(service.calls, ['propose:2:1000', 'propose:2:800', 'accept:h1']);
    });

    testWidgets('feuille : proposer, contre-prix, conclu', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: Scaffold(
            body: HaggleSheet(
              service: _Haggling(),
              config: _togo(),
              variantId: 'v1',
              quantity: 2,
              productName: 'Igname',
              priceMinor: 1000,
            ),
          ),
        ),
      );
      expect(find.text('Marchander avec la vendeuse'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '800');
      await tester.tap(find.text('Proposer'));
      await tester.pumpAndSettle();
      expect(find.text('Accepter ce prix'), findsOneWidget);
      await tester.tap(find.text('Accepter ce prix'));
      await tester.pumpAndSettle();
      expect(find.text("C'est bon"), findsOneWidget);
    });
  });
}
