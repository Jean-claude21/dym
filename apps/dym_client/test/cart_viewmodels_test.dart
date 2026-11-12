import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/cart/cart_viewmodels.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/cart_fixtures.dart';

void main() {
  group('panier (05)', () {
    test('montants de la maquette 05 : 3 400 + 700 = 4 100', () async {
      final ordered = <Purchase>[];
      final vm = CartViewModel(service: memoryCart(), onOrdered: ordered.add);
      await vm.load();
      expect(vm.ready, isTrue);
      expect(vm.cart.storeCount, 2);
      expect(vm.cart.itemCount, 6);
      expect(vm.cart.subtotalMinor, 3400);
      expect(vm.cart.deliveryFeeMinor, 700);
      expect(vm.cart.totalMinor, 4100);
      expect(vm.cart.remainingForFreeMinor, 600);
      expect(vm.freeDeliveryProgress, closeTo(0.85, 0.001));
      expect(vm.canOrder, isTrue);
    });

    test('retirer une ligne ; le sous-panier vide disparaît', () async {
      final vm = CartViewModel(
        service: memoryCart(lines: const {'tomates': 1, 'bissap': 1}),
        onOrdered: (_) {},
      );
      await vm.load();
      await vm.setQuantity('tomates', 0);
      expect(vm.cart.storeCount, 1);
      expect(vm.cart.stores.single.id, 'esi');
    });

    test('commande en un tap : achat, panier vidé, order_created', () async {
      final service = memoryCart();
      final ordered = <Purchase>[];
      final vm = CartViewModel(service: service, onOrdered: ordered.add);
      await vm.load();
      await vm.order();
      expect(ordered.single.orders, hasLength(2));
      expect(ordered.single.totalMinor, 4100);
      expect(ordered.single.address?.zoneName, 'Bè');
      expect(vm.cart.isEmpty, isTrue);
      expect(service.events, contains('order_created'));
    });

    test('sans adresse : refus lisible, rien de créé', () async {
      final ordered = <Purchase>[];
      final vm = CartViewModel(
        service: memoryCart(addresses: const []),
        onOrdered: ordered.add,
      );
      await vm.load();
      await vm.order();
      expect(vm.orderError, OrderError.addressRequired);
      expect(ordered, isEmpty);
    });

    test('boutique fermée : commande impossible', () async {
      final vm = CartViewModel(
        service: memoryCart(kodjoOpen: false),
        onOrdered: (_) {},
      );
      await vm.load();
      expect(vm.cart.blocking, isTrue);
      expect(vm.canOrder, isFalse);
    });

    test('hors ligne au moment de commander : erreur réseau', () async {
      final service = memoryCart();
      final vm = CartViewModel(service: service, onOrdered: (_) {});
      await vm.load();
      service.failNext = const NetworkFailure('3G');
      await vm.order();
      expect(vm.orderError, OrderError.offline);
      expect(vm.cart.isEmpty, isFalse, reason: 'le panier reste');
    });

    test('refus de la base traduits', () {
      expect(
        orderErrorOf(const ValidationFailure('total_changed')),
        OrderError.totalChanged,
      );
      expect(
        orderErrorOf(const ValidationFailure('payment_unavailable')),
        OrderError.paymentUnavailable,
      );
      expect(
        orderErrorOf(const ServerFailure('x', statusCode: 500)),
        OrderError.generic,
      );
    });
  });

  group('livraison (34)', () {
    test('checkout_started, retrait chez Esi : un seul ramassage', () async {
      final service = memoryCart();
      final vm = DeliveryViewModel(service: service);
      await vm.load();
      expect(service.events, contains('checkout_started'));
      expect(vm.addresses.single.id, 'home');
      expect(vm.addressId, 'home');
      await vm.setMode('esi', Fulfillment.pickup);
      expect(vm.cart.pickupCount, 1);
      expect(vm.cart.deliveryFeeMinor, 500, reason: 'base portée par Kodjo');
    });
  });

  group('adresses (35, 36)', () {
    test('formulaire : erreurs après la tentative, puis position', () async {
      final service = memoryCart(addresses: const []);
      final vm = AddressFormViewModel(service: service);
      await vm.load();
      expect(await vm.save(), isFalse);
      expect(vm.showErrors, isTrue);
      expect(vm.landmarkValid, isFalse);

      await vm.locate();
      expect(vm.zoneId, 'agoe');
      expect(vm.hasPosition, isTrue);
      vm
        ..setLandmark('Derrière l’église')
        ..setPhone('+228 91 00 00 00');
      expect(await vm.save(), isTrue);
      final saved = (await service.addresses()).valueOrNull!.single;
      expect(saved.isDefault, isTrue, reason: 'la première est par défaut');
      expect(saved.hasPosition, isTrue);
    });

    test('quartier choisi par recherche : la position est oubliée', () async {
      final vm = AddressFormViewModel(service: memoryCart());
      await vm.load();
      await vm.locate();
      vm.selectZone('tokoin');
      expect(vm.hasPosition, isFalse);
    });

    test('position hors zone : quartier non choisi (spec 065)', () async {
      final vm = AddressFormViewModel(
        service: memoryCart(
          located: const LocatedPlace(
            GeoPoint(5.36, -4.01),
            ZoneMatch(
              zoneId: 'be',
              zoneName: 'Bè',
              cityId: 'lome',
              cityName: 'Lomé',
              countryCode: 'TG',
              distanceM: 640000,
              covered: false,
            ),
          ),
        ),
      );
      await vm.load();
      await vm.locate();
      expect(vm.location, AddressLocation.outside);
      expect(vm.zoneId, isNull);
      expect(vm.hasPosition, isFalse);
    });

    test('position indisponible : message, saisie possible', () async {
      final service = memoryCart();
      final vm = AddressFormViewModel(service: service);
      await vm.load();
      service.failNext = const NetworkFailure('gps');
      await vm.locate();
      expect(vm.location, AddressLocation.unavailable);
      expect(vm.zoneId, isNull);
    });

    test('mes adresses : par défaut et suppression', () async {
      final service = memoryCart();
      await service.saveAddress(
        const AddressInput(
          id: 'work',
          kind: AddressKind.work,
          zoneId: 'tokoin',
          landmark: 'Immeuble jaune, 2e étage',
          phone: '+228 92 00 00 00',
        ),
      );
      final vm = AddressesViewModel(service: service);
      await vm.load();
      expect(vm.addresses.first.id, 'home');
      await vm.setDefault('work');
      expect(vm.addresses.first.id, 'work');
      await vm.delete('work');
      expect(vm.addresses.single.isDefault, isTrue);
    });
  });
}
