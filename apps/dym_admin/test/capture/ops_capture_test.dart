@Tags(['golden'])
library;

import 'package:dym_admin/features/ops/testing.dart';
import 'package:dym_admin/features/ops_center/ops_center_view.dart';
import 'package:dym_admin/ui/admin_theme.dart';
import 'package:dym_admin/ui/navigation.dart';
import 'package:dym_admin/ui/views/home/admin_home_view.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures de la console (design « Épuré », planche 06), sur ordinateur.
class _Auth implements AuthService {
  @override
  AccountApp get app => AccountApp.admin;

  @override
  String? get email => 'ops@dym.example';

  @override
  Me? get me => const Me(userId: 'u1', roles: {UserRole.admin});

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Navigator implements AdminNavigator {
  @override
  void toHome() {}

  @override
  void toSignIn({AdminNotice? notice}) {}
}

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
  testWidgets('en direct', (tester) async {
    const size = Size(1280, 800);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: adminTheme(),
        locale: const Locale('fr'),
        localizationsDelegates: DymLocalizations.localizationsDelegates,
        supportedLocales: DymLocalizations.supportedLocales,
        home: AdminHomeView(
          service: _Auth(),
          admin: MemoryAdminService(),
          ops: _Ops(),
          navigator: _Navigator(),
          initialTab: AdminTab.ops,
          clock: () => DateTime(2026, 11, 11, 11),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/en_direct.png'),
    );
  });
}
