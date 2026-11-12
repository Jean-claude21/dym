// Fakes repris des tests d'écran : certaines aides n'y servent pas.
@Tags(['golden'])
library;

import 'dart:typed_data';

import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/till/end_of_market_view.dart';
import 'package:dym_vendor/features/till/till_service.dart';
import 'package:dym_vendor/features/till/till_view.dart';
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

class _Recorder implements VoiceRecorder {
  @override
  Stream<double> get level => const Stream.empty();

  @override
  Future<Result<void>> start() async => const Ok(null);

  @override
  Future<Result<RecordedAudio?>> stop() async => Ok(
    RecordedAudio(
      bytes: Uint8List(4),
      contentType: 'audio/wav',
      duration: const Duration(seconds: 2),
    ),
  );

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}

/// Caisse en mémoire : mêmes règles utiles que la base.
class _Till implements TillService {
  Till state = const Till(
    currencyCode: 'XOF',
    balanceMinor: 2000,
    simulatedPayout: true,
  );
  String? heard = '3 tas de tomates 1500';

  @override
  final VoiceRecorder recorder = _Recorder();

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(_togo());

  @override
  Future<Result<Till>> till() async => Ok(state);

  @override
  Future<Result<TillDraft>> parse(String text) async => const Ok(
    TillDraft(label: '3 tas de tomates', amountMinor: 1500, quantity: 3),
  );

  @override
  Future<Result<String?>> dictate() async => Ok(heard);

  @override
  Future<Result<Till>> record({
    required String label,
    required int amountMinor,
    required TillMethod method,
    String? variantId,
    int quantity = 1,
  }) async {
    final sale = TillSale(
      id: 's${state.sales.length + 1}',
      label: label,
      amountMinor: amountMinor,
      method: method,
      soldAt: DateTime(2026, 11, 10, 9),
      quantity: quantity,
    );
    return Ok(
      state = Till(
        currencyCode: 'XOF',
        todayOffAppMinor: state.todayOffAppMinor + amountMinor,
        todayOffAppCount: state.todayOffAppCount + 1,
        byMethod: {method: (state.byMethod[method] ?? 0) + amountMinor},
        balanceMinor: state.balanceMinor,
        simulatedPayout: true,
        sales: [sale, ...state.sales],
      ),
    );
  }

  @override
  Future<Result<Till>> voidSale(TillSale sale) async => Ok(state);

  PaymentRequest? request;
  EndOfMarket eom = const EndOfMarket();
  final shared = <String>[];

  @override
  Future<Result<EndOfMarket>> endOfMarket() async => Ok(eom);

  @override
  Future<Result<EndOfMarket>> startEndOfMarket(int percent, int hours) async =>
      Ok(
        eom = EndOfMarket(
          active: true,
          percent: percent,
          until: DateTime(2026, 11, 10, 18),
          products: 4,
        ),
      );

  @override
  Future<Result<EndOfMarket>> stopEndOfMarket() async =>
      Ok(eom = const EndOfMarket());

  @override
  Future<Result<void>> shareStore(String Function(Uri link) message) async {
    shared.add(message(Uri.parse('https://fn.test/b/s1')));
    return const Ok(null);
  }

  @override
  Future<Result<PaymentRequest>> requestPayment(
    int amountMinor, {
    String? label,
  }) async => Ok(
    request = PaymentRequest(
      id: 'r1',
      code: '123456',
      qr: 'DYM-PAY:123456',
      amountMinor: amountMinor,
      currencyCode: 'XOF',
      status: PaymentRequestStatus.open,
      expiresAt: DateTime(2026, 11, 10, 10, 10),
      storeName: 'Étal de Kodjo',
    ),
  );

  /// Statut renvoyé à la prochaine relecture.
  PaymentRequestStatus next = PaymentRequestStatus.open;

  @override
  Future<Result<PaymentRequest>> requestStatus(PaymentRequest r) async => Ok(
    PaymentRequest(
      id: r.id,
      code: r.code,
      qr: r.qr,
      amountMinor: r.amountMinor,
      currencyCode: r.currencyCode,
      status: next,
      expiresAt: r.expiresAt,
      storeName: r.storeName,
    ),
  );

  @override
  Future<Result<PaymentRequest>> cancelRequest(PaymentRequest r) async =>
      await requestStatus(r);

  @override
  Future<Result<Till>> payout(int amountMinor) async {
    if (amountMinor > state.balanceMinor) {
      return const Err(ValidationFailure('balance_insufficient'));
    }
    return Ok(
      state = Till(
        currencyCode: 'XOF',
        balanceMinor: state.balanceMinor - amountMinor,
        simulatedPayout: true,
        sales: state.sales,
      ),
    );
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
  testWidgets('till', (tester) async {
    await _capture(tester, 'v_till', TillView(service: _Till(), onBack: () {}));
  });
  testWidgets('fin de marché', (tester) async {
    await _capture(
      tester,
      'v_fin_marche',
      EndOfMarketView(service: _Till(), onBack: () {}),
    );
  });
}
