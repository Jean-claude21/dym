import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/content/product_videos.dart';
import 'package:dym_client/features/content/report_sheet.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/discovery_viewmodels.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_client/features/favorites/favorites_service.dart';
import 'package:dym_client/features/favorites/favorites_views.dart';
import 'package:dym_client/features/haggle/haggle_sheet.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Écran 28 : fiche produit (photos, boutique, prix, variantes, délai).
class ProductPageView extends StackedView<ProductPageViewModel> {
  const new({
    required this.service,
    required this.productId,
    required this.onBack,
    required this.onOpenStore,
    super.key,
    this.onAsk,
    this.content,
    this.onVideos,
    this.favorites,
    this.haggle,
    this.onOpenProduct,
  });

  /// Ouvre un autre produit (« De la même boutique ») ; absent : la boutique.
  final ValueChanged<String>? onOpenProduct;

  /// Marchandage (spec 050) ; absent : bouton masqué.
  final HaggleService? haggle;

  /// Vidéos et signalement (spec 020) ; absent : rien n'est proposé.
  final ContentService? content;

  /// Vidéos qui montrent ce produit (C-CAT-12).
  final ValueChanged<String>? onVideos;

  final DiscoveryService service;
  final String productId;
  final VoidCallback onBack;

  /// Cœur du produit (spec 030) ; absent : masqué.
  final FavoritesService? favorites;
  final ValueChanged<String> onOpenStore;

  /// Poser une question à la boutique sur ce produit (spec 015).
  final void Function(String storeId, String productId)? onAsk;

  @override
  ProductPageViewModel viewModelBuilder(BuildContext context) =>
      ProductPageViewModel(service: service, productId: productId);

  @override
  void onViewModelReady(ProductPageViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    ProductPageViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final vm = viewModel;
    final page = vm.page;
    final back = PhotoButton(
      icon: Icons.arrow_back_rounded,
      tooltip: l10n.authBack,
      onPressed: onBack,
    );
    final heart = switch (favorites) {
      final f? => FavoriteButton(
        service: f,
        kind: FavoriteKind.product,
        id: productId,
      ),
      null => null,
    };
    if (!vm.ready || page == null) {
      return Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Stack(
            children: [
              DiscoveryState(
                failure: vm.isBusy ? null : vm.failure,
                onRetry: vm.load,
                goneMessage: l10n.productUnavailableTitle,
              ),
              Positioned(top: 8, left: 8, child: back),
              if (heart != null) Positioned(top: 8, right: 8, child: heart),
            ],
          ),
        ),
      );
    }
    final item = page.item;
    final store = page.store;
    final origin = originOf(store.origin);
    final price = moneyOf(vm.config, vm.priceMinor);
    final unit = item.unitLabel?.resolve(locale);
    final photos = page.photoKeys.isEmpty
        ? [storeFallback(store.origin)]
        : [for (final k in page.photoKeys) vm.service.photo(k)];
    final showVariants =
        page.variants.length > 1 ||
        (page.variants.length == 1 && page.variants.first.label != null);
    final delivery = page.zoneName == null
        ? l10n.productDeliveryEstimateShort(store.deliveryMinutes)
        : l10n.productDeliveryEstimate(store.deliveryMinutes, page.zoneName!);
    final variantId = vm.variant?.id;
    final canAdd = CartScope.maybeOf(context) != null && variantId != null;
    final top = MediaQuery.paddingOf(context).top;
    final storeLine = [
      store.name,
      if (origin != null) originLabel(vm.config, store.origin, locale),
      store.zoneName,
    ].join(' · ');
    final storePhoto = store.coverKey == null
        ? storeFallback(store.origin)
        : vm.service.photo(store.coverKey!);
    Widget info(IconData icon, String text, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s2 + 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? c.brandDeep),
          const SizedBox(width: DymTokenSpace.s3),
          Expanded(
            child: Text(
              text,
              style: t.body.copyWith(color: color ?? c.textPrimary),
            ),
          ),
        ],
      ),
    );
    final infos = <Widget>[
      if (page.servesZone)
        info(Icons.local_shipping_outlined, delivery)
      else if (page.zoneName != null)
        info(
          Icons.local_shipping_outlined,
          l10n.productNotServed(page.zoneName!),
          color: c.pimentStrong,
        ),
      if (!store.openNow)
        info(
          Icons.schedule_outlined,
          l10n.productStoreClosed,
          color: c.pimentStrong,
        ),
      if (item.arrivalOn case final arrival?)
        info(
          Icons.event_available_outlined,
          l10n.productArrivalBadge(
            MaterialLocalizations.of(context).formatMediumDate(arrival),
          ),
        ),
      if (vm.available)
        info(Icons.check_rounded, l10n.productInStock)
      else
        info(
          Icons.remove_shopping_cart_outlined,
          l10n.productOutOfStock,
          color: c.pimentStrong,
        ),
    ];
    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: canAdd
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: c.card,
                border: Border(top: BorderSide(color: c.hairline)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DymContentWidth.form(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        child: Row(
                          children: [
                            DymQuantityStepper(
                              quantity: vm.quantity,
                              min: 1,
                              decreaseLabel: l10n.productStockDecrease,
                              increaseLabel: l10n.productStockIncrease,
                              onChanged: vm.setQuantity,
                            ),
                            const SizedBox(width: DymTokenSpace.s3),
                            Expanded(
                              child: DymButton(
                                // Prix unitaire de la base, seulement pour 1.
                                label: price != null && vm.quantity == 1
                                    ? l10n.productAddPrice(price.format())
                                    : l10n.cartAdd,
                                icon: Icons.shopping_basket_outlined,
                                onPressed: vm.available
                                    ? () => addToCart(
                                        context,
                                        variantId,
                                        quantity: vm.quantity,
                                        confirm: true,
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, box) {
          final inset = DymLayout.sideInset(
            box.maxWidth,
            gutter: DymLayout.gutter(context),
            maxWidth: DymTokenLayout.formMax,
          );
          final photoSize = (box.maxWidth - inset * 2 + 32).clamp(
            0.0,
            box.maxWidth,
          );
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // Photo pleine largeur sur menthe (planche 08).
              Center(
                child: SizedBox(
                  width: photoSize,
                  height: (photoSize * 0.9).clamp(0.0, 460.0),
                  child: ColoredBox(
                    color: c.tintVertTendre,
                    child: Stack(
                      children: [
                        PageView(
                          onPageChanged: vm.showPhoto,
                          children: [
                            for (final (i, photo) in photos.indexed)
                              Semantics(
                                label: l10n.productPhotoPosition(
                                  i + 1,
                                  photos.length,
                                ),
                                child: Image(
                                  image: photo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Center(
                                    child: Icon(
                                      Icons.eco_outlined,
                                      size: 64,
                                      color: c.brandDeep,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Positioned(top: top + 8, left: 12, child: back),
                        if (heart != null)
                          Positioned(top: top + 8, right: 12, child: heart),
                        if (photos.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: ExcludeSemantics(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var i = 0; i < photos.length; i++)
                                    Container(
                                      width: i == vm.photoIndex ? 18 : 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        color: i == vm.photoIndex
                                            ? c.card
                                            : c.card.withValues(alpha: 0.6),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(inset, 12, inset, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Boutique en une ligne cliquable.
                    InkWell(
                      onTap: () => onOpenStore(store.id),
                      borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Row(
                          children: [
                            ClipOval(
                              child: Image(
                                image: storePhoto,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                excludeFromSemantics: true,
                                errorBuilder: (_, _, _) => Container(
                                  width: 32,
                                  height: 32,
                                  color: c.tintVertTendre,
                                ),
                              ),
                            ),
                            const SizedBox(width: DymTokenSpace.s2),
                            Expanded(
                              child: Text(
                                storeLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.label.copyWith(
                                  color: c.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: c.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Semantics(
                      header: true,
                      child: Text(item.name, style: t.display),
                    ),
                    if (price != null) ...[
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          text: price.format(),
                          style: t.display.copyWith(
                            fontSize: 26,
                            color: c.brandDeep,
                          ),
                          children: [
                            if (unit != null)
                              TextSpan(
                                text: '  $unit',
                                style: t.body.copyWith(
                                  fontSize: 16,
                                  color: c.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (haggle case final haggle?
                        when page.canHaggle &&
                            canAdd &&
                            vm.available &&
                            vm.config != null &&
                            vm.priceMinor != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => showHaggleSheet(
                            context,
                            service: haggle,
                            config: vm.config!,
                            variantId: variantId,
                            quantity: vm.quantity,
                            productName: item.name,
                            priceMinor: vm.priceMinor!,
                          ),
                          icon: const Icon(Icons.handshake_outlined),
                          label: Text(l10n.haggleAction),
                        ),
                      ),
                    if (showVariants) ...[
                      const SizedBox(height: DymTokenSpace.s3),
                      Text(
                        l10n.productFormat,
                        style: t.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: DymTokenSpace.s2),
                      LayoutBuilder(
                        builder: (context, row) {
                          const gap = DymTokenSpace.s2;
                          final columns = row.maxWidth >= 300 ? 2 : 1;
                          final width =
                              (row.maxWidth - gap * (columns - 1)) / columns;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final v in page.variants)
                                SizedBox(
                                  width: width,
                                  child: _VariantTile(
                                    label: [
                                      ?v.label,
                                      vm.config?.money(v.priceMinor).format(),
                                    ].nonNulls.join(' — '),
                                    selected: vm.variant?.id == v.id,
                                    available: v.available,
                                    onTap: () => vm.selectVariant(v.id),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: DymTokenSpace.s3),
                    // Informations en filets, pas en cartes.
                    for (final (i, w) in infos.indexed) ...[
                      if (i > 0) Divider(height: 1, color: c.hairline),
                      w,
                    ],
                    Divider(height: 1, color: c.hairline),
                    if (page.description != null) ...[
                      const SizedBox(height: DymTokenSpace.s3),
                      Text(page.description!, style: t.body),
                    ],
                    const SizedBox(height: DymTokenSpace.s2),
                    Wrap(
                      runSpacing: DymTokenSpace.s2,
                      spacing: DymTokenSpace.s1,
                      children: [
                        if (content case final content?)
                          if (onVideos case final open?)
                            ProductVideosButton(
                              service: content,
                              productId: item.id,
                              onOpen: () => open(item.id),
                            ),
                        if (onAsk case final ask?)
                          TextButton.icon(
                            onPressed: () => ask(store.id, item.id),
                            icon: const Icon(Icons.chat_bubble_outline_rounded),
                            label: Text(l10n.chatAskProduct),
                          ),
                        if (content case final content?)
                          TextButton.icon(
                            onPressed: () async {
                              final reason = await showReportSheet(context);
                              if (reason != null) {
                                await content.report(
                                  ReportTarget.product,
                                  item.id,
                                  reason,
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: c.textSecondary,
                            ),
                            icon: const Icon(Icons.flag_outlined),
                            label: Text(l10n.reportAction),
                          ),
                      ],
                    ),
                    if (vm.related.isNotEmpty) ...[
                      const SizedBox(height: DymTokenSpace.s4),
                      Text(
                        l10n.productSameStore,
                        style: t.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      ProductList(
                        items: vm.related,
                        service: vm.service,
                        config: vm.config,
                        onOpen: onOpenProduct ?? (_) => onOpenStore(store.id),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Format sélectionnable (planche 08) : filet, vert et menthe une fois choisi.
class _VariantTile extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.available,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.tintVertTendre : c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DymTokenRadius.button),
          side: BorderSide(
            color: selected ? c.brand : c.lineStrong,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DymTokenRadius.button),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: context.dym.text.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: available ? c.textPrimary : c.textSecondary,
                    decoration: available ? null : TextDecoration.lineThrough,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
