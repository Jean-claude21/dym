import 'package:flutter/widgets.dart';

/// Images de démonstration générées avec ChatGPT (gpt-image-2) via Codex.
abstract final class DemoImages {
  static AssetImage product(String name) =>
      AssetImage('assets/demo/products/$name.webp');
  static AssetImage aisle(String name) =>
      AssetImage('assets/demo/aisles/$name.webp');
  static AssetImage person(String name) =>
      AssetImage('assets/demo/people/$name.webp');
  static AssetImage store(String name) =>
      AssetImage('assets/demo/stores/$name.webp');
  static AssetImage illustration(String name) =>
      AssetImage('assets/demo/illustrations/$name.webp');

  static final AssetImage rider = illustration('livreur');
  static final AssetImage basket = illustration('panier');
  static final AssetImage splashBasin = illustration('splash-bassine');
  static final AssetImage kente = illustration('kente');
  static final AssetImage map = illustration('carte-ville');
}

/// Écrans validés (docs/design/screens) copiés pour le mode « Comparer ».
abstract final class ReferenceImages {
  static AssetImage of(String file) => AssetImage('assets/reference/$file');
}
