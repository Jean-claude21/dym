import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/dashboard/dashboard_service.dart';
import 'package:dym_vendor/features/dashboard/dashboard_view.dart';
import 'package:dym_vendor/features/dashboard/dashboard_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/store_fixtures.dart';

VendorDashboard _summary(DashboardPeriod period, {int revenue = 12500}) =>
    VendorDashboard(
      period: period,
      currencyCode: 'XOF',
      revenueMinor: revenue,
      orderCount: revenue == 0 ? 0 : 6,
      pendingPayments: 2,
      pendingOrders: 2,
      activeOrders: 3,
      outOfStock: 1,
      criticalNotifications: 1,
    );

class _Service implements DashboardService {
  Result<VendorDashboard>? result;
  Future<Result<VendorDashboard>> Function(DashboardPeriod)? handler;

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(togoConfig());

  @override
  Future<Result<VendorDashboard>> summary(DashboardPeriod period) =>
      handler?.call(period) ?? Future.value(result ?? Ok(_summary(period)));
}

void main() {
  test('montants serveur et échec réseau : dernier résumé conservé', () async {
    final service = _Service();
    final vm = DashboardViewModel(service: service);
    addTearDown(vm.dispose);
    await vm.load();
    expect(vm.revenue?.amountMinor, 12500);
    service.result = const Err(NetworkFailure('offline'));
    await vm.load();
    expect(vm.offline, isTrue);
    expect(vm.summary?.revenueMinor, 12500);
  });

  test(
    'la dernière période choisie gagne face aux réponses désordonnées',
    () async {
      final day = Completer<Result<VendorDashboard>>();
      final service = _Service()
        ..handler = (period) async => period == DashboardPeriod.day
            ? await day.future
            : Ok(_summary(period, revenue: 50000));
      final vm = DashboardViewModel(service: service);
      addTearDown(vm.dispose);
      final first = vm.load();
      await Future<void>.delayed(Duration.zero);
      await vm.selectPeriod(DashboardPeriod.week);
      day.complete(Ok(_summary(DashboardPeriod.day)));
      await first;
      expect(vm.summary?.period, DashboardPeriod.week);
      expect(vm.revenue?.amountMinor, 50000);
      expect(vm.isBusy, isFalse);
    },
  );

  const sizes = [
    Size(360, 640),
    Size(412, 915),
    Size(915, 412),
    Size(640, 360),
    Size(800, 1280),
    Size(1280, 800),
    Size(1440, 900),
  ];
  for (final size in sizes) {
    for (final locale in const [Locale('fr'), Locale('en')]) {
      testWidgets('dashboard $size $locale texte 130 %', (tester) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var orders = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: DymTheme.light(),
            locale: locale,
            localizationsDelegates: DymLocalizations.localizationsDelegates,
            supportedLocales: DymLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(1.3),
              ),
              child: Scaffold(
                body: DashboardView(
                  service: _Service(),
                  onOrders: () => orders++,
                  onProducts: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final week = find.text(
          locale.languageCode == 'fr' ? 'Semaine' : 'Week',
        );
        await tester.ensureVisible(week);
        await tester.pump();
        await tester.tap(week);
        await tester.pump();
        expect(tester.takeException(), isNull);
        final action = find.text(
          locale.languageCode == 'fr'
              ? '2 nouvelles commandes'
              : '2 new orders',
        );
        await tester.ensureVisible(action);
        await tester.pump();
        await tester.tap(action);
        expect(orders, 1);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
