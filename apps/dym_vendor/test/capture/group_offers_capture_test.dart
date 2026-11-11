// Fakes repris des tests d'écran : certaines aides n'y servent pas.
@Tags(['golden'])
library;

import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/group_buy/group_offers_view.dart';
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

class _Offers implements GroupOffersService {
  List<GroupOffer> state = [];
  final calls = <String>[];

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(_togo());

  @override
  Future<Result<List<GroupOffer>>> mine() async => Ok(state);

  @override
  Future<Result<List<Product>>> products() async => const Ok([]);

  @override
  Future<Result<GroupOffer>> create({
    required String productId,
    required int groupPriceMinor,
    required int minQuantity,
    int days = 3,
    int? memberDeliveryFeeMinor,
  }) async {
    calls.add('create:$groupPriceMinor:$minQuantity:$memberDeliveryFeeMinor');
    state = [_offer()];
    return Ok(state.single);
  }

  @override
  Future<Result<GroupOffer>> cancel(GroupOffer offer) async {
    calls.add('cancel');
    return Ok(offer);
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
  testWidgets('group_offers', (tester) async {
    final service = _Offers()..state = [_offer(committed: 2)];
    await _capture(
      tester,
      'v_group_offers',
      GroupOffersView(service: service, onBack: () {}),
    );
  });
}
