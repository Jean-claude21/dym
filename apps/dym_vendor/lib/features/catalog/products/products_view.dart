import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:dym_vendor/features/catalog/products/products_viewmodel.dart';
import 'package:dym_vendor/features/store/widgets/store_widgets.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Écran 24 : « Mes produits ».
class ProductsView extends StackedView<ProductsViewModel> {
  const new({
    required this.service,
    required this.onEdit,
    required this.onCategories,
    super.key,
  });

  final CatalogService service;
  final Future<void> Function(Product? product) onEdit;
  final Future<void> Function() onCategories;

  @override
  ProductsViewModel viewModelBuilder(BuildContext context) => ProductsViewModel(
    service: service,
    onEdit: onEdit,
    onCategories: onCategories,
  );

  @override
  void onViewModelReady(ProductsViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    ProductsViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    if (!viewModel.ready) {
      return SafeArea(
        child: viewModel.loadFailure == null
            ? Center(
                child: Semantics(
                  label: l10n.startupPreparing,
                  child: CircularProgressIndicator(color: c.brand),
                ),
              )
            : DymStateView(
                kind: viewModel.offline
                    ? DymStateKind.offline
                    : DymStateKind.error,
                title: viewModel.offline
                    ? l10n.errorOffline
                    : l10n.errorGeneric,
                message: l10n.storeSaveError,
                actionLabel: l10n.retry,
                onAction: viewModel.load,
              ),
      );
    }
    final add = DymContentWidth.form(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          DymLayout.gutter(context),
          4,
          DymLayout.gutter(context),
          12,
        ),
        child: DymButton(
          label: l10n.productsAdd,
          icon: Icons.add_circle_rounded,
          variant: DymButtonVariant.plantain,
          onPressed: viewModel.add,
        ),
      ),
    );
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: viewModel.isEmpty && !viewModel.showArchived
                ? _Header(
                    viewModel: viewModel,
                    child: DymStateView(
                      kind: DymStateKind.empty,
                      title: l10n.productsEmpty,
                      message: l10n.productsEmptyHint,
                    ),
                  )
                : _List(viewModel: viewModel),
          ),
          add,
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const new({required this.viewModel, this.child});

  final ProductsViewModel viewModel;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final header = Padding(
      padding: EdgeInsets.symmetric(horizontal: DymLayout.gutter(context)),
      child: DymContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: DymTokenSpace.s3),
            Row(
              children: [
                const SizedBox(width: DymTokenSize.touchMin),
                Expanded(
                  child: Text(
                    l10n.appNameVendor,
                    textAlign: TextAlign.center,
                    style: t.title.copyWith(color: c.brandDeep),
                  ),
                ),
                IconButton(
                  tooltip: l10n.categoriesTitle,
                  onPressed: viewModel.manageCategories,
                  icon: Icon(Icons.sell_rounded, color: c.brandDeep),
                ),
              ],
            ),
            Semantics(
              header: true,
              child: Text(
                l10n.productsTitle,
                textAlign: TextAlign.center,
                style: t.display.copyWith(fontSize: 40, color: c.brandDeep),
              ),
            ),
          ],
        ),
      ),
    );
    if (child == null) return header;
    return Column(
      children: [
        header,
        Expanded(child: child!),
      ],
    );
  }
}

class _List extends StatelessWidget {
  const new({required this.viewModel});

  final ProductsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final products = viewModel.visible;
    return LayoutBuilder(
      builder: (context, box) {
        final gutter = DymLayout.gutter(context);
        final inset = DymLayout.sideInset(box.maxWidth, gutter: gutter);
        const spacing = DymTokenSpace.s3;
        final inner = box.maxWidth - inset * 2;
        final columns = DymLayout.columns(
          inner,
          minTileWidth: 360,
          spacing: spacing,
          max: 2,
        );
        final width = (inner - spacing * (columns - 1)) / columns;
        return ListView(
          padding: const EdgeInsets.only(bottom: DymTokenSpace.s4),
          children: [
            _Header(viewModel: viewModel),
            const SizedBox(height: DymTokenSpace.s3),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: inset),
              child: Row(
                spacing: DymTokenSpace.s2,
                children: [
                  DymFilterChip(
                    label: l10n.productsAll,
                    selected:
                        viewModel.filter == null && !viewModel.showArchived,
                    onTap: () => viewModel.selectFilter(null),
                  ),
                  for (final category in viewModel.categories)
                    DymFilterChip(
                      label: category.name,
                      selected: viewModel.filter == category.id,
                      onTap: () => viewModel.selectFilter(category.id),
                    ),
                  if (viewModel.hasArchived)
                    DymFilterChip(
                      label: l10n.productsArchived,
                      selected: viewModel.showArchived,
                      onTap: viewModel.selectArchived,
                    ),
                ],
              ),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: inset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StoreErrorBanner(failure: viewModel.actionFailure),
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final product in products)
                        SizedBox(
                          width: width,
                          child: _ProductCard(
                            viewModel: viewModel,
                            product: product,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const new({required this.viewModel, required this.product});

  final ProductsViewModel viewModel;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final price = viewModel.price(product);
    final unit = viewModel.unitLabel(product, locale);
    final stock = product.trackedStock;
    final faded = !product.isAvailable || product.isArchived;
    final pending = viewModel.isPending(product.id);
    final photo = product.photoKeys.isEmpty
        ? null
        : viewModel.service.photo(product.photoKeys.first);
    final info = switch (product) {
      Product(isArchived: true) => null,
      Product(status: ProductStatus.draft) => _Badge(
        label: l10n.productDraft,
        background: c.tintPlantainClair,
        foreground: c.textPrimary,
      ),
      Product(isAvailable: false) => _Badge(
        label: l10n.productOutOfStock,
        background: c.tintPimentClair,
        foreground: c.pimentStrong,
      ),
      _ => Text(
        product.variants.length > 1
            ? l10n.productVariantCount(product.variants.length)
            : stock == null
            ? ''
            : l10n.productStockCount(stock),
        style: t.body.copyWith(color: c.textSecondary),
      ),
    };
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(DymTokenRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        onTap: () => viewModel.edit(product),
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s3),
          child: Row(
            children: [
              Opacity(
                opacity: faded ? 0.55 : 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                  child: SizedBox.square(
                    dimension: 88,
                    child: photo == null
                        ? ColoredBox(
                            color: c.tintVertTendre,
                            child: Icon(
                              Icons.photo_camera_rounded,
                              color: c.brandDeep,
                              size: 32,
                            ),
                          )
                        : Image(image: photo, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.title.copyWith(fontSize: 19),
                    ),
                    if (price != null)
                      Text.rich(
                        TextSpan(
                          text: price.format(),
                          style: t.title.copyWith(
                            fontSize: 17,
                            color: c.brandDeep,
                          ),
                          children: [
                            if (unit != null)
                              TextSpan(
                                text: ' · $unit',
                                style: t.body.copyWith(color: c.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ?info,
                  ],
                ),
              ),
              const SizedBox(width: DymTokenSpace.s2),
              if (product.isArchived)
                TextButton(
                  onPressed: pending
                      ? null
                      : () => viewModel.archive(product, archived: false),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: Text(l10n.productRestore),
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      label: '${l10n.productInStock}, ${product.name}',
                      child: Switch(
                        value: product.isAvailable,
                        activeTrackColor: c.brand,
                        onChanged: pending
                            ? null
                            : (value) => viewModel.setAvailable(
                                product,
                                available: value,
                              ),
                      ),
                    ),
                    ExcludeSemantics(
                      child: Text(
                        l10n.productInStock,
                        style: t.label.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const new({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: DymTokenSpace.s1),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
      ),
      child: Text(
        label,
        style: context.dym.text.label.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    ),
  );
}
