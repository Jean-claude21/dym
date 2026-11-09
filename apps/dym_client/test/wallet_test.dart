import 'package:dym_client/features/wallet/testing.dart';
import 'package:dym_client/features/wallet/wallet_view.dart';
import 'package:dym_client/features/wallet/wallet_viewmodel.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

void main() {
  MemoryWalletService service({int balance = 0, bool simulated = true}) =>
      MemoryWalletService(
        config: togoConfig(),
        balanceMinor: balance,
        simulatedTopup: simulated,
      );

  group('wallet (spec 025)', () {
    test('chargement : solde et poches', () async {
      final vm = WalletViewModel(service: service(balance: 1500));
      await vm.load();
      expect(vm.ready, isTrue);
      expect(vm.wallet!.balanceMinor, 1500);
      expect(vm.money(1500)!.format(), contains('1'));
    });

    test('recharge simulée : montant saisi en unités de la devise', () async {
      final vm = WalletViewModel(service: service());
      await vm.load();
      expect(await vm.topup('5 000'), isTrue);
      expect(vm.wallet!.balanceMinor, 5000);
      expect(vm.wallet!.movements, hasLength(1));
    });

    test('montant invalide refusé sans appel', () async {
      final vm = WalletViewModel(service: service());
      await vm.load();
      expect(await vm.topup('abc'), isFalse);
      expect(vm.walletError, WalletError.amount);
      expect(await vm.topup('-3'), isFalse);
    });

    test('poche avec objectif, puis transfert et solde insuffisant', () async {
      final vm = WalletViewModel(service: service(balance: 3000));
      await vm.load();
      expect(await vm.createPocket(name: 'Tabaski', goalText: '10000'), isTrue);
      final pocket = vm.wallet!.pockets.single;
      expect(pocket.goalMinor, 10000);
      expect(
        await vm.transfer(amountText: '2000', toPocket: pocket.id),
        isTrue,
      );
      expect(vm.wallet!.balanceMinor, 1000);
      expect(vm.wallet!.pockets.single.progress, closeTo(0.2, 0.001));
      expect(
        await vm.transfer(amountText: '5000', toPocket: pocket.id),
        isFalse,
      );
      expect(vm.walletError, WalletError.insufficient);
    });

    test('poche sans nom refusée', () async {
      final vm = WalletViewModel(service: service());
      await vm.load();
      expect(await vm.createPocket(name: '  '), isFalse);
      expect(vm.walletError, WalletError.amount);
    });

    test('refus du serveur traduit', () {
      expect(
        walletErrorOf(const ValidationFailure('feature_disabled')),
        WalletError.topupDisabled,
      );
      expect(
        walletErrorOf(const ValidationFailure('pocket_limit')),
        WalletError.pocketLimit,
      );
      expect(walletErrorOf(const NetworkFailure('x')), WalletError.offline);
    });

    testWidgets('écran : solde, recharge visible en test', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: WalletView(service: service(balance: 2500), onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mon wallet'), findsOneWidget);
      expect(find.text('Recharger'), findsOneWidget);
      expect(find.text('Mes poches'), findsOneWidget);
    });

    testWidgets('écran : recharge masquée hors test', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: WalletView(
            service: service(balance: 2500, simulated: false),
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Recharger'), findsNothing);
    });
  });
}
