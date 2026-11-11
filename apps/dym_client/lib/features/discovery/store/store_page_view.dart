import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
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

/// Écran 04 : page boutique.
class StorePageView extends StackedView<StorePageViewModel> {
  const new({
    required this.service,
    required this.storeId,
    required this.onBack,
    required this.onOpenProduct,
    super.key,
    this.onMessage,
    this.onReviews,
    this.favorites,
  });

  final DiscoveryService service;
  final String storeId;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenProduct;

  /// Écrire à la boutique (spec 015) ; nul : non proposé.
  final VoidCallback? onMessage;

  /// Avis de la boutique (écran 64).
  final VoidCallback? onReviews;

  /// Cœur de la boutique (spec 030) ; absent : masqué.
  final FavoritesService? favorites;

  @override
  StorePageViewModel viewModelBuilder(BuildContext context) =>
      StorePageViewModel(service: service, storeId: storeId);

  @override
  void onViewModelReady(StorePageViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    StorePageViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final vm = viewModel;
    final page = vm.page;
    if (!vm.ready || page == null) {
      return Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Stack(
            children: [
              DiscoveryState(
                failure: vm.isBusy ? null : vm.failure,
                onRetry: vm.load,
                goneMessage: l10n.storePageUnavailable,
              ),
              Positioned(
                top: 8,
                left: 8,
                child: PhotoButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: l10n.authBack,
                  onPressed: onBack,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final store = page.store;
    final origin = originOf(store.origin);
    final fallback = storeFallback(store.origin);
    final cover = store.coverKey == null
        ? fallback
        : vm.service.photo(store.coverKey!);
    final top = MediaQuery.paddingOf(context).top;
    final rating = store.rating;
    return Scaffold(
      backgroundColor: c.background,
      body: WithMiniCart(
        child: LayoutBuilder(
          builder: (context, box) {
            final inset = DymLayout.sideInset(
              box.maxWidth,
              gutter: DymLayout.gutter(context),
            );
            final coverHeight = (box.maxWidth * 9 / 16).clamp(180.0, 320.0);
            return ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                // Couverture : la vendeuse et son étal ; photo ronde qui
                // déborde (planche 09).
                SizedBox(
                  height: coverHeight + 36,
                  child: Stack(
                    children: [
                      SizedBox(
                        height: coverHeight,
                        width: double.infinity,
                        child: Image(
                          image: cover,
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) =>
                              ColoredBox(color: c.tintVertTendre),
                        ),
                      ),
                      Positioned(
                        top: top + 8,
                        left: 12,
                        child: PhotoButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: l10n.authBack,
                          onPressed: onBack,
                        ),
                      ),
                      if (favorites case final f?)
                        Positioned(
                          top: top + 8,
                          right: 12,
                          child: FavoriteButton(
                            service: f,
                            kind: FavoriteKind.store,
                            id: storeId,
                          ),
                        ),
                      Positioned(
                        left: inset,
                        bottom: 0,
                        child: Container(
                          width: 76,
                          height: 76,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: c.background,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image(
                              image: cover,
                              fit: BoxFit.cover,
                              excludeFromSemantics: true,
                              errorBuilder: (_, _, _) => ColoredBox(
                                color: c.tintVertTendre,
                                child: Icon(
                                  Icons.storefront_outlined,
                                  color: c.brandDeep,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(inset, 8, inset, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: DymTokenSpace.s2,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              store.name,
                              style: t.display.copyWith(fontSize: 26),
                            ),
                          ),
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
                        ],
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: onReviews,
                        child: Text.rich(
                          TextSpan(
                            style: t.label.copyWith(
                              color: store.openNow
                                  ? c.textSecondary
                                  : c.pimentStrong,
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(text: storeMeta(context, store)),
                              if (rating != null) ...[
                                const TextSpan(text: '  ·  '),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: c.plantain,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      ' ${rating.toStringAsFixed(1)} '
                                      '(${store.reviewCount})',
                                  style: TextStyle(color: c.textPrimary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: DymTokenSpace.s3),
                      _Facts(store: store),
                      if (store.offersPickup) ...[
                        const SizedBox(height: DymTokenSpace.s2),
                        // Fait maison : l'adresse n'est jamais publique.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: c.textSecondary,
                            ),
                            const SizedBox(width: DymTokenSpace.s2),
                            Expanded(
                              child: Text(
                                l10n.storePagePickupNote(store.zoneName),
                                style: t.label.copyWith(
                                  color: c.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (store.description != null) ...[
                        const SizedBox(height: DymTokenSpace.s3),
                        Text(
                          store.description!,
                          style: t.body.copyWith(color: c.textSecondary),
                        ),
                      ],
                      if (onMessage != null || onReviews != null) ...[
                        const SizedBox(height: DymTokenSpace.s3),
                        Row(
                          children: [
                            if (onMessage case final message?)
                              Expanded(
                                child: DymButton(
                                  label: l10n.chatWriteToStore,
                                  icon: Icons.chat_bubble_outline_rounded,
                                  variant: DymButtonVariant.secondary,
                                  compact: true,
                                  onPressed: message,
                                ),
                              ),
                            if (onMessage != null && onReviews != null)
                              const SizedBox(width: DymTokenSpace.s2),
                            if (onReviews case final reviews?)
                              Expanded(
                                child: DymButton(
                                  label: l10n.reviewCount(store.reviewCount),
                                  icon: Icons.star_outline_rounded,
                                  variant: DymButtonVariant.secondary,
                                  compact: true,
                                  onPressed: reviews,
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: DymTokenSpace.s4),
                      if (page.categories.isNotEmpty)
                        SizedBox(
                          height: 48,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final (id, label) in [
                                (null, l10n.productsAll),
                                for (final cat in page.categories)
                                  (cat.id, cat.name),
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Center(
                                    child: DymFilterChip(
                                      label: label,
                                      selected: vm.category == id,
                                      onTap: () => vm.selectCategory(id),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      else
                        Semantics(
                          header: true,
                          child: Text(l10n.storePageProducts, style: t.title),
                        ),
                      const SizedBox(height: DymTokenSpace.s1),
                      if (vm.products.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            l10n.storePageEmpty,
                            style: t.body.copyWith(color: c.textSecondary),
                          ),
                        )
                      else
                        ProductList(
                          items: vm.products,
                          service: vm.service,
                          config: vm.config,
                          onOpen: onOpenProduct,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Délai, livraison ou retrait : trois faits séparés par des filets.
class _Facts extends StatelessWidget {
  const new({required this.store});

  final PublicStore store;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final facts = [
      (Icons.schedule_outlined, l10n.storeFactMinutes(store.deliveryMinutes)),
      (Icons.delivery_dining_outlined, l10n.storeFactDelivery),
      if (store.offersPickup) (Icons.storefront_outlined, l10n.storeFactPickup),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s2),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: c.hairline)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final (i, (icon, label)) in facts.indexed) ...[
              if (i > 0) VerticalDivider(width: 1, color: c.hairline),
              Expanded(
                child: Column(
                  children: [
                    Icon(icon, color: c.brandDeep, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: t.label.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
