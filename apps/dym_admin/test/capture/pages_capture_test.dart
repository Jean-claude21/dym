@Tags(['golden'])
library;

import 'package:dym_admin/features/audit/audit_view.dart';
import 'package:dym_admin/features/disputes/disputes_view.dart';
import 'package:dym_admin/features/finance/finance_view.dart';
import 'package:dym_admin/features/ops/testing.dart';
import 'package:dym_admin/features/orders/orders_views.dart';
import 'package:dym_admin/features/stores/stores_view.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures de contrôle des pages de l'admin (bilan avant refonte).
final _now = DateTime(2026, 10, 5, 12);

Future<void> _capture(WidgetTester tester, String name, Widget child) async {
  const size = Size(1280, 800);
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: DymTheme.light(),
      locale: const Locale('fr'),
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: Scaffold(body: SafeArea(child: child)),
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
  testWidgets('commande', (t) async {
    await _capture(
      t,
      'admin_commande',
      AdminOrderView(
        service: MemoryAdminService(),
        orderId: 'o1',
        onBack: () {},
        clock: () => _now,
      ),
    );
  });
  testWidgets('commandes', (t) async {
    await _capture(
      t,
      'admin_commandes',
      AdminOrdersView(
        service: MemoryAdminService(),
        onOpen: (_) {},
        clock: () => _now,
      ),
    );
  });
  testWidgets('boutiques', (t) async {
    await _capture(
      t,
      'admin_boutiques',
      AdminStoresView(service: MemoryAdminService()),
    );
  });
  testWidgets('finances', (t) async {
    await _capture(
      t,
      'admin_finances',
      AdminFinanceView(service: MemoryAdminService(), clock: () => _now),
    );
  });
  testWidgets('litiges', (t) async {
    await _capture(
      t,
      'admin_litiges',
      AdminDisputesView(service: MemoryAdminService(), clock: () => _now),
    );
  });
  testWidgets('journal', (t) async {
    await _capture(
      t,
      'admin_journal',
      AdminAuditView(service: MemoryAdminService()),
    );
  });
}
