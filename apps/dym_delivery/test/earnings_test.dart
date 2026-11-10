import 'package:dym_core/dym_core.dart';
import 'package:dym_delivery/features/earnings/earnings_view.dart';
import 'package:dym_delivery/features/missions/missions_service.dart';
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

MemoryMissionsService _service() =>
    MemoryMissionsService(config: _togo())
      ..money = const CourierEarnings(
        todayCount: 3,
        todayFeesMinor: 1500,
        walletMinor: 1000,
        cash: [
          CourierCashLine(
            storeId: 's1',
            storeName: 'Étal de Kodjo',
            amountMinor: 4000,
          ),
        ],
      );

void main() {
  group('gains du livreur (spec 043)', () {
    test('point de recharge : code et montant ; code faux refusé', () async {
      final service = _service();
      final vm = EarningsViewModel(service: service);
      await vm.load();
      expect(await vm.topup('000000', '2000'), isFalse);
      expect(vm.problem, 'invalid_code');
      expect(await vm.topup('482913', '2000'), isTrue);
      expect(vm.earnings!.cashTotalMinor, 6000);
      expect(await vm.topup('482913', 'abc'), isFalse);
      expect(vm.problem, 'wallet_amount_invalid');
    });

    test('retrait : pas plus que le wallet', () async {
      final service = _service();
      final vm = EarningsViewModel(service: service);
      await vm.load();
      expect(await vm.withdraw('5000'), isFalse);
      expect(vm.problem, 'wallet_insufficient');
      expect(await vm.withdraw('600'), isTrue);
      expect(vm.earnings!.walletMinor, 400);
    });

    testWidgets('écran : jour, wallet, cash à remettre', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: Scaffold(body: EarningsView(service: _service())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3 courses aujourd’hui'), findsNothing);
      expect(find.textContaining('courses aujourd'), findsOneWidget);
      expect(find.text('Étal de Kodjo'), findsOneWidget);
      expect(find.text('Point de recharge'), findsOneWidget);
    });
  });
}
