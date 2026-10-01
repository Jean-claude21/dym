import 'package:dym_core/dym_core.dart';
import 'package:dym_gallery/demo/demo_catalog.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:flutter/foundation.dart';

/// Panier de démonstration interactif (écran Rayon).
class DemoCart extends ChangeNotifier {
  new([Map<String, int>? initial]) : _lines = {...?initial};

  final Map<String, int> _lines;

  int quantityOf(String productId) => _lines[productId] ?? 0;

  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      _lines.remove(productId);
    } else {
      _lines[productId] = quantity;
    }
    notifyListeners();
  }

  int get itemCount => _lines.values.fold(0, (a, b) => a + b);

  int get storeCount =>
      _lines.keys.map((id) => DemoCatalog.products[id]!.storeId).toSet().length;

  Money total(DemoCountry country) => _lines.entries.fold(
    Money.zero(country.currency),
    (sum, e) =>
        sum + country.price(DemoCatalog.products[e.key]!.priceXof) * e.value,
  );

  /// « 4 articles · 2 boutiques · 1 500 F CFA »
  String summary(DemoCountry country) {
    final items = itemCount;
    final stores = storeCount;
    return '$items article${items > 1 ? 's' : ''} · '
        '$stores boutique${stores > 1 ? 's' : ''} · '
        '${total(country).format()}';
  }
}
