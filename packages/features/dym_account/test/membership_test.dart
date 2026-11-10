import 'package:dym_account/dym_account.dart';
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

MembershipPlan _plan({DateTime? until}) => MembershipPlan(
  id: 'p1',
  code: 'dym_plus',
  name: LocalizedText.fromJson(const {'fr': 'DYM+', 'en': 'DYM+'}),
  priceMinor: 1500,
  periodDays: 30,
  benefits: const {'delivery_refund': true, 'cashback_bonus_bps': 200},
  activeUntil: until,
);

class _Membership implements MembershipService {
  new({this.balance = 5000});

  int balance;
  final keys = <String>[];
  DateTime? until;

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(_togo());

  @override
  Future<Result<MembershipOffer>> offer() async => Ok(
    MembershipOffer(
      plans: [_plan(until: until)],
      walletBalanceMinor: balance,
    ),
  );

  @override
  Future<Result<MembershipOffer>> subscribe(
    MembershipPlan plan,
    String key,
  ) async {
    keys.add(key);
    if (balance < plan.priceMinor) {
      return const Err(ValidationFailure('wallet_insufficient'));
    }
    balance -= plan.priceMinor;
    until = DateTime(2026, 12, 10);
    return await offer();
  }
}

void main() {
  group('formules (spec 052)', () {
    test(
      'wallet insuffisant puis abonnement ; nouvelle clé à chaque achat',
      () async {
        final service = _Membership(balance: 1000);
        final vm = MembershipViewModel(service: service);
        await vm.load();
        expect(await vm.subscribe(vm.offer!.plans.single), isFalse);
        expect(vm.problem, 'wallet_insufficient');
        service.balance = 5000;
        expect(await vm.subscribe(vm.offer!.plans.single), isTrue);
        expect(vm.offer!.plans.single.active, isTrue);
        expect(vm.offer!.walletBalanceMinor, 3500);
        expect(service.keys.toSet(), hasLength(2));
      },
    );

    testWidgets('écran : avantages, prix, prise de la formule', (tester) async {
      final service = _Membership();
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: MembershipView(service: service, title: 'DYM+', onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('remboursés'), findsOneWidget);
      expect(find.textContaining('cashback'), findsOneWidget);
      await tester.tap(find.text('Prendre la formule'));
      await tester.pumpAndSettle();
      expect(find.text('Prolonger'), findsOneWidget);
      expect(find.textContaining('Active jusqu'), findsOneWidget);
    });
  });
}
