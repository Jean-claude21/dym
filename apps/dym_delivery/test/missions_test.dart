import 'package:dym_core/dym_core.dart';
import 'package:dym_delivery/features/missions/missions_service.dart';
import 'package:dym_delivery/features/missions/missions_views.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
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
  cities: [
    City.fromJson(const {
      'id': 'lome',
      'country_code': 'TG',
      'slug': 'lome',
      'name': 'Lomé',
    }),
  ],
  zones: [
    for (final (id, name) in const [('be', 'Bè'), ('tokoin', 'Tokoin')])
      Zone.fromJson({'id': id, 'city_id': 'lome', 'slug': id, 'name': name}),
  ],
  categories: const [],
  storeOrigins: const [],
  units: const [],
  paymentMethods: const [],
  deliveryFees: const [],
  featureFlags: const [],
);

Mission _mission(String id, {String status = 'ready'}) => Mission(
  orderId: id,
  status: status,
  createdAt: DateTime(2026, 11, 10, 9),
  deliveryFeeMinor: 500,
  currencyCode: 'XOF',
  itemCount: 3,
  store: const MissionPlace(name: 'Étal de Kodjo', zoneName: 'Bè'),
  customer: const MissionPlace(zoneName: 'Tokoin'),
);

const _kofi = CourierProfile(
  displayName: 'Kofi',
  phone: '+228 90 11 22 33',
  vehicle: CourierVehicle.moto,
  zoneIds: ['be'],
);

Widget _app(Widget child) => MaterialApp(
  theme: DymTheme.light(),
  locale: const Locale('fr'),
  localizationsDelegates: DymLocalizations.localizationsDelegates,
  supportedLocales: DymLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('temps réel : une course proposée apparaît sans attendre', (
    tester,
  ) async {
    final service = MemoryMissionsService(
      config: _togo(),
      current: const CourierProfile(
        displayName: 'Kofi',
        phone: '+228 90 11 22 33',
        vehicle: CourierVehicle.moto,
        zoneIds: ['be'],
        isOnline: true,
      ),
    );
    final vm = MissionsViewModel(service: service);
    await tester.runAsync(vm.start);
    expect(vm.missions, isEmpty);
    service.open.add(_mission('o1', status: 'accepted'));
    service.liveSignals.add(
      const LiveSignal.event(
        kind: 'notification',
        payload: {'kind': 'mission_available'},
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    expect(vm.missions?.map((m) => m.orderId), ['o1']);
    vm.dispose();
  });

  group('inscription (spec 041)', () {
    test('nom, téléphone, moyen et zones exigés', () async {
      final service = MemoryMissionsService(config: _togo());
      final vm = CourierOnboardingViewModel(
        service: service,
        firstName: 'Kofi',
      );
      await vm.load();
      expect(vm.canSave, isFalse);
      vm
        ..phoneController.text = '+228 90 11 22 33'
        ..chooseVehicle(CourierVehicle.bike)
        ..toggleZone('be');
      expect(vm.canSave, isTrue);
      expect(await vm.save(), isTrue);
      expect(service.current!.vehicle, CourierVehicle.bike);
      expect(service.current!.zoneIds, ['be']);
    });

    test('téléphone refusé : message', () async {
      final vm = CourierOnboardingViewModel(
        service: MemoryMissionsService(config: _togo()),
        firstName: 'Kofi',
      );
      await vm.load();
      vm
        ..phoneController.text = 'abcdefghij'
        ..toggleZone('be');
      expect(await vm.save(), isFalse);
      expect(vm.problem, MissionError.invalidPhone);
    });

    testWidgets('écran : zones du pays proposées', (tester) async {
      await tester.pumpWidget(
        _app(
          CourierOnboardingView(
            service: MemoryMissionsService(config: _togo()),
            onDone: () {},
            firstName: 'Kofi',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bè'), findsOneWidget);
      expect(find.text('Tokoin'), findsOneWidget);
      expect(find.text('Moto'), findsOneWidget);
    });
  });

  group('missions', () {
    test('hors ligne : rien ; en ligne : missions proposées', () async {
      final service = MemoryMissionsService(
        config: _togo(),
        current: _kofi,
        open: [_mission('o1')],
      );
      final vm = MissionsViewModel(service: service);
      await vm.load();
      expect(vm.missions, isEmpty);
      await vm.setOnline(online: true);
      expect(vm.missions, hasLength(1));
      expect(await vm.accept(vm.missions!.single), isTrue);
      expect(service.accepted, hasLength(1));
      expect(vm.missions, isEmpty);
    });

    test('déjà prise : message', () async {
      final service = MemoryMissionsService(
      config: _togo(),
      current: const CourierProfile(
        displayName: 'Kofi',
        phone: '+228 90 11 22 33',
        vehicle: CourierVehicle.moto,
        zoneIds: ['be'],
        isOnline: true,
      ),
    );
      final vm = MissionsViewModel(service: service);
      await vm.load();
      expect(await vm.accept(_mission('o9')), isFalse);
      expect(vm.problem, MissionError.taken);
    });

    testWidgets('écran : interrupteur, carte, acceptation', (tester) async {
      var accepted = false;
      final service = MemoryMissionsService(
        config: _togo(),
        current: _kofi,
        open: [_mission('o1')],
      );
      await tester.pumpWidget(
        _app(MissionsView(service: service, onAccepted: () => accepted = true)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tu es hors ligne'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      // Trajet « boutique → cliente » et lieu de ramassage.
      expect(find.textContaining('Étal de Kodjo'), findsWidgets);
      expect(find.text('3 articles'), findsOneWidget);
      await tester.tap(find.text('Accepter la course'));
      await tester.pumpAndSettle();
      expect(accepted, isTrue);
    });
  });

  group('mes courses', () {
    test('récupérer puis livrer ; rendre avant retrait', () async {
      final service = MemoryMissionsService(
        config: _togo(),
        current: _kofi,
        open: [_mission('o1'), _mission('o2')],
      );
      await service.accept(_mission('o1'));
      await service.accept(_mission('o2'));
      final vm = MyRunsViewModel(service: service);
      await vm.load();
      expect(vm.runs, hasLength(2));
      service.codes['o1'] = '4821';
      await vm.advance(vm.runs!.first, 'out_for_delivery');
      expect(await vm.deliver(vm.runs!.first, '0000'), 4);
      expect(vm.runs!.first.delivered, isFalse);
      expect(await vm.deliver(vm.runs!.first, ' 4821 '), isNull);
      expect(vm.runs!.first.delivered, isTrue);
      await vm.release(vm.runs!.last);
      expect(vm.runs, hasLength(1));
      expect(service.gestures, contains('release:o2'));
    });

    testWidgets('écran : geste suivant affiché', (tester) async {
      final service = MemoryMissionsService(
        config: _togo(),
        current: _kofi,
        open: [_mission('o1')],
      );
      await service.accept(_mission('o1'));
      await tester.pumpWidget(
        _app(ListView(children: [MyRunsView(service: service)])),
      );
      await tester.pumpAndSettle();
      expect(find.text('Course en cours'), findsOneWidget);
      expect(find.text('Commande récupérée'), findsOneWidget);
      await tester.tap(find.text('Commande récupérée'));
      await tester.pumpAndSettle();
      expect(find.text('Commande remise'), findsOneWidget);
      // Remise : le code de la cliente est demandé.
      service.codes['o1'] = '4821';
      await tester.tap(find.text('Commande remise'));
      await tester.pumpAndSettle();
      // Clavier géant : un chiffre par touche.
      for (final d in '4821'.split('')) {
        await tester.tap(find.bySemanticsLabel(d).last);
        await tester.pump();
      }
      await tester.tap(find.text('Valider la remise'));
      await tester.pumpAndSettle();
      // Livrée : elle quitte « en cours » et passe dans l'historique.
      expect(find.text('Commande remise'), findsNothing);
      await tester.pumpWidget(
        _app(MyRunsView(service: service, history: true)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Livrée'), findsOneWidget);
    });

    testWidgets('carte : tournée et consignes de conservation', (tester) async {
      final service = MemoryMissionsService(
        config: _togo(),
        current: _kofi,
        open: [
          Mission(
            orderId: 'o1',
            status: 'ready',
            createdAt: DateTime(2026, 11, 10, 9),
            deliveryFeeMinor: 500,
            currencyCode: 'XOF',
            itemCount: 3,
            store: const MissionPlace(name: 'Étal de Kodjo', zoneName: 'Bè'),
            customer: const MissionPlace(zoneName: 'Tokoin'),
            runSize: 2,
            storage: const [StorageHint.cool, StorageHint.fragile],
          ),
        ],
      );
      await service.setOnline(online: true);
      await tester.pumpWidget(
        _app(MissionsView(service: service, onAccepted: () {})),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tournée · 2 boutiques'), findsOneWidget);
      expect(find.text('Au frais'), findsOneWidget);
      expect(find.text('Fragile'), findsOneWidget);
    });
  });
}
