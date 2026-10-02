import 'package:dym_client/features/discovery/testing.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/demo/demo_store.dart';
import 'package:dym_models/dym_models.dart';

/// Découverte de démonstration (écrans 28 à 33), sans requête : boutiques et
/// produits de la galerie, prix dans la devise du pays choisi.
abstract final class DemoDiscovery {
  static PublicStore _store(
    DemoCountry c, {
    required String id,
    required String name,
    required String origin,
    required String zone,
    required String cover,
    int prep = 15,
    bool open = true,
    String? description,
  }) => PublicStore(
    id: id,
    name: name,
    description: description,
    origin: origin,
    zoneId: DemoStore.zoneIdOf(zone),
    zoneName: zone,
    currencyCode: c.currency.code,
    prepTimeMinutes: prep,
    deliveryMinutes: prep + 20,
    offersPickup: origin == 'maison',
    openNow: open,
    closesAt: '20:00',
    coverKey: 'stores/$id/cover/$cover.jpg',
    productCount: 3,
  );

  static List<PublicStore> stores(DemoCountry c) {
    final zones = DemoStore.zoneNames(c);
    return [
      _store(
        c,
        id: 'akossiwa',
        name: "Étal d'Akossiwa",
        origin: 'marche',
        zone: zones[1],
        cover: 'etal-akossiwa',
      ),
      _store(
        c,
        id: 'esi',
        name: "Les jus d'Esi",
        origin: 'maison',
        zone: zones[0],
        cover: 'cour-esi',
        prep: 30,
        description:
            'Je prépare mes jus chaque matin avec les fleurs de bissap du '
            "marché d'Adawlato.",
      ),
      _store(
        c,
        id: 'kodjo',
        name: 'Alimentation Kodjo',
        origin: 'magasin',
        zone: zones[3],
        cover: 'epicerie-kodjo',
        prep: 20,
      ),
    ];
  }

  static ProductPageData _product(
    DemoCountry c,
    PublicStore store, {
    required String id,
    required String name,
    required String category,
    required int xof,
    required String unit,
    List<(String, int)> variants = const [],
    String? description,
  }) {
    final list = variants.isEmpty
        ? [PublicVariant(id: '$id-v', priceMinor: c.price(xof).amountMinor)]
        : [
            for (final (label, price) in variants)
              PublicVariant(
                id: '$id-$label',
                label: label,
                priceMinor: c.price(price).amountMinor,
              ),
          ];
    final key = 'stores/${store.id}/products/$id.jpg';
    return ProductPageData(
      item: CatalogItem(
        id: id,
        name: name,
        categoryId: category,
        priceMinor: c.price(xof).amountMinor,
        minPriceMinor: list
            .map((v) => v.priceMinor)
            .reduce((a, b) => a < b ? a : b),
        currencyCode: c.currency.code,
        unitLabel: LocalizedText.fromJson({'fr': unit, 'en': unit}),
        photoKey: key,
        variantCount: list.length,
        store: CatalogItemStore(
          id: store.id,
          name: store.name,
          origin: store.origin,
          zoneName: store.zoneName,
        ),
      ),
      store: store,
      description: description,
      photoKeys: [key, key],
      variants: list,
    );
  }

  static List<ProductPageData> products(DemoCountry c) {
    final [akossiwa, esi, kodjo] = stores(c);
    return [
      _product(
        c,
        akossiwa,
        id: 'tomates',
        name: 'Tomates fraîches',
        category: 'legumes',
        xof: 500,
        unit: 'le tas',
      ),
      _product(
        c,
        akossiwa,
        id: 'gombo',
        name: 'Gombo frais',
        category: 'legumes',
        xof: 300,
        unit: 'le tas',
      ),
      _product(
        c,
        akossiwa,
        id: 'piment',
        name: 'Piment rouge',
        category: 'epices',
        xof: 200,
        unit: 'le tas',
      ),
      _product(
        c,
        akossiwa,
        id: 'ademe',
        name: 'Adémè',
        category: 'legumes',
        xof: 250,
        unit: 'la botte',
      ),
      _product(
        c,
        kodjo,
        id: 'oignons',
        name: 'Oignons',
        category: 'legumes',
        xof: 400,
        unit: 'le tas',
      ),
      _product(
        c,
        kodjo,
        id: 'aubergines',
        name: 'Aubergines locales',
        category: 'legumes',
        xof: 300,
        unit: 'le tas',
      ),
      _product(
        c,
        esi,
        id: 'bissap',
        name: 'Jus de bissap',
        category: 'boissons',
        xof: 700,
        unit: 'le litre',
        variants: const [('50 cl', 400), ('1 L', 700)],
        description:
            'Jus de bissap frais au gingembre, préparé chaque matin avec les '
            "fleurs du marché d'Adawlato.",
      ),
      _product(
        c,
        esi,
        id: 'gingembre',
        name: 'Jus de gingembre',
        category: 'boissons',
        xof: 700,
        unit: 'le litre',
      ),
      _product(
        c,
        esi,
        id: 'baobab',
        name: 'Jus de baobab',
        category: 'boissons',
        xof: 800,
        unit: 'le litre',
      ),
    ];
  }

  static MemoryDiscoveryService service(DemoCountry c) =>
      MemoryDiscoveryService(
        config: DemoStore.config(c),
        stores: stores(c),
        products: products(c),
        initialZone: DemoStore.zoneIdOf(c.zone),
        photoResolver: (key) {
          final name = key.split('/').last.replaceAll('.jpg', '');
          return key.contains('/cover/')
              ? DemoImages.store(name)
              : DemoImages.product(name);
        },
      );
}
