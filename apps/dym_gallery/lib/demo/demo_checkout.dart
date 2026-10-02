import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/cart/testing.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_gallery/demo/demo_catalog.dart' show DemoCatalog;
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/demo/demo_store.dart';
import 'package:dym_models/dym_models.dart';

/// Panier, adresses et commande de démonstration (écrans 34 à 38), sans
/// requête : le panier de la maquette 05, prix dans la devise du pays.
abstract final class DemoCheckout {
  static int _minor(DemoCountry c, int xof) => c.price(xof).amountMinor;

  static MemoryCartVariant _variant(DemoCountry c, String id, String store) {
    final p = DemoCatalog.products[id]!;
    return MemoryCartVariant(
      id: id,
      productId: 'p-$id',
      storeId: store,
      name: p.name,
      priceMinor: _minor(c, p.priceXof),
      unitLabel: LocalizedText({'fr': p.unit, 'en': p.unit}),
      photoKey: 'demo/$id',
    );
  }

  static List<CustomerAddress> addresses(DemoCountry c) {
    final zones = DemoStore.zoneNames(c);
    final city = c.city.split(',').last.trim();
    return [
      CustomerAddress(
        id: 'home',
        kind: AddressKind.home,
        zoneId: DemoStore.zoneIdOf(c.zone),
        zoneName: c.zone,
        cityName: city,
        countryCode: c.code,
        landmark: 'Portail bleu après la pharmacie',
        phone: c.code == 'GH' ? '+233 20 000 0000' : '+228 90 00 00 00',
        latitude: 6.13,
        longitude: 1.239,
        isDefault: true,
      ),
      CustomerAddress(
        id: 'work',
        kind: AddressKind.work,
        zoneId: DemoStore.zoneIdOf(zones[0]),
        zoneName: zones[0],
        cityName: city,
        countryCode: c.code,
        landmark: 'Immeuble jaune, 2e étage',
        phone: c.code == 'GH' ? '+233 20 000 0001' : '+228 90 00 00 01',
      ),
    ];
  }

  static MemoryCartService service(
    DemoCountry c, {
    List<CustomerAddress>? addresses,
  }) {
    final config = DemoStore.config(c);
    final zones = DemoStore.zoneNames(c);
    final cash = PaymentMethod.fromJson({
      'id': 'cash',
      'country_code': c.code,
      'provider_code': 'cash',
      'label': const {'fr': 'Cash à la livraison', 'en': 'Cash on delivery'},
    });
    return MemoryCartService(
      config: config,
      stores: {
        'akossiwa': MemoryCartStore(
          id: 'akossiwa',
          name: "Étal d'Akossiwa",
          origin: 'marche',
          zoneName: zones[1],
        ),
        'esi': MemoryCartStore(
          id: 'esi',
          name: "Les jus d'Esi",
          origin: 'maison',
          zoneName: zones[0],
          offersPickup: true,
        ),
      },
      variants: {
        for (final id in const ['tomates', 'gombo'])
          id: _variant(c, id, 'akossiwa'),
        for (final id in const ['bissap', 'gingembre'])
          id: _variant(c, id, 'esi'),
      },
      baseFeeMinor: _minor(c, 500),
      extraPickupFeeMinor: _minor(c, 200),
      freeThresholdMinor: _minor(c, 4000),
      paymentMethods: [cash],
      addresses: addresses ?? DemoCheckout.addresses(c),
      initialLines: const {
        'tomates': 2,
        'gombo': 1,
        'bissap': 2,
        'gingembre': 1,
      },
      located: LocatedPlace(
        memoryPoint,
        ZoneMatch(
          zoneId: DemoStore.zoneIdOf(c.zone),
          zoneName: c.zone,
          cityId: 'city',
          cityName: c.city.split(',').last.trim(),
          countryCode: c.code,
          distanceM: 180,
        ),
      ),
      photoResolver: (key) => DemoCatalog.products[key.split('/').last]!.image,
    );
  }

  /// Achat de l'écran 37 (le panier de la maquette 05, commandé).
  static Future<Purchase> purchase(DemoCountry c) async =>
      (await service(c).placeOrder()).valueOrNull!;
}
