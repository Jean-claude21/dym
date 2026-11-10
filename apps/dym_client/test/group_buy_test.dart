import 'package:dym_client/features/group_buy/group_buy_view.dart';
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

GroupOffer _offer({int committed = 0, int? mine, bool reached = false}) =>
    GroupOffer(
      id: 'g1',
      storeId: 's1',
      storeName: 'Étal de Kodjo',
      productId: 'p1',
      productName: 'Igname',
      variantId: 'v1',
      groupPriceMinor: 800,
      priceMinor: 1000,
      minQuantity: 5,
      closesAt: DateTime(2026, 11, 13),
      status: 'open',
      memberDeliveryFeeMinor: 200,
      committed: committed,
      members: committed == 0 ? 0 : 1,
      myQuantity: mine,
      reached: reached,
    );

class _Groups implements GroupBuyService {
  List<GroupOffer> state = [_offer()];
  final calls = <String>[];

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(_togo());

  @override
  Future<Result<List<GroupOffer>>> near() async => Ok(state);

  @override
  Future<Result<GroupOffer>> join(GroupOffer offer, int quantity) async {
    calls.add('join:$quantity');
    if (offer.reached && quantity < (offer.myQuantity ?? 0)) {
      return const Err(ValidationFailure('group_locked'));
    }
    final o = _offer(
      committed: quantity,
      mine: quantity,
      reached: quantity >= 5,
    );
    state = [o];
    return Ok(o);
  }
}

void main() {
  group('achats groupés (spec 051)', () {
    test('rejoindre, débloquer ; baisse refusée ensuite', () async {
      final service = _Groups();
      final vm = GroupBuysViewModel(service: service);
      await vm.load();
      expect(await vm.join(vm.offers!.single, 'x'), isFalse);
      expect(vm.problem, 'invalid_quantity');
      expect(await vm.join(vm.offers!.single, '5'), isTrue);
      expect(vm.offers!.single.canOrder, isTrue);
      expect(await vm.join(vm.offers!.single, '2'), isFalse);
      expect(vm.problem, 'group_locked');
      expect(service.calls, ['join:5', 'join:2']);
    });

    testWidgets('écran : prix de groupe, livraison partagée, jauge', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: GroupBuysView(service: _Groups(), onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Igname'), findsOneWidget);
      expect(find.textContaining('au lieu de'), findsOneWidget);
      expect(find.textContaining('Livraison partagée'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Rejoindre le groupe'), findsOneWidget);
    });
  });
}
