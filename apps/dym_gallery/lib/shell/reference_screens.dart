import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/screens/s01_splash.dart';
import 'package:dym_gallery/screens/s02_home.dart';
import 'package:dym_gallery/screens/s03_aisle.dart';
import 'package:dym_gallery/screens/s04_store.dart';
import 'package:dym_gallery/screens/s05_cart.dart';
import 'package:dym_gallery/screens/s06_tracking.dart';
import 'package:dym_gallery/screens/s07_seller_origin.dart';
import 'package:dym_gallery/screens/s08_seller_new_order.dart';
import 'package:flutter/widgets.dart';

/// Écran validé et sa reproduction avec dym_ui.
@immutable
class ReferenceScreen {
  const new({
    required this.id,
    required this.title,
    required this.surface,
    required this.referenceFile,
    required this.builder,
  });

  final String id;
  final String title;
  final String surface;
  final String referenceFile;
  final Widget Function(DemoCountry country) builder;
}

final referenceScreens = <ReferenceScreen>[
  ReferenceScreen(
    id: '01',
    title: 'Splash',
    surface: 'Cliente',
    referenceFile: '01-splash.webp',
    builder: (c) => SplashScreen(country: c),
  ),
  ReferenceScreen(
    id: '02',
    title: 'Accueil',
    surface: 'Cliente',
    referenceFile: '02-accueil.webp',
    builder: (c) => HomeScreen(country: c),
  ),
  ReferenceScreen(
    id: '03',
    title: 'Rayon Légumes',
    surface: 'Cliente',
    referenceFile: '03-rayon-legumes.webp',
    builder: (c) => AisleScreen(country: c),
  ),
  ReferenceScreen(
    id: '04',
    title: "Page boutique · Les jus d'Esi",
    surface: 'Cliente',
    referenceFile: '04-page-boutique.webp',
    builder: (c) => StoreScreen(country: c),
  ),
  ReferenceScreen(
    id: '05',
    title: 'Panier multi-boutiques',
    surface: 'Cliente',
    referenceFile: '05-panier.webp',
    builder: (c) => CartScreen(country: c),
  ),
  ReferenceScreen(
    id: '06',
    title: 'Suivi de livraison',
    surface: 'Cliente',
    referenceFile: '06-suivi.webp',
    builder: (c) => TrackingScreen(country: c),
  ),
  ReferenceScreen(
    id: '07',
    title: 'Où vends-tu ?',
    surface: 'Vendeuse',
    referenceFile: '07-vendeuse-ou-vends-tu.webp',
    builder: (c) => SellerOriginScreen(country: c),
  ),
  ReferenceScreen(
    id: '08',
    title: 'Commande reçue',
    surface: 'Vendeuse',
    referenceFile: '08-vendeuse-commande-recue.webp',
    builder: (c) => SellerNewOrderScreen(country: c),
  ),
];
