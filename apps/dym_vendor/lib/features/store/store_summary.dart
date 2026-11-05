import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/widgets.dart';

/// Libellés d'une boutique résolus avec le référentiel du pays.
class StoreSummary {
  new(this.store, this.config, this.locale);

  final MyStore store;
  final CountryConfig config;
  final String locale;

  String? get zoneName =>
      config.zones.where((z) => z.id == store.zoneId).firstOrNull?.name;

  String? get originLabel => config.storeOrigins
      .where((o) => o.code == store.origin)
      .firstOrNull
      ?.label
      .resolve(locale);

  /// Origine du design system (badge), si le code est connu.
  StoreOrigin? get origin =>
      StoreOrigin.values.where((o) => o.name == store.origin).firstOrNull;

  /// Moyens de paiement acceptés, dans l'ordre du référentiel.
  String get paymentLabels => [
    for (final method in config.paymentMethods)
      if (store.paymentMethodIds.contains(method.id))
        method.label.resolve(locale),
  ].join(', ');

  int get deliveryZoneCount => store.deliveryZoneIds.length;

  /// Initiale du nom (avatar sans photo).
  String get initial {
    final name = store.name.trim();
    return name.isEmpty ? '' : name.characters.first.toUpperCase();
  }
}
