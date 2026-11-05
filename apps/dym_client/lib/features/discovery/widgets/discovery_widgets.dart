import 'dart:async';

import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Origine du design system pour un code du référentiel.
StoreOrigin? originOf(String? code) =>
    StoreOrigin.values.where((o) => o.name == code).firstOrNull;

/// Libellé d'une origine (référentiel du pays).
String originLabel(CountryConfig? config, String? code, String locale) =>
    config?.storeOrigins
        .where((o) => o.code == code)
        .firstOrNull
        ?.label
        .resolve(locale) ??
    '';

/// Montant dans la devise d'un élément.
Money? moneyOf(CountryConfig? config, int? amountMinor) =>
    config == null || amountMinor == null ? null : config.money(amountMinor);

/// Illustration de repli d'une boutique sans photo.
ImageProvider storeFallback(String? origin) =>
    DymIllustrations.origin(origin) ?? DymIllustrations.storeOpened;

/// « Tokoin · Ouvert jusqu'à 19:00 » / « Tokoin · Fermé ».
String storeMeta(BuildContext context, PublicStore store) {
  final l10n = DymLocalizations.of(context);
  final status = !store.openNow
      ? l10n.storeClosedNow
      : store.closesAt == null
      ? l10n.storeOpenNow
      : l10n.storeOpenUntil(store.closesAt!);
  return l10n.placeAndMeta(store.zoneName, status);
}

/// Teintes des tuiles, en rotation (tokens `color.tint.*`).
List<Color> tileTints(DymColors c) => [
  c.tintVertTendre,
  c.tintPlantainClair,
  c.tintPeche,
  c.tintPimentClair,
  c.tintIndigoClair,
];

/// Carte d'une boutique (accueil, recherche).
class StoreTile extends StatelessWidget {
  const new({
    required this.store,
    required this.service,
    required this.config,
    required this.onTap,
    super.key,
    this.width = 200,
  });

  final PublicStore store;
  final DiscoveryService service;
  final CountryConfig? config;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final origin = originOf(store.origin) ?? StoreOrigin.marche;
    final fallback = storeFallback(store.origin);
    return DymStoreCard(
      cover: store.coverKey == null ? fallback : service.photo(store.coverKey!),
      avatar: fallback,
      name: store.name,
      origin: origin,
      originLabel: originLabel(config, store.origin, locale),
      meta: storeMeta(context, store),
      width: width,
      onTap: onTap,
    );
  }
}

/// Carte produit d'une grille (rayon, page boutique).
class ProductTile extends StatelessWidget {
  const new({
    required this.item,
    required this.service,
    required this.config,
    required this.onTap,
    super.key,
    this.tint,
    this.showStore = true,
  });

  final CatalogItem item;
  final DiscoveryService service;
  final CountryConfig? config;
  final VoidCallback onTap;
  final Color? tint;
  final bool showStore;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final price = moneyOf(config, item.displayPriceMinor);
    final unit = item.unitLabel?.resolve(locale) ?? '';
    final cart = CartScope.maybeOf(context);
    if (cart == null || !item.available) return _card(context, price, unit, 0);
    return ValueListenableBuilder(
      valueListenable: cart.service.cart,
      builder: (context, view, _) {
        // « + » ajoute toujours directement (première variante) ; toucher la
        // carte ouvre la fiche pour choisir une autre variante.
        final variant = item.defaultVariantId;
        return _card(
          context,
          price,
          unit,
          cartQuantityOf(view, variant),
          onQuantity: (q) {
            if (variant == null) {
              onTap(); // variante inconnue : choix sur la fiche
            } else if (cartQuantityOf(view, variant) == 0) {
              unawaited(addToCart(context, variant, quantity: q));
            } else {
              unawaited(cart.service.setQuantity(variant, q));
            }
          },
        );
      },
    );
  }

  Widget _card(
    BuildContext context,
    Money? price,
    String unit,
    int quantity, {
    ValueChanged<int>? onQuantity,
  }) {
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final origin = originOf(item.store.origin);
    return DymProductCard(
      quantity: quantity,
      onQuantityChanged: onQuantity,
      addLabel: l10n.cartAddShort,
      image: item.photoKey == null
          ? storeFallback(item.store.origin)
          : service.photo(item.photoKey!),
      name: item.name,
      unit: item.variantCount > 1 && price != null
          ? l10n.productFrom(price.format())
          : unit,
      price: price ?? Money.zero(config!.currency),
      tint: tint,
      onTap: onTap,
      badge: item.available
          ? null
          : DymPromoBadge(label: l10n.productOutOfStock),
      store: !showStore || origin == null
          ? null
          : DymProductStore(
              name: item.store.name,
              origin: origin,
              originLabel: originLabel(config, item.store.origin, locale),
              avatar: storeFallback(item.store.origin),
            ),
    );
  }
}

/// Grille responsive de cartes produit.
class ProductGrid extends StatelessWidget {
  const new({
    required this.items,
    required this.service,
    required this.config,
    required this.onOpen,
    super.key,
    this.showStore = true,
  });

  final List<CatalogItem> items;
  final DiscoveryService service;
  final CountryConfig? config;
  final ValueChanged<String> onOpen;
  final bool showStore;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final tints = tileTints(c);
    return LayoutBuilder(
      builder: (context, box) {
        const spacing = DymTokenSpace.s3;
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = DymLayout.columns(
          box.maxWidth,
          minTileWidth: 160 * scale,
          spacing: spacing,
          max: 5,
        );
        final width = (box.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final (i, item) in items.indexed)
              SizedBox(
                width: width,
                child: ProductTile(
                  item: item,
                  service: service,
                  config: config,
                  tint: tints[i % tints.length],
                  showStore: showStore,
                  onTap: () => onOpen(item.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Chargement, échec ou hors ligne d'un écran de découverte.
class DiscoveryState extends StatelessWidget {
  const new({
    required this.failure,
    required this.onRetry,
    super.key,
    this.goneMessage,
  });

  final Failure? failure;
  final VoidCallback onRetry;

  /// Message si la ressource n'existe plus (`NotFoundFailure`).
  final String? goneMessage;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final current = failure;
    if (current == null) {
      return Center(
        child: Semantics(
          label: l10n.startupPreparing,
          child: CircularProgressIndicator(color: c.brand),
        ),
      );
    }
    if (current is NotFoundFailure && goneMessage != null) {
      return DymStateView(
        kind: DymStateKind.empty,
        title: goneMessage!,
        message: '',
      );
    }
    final offline = current is NetworkFailure;
    return DymStateView(
      kind: offline ? DymStateKind.offline : DymStateKind.error,
      title: offline ? l10n.errorOffline : l10n.errorGeneric,
      message: l10n.storeSaveError,
      actionLabel: l10n.retry,
      onAction: onRetry,
    );
  }
}

/// Bouton rond blanc posé sur une photo (retour).
class PhotoButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Material(
      color: c.card,
      shape: const CircleBorder(),
      elevation: 1,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: c.textPrimary),
      ),
    );
  }
}
