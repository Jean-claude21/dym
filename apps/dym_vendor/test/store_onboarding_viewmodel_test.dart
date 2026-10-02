import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/store/my_store/my_store_viewmodel.dart';
import 'package:dym_vendor/features/store/onboarding/store_onboarding_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/store_fixtures.dart';

void main() {
  group('onboarding', () {
    test('sans boutique : étape 1, quartier du profil proposé', () async {
      final vm = StoreOnboardingViewModel(
        service: memoryStores(),
        onOpened: (_, _) {},
      );
      await vm.load();
      expect(vm.step, StoreStep.name);
      expect(vm.canContinue, isFalse);
      expect(vm.zoneId, 'tokoin');
      vm.setName('E');
      expect(vm.canContinue, isFalse, reason: '2 caractères minimum');
      vm.setName("Les jus d'Esi");
      expect(vm.canContinue, isTrue);
    });

    test('les 7 étapes enregistrées une à une, puis ouverture', () async {
      final stores = memoryStores();
      MyStore? opened;
      final vm = StoreOnboardingViewModel(
        service: stores,
        onOpened: (store, _) => opened = store,
      );
      await vm.load();

      vm
        ..setName("Les jus d'Esi")
        ..setDescription('Jus de bissap préparés chaque matin.');
      await vm.submit();
      expect(vm.step, StoreStep.origin);

      vm.selectOrigin('maison');
      await vm.submit();
      expect(vm.step, StoreStep.address);
      expect(vm.canContinue, isFalse, reason: 'adresse vide');

      vm
        ..setAddress('Rue des Hibiscus, maison bleue')
        ..setLandmark('Derrière la pharmacie');
      await vm.submit();
      expect(vm.step, StoreStep.category);

      vm.selectCategory('fait-maison');
      await vm.submit();
      expect(vm.step, StoreStep.delivery);
      expect(vm.canContinue, isFalse, reason: 'aucun quartier desservi');

      vm
        ..selectAllDeliveryZones()
        ..setPrepTime(45)
        ..setPickup(value: true);
      expect(vm.deliveryZoneIds, hasLength(7));
      await vm.submit();
      expect(vm.step, StoreStep.payment);
      expect(vm.paymentOptions, hasLength(3));
      expect(vm.paymentMethodIds, {'cash'}, reason: 'cash proposé par défaut');

      await vm.submit();
      expect(vm.step, StoreStep.hours);
      expect(vm.hours.where((h) => h.open), hasLength(6));

      await vm.submit();
      expect(opened?.status, StoreStatus.active);
      expect(opened?.isOpen, isTrue);
      expect(opened?.prepTimeMinutes, 45);
      expect(opened?.pickupAddress?.landmark, 'Derrière la pharmacie');
      expect(stores.calls.last, 'publish');
    });

    test('reprise : étape enregistrée et valeurs précédentes', () async {
      final vm = StoreOnboardingViewModel(
        service: memoryStores(
          initial: const MyStore(
            id: 'store',
            name: "Les jus d'Esi",
            origin: 'maison',
            zoneId: 'tokoin',
            prepTimeMinutes: 30,
            offersPickup: false,
            status: StoreStatus.draft,
            isOpen: false,
            onboardingStep: 4,
            pickupAddress: PickupAddress(address: 'Rue des Hibiscus'),
          ),
        ),
        onOpened: (_, _) {},
      );
      await vm.load();
      expect(vm.step, StoreStep.category);
      vm.back();
      expect(vm.step, StoreStep.address);
      expect(vm.address, 'Rue des Hibiscus');
      vm.back();
      expect(vm.origin, 'maison');
    });

    test('hors ligne : étape conservée, rien de perdu, réessai', () async {
      final stores = memoryStores();
      final vm = StoreOnboardingViewModel(service: stores, onOpened: (_, _) {});
      await vm.load();
      vm.setName('Chez Afi');
      stores.failNext = const NetworkFailure('hors ligne');
      await vm.submit();
      expect(vm.step, StoreStep.name);
      expect(vm.offline, isTrue);
      expect(vm.name, 'Chez Afi');
      await vm.submit();
      expect(vm.step, StoreStep.origin);
      expect(vm.saveFailure, isNull);
    });

    test('Mobile Money « Bientôt » : non sélectionnable', () async {
      final vm = StoreOnboardingViewModel(
        service: memoryStores(
          initial: const MyStore(
            id: 'store',
            name: 'Chez Afi',
            zoneId: 'tokoin',
            prepTimeMinutes: 30,
            offersPickup: false,
            status: StoreStatus.draft,
            isOpen: false,
            onboardingStep: 6,
          ),
        ),
        onOpened: (_, _) {},
      );
      await vm.load();
      expect(vm.step, StoreStep.payment);
      vm.togglePaymentMethod(vm.paymentOptions[1]);
      expect(vm.paymentMethodIds, {'cash'});
    });

    test('horaires : inversés ou tous fermés refusés', () async {
      final vm = StoreOnboardingViewModel(
        service: memoryStores(),
        onOpened: (_, _) {},
        editStep: StoreStep.hours,
      );
      await vm.load();
      expect(vm.canContinue, isTrue);
      vm
        ..setOpensAt(1, '19:00')
        ..setClosesAt(1, '07:00');
      expect(vm.canContinue, isFalse);
      vm.applyFirstDayToAll();
      expect(vm.hours.where((h) => h.open).every((h) => !h.isValid), isTrue);
      for (var day = 1; day <= 7; day++) {
        vm.setDayOpen(day, open: false);
      }
      expect(vm.canContinue, isFalse);
    });

    test('ouverture refusée (incomplète) : message dédié', () async {
      final vm = StoreOnboardingViewModel(
        service: memoryStores(
          initial: const MyStore(
            id: 'store',
            name: 'Chez Afi',
            prepTimeMinutes: 30,
            offersPickup: false,
            status: StoreStatus.draft,
            isOpen: false,
            onboardingStep: 7,
          ),
        ),
        onOpened: (_, _) => fail('ne doit pas ouvrir'),
      );
      await vm.load();
      await vm.submit();
      expect(vm.incomplete, isTrue);
      expect(vm.step, StoreStep.hours);
    });

    test("réglage d'une étape : enregistre sans publier", () async {
      final stores = memoryStores(initial: openStore());
      MyStore? saved;
      final vm = StoreOnboardingViewModel(
        service: stores,
        onOpened: (_, _) => fail('ne doit pas publier'),
        editStep: StoreStep.hours,
        onSaved: (store) => saved = store,
      );
      await vm.load();
      expect(vm.canGoBack, isFalse);
      vm.setDayOpen(7, open: true);
      await vm.submit();
      expect(saved?.hours, hasLength(7));
      expect(stores.calls, isNot(contains('publish')));
    });
  });

  group('Ma boutique', () {
    test('fermer puis rouvrir : état renvoyé par la base', () async {
      final stores = memoryStores(initial: openStore());
      final vm = MyStoreViewModel(service: stores, onEdit: (_) async {});
      await vm.load();
      await vm.setOpen(open: false);
      expect(vm.store?.isOpen, isFalse);
      await vm.setOpen(open: true);
      expect(vm.store?.isOpen, isTrue);
    });

    test('suspendue : interrupteur sans effet', () async {
      final stores = memoryStores(
        initial: openStore(open: false, status: StoreStatus.suspended),
      );
      final vm = MyStoreViewModel(service: stores, onEdit: (_) async {});
      await vm.load();
      expect(vm.suspended, isTrue);
      await vm.setOpen(open: true);
      expect(stores.calls, isNot(contains('setOpen')));
    });

    test('hors ligne : échec signalé, état inchangé', () async {
      final stores = memoryStores(initial: openStore());
      final vm = MyStoreViewModel(service: stores, onEdit: (_) async {});
      await vm.load();
      stores.failNext = const NetworkFailure('hors ligne');
      await vm.setOpen(open: false);
      expect(vm.store?.isOpen, isTrue);
      expect(vm.toggleFailure, isA<NetworkFailure>());
    });

    test('après un réglage : boutique relue', () async {
      final stores = memoryStores(initial: openStore());
      final vm = MyStoreViewModel(
        service: stores,
        onEdit: (_) => stores.update({'prep_time_minutes': 60}),
      );
      await vm.load();
      await vm.edit(StoreStep.delivery);
      expect(vm.store?.prepTimeMinutes, 60);
    });
  });
}
