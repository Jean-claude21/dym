import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/discovery_viewmodels.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Écran 03 : un rayon (« Légumes »), filtres par origine et sous-rayon.
class AisleView extends StackedView<AisleViewModel> {
  const new({
    required this.service,
    required this.categoryId,
    required this.onBack,
    required this.onSearch,
    required this.onOpenProduct,
    super.key,
  });

  final DiscoveryService service;
  final String categoryId;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final ValueChanged<String> onOpenProduct;

  @override
  AisleViewModel viewModelBuilder(BuildContext context) =>
      AisleViewModel(service: service, categoryId: categoryId);

  @override
  void onViewModelReady(AisleViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    AisleViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final vm = viewModel;
    final title = vm.category?.label.resolve(locale) ?? '';
    final origins = vm.config?.storeOrigins ?? const [];
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: l10n.authBack,
                        onPressed: onBack,
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: c.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: l10n.searchHint,
                        onPressed: onSearch,
                        icon: Icon(Icons.search_rounded, color: c.textPrimary),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                    child: Semantics(
                      header: true,
                      child: Text(title, style: t.display),
                    ),
                  ),
                ],
              ),
            ),
            // Sous-rayons : la catégorie de produit (Tomates, Feuilles…).
            if (vm.subCategories.isNotEmpty)
              _ChipRow(
                chips: [
                  (
                    l10n.aisleAll,
                    vm.subCategoryId == null,
                    () => vm.selectSubCategory(null),
                  ),
                  for (final s in vm.subCategories)
                    (
                      s.label.resolve(locale),
                      vm.subCategoryId == s.id,
                      () => vm.selectSubCategory(s.id),
                    ),
                ],
              ),
            // Où acheter : un filtre sur la vendeuse, pas une catégorie.
            if (origins.isNotEmpty)
              _ChipRow(
                lead: l10n.aisleWhere,
                small: true,
                chips: [
                  (
                    l10n.aisleAnywhere,
                    vm.origin == null,
                    () => vm.selectOrigin(null),
                  ),
                  for (final o in origins)
                    (
                      o.label.resolve(locale),
                      vm.origin == o.code,
                      () => vm.selectOrigin(o.code),
                    ),
                ],
              ),
            const SizedBox(height: DymTokenSpace.s2),
            Expanded(
              child: !vm.ready || vm.isBusy
                  ? DiscoveryState(
                      failure: vm.isBusy ? null : vm.failure,
                      onRetry: vm.load,
                    )
                  : vm.products.isEmpty
                  ? DymStateView(
                      kind: DymStateKind.empty,
                      icon: Icons.eco_outlined,
                      title: l10n.aisleEmpty,
                      message: '',
                    )
                  : LayoutBuilder(
                      builder: (context, box) {
                        final inset = DymLayout.sideInset(
                          box.maxWidth,
                          gutter: DymLayout.gutter(context),
                        );
                        return ListView(
                          padding: EdgeInsets.fromLTRB(inset, 8, inset, 24),
                          children: [
                            ProductGrid(
                              items: vm.products,
                              service: vm.service,
                              config: vm.config,
                              onOpen: onOpenProduct,
                            ),
                            if (vm.hasMore) ...[
                              const SizedBox(height: DymTokenSpace.s3),
                              DymButton(
                                label: l10n.searchLoadMore,
                                variant: DymButtonVariant.secondary,
                                loading: vm.loadingMore,
                                onPressed: vm.loadMore,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rangée de puces défilante ; [lead] l'introduit (« Où acheter »).
class _ChipRow extends StatelessWidget {
  const new({required this.chips, this.lead, this.small = false});

  final List<(String, bool, VoidCallback)> chips;
  final String? lead;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return SizedBox(
      height: small ? 48 : 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: DymLayout.gutter(context)),
        children: [
          if (lead case final l?)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: DymTokenSpace.s2),
                child: Text(
                  l,
                  style: t.label.copyWith(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          for (final (label, selected, onTap) in chips) ...[
            Center(
              child: DymFilterChip(
                label: label,
                selected: selected,
                onTap: onTap,
              ),
            ),
            const SizedBox(width: DymTokenSpace.s2),
          ],
        ],
      ),
    );
  }
}
