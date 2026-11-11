// Fakes repris des tests d'écran : certaines aides n'y servent pas.
@Tags(['golden'])
library;

import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/wholesale/wholesale_view.dart';
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

WholesaleOffer _offer({int committed = 0, int? mine, bool own = false}) =>
    WholesaleOffer(
      id: 'o1',
      productName: 'Riz 25 kg',
      storeName: 'Grossiste Yao',
      unitPriceMinor: 15000,
      minQuantity: 20,
      closesAt: DateTime(2026, 11, 17),
      status: 'open',
      committed: committed,
      buyers: committed == 0 ? 0 : 1,
      myQuantity: mine,
      mine: own,
    );

class _Wholesale implements WholesaleService {
  WholesaleBoard state = WholesaleBoard(open: [_offer()]);
  final calls = <String>[];

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(_togo());

  @override
  Future<Result<WholesaleBoard>> board() async => Ok(state);

  @override
  Future<Result<WholesaleBoard>> setWholesaler({required bool on}) async =>
      Ok(state = WholesaleBoard(isWholesaler: on, open: state.open));

  @override
  Future<Result<List<Product>>> products() async => const Ok([]);

  @override
  Future<Result<WholesaleOffer>> create({
    required String productId,
    required int unitPriceMinor,
    required int minQuantity,
    int days = 7,
    String? note,
  }) async {
    calls.add('create:$unitPriceMinor:$minQuantity');
    return Ok(_offer(own: true));
  }

  @override
  Future<Result<WholesaleOffer>> commit(
    WholesaleOffer offer,
    int quantity,
  ) async {
    calls.add('commit:$quantity');
    final o = _offer(
      committed: quantity,
      mine: quantity == 0 ? null : quantity,
    );
    state = WholesaleBoard(isWholesaler: state.isWholesaler, open: [o]);
    return Ok(o);
  }

  @override
  Future<Result<WholesaleOffer>> decide(
    WholesaleOffer offer, {
    required bool confirm,
  }) async => offer.reached || !confirm
      ? Ok(offer)
      : const Err(ValidationFailure('minimum_not_reached'));
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
  testWidgets('wholesale', (tester) async {
    await _capture(
      tester,
      'v_wholesale',
      WholesaleView(service: _Wholesale(), onBack: () {}),
    );
  });
}
