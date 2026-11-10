import 'package:dym_client/features/spaces/spaces_viewmodels.dart';
import 'package:dym_client/features/spaces/spaces_views.dart';
import 'package:dym_client/features/spaces/testing.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

void main() {
  Space space({int pocket = 0, int quantity = 4}) => Space(
    id: 'sp1',
    name: 'Maison',
    joinCode: 'ABCD2345',
    myRole: SpaceRole.payer,
    isOwner: true,
    currencyCode: 'XOF',
    totalMinor: 500 * quantity,
    pocketBalanceMinor: pocket,
    members: const [
      SpaceMember(
        userId: 'u1',
        firstName: 'Awa',
        role: SpaceRole.payer,
        isOwner: true,
        isMe: true,
        contributedMonthMinor: 1500,
      ),
    ],
    items: [
      SpaceItem(
        variantId: 'v1',
        productId: 'p1',
        name: 'Tomates',
        quantity: quantity,
        unitPriceMinor: 500,
        available: true,
      ),
    ],
  );

  group('argent des espaces (spec 032)', () {
    test('versement : montant lu, wallet insuffisant refusé', () async {
      final service = MemorySpacesService(
        discovery: memoryDiscovery(),
        spaces: [space()],
      )..walletMinor = 3000;
      final vm = SpaceViewModel(service: service, spaceId: 'sp1');
      await vm.load();
      expect(await vm.contribute('abc'), isFalse);
      expect(vm.problem, SpaceError.amount);
      expect(await vm.contribute('2 000'), isTrue);
      expect(vm.space!.pocketBalanceMinor, 2000);
      expect(await vm.contribute('5000'), isFalse);
      expect(vm.problem, SpaceError.walletInsufficient);
    });

    test('validation financée : poche suffisante, sinon refus', () async {
      final service = MemorySpacesService(
        discovery: memoryDiscovery(),
        spaces: [space(pocket: 1000)],
      );
      final vm = SpaceViewModel(service: service, spaceId: 'sp1');
      await vm.load();
      vm.setUsePocket(value: true);
      expect(await vm.validate(), isFalse);
      expect(vm.problem, SpaceError.pocketInsufficient);

      await service.setItem('sp1', 'v1', 2);
      await vm.load();
      expect(await vm.validate(), isTrue);
      expect(vm.fundedMinor, 1000);
      expect(service.funded, ['sp1']);
      expect(vm.space!.pocketBalanceMinor, 0);
    });

    test('mouvements du wallet reconnus', () {
      expect(
        WalletMovementKind.parse('space_contribution'),
        WalletMovementKind.spaceContribution,
      );
      expect(
        WalletMovementKind.parse('space_payout'),
        WalletMovementKind.spacePayout,
      );
      expect(
        spaceErrorOf(const ValidationFailure('space_balance')),
        SpaceError.spaceBalance,
      );
    });

    testWidgets('écran : poche, part de chacun, interrupteur', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: SpaceView(
            service: MemorySpacesService(
              discovery: memoryDiscovery(),
              spaces: [space(pocket: 2500)],
            ),
            spaceId: 'sp1',
            onBack: () {},
            onValidated: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Poche commune'), findsOneWidget);
      expect(find.text('Verser'), findsOneWidget);
      expect(find.textContaining('a versé'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Payer avec la poche commune'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Payer avec la poche commune'), findsOneWidget);
    });
  });
}
