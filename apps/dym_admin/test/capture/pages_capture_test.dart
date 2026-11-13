@Tags(['golden'])
library;

import 'package:dym_admin/features/audit/audit_view.dart';
import 'package:dym_admin/features/clients/clients_view.dart';
import 'package:dym_admin/features/dashboard/dashboard_view.dart';
import 'package:dym_admin/features/disputes/disputes_view.dart';
import 'package:dym_admin/features/finance/finance_view.dart';
import 'package:dym_admin/features/moderation/moderation_view.dart';
import 'package:dym_admin/features/ops/testing.dart';
import 'package:dym_admin/features/orders/orders_views.dart';
import 'package:dym_admin/features/settings/settings_view.dart';
import 'package:dym_admin/features/stores/stores_view.dart';
import 'package:dym_admin/features/support/support_view.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures de contrôle des pages de l'admin (bilan avant refonte).
final _now = DateTime(2026, 10, 5, 12);

Future<void> _capture(
  WidgetTester tester,
  String name,
  Widget child, {
  Size size = const Size(1280, 800),
}) async {
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
  testWidgets('clientes', (t) async {
    await _capture(
      t,
      'admin_clientes',
      AdminClientsView(service: MemoryAdminService(), clock: () => _now),
    );
  });
  testWidgets('support', (t) async {
    await _capture(
      t,
      'admin_support',
      AdminSupportView(service: MemoryAdminService(), clock: () => _now),
    );
  });
  testWidgets('modération', (t) async {
    await _capture(
      t,
      'admin_moderation',
      AdminModerationView(service: MemoryAdminService(), clock: () => _now),
    );
  });
  testWidgets('configuration', (t) async {
    await _capture(
      t,
      'admin_configuration',
      AdminSettingsView(service: MemoryAdminService()),
    );
  });
  testWidgets('tableau de bord', (t) async {
    await _capture(
      t,
      'admin_tableau',
      AdminDashboardView(service: MemoryAdminService(), onOpen: (_) {}),
    );
  });
  // Page entière (relecture) : grand écran, tablette, téléphone.
  for (final (name, size) in const [
    ('admin_tableau_complet', Size(1440, 2000)),
    ('admin_tableau_tablette', Size(800, 2600)),
    ('admin_tableau_telephone', Size(412, 4200)),
  ]) {
    testWidgets('tableau de bord $name', (t) async {
      await _capture(
        t,
        name,
        AdminDashboardView(service: MemoryAdminService(), onOpen: (_) {}),
        size: size,
      );
    });
  }
  for (final section in [FinanceSection.refunds, FinanceSection.payments]) {
    testWidgets('finances ${section.name}', (t) async {
      await _capture(
        t,
        'admin_finances_${section.name}',
        AdminFinanceView(
          service: MemoryAdminService(),
          clock: () => _now,
          initialSection: section,
        ),
      );
    });
  }
}
