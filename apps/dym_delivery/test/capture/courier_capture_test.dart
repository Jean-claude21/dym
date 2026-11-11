@Tags(['golden'])
library;

import 'package:dym_core/dym_core.dart';
import 'package:dym_delivery/features/earnings/earnings_view.dart';
import 'package:dym_delivery/features/missions/missions_service.dart';
import 'package:dym_delivery/features/missions/missions_views.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures de contrôle du livreur (design « Épuré », planche 05).
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

Mission _mission(
  String id,
  String store, {
  List<StorageHint> storage = const [],
}) => Mission(
  orderId: id,
  status: 'ready',
  createdAt: DateTime(2026, 11, 11, 9),
  deliveryFeeMinor: 500,
  currencyCode: 'XOF',
  itemCount: 3,
  cashToCollectMinor: 3450,
  scheduledStart: DateTime(2026, 11, 12, 8),
  scheduledEnd: DateTime(2026, 11, 12, 10),
  storage: storage,
  next: const ['out_for_delivery'],
  store: MissionPlace(name: store, zoneName: 'Bè'),
  customer: const MissionPlace(
    name: 'Awa',
    zoneName: 'Bè',
    landmark: 'Portail bleu après la pharmacie',
  ),
);

const _kofi = CourierProfile(
  displayName: 'Komlan',
  phone: '+228 90 11 22 33',
  vehicle: CourierVehicle.moto,
  zoneIds: ['be'],
  isOnline: true,
);

Future<void> _capture(
  WidgetTester tester,
  String name,
  Widget child, {
  int tab = 0,
  Future<void> Function(WidgetTester tester)? before,
}) async {
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
        child: Builder(
          builder: (context) {
            final l10n = DymLocalizations.of(context);
            return DymAdaptiveScaffold(
              currentIndex: tab,
              onDestinationSelected: (_) {},
              destinations: [
                DymNavItem(
                  icon: Icons.inventory_2_outlined,
                  label: l10n.missionsTitle,
                ),
                DymNavItem(
                  icon: Icons.history_rounded,
                  label: l10n.runsHistoryTitle,
                ),
                DymNavItem(
                  icon: Icons.payments_outlined,
                  label: l10n.earningsTitle,
                ),
                DymNavItem(
                  icon: Icons.person_outline_rounded,
                  label: l10n.accountTitle,
                ),
              ],
              body: child,
            );
          },
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 600));
  if (before != null) await before(tester);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

Future<MemoryMissionsService> _service() async {
  final service = MemoryMissionsService(
    config: _togo(),
    current: _kofi,
    open: [
      _mission('o1', 'Chez Fatou', storage: const [StorageHint.cool]),
      _mission('o2', "Étal d'Akossiwa"),
    ],
  );
  await service.accept(_mission('o1', 'Chez Fatou'));
  return service;
}

void main() {
  testWidgets('missions', (t) async {
    final service = await _service();
    await _capture(
      t,
      'missions',
      MissionsView(
        service: service,
        onAccepted: () {},
        active: MyRunsView(service: service),
      ),
    );
  });
  testWidgets('remise', (t) async {
    final service = await _service();
    await service.advance(_mission('o1', 'Chez Fatou'), 'out_for_delivery');
    await _capture(
      t,
      'remise',
      ListView(children: [MyRunsView(service: service)]),
      before: (t) async {
        await t.tap(find.text('Commande remise'));
        await t.pumpAndSettle();
        expect(find.text('Valider la remise'), findsOneWidget);
        for (final d in ['4', '8']) {
          await t.tap(find.bySemanticsLabel(d).last);
          await t.pump();
        }
      },
    );
  });
  testWidgets('gains', (t) async {
    final service = MemoryMissionsService(config: _togo())
      ..money = const CourierEarnings(
        todayCount: 3,
        todayFeesMinor: 8700,
        walletMinor: 12000,
        cash: [
          CourierCashLine(
            storeId: 's1',
            storeName: 'Chez Fatou',
            amountMinor: 2950,
          ),
          CourierCashLine(
            storeId: 's2',
            storeName: "Étal d'Akossiwa",
            amountMinor: 1200,
          ),
        ],
      );
    await _capture(t, 'gains', EarningsView(service: service), tab: 2);
  });
  testWidgets('inscription', (t) async {
    await _capture(
      t,
      'inscription',
      CourierOnboardingView(
        service: MemoryMissionsService(config: _togo()),
        onDone: () {},
        firstName: 'Komlan',
      ),
    );
  });
}
