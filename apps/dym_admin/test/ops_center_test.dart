import 'package:dym_admin/features/ops_center/ops_center_view.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

OpsLive _live({List<CourierCashDue> cash = const []}) => OpsLive(
  countryCode: 'TG',
  currencyCode: 'XOF',
  countries: const ['TG', 'GH'],
  ordersByStatus: const {OrderStatus.pending: 3, OrderStatus.delivered: 12},
  deliveredMinor: 45000,
  alerts: const [
    OpsAlert(
      orderId: 'o1',
      storeName: 'Étal de Kodjo',
      status: OrderStatus.pending,
      minutes: 32,
    ),
  ],
  couriersOnline: 2,
  courierCash: cash,
);

const _settings = OpsSettings(
  countryCode: 'TG',
  currencyCode: 'XOF',
  thresholds: {'pending': 10, 'ready': 20, 'transit': 60},
  feedWeights: {'weight_local': 3},
  canManageScopes: true,
);

class _Ops implements OpsCenterService {
  final calls = <String>[];
  List<CourierCashDue> cash = const [
    CourierCashDue(
      courierId: 'c1',
      name: 'Yao',
      phone: '+22890000000',
      amountMinor: 4000,
      currencyCode: 'XOF',
    ),
  ];

  @override
  Future<Result<Map<String, Currency>>> currencies() async =>
      Ok({'XOF': Currency.xof});

  @override
  Future<Result<List<String>>> countries() async => const Ok(['TG', 'GH']);

  @override
  Future<Result<OpsLive>> live(String country) async {
    calls.add('live:$country');
    return Ok(_live(cash: cash));
  }

  @override
  Future<Result<OpsSettings>> settings(String country) async =>
      const Ok(_settings);

  @override
  Future<Result<OpsSettings>> setThresholds(
    String country,
    Map<String, int> values,
  ) async {
    calls.add('thresholds:${values['pending']}');
    return const Ok(_settings);
  }

  @override
  Future<Result<OpsSettings>> setFeedWeights(
    String country,
    Map<String, int> weights,
  ) async => const Ok(_settings);

  @override
  Future<Result<OpsSettings>> savePlan(Map<String, Object?> plan) async =>
      const Ok(_settings);

  @override
  Future<Result<OpsSettings>> setScope(
    String email,
    String country, {
    required bool on,
  }) async {
    calls.add('scope:$email:$country:$on');
    return const Ok(_settings);
  }

  List<FraudSignal> signals = [
    FraudSignal(
      id: 'f1',
      kind: 'shared_device',
      subjectType: 'user',
      subject: 'Awa',
      createdAt: DateTime(2026, 11, 10),
      detail: const {'accounts': 3},
    ),
  ];

  @override
  Future<Result<List<FraudSignal>>> fraudSignals(String country) async =>
      Ok(signals);

  @override
  Future<Result<List<FraudSignal>>> decideFraud(
    FraudSignal signal, {
    required bool confirm,
  }) async {
    calls.add('fraud:${signal.id}:$confirm');
    signals = [];
    return Ok(signals);
  }

  @override
  Future<Result<int>> confirmCourierCash(CourierCashDue due, String key) async {
    calls.add('cash:${due.courierId}');
    cash = const [];
    return Ok(due.amountMinor);
  }
}

void main() {
  group('centre d’opérations (spec 053)', () {
    test('pays, seuils invalides refusés, cash reçu', () async {
      final service = _Ops();
      final vm = OpsCenterViewModel(service: service);
      await vm.load();
      expect(vm.country, 'TG');
      expect(await vm.setThresholds({'pending': 'x'}), isFalse);
      expect(vm.problem, 'invalid');
      expect(await vm.setThresholds({'pending': '15'}), isTrue);
      expect(await vm.setScope('agent@example.com', 'GH', on: true), isTrue);
      expect(await vm.confirmCash(vm.live!.courierCash.single), isTrue);
      expect(vm.signals, hasLength(1));
      expect(await vm.decideFraud(vm.signals.single, confirm: false), isTrue);
      expect(vm.signals, isEmpty);
      expect(service.calls, contains('fraud:f1:false'));
      expect(vm.live!.courierCash, isEmpty);
      await vm.selectCountry('GH');
      expect(service.calls, contains('live:GH'));
      vm.dispose();
    });

    testWidgets('écran : indicateurs, retard, cash des livreurs', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1800);
      addTearDown(tester.view.reset);
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          theme: DymTheme.light(),
          locale: const Locale('fr'),
          localizationsDelegates: DymLocalizations.localizationsDelegates,
          supportedLocales: DymLocalizations.supportedLocales,
          home: Scaffold(
            body: OpsCenterView(
              service: _Ops(),
              onOpenOrder: (id) => opened = id,
              refresh: const Duration(hours: 1),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Étal de Kodjo'), findsOneWidget);
      expect(find.text('32 min'), findsOneWidget);
      expect(find.text('Cash reçu'), findsOneWidget);
      expect(
        find.text('Appareil partagé par plusieurs comptes · 3'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Étal de Kodjo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Étal de Kodjo'));
      expect(opened, 'o1');
    });
  });
}
