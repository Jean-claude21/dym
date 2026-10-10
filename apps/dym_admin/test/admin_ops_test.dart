import 'package:dym_admin/features/audit/audit_view.dart';
import 'package:dym_admin/features/disputes/disputes_view.dart';
import 'package:dym_admin/features/disputes/disputes_viewmodel.dart';
import 'package:dym_admin/features/finance/finance_view.dart';
import 'package:dym_admin/features/ops/testing.dart';
import 'package:dym_admin/features/orders/orders_viewmodels.dart';
import 'package:dym_admin/features/orders/orders_views.dart';
import 'package:dym_admin/features/settings/settings_view.dart';
import 'package:dym_admin/features/settings/settings_viewmodel.dart';
import 'package:dym_admin/features/stores/stores_view.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sizes = [
  Size(360, 640),
  Size(412, 915),
  Size(915, 412),
  Size(640, 360),
  Size(800, 1280),
  Size(1280, 800),
  Size(1440, 900),
];

final _now = DateTime.utc(2026, 10, 5, 11);
DateTime _clock() => _now;

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1280, 800),
  Locale locale = const Locale('fr'),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: DymTheme.light(),
      locale: locale,
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('viewmodels', () {
    test('commandes : filtre bloquées, recherche', () async {
      final vm = AdminOrdersViewModel(service: MemoryAdminService());
      await vm.load();
      expect(vm.page!.total, 4);
      expect(vm.page!.stuckCount, 1);
      await vm.selectFilter(AdminOrderFilter.stuck);
      expect(vm.page!.orders.map((o) => o.id), ['o1']);
      await vm.selectFilter(AdminOrderFilter.all);
      await vm.search('afi');
      expect(vm.page!.orders.map((o) => o.id), ['o3', 'o4']);
    });

    test('commande : statut forcé, livreur, annulation remboursée', () async {
      final service = MemoryAdminService();
      final vm = AdminOrderViewModel(service: service, orderId: 'o1');
      await vm.load();
      expect(await vm.forceStatus('Raison'), isFalse, reason: 'sans statut');
      vm.selectTarget(OrderStatus.ready);
      expect(await vm.forceStatus('Vendeuse injoignable'), isTrue);
      expect(vm.order!.status, OrderStatus.ready);
      expect(vm.order!.timeline.last.actorRole, 'admin');
      expect(await vm.assignCourier('Yao', '+000 91 00 00 00'), isTrue);
      expect(vm.order!.courier?.name, 'Yao');
      expect(await vm.cancel('Boutique fermée'), isTrue);
      expect(vm.order!.status, OrderStatus.cancelled);
      expect(vm.order!.refunds, hasLength(1));
      expect(service.gestures, ['o1:ready', 'o1:courier', 'o1:cancel']);
      expect(await vm.cancel('Encore'), isFalse);
      expect(vm.actionFailure, const ValidationFailure('order_closed'));
    });

    test('litige : montant plafonné, décision, liste mise à jour', () async {
      final service = MemoryAdminService();
      final vm = AdminDisputesViewModel(service: service);
      await vm.load();
      expect(vm.rows.map((r) => r.id), ['d2', 'd1'], reason: 'plus ancien');
      await vm.select('d1');
      vm.setAmount('99999');
      expect(vm.canResolve, isFalse, reason: 'au-delà du total');
      vm.setAmount('300');
      expect(vm.canResolve, isTrue);
      vm
        ..setWarnVendor(value: true)
        ..note = 'Gombo manquant confirmé';
      expect(await vm.reply('Nous regardons.'), isTrue);
      expect(await vm.resolve(), isTrue);
      expect(vm.detail!.dispute.isOpen, isFalse);
      expect(vm.detail!.dispute.refundMinor, 300);
      expect(vm.rows.map((r) => r.id), ['d2']);
      expect(service.gestures, ['d1:reply', 'd1:partialRefund:warn']);
    });

    test('réglages : pays incomplet refusé, ville ajoutée', () async {
      final service = MemoryAdminService();
      final vm = AdminSettingsViewModel(service: service);
      await vm.load();
      expect(await vm.setCountryActive('GH', active: true), isFalse);
      expect(vm.actionFailure, const ValidationFailure('country_not_ready'));
      await vm.selectTab(SettingsTab.geography);
      expect(await vm.saveCity({'name': 'Ville B'}), isTrue);
      expect(vm.cities.map((c) => c.name), ['Ville A', 'Ville B']);
      expect(percentToBps('10,5'), 1050);
      expect(percentToBps('101'), isNull);
      expect(bpsToPercent(1050), '10,5');
    });
  });

  group('écrans 52 à 58 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        final name =
            '${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}';
        Future<void> show(WidgetTester tester, Widget view) async {
          await _pump(tester, view, size: size, locale: locale, textScale: 1.3);
          expect(tester.takeException(), isNull);
        }

        testWidgets('52 · $name', (tester) async {
          await show(
            tester,
            AdminOrdersView(
              service: MemoryAdminService(),
              onOpen: (_) {},
              clock: _clock,
            ),
          );
        });
        for (final id in const ['o1', 'o2', 'o3']) {
          testWidgets('53 $id · $name', (tester) async {
            await show(
              tester,
              AdminOrderView(
                service: MemoryAdminService(),
                orderId: id,
                onBack: () {},
                clock: _clock,
              ),
            );
          });
        }
        testWidgets('54 · $name', (tester) async {
          await show(
            tester,
            AdminDisputesView(service: MemoryAdminService(), clock: _clock),
          );
        });
        testWidgets('55 · $name', (tester) async {
          await show(tester, AdminStoresView(service: MemoryAdminService()));
          await tester.tap(find.text("Étal d'Akossiwa").first);
          await _settle(tester);
          expect(tester.takeException(), isNull);
        });
        testWidgets('56 · $name', (tester) async {
          await show(
            tester,
            AdminSettingsView(service: MemoryAdminService(), onSignOut: () {}),
          );
          final l10n = await DymLocalizations.delegate.load(locale);
          for (final tab in [
            l10n.adminTabGeography,
            l10n.adminColPayment,
            l10n.adminTabCommission,
            l10n.adminTabFees,
            l10n.adminTabCategories,
          ]) {
            await tester.ensureVisible(find.text(tab).first);
            await tester.tap(find.text(tab).first);
            await _settle(tester);
            expect(tester.takeException(), isNull, reason: tab);
          }
        });
        testWidgets('57 · $name', (tester) async {
          await show(
            tester,
            AdminFinanceView(service: MemoryAdminService(), clock: _clock),
          );
        });
        testWidgets('58 · $name', (tester) async {
          await show(tester, AdminAuditView(service: MemoryAdminService()));
        });
      }
    }
  });

  testWidgets('52 → filtre bloquées', (tester) async {
    final opened = <String>[];
    await _pump(
      tester,
      AdminOrdersView(
        service: MemoryAdminService(),
        onOpen: opened.add,
        clock: _clock,
      ),
    );
    expect(find.text('Bloquée'), findsOneWidget);
    await tester.tap(find.text('Bloquées · 1'));
    await _settle(tester);
    expect(find.text('4M9A0B2C'), findsNothing);
    await tester.tap(find.text('7K2Q4F1A'));
    expect(opened, ['o1']);
  });

  testWidgets('53 : forcer « Prête » avec une raison', (tester) async {
    final service = MemoryAdminService();
    await _pump(
      tester,
      AdminOrderView(
        service: service,
        orderId: 'o1',
        onBack: () {},
        clock: _clock,
      ),
      size: const Size(1440, 900),
    );
    expect(find.text('Bloquée depuis 57 min'), findsOneWidget);
    await tester.tap(find.text('Choisis un statut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prête').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Raison (obligatoire)'),
      'Vendeuse injoignable',
    );
    await tester.pump();
    await tester.tap(find.text('Appliquer'));
    await _settle(tester);
    expect(service.gestures, ['o1:ready']);
    expect(find.textContaining('Vendeuse injoignable'), findsWidgets);
  });

  testWidgets('53 : annuler et rembourser après une raison', (tester) async {
    final service = MemoryAdminService();
    await _pump(
      tester,
      AdminOrderView(
        service: service,
        orderId: 'o1',
        onBack: () {},
        clock: _clock,
      ),
      size: const Size(1440, 900),
    );
    await tester.ensureVisible(find.text('Annuler et rembourser'));
    await tester.tap(find.text('Annuler et rembourser'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Boutique fermée');
    await tester.pump();
    await tester.tap(find.text('Annuler et rembourser').last);
    await tester.pumpAndSettle();
    expect(service.gestures, ['o1:cancel']);
    expect(find.textContaining('Annulée'), findsWidgets);
  });

  testWidgets('57 : exécuter, puis remis en main propre', (tester) async {
    final service = MemoryAdminService();
    await _pump(
      tester,
      AdminFinanceView(service: service, clock: _clock),
      size: const Size(1440, 900),
    );
    await tester.tap(find.text('Remboursements').first);
    await _settle(tester);
    await tester.tap(find.text('Exécuter'));
    await _settle(tester);
    await tester.tap(find.text('Marquer remis en main propre'));
    await _settle(tester);
    expect(service.gestures, ['r1:execute', 'r2:cash']);
    expect(find.text('Aucun remboursement.'), findsOneWidget);
  });

  testWidgets('55 : suspendre avec une raison', (tester) async {
    final service = MemoryAdminService();
    await _pump(
      tester,
      AdminStoresView(service: service),
      size: const Size(1440, 900),
    );
    await tester.tap(find.text("Étal d'Akossiwa").first);
    await _settle(tester);
    await tester.ensureVisible(find.text('Suspendre la boutique'));
    await tester.tap(find.text('Suspendre la boutique'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Produits non conformes',
    );
    await tester.pump();
    await tester.tap(find.text('Suspendre la boutique').last);
    await tester.pumpAndSettle();
    expect(service.gestures, ['s1:store_suspended']);
    expect(find.text('Suspendue'), findsOneWidget);
  });

  testWidgets('56 : pays incomplet, message', (tester) async {
    await _pump(
      tester,
      AdminSettingsView(service: MemoryAdminService()),
      size: const Size(1440, 900),
    );
    await tester.tap(find.byType(Switch).last);
    await _settle(tester);
    expect(
      find.text("Ce pays n'est pas prêt : complète ce qui manque."),
      findsOneWidget,
    );
  });

  testWidgets('58 : avant / après', (tester) async {
    await _pump(
      tester,
      AdminAuditView(service: MemoryAdminService()),
      size: const Size(1440, 900),
    );
    await tester.tap(find.text('Boutique suspendue'));
    await _settle(tester);
    expect(find.text('Avant / après'), findsOneWidget);
  });
}
