import 'dart:typed_data';

import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/till/qr_charge_view.dart';
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

void main() {
  group('caisse (spec 045)', () {
    test('dictée : vente lue puis enregistrée', () async {
      final vm = TillViewModel(service: _Till());
      await vm.load();
      final draft = await vm.dictate();
      expect(draft?.amountMinor, 1500);
      expect(vm.amountText(draft!.amountMinor!), '1500');
      expect(
        await vm.record(
          label: draft.label!,
          amountText: '1500',
          method: TillMethod.cash,
        ),
        isTrue,
      );
      expect(vm.till!.todayOffAppMinor, 1500);
    });

    test('rien entendu ; montant invalide refusé', () async {
      final service = _Till()..heard = null;
      final vm = TillViewModel(service: service);
      await vm.load();
      expect(await vm.dictate(), isNull);
      expect(vm.problem, 'nothing_heard');
      expect(
        await vm.record(
          label: 'Gombo',
          amountText: 'abc',
          method: TillMethod.cash,
        ),
        isFalse,
      );
      expect(vm.problem, 'invalid_amount');
    });

    test('versement : jamais plus que le solde', () async {
      final vm = TillViewModel(service: _Till());
      await vm.load();
      expect(await vm.payout('5000'), isFalse);
      expect(vm.problem, 'balance_insufficient');
      expect(await vm.payout('1500'), isTrue);
      expect(vm.till!.balanceMinor, 500);
    });

    testWidgets('écran : nouvelle vente saisie, visible dans la liste', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: TillView(service: _Till(), onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aucune vente hors app enregistrée.'), findsOneWidget);
      await tester.tap(find.text('Nouvelle vente'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Gombo');
      await tester.enterText(find.byType(TextField).at(1), '700');
      await tester.tap(find.text('Enregistrer la vente'));
      await tester.pumpAndSettle();
      expect(find.text('Gombo'), findsOneWidget);
    });
  });

  group('encaisser par QR (spec 046)', () {
    test('montant, QR affiché, payé à la relecture', () async {
      final service = _Till();
      final vm = QrChargeViewModel(service: service);
      await vm.init();
      await vm.create('abc');
      expect(vm.problem, 'invalid_amount');
      await vm.create('2000');
      expect(vm.request?.qr, 'DYM-PAY:123456');
      expect(vm.request?.amountMinor, 2000);
      service.next = PaymentRequestStatus.paid;
      await vm.poll();
      expect(vm.request?.status, PaymentRequestStatus.paid);
      vm.dispose();
    });
  });
}
