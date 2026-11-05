import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/cart/testing.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';

import 'discovery_fixtures.dart';

final cash = PaymentMethod.fromJson(const {
  'id': 'cash',
  'country_code': 'TG',
  'provider_code': 'cash',
  'label': {'fr': 'Cash à la livraison', 'en': 'Cash on delivery'},
});

final simulated = PaymentMethod.fromJson(const {
  'id': 'sim',
  'country_code': 'TG',
  'provider_code': 'simulator',
  'label': {'fr': 'Mobile Money (simulé)', 'en': 'Mobile Money (simulated)'},
});

const _tas = LocalizedText({'fr': 'le tas', 'en': 'per heap'});
const _litre = LocalizedText({'fr': '1 L', 'en': '1 L'});

const homeAddress = CustomerAddress(
  id: 'home',
  kind: AddressKind.home,
  zoneId: 'be',
  zoneName: 'Bè',
  cityName: 'Lomé',
  countryCode: 'TG',
  landmark: 'Portail bleu après la pharmacie',
  phone: '+228 90 00 00 00',
  latitude: 6.13,
  longitude: 1.239,
  isDefault: true,
);

/// Panier de la maquette 05 : 3 400 + 700 de livraison = 4 100.
MemoryCartService memoryCart({
  List<CustomerAddress> addresses = const [homeAddress],
  Map<String, int>? lines,
  bool kodjoOpen = true,
  LocatedPlace? located,
  bool online = false,
}) => MemoryCartService(
  config: togoConfig(),
  stores: {
    'kodjo': MemoryCartStore(
      id: 'kodjo',
      name: "Étal d'Akossiwa",
      origin: 'marche',
      zoneName: 'Bè',
      isOpen: kodjoOpen,
      servedZoneIds: const {'be', 'tokoin'},
    ),
    'esi': const MemoryCartStore(
      id: 'esi',
      name: "Les jus d'Esi",
      origin: 'maison',
      zoneName: 'Tokoin',
      offersPickup: true,
      servedZoneIds: {'be', 'tokoin'},
    ),
  },
  variants: const {
    'tomates': MemoryCartVariant(
      id: 'tomates',
      productId: 'p-tomates',
      storeId: 'kodjo',
      name: 'Tomates fraîches',
      priceMinor: 500,
      unitLabel: _tas,
    ),
    'gombo': MemoryCartVariant(
      id: 'gombo',
      productId: 'p-gombo',
      storeId: 'kodjo',
      name: 'Gombo frais',
      priceMinor: 300,
      unitLabel: _tas,
    ),
    'bissap': MemoryCartVariant(
      id: 'bissap',
      productId: 'p-bissap',
      storeId: 'esi',
      name: 'Bissap',
      priceMinor: 700,
      unitLabel: _litre,
      stockQuantity: 5,
    ),
    'gingembre': MemoryCartVariant(
      id: 'gingembre',
      productId: 'p-gingembre',
      storeId: 'esi',
      name: 'Gingembre',
      priceMinor: 700,
      unitLabel: _litre,
    ),
  },
  paymentMethods: [cash, if (online) simulated],
  addresses: addresses,
  initialLines:
      lines ?? const {'tomates': 2, 'gombo': 1, 'bissap': 2, 'gingembre': 1},
  located:
      located ??
      const LocatedPlace(
        memoryPoint,
        ZoneMatch(
          zoneId: 'agoe',
          zoneName: 'Agoè',
          cityId: 'lome',
          cityName: 'Lomé',
          countryCode: 'TG',
          distanceM: 120,
        ),
      ),
);

/// Montant formaté dans la devise des fixtures.
String xof(int minor) => Money(minor, Currency.xof).format();
