import 'package:dym_admin/features/clients/clients_view.dart';
import 'package:dym_admin/features/dashboard/dashboard_view.dart';
import 'package:dym_admin/features/finance/finance_view.dart';
import 'package:dym_admin/features/ops/testing.dart';
import 'package:dym_admin/features/settings/settings_view.dart';
import 'package:dym_admin/features/settings/settings_viewmodel.dart';
import 'package:dym_admin/features/stores/stores_view.dart';
import 'package:dym_admin/features/stores/stores_viewmodel.dart';
import 'package:dym_admin/features/support/support_view.dart';
import 'package:dym_admin/ui/navigation.dart';
import 'package:dym_admin/ui/views/home/admin_home_view.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
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
  Size size = const Size(1440, 900),
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

class _Auth implements AuthService {
  @override
  AccountApp get app => AccountApp.admin;

  @override
  Future<Result<void>> signOut() async => const Ok(null);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Navigator implements AdminNavigator {
  @override
  void toHome() {}

  @override
  void toSignIn({AdminNotice? notice}) {}
}

void main() {
  group('viewmodels', () {
    test('tableau de bord : période, alertes', () async {
      final vm = AdminDashboardViewModel(service: MemoryAdminService());
      await vm.load();
      expect(vm.data!.stuckOrders, 1);
      expect(vm.data!.payments24h.percent, 96);
      await vm.selectPeriod('week');
      expect(vm.data!.period, 'week');
    });

    test('support : répondre passe en attente, fermer', () async {
      final service = MemoryAdminService();
      final vm = AdminSupportViewModel(service: service);
      await vm.load();
      expect(vm.tickets!.map((t) => t.id), ['t1', 't2']);
      expect(vm.selected, isNull, reason: 'liste d’abord sur téléphone');
      vm.select('t1');
      expect(await vm.reply('  Nous vérifions.  '), isTrue);
      expect(vm.tickets!.map((t) => t.id), ['t2'], reason: 'passé en attente');
      vm.select('t2');
      expect(await vm.close(), isTrue);
      expect(vm.tickets, isEmpty);
      expect(service.gestures, ['t1:reply', 't2:close']);
      await vm.selectStatus(TicketStatus.pending);
      expect(vm.tickets!.single.messages.last.body, 'Nous vérifions.');
    });

    test(
      'support : brouillon de l’agent, relu avant envoi (spec 054)',
      () async {
        final vm = AdminSupportViewModel(service: MemoryAdminService());
        await vm.load();
        expect(await vm.draft(), isNull, reason: 'aucun ticket choisi');
        vm.select('t1');
        expect(await vm.draft(), 'Bonjour, nous regardons votre demande.');
        expect(vm.acting, isFalse);
      },
    );

    test('clientes : recherche, profil consulté', () async {
      final service = MemoryAdminService();
      final vm = AdminClientsViewModel(service: service);
      await vm.load();
      expect(vm.rows, hasLength(3));
      await vm.search('mar');
      expect(vm.rows!.map((r) => r.firstName), ['Mariam']);
      await vm.select('u1');
      expect(vm.client!.orderCount, 12);
      expect(service.gestures, ['u1:viewed']);
    });

    test('réglages : fonctionnalité activée', () async {
      final service = MemoryAdminService();
      final vm = AdminSettingsViewModel(service: service);
      await vm.load();
      await vm.selectTab(SettingsTab.flags);
      expect(vm.flags.first.isEnabled, isFalse);
      expect(await vm.setFlag(vm.flags.first, enabled: true), isTrue);
      expect(vm.flags.first.isEnabled, isTrue);
      expect(service.gestures, ['flag:ai_search:true']);
    });

    test('boutiques : vue vendeuse, suppression refusée puis faite', () async {
      final service = MemoryAdminService();
      final vm = AdminStoresViewModel(service: service);
      await vm.load();
      await vm.select('s1');
      final view = await vm.vendorView();
      expect(view.valueOrNull!.products, hasLength(3));
      expect(await vm.deleteVendor('Doublon'), isFalse);
      expect(vm.actionFailure, const ValidationFailure('vendor_has_orders'));
      await vm.select('s4');
      expect(await vm.deleteVendor('Doublon'), isTrue);
      expect(vm.store, isNull);
      expect(service.gestures, ['s1:vendor_viewed', 's4:deleted']);
    });

    test('finances : revenus de la période', () async {
      final vm = AdminFinanceViewModel(service: MemoryAdminService());
      await vm.load();
      expect(vm.section, FinanceSection.revenue);
      expect(vm.revenue!.stores, hasLength(2));
      await vm.selectPeriod('last_month');
      expect(vm.revenue!.period, 'last_month');
    });
  });

  group('écrans 67 à 70 aux 7 tailles, texte 130 %', () {
    for (final size in _sizes) {
      for (final locale in const [Locale('fr'), Locale('en')]) {
        final name =
            '${size.width.toInt()}×${size.height.toInt()} · '
            '${locale.languageCode}';
        Future<void> show(WidgetTester tester, Widget view) async {
          await _pump(tester, view, size: size, locale: locale, textScale: 1.3);
          expect(tester.takeException(), isNull);
        }

        testWidgets('67 · $name', (tester) async {
          await show(
            tester,
            AdminDashboardView(service: MemoryAdminService(), onOpen: (_) {}),
          );
          expect(find.text("Étal d'Akossiwa"), findsOneWidget);
        });
        testWidgets('68 · $name', (tester) async {
          await show(
            tester,
            AdminClientsView(service: MemoryAdminService(), clock: _clock),
          );
          await tester.tap(find.text('Awa').first);
          await _settle(tester);
          expect(tester.takeException(), isNull);
          expect(find.text('awa@exemple.com'), findsOneWidget);
        });
        testWidgets('69 · $name', (tester) async {
          await show(
            tester,
            AdminSupportView(service: MemoryAdminService(), clock: _clock),
          );
          await tester.tap(find.text('Je n’ai pas reçu ma monnaie').first);
          await _settle(tester);
          expect(tester.takeException(), isNull);
        });
        testWidgets('70 · $name', (tester) async {
          await show(
            tester,
            AdminFinanceView(service: MemoryAdminService(), clock: _clock),
          );
          expect(find.text('Les jus d’Esi'), findsOneWidget);
        });
        testWidgets('réglages · fonctionnalités · $name', (tester) async {
          await show(
            tester,
            AdminSettingsView(service: MemoryAdminService(), onSignOut: () {}),
          );
          final l10n = await DymLocalizations.delegate.load(locale);
          await tester.ensureVisible(find.text(l10n.adminTabFlags));
          await tester.tap(find.text(l10n.adminTabFlags));
          await _settle(tester);
          expect(tester.takeException(), isNull);
          expect(find.text('ai_search'), findsOneWidget);
        });
        testWidgets('boutique · voir comme elle · $name', (tester) async {
          await show(tester, AdminStoresView(service: MemoryAdminService()));
          await tester.tap(find.text("Étal d'Akossiwa").first);
          await _settle(tester);
          final l10n = await DymLocalizations.delegate.load(locale);
          await tester.ensureVisible(find.text(l10n.adminViewAsVendor));
          await tester.tap(find.text(l10n.adminViewAsVendor));
          await _settle(tester);
          expect(tester.takeException(), isNull);
          expect(find.text('Gombo frais'), findsOneWidget);
        });
      }
    }
  });

  testWidgets('69 : répondre puis fermer', (tester) async {
    final service = MemoryAdminService();
    await _pump(tester, AdminSupportView(service: service, clock: _clock));
    expect(find.text('> 1 h'), findsOneWidget, reason: 't2 sans réponse');
    await tester.tap(find.text('Comment changer mes horaires ?').first);
    await _settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Dans Ma boutique.');
    await tester.pump();
    await tester.tap(find.text('Répondre'));
    await _settle(tester);
    expect(service.gestures, ['t2:reply']);
    await tester.tap(find.text('Je n’ai pas reçu ma monnaie').first);
    await _settle(tester);
    await tester.tap(find.text('Fermer le ticket'));
    await _settle(tester);
    expect(service.gestures, ['t2:reply', 't1:close']);
    expect(find.text('Aucune demande ici.'), findsOneWidget);
  });

  testWidgets('67 : une alerte ouvre son onglet', (tester) async {
    await _pump(
      tester,
      AdminHomeView(
        service: _Auth(),
        admin: MemoryAdminService(),
        navigator: _Navigator(),
        clock: _clock,
      ),
    );
    await tester.tap(find.text('Tickets ouverts'));
    await _settle(tester);
    expect(find.text('Comment changer mes horaires ?'), findsOneWidget);
  });

  testWidgets('téléphone : « Plus » ouvre les autres onglets', (tester) async {
    await _pump(
      tester,
      AdminHomeView(
        service: _Auth(),
        admin: MemoryAdminService(),
        navigator: _Navigator(),
        clock: _clock,
      ),
      size: const Size(412, 915),
    );
    // Sept domaines : les trois premiers dans la barre, le reste dans « Plus ».
    expect(find.text('Plus'), findsOneWidget);
    expect(find.text('Journal'), findsNothing);
    await tester.tap(find.text('Support').last);
    await tester.pumpAndSettle();
    expect(find.text('Je n’ai pas reçu ma monnaie'), findsOneWidget);
    await tester.tap(find.text('Plus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
