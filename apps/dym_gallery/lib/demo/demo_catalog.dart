import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/widgets.dart';

/// Boutique de démonstration.
@immutable
class DemoStore {
  const new({
    required this.id,
    required this.name,
    required this.owner,
    required this.origin,
    required this.area,
    required this.distance,
    required this.avatar,
    this.cover,
  });

  final String id;
  final String name;
  final String owner;
  final StoreOrigin origin;
  final String area;
  final String distance;
  final ImageProvider avatar;
  final ImageProvider? cover;
}

/// Badge de démonstration sur un produit.
enum DemoBadge { none, promo20, arrivage }

/// Produit de démonstration (prix saisi en F CFA).
@immutable
class DemoProduct {
  const new({
    required this.id,
    required this.name,
    required this.unit,
    required this.priceXof,
    required this.storeId,
    required this.image,
    this.badge = DemoBadge.none,
  });

  final String id;
  final String name;
  final String unit;
  final int priceXof;
  final String storeId;
  final ImageProvider image;
  final DemoBadge badge;
}

/// Libellés d'origine affichés (en production : dym_l10n).
String originLabel(StoreOrigin origin) => switch (origin) {
  StoreOrigin.marche => 'Au marché',
  StoreOrigin.maison => 'Fait maison',
  StoreOrigin.magasin => 'Boutique',
};

abstract final class DemoCatalog {
  static final stores = <String, DemoStore>{
    'akossiwa': DemoStore(
      id: 'akossiwa',
      name: "Étal d'Akossiwa",
      owner: 'Maman Akossiwa',
      origin: StoreOrigin.marche,
      area: 'Bè',
      distance: '400 m',
      avatar: DemoImages.person('akossiwa'),
      cover: DemoImages.store('etal-akossiwa'),
    ),
    'esi': DemoStore(
      id: 'esi',
      name: "Les jus d'Esi",
      owner: 'Esi',
      origin: StoreOrigin.maison,
      area: 'Tokoin',
      distance: '1,1 km',
      avatar: DemoImages.person('esi'),
      cover: DemoImages.store('cour-esi'),
    ),
    'kodjo': DemoStore(
      id: 'kodjo',
      name: 'Alimentation Kodjo',
      owner: 'Kodjo',
      origin: StoreOrigin.magasin,
      area: 'Bè Kpota',
      distance: '800 m',
      avatar: DemoImages.person('kodjo'),
      cover: DemoImages.store('epicerie-kodjo'),
    ),
    'yawa': DemoStore(
      id: 'yawa',
      name: 'Le jardin de Yawa',
      owner: 'Yawa',
      origin: StoreOrigin.maison,
      area: 'Adakpamé',
      distance: '1,8 km',
      avatar: DemoImages.person('yawa'),
    ),
    'dede': DemoStore(
      id: 'dede',
      name: 'Épices de Dédé',
      owner: 'Dédé',
      origin: StoreOrigin.marche,
      area: 'Bè',
      distance: '450 m',
      avatar: DemoImages.person('dede'),
    ),
  };

  static final products = <String, DemoProduct>{
    'tomates': DemoProduct(
      id: 'tomates',
      name: 'Tomates fraîches',
      unit: 'le tas',
      priceXof: 500,
      storeId: 'akossiwa',
      image: DemoImages.product('tomates'),
    ),
    'gombo': DemoProduct(
      id: 'gombo',
      name: 'Gombo frais',
      unit: 'le tas',
      priceXof: 300,
      storeId: 'akossiwa',
      image: DemoImages.product('gombo'),
    ),
    'piment': DemoProduct(
      id: 'piment',
      name: 'Piment rouge',
      unit: 'le tas',
      priceXof: 200,
      storeId: 'dede',
      image: DemoImages.product('piment'),
    ),
    'ademe': DemoProduct(
      id: 'ademe',
      name: 'Adémè',
      unit: 'la botte',
      priceXof: 250,
      storeId: 'yawa',
      image: DemoImages.product('ademe'),
    ),
    'oignons': DemoProduct(
      id: 'oignons',
      name: 'Oignons',
      unit: 'le tas',
      priceXof: 400,
      storeId: 'kodjo',
      image: DemoImages.product('oignons'),
      badge: DemoBadge.arrivage,
    ),
    'aubergines': DemoProduct(
      id: 'aubergines',
      name: 'Aubergines locales',
      unit: 'le tas',
      priceXof: 300,
      storeId: 'yawa',
      image: DemoImages.product('aubergines'),
      badge: DemoBadge.promo20,
    ),
    'gari': DemoProduct(
      id: 'gari',
      name: 'Gari',
      unit: 'la boîte',
      priceXof: 600,
      storeId: 'akossiwa',
      image: DemoImages.product('gari'),
    ),
    'huile': DemoProduct(
      id: 'huile',
      name: 'Huile rouge',
      unit: '1 L',
      priceXof: 1200,
      storeId: 'kodjo',
      image: DemoImages.product('huile-rouge'),
    ),
    'bissap': DemoProduct(
      id: 'bissap',
      name: 'Bissap',
      unit: '1 L',
      priceXof: 700,
      storeId: 'esi',
      image: DemoImages.product('bissap'),
    ),
    'gingembre': DemoProduct(
      id: 'gingembre',
      name: 'Gingembre',
      unit: '1 L',
      priceXof: 700,
      storeId: 'esi',
      image: DemoImages.product('gingembre'),
    ),
    'baobab': DemoProduct(
      id: 'baobab',
      name: 'Baobab',
      unit: '1 L',
      priceXof: 800,
      storeId: 'esi',
      image: DemoImages.product('baobab'),
    ),
    'pack-jus': DemoProduct(
      id: 'pack-jus',
      name: 'Pack 4 jus',
      unit: '4 × 1 L',
      priceXof: 2600,
      storeId: 'esi',
      image: DemoImages.product('pack-jus'),
    ),
  };

  static DemoStore storeOf(DemoProduct p) => stores[p.storeId]!;
}
