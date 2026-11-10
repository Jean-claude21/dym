import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/content/product_videos.dart';
import 'package:dym_client/features/content/report_sheet.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/discovery_viewmodels.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_client/features/favorites/favorites_service.dart';
import 'package:dym_client/features/favorites/favorites_views.dart';
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
  });

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
    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: canAdd
          ? SafeArea(
              // Barre à sa hauteur naturelle (le conteneur de largeur, aligné,
              // prendrait sinon toute la hauteur de l'écran).
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DymContentWidth.form(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                              label: l10n.cartAdd,
                              icon: Icons.add_shopping_cart_rounded,
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
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final inset = DymLayout.sideInset(
              box.maxWidth,
              gutter: DymLayout.gutter(context),
              maxWidth: DymTokenLayout.formMax,
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(inset, 8, inset, 24),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DymTokenRadius.card),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
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
                                child: Image(image: photo, fit: BoxFit.cover),
                              ),
                          ],
                        ),
                        Positioned(top: 8, left: 8, child: back),
                        if (heart != null)
                          Positioned(top: 8, right: 8, child: heart),
                      ],
                    ),
                  ),
                ),
                if (photos.length > 1) ...[
                  const SizedBox(height: DymTokenSpace.s2),
                  ExcludeSemantics(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < photos.length; i++)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == vm.photoIndex
                                  ? c.brand
                                  : c.textSecondary.withValues(alpha: 0.25),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: DymTokenSpace.s3),
                Semantics(
                  header: true,
                  child: Text(
                    item.name,
                    style: t.display.copyWith(fontSize: 30),
                  ),
                ),
                const SizedBox(height: DymTokenSpace.s3),
                if (!store.openNow)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DymTokenSpace.s3),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: c.pimentStrong),
                        const SizedBox(width: DymTokenSpace.s2),
                        Expanded(child: Text(l10n.productStoreClosed)),
                      ],
                    ),
                  ),
                Material(
                  color: c.card,
                  borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                    onTap: () => onOpenStore(store.id),
                    child: Padding(
                      padding: const EdgeInsets.all(DymTokenSpace.s3),
                      child: Row(
                        children: [
                          DymAvatar(
                            image: storeFallback(store.origin),
                            size: 52,
                          ),
                          const SizedBox(width: DymTokenSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.name,
                                  style: t.title.copyWith(fontSize: 18),
                                ),
                                const SizedBox(height: 2),
                                Wrap(
                                  spacing: DymTokenSpace.s2,
                                  runSpacing: DymTokenSpace.s1,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (origin != null)
                                      DymOriginBadge(
                                        origin: origin,
                                        label: originLabel(
                                          vm.config,
                                          store.origin,
                                          locale,
                                        ),
                                        dense: true,
                                      ),
                                    Text(
                                      store.zoneName,
                                      style: t.label.copyWith(
                                        color: c.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
                if (content case final content?)
                  Wrap(
                    spacing: DymTokenSpace.s2,
                    children: [
                      if (onVideos case final open?)
                        ProductVideosButton(
                          service: content,
                          productId: item.id,
                          onOpen: () => open(item.id),
                        ),
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
                        icon: const Icon(Icons.flag_outlined),
                        label: Text(l10n.reportAction),
                      ),
                    ],
                  ),
                if (onAsk case final ask?) ...[
                  const SizedBox(height: DymTokenSpace.s2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => ask(store.id, item.id),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: Text(l10n.chatAskProduct),
                    ),
                  ),
                ],
                const SizedBox(height: DymTokenSpace.s3),
                if (price != null)
                  Text.rich(
                    TextSpan(
                      text: price.format(),
                      style: t.display.copyWith(
                        fontSize: 30,
                        color: c.brandDeep,
                      ),
                      children: [
                        if (unit != null)
                          TextSpan(
                            text: ' · $unit',
                            style: t.body.copyWith(
                              fontSize: 18,
                              color: c.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (showVariants) ...[
                  const SizedBox(height: DymTokenSpace.s3),
                  Text(
                    l10n.productChoose,
                    style: t.title.copyWith(fontSize: 19),
                  ),
                  const SizedBox(height: DymTokenSpace.s2),
                  Wrap(
                    spacing: DymTokenSpace.s2,
                    runSpacing: DymTokenSpace.s1,
                    children: [
                      for (final v in page.variants)
                        DymFilterChip(
                          label: [
                            ?v.label,
                            vm.config?.money(v.priceMinor).format(),
                          ].nonNulls.join(' · '),
                          selected: vm.variant?.id == v.id,
                          onTap: () => vm.selectVariant(v.id),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: DymTokenSpace.s3),
                if (page.servesZone)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DymTokenSpace.s3,
                      vertical: DymTokenSpace.s2,
                    ),
                    decoration: BoxDecoration(
                      color: c.tintVertTendre,
                      borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                    ),
                    child: Row(
                      children: [
                        const Image(
                          image: DymIllustrations.zem,
                          width: 40,
                          height: 40,
                          excludeFromSemantics: true,
                        ),
                        const SizedBox(width: DymTokenSpace.s2),
                        Expanded(
                          child: Text(
                            delivery,
                            style: t.title.copyWith(
                              fontSize: 16,
                              color: c.brandDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (page.zoneName != null)
                  Text(
                    l10n.productNotServed(page.zoneName!),
                    style: t.label.copyWith(color: c.pimentStrong),
                  ),
                const SizedBox(height: DymTokenSpace.s3),
                Row(
                  children: [
                    if (vm.available) ...[
                      Icon(Icons.check_circle_rounded, color: c.brand),
                      const SizedBox(width: DymTokenSpace.s2),
                      Text(
                        l10n.productInStock,
                        style: t.title.copyWith(
                          fontSize: 17,
                          color: c.brandDeep,
                        ),
                      ),
                    ] else
                      DymPromoBadge(label: l10n.productOutOfStock),
                  ],
                ),
                if (page.description != null) ...[
                  const SizedBox(height: DymTokenSpace.s3),
                  Text(page.description!, style: t.body.copyWith(fontSize: 17)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
