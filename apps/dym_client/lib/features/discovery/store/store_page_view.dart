import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/discovery_viewmodels.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_client/features/favorites/favorites_service.dart';
import 'package:dym_client/features/favorites/favorites_views.dart';
import 'package:dym_client/features/reviews/review_views.dart';
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
    return Scaffold(
      backgroundColor: c.background,
      body: LayoutBuilder(
        builder: (context, box) {
          final inset = DymLayout.sideInset(
            box.maxWidth,
            gutter: DymLayout.gutter(context),
          );
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Image(
                      image: store.coverKey == null
                          ? fallback
                          : vm.service.photo(store.coverKey!),
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 8,
                    left: 12,
                    child: PhotoButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: l10n.authBack,
                      onPressed: onBack,
                    ),
                  ),
                  if (favorites case final f?)
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      right: 12,
                      child: FavoriteButton(
                        service: f,
                        kind: FavoriteKind.store,
                        id: storeId,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(inset, 16, inset, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        DymAvatar(image: fallback, size: 72),
                        const SizedBox(width: DymTokenSpace.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  store.name,
                                  style: t.display.copyWith(fontSize: 28),
                                ),
                              ),
                              if (origin != null) ...[
                                const SizedBox(height: DymTokenSpace.s1),
                                DymOriginBadge(
                                  origin: origin,
                                  label: originLabel(
                                    vm.config,
                                    store.origin,
                                    locale,
                                  ),
                                ),
                              ],
                              const SizedBox(height: DymTokenSpace.s1),
                              Text(
                                storeMeta(context, store),
                                style: t.body.copyWith(color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (onReviews case final reviews?) ...[
                      const SizedBox(height: DymTokenSpace.s2),
                      StoreRatingRow(store: store, onTap: reviews),
                    ],
                    if (store.description != null) ...[
                      const SizedBox(height: DymTokenSpace.s3),
                      Text(store.description!, style: t.body),
                    ],
                    if (onMessage case final message?) ...[
                      const SizedBox(height: DymTokenSpace.s3),
                      DymButton(
                        label: l10n.chatWriteToStore,
                        icon: Icons.chat_bubble_rounded,
                        variant: DymButtonVariant.secondary,
                        onPressed: message,
                      ),
                    ],
                    if (store.offersPickup) ...[
                      const SizedBox(height: DymTokenSpace.s3),
                      Container(
                        padding: const EdgeInsets.all(DymTokenSpace.s3),
                        decoration: BoxDecoration(
                          color: c.tintVertTendre,
                          borderRadius: BorderRadius.circular(
                            DymTokenRadius.tile,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_rounded, color: c.brandDeep),
                            const SizedBox(width: DymTokenSpace.s2),
                            Expanded(
                              child: Text(
                                l10n.storePagePickupNote(store.zoneName),
                                style: t.label.copyWith(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: DymTokenSpace.s4),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.storePageProducts,
                        style: t.title.copyWith(fontSize: 24),
                      ),
                    ),
                    if (page.categories.isNotEmpty) ...[
                      const SizedBox(height: DymTokenSpace.s2),
                      Wrap(
                        spacing: DymTokenSpace.s2,
                        children: [
                          DymFilterChip(
                            label: l10n.productsAll,
                            selected: vm.category == null,
                            onTap: () => vm.selectCategory(null),
                          ),
                          for (final category in page.categories)
                            DymFilterChip(
                              label: category.name,
                              selected: vm.category == category.id,
                              onTap: () => vm.selectCategory(category.id),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: DymTokenSpace.s3),
                    if (vm.products.isEmpty)
                      Text(
                        l10n.storePageEmpty,
                        style: t.body.copyWith(color: c.textSecondary),
                      )
                    else
                      ProductGrid(
                        items: vm.products,
                        service: vm.service,
                        config: vm.config,
                        showStore: false,
                        onOpen: onOpenProduct,
                      ),
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
