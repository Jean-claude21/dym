import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/discovery_viewmodels.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Onglet « Marché » (design « Épuré », PARCOURS §4.1) : recherche, rayons en
/// photos, achats groupés, boutiques du quartier en liste.
class MarketView extends StackedView<DiscoveryHomeViewModel> {
  const new({
    required this.service,
    required this.onSearch,
    required this.onOpenAisle,
    required this.onOpenStore,
    super.key,
    this.onGroupBuys,
  });

  final DiscoveryService service;
  final VoidCallback onSearch;
  final ValueChanged<String> onOpenAisle;
  final ValueChanged<String> onOpenStore;

  /// Achats groupés près de moi (spec 051) ; absent : ligne masquée.
  final VoidCallback? onGroupBuys;

  @override
  DiscoveryHomeViewModel viewModelBuilder(BuildContext context) =>
      DiscoveryHomeViewModel(service: service);

  @override
  void onViewModelReady(DiscoveryHomeViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    DiscoveryHomeViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    if (!vm.ready) {
      return SafeArea(
        child: DiscoveryState(
          failure: vm.isBusy ? null : vm.failure,
          onRetry: vm.load,
        ),
      );
    }
    final locale = Localizations.localeOf(context).languageCode;
    final stores = [
      ...vm.result.openStores,
      ...vm.result.stores.where((s) => !s.openNow),
    ];
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, box) {
          final inset = DymLayout.sideInset(
            box.maxWidth,
            gutter: DymLayout.gutter(context),
          );
          final inner = box.maxWidth - inset * 2;
          const spacing = DymTokenSpace.s2;
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final columns = DymLayout.columns(
            inner,
            minTileWidth: 80 * scale,
            spacing: spacing,
            max: 8,
            itemCount: vm.aisles.length,
          );
          final tile = (inner - spacing * (columns - 1)) / columns;
          return RefreshIndicator(
            onRefresh: vm.load,
            child: ListView(
              padding: EdgeInsets.fromLTRB(inset, 16, inset, 96),
              children: [
                Semantics(
                  header: true,
                  child: Text(l10n.navMarket, style: t.display),
                ),
                const SizedBox(height: DymTokenSpace.s3),
                DymSearchBar(
                  hint: l10n.homeSearchHint,
                  onTap: onSearch,
                  onMic: onSearch,
                  micLabel: l10n.voiceSearchAction,
                ),
                const SizedBox(height: DymTokenSpace.s4),
                DymSectionHeader(title: l10n.homeAisles),
                const SizedBox(height: DymTokenSpace.s2),
                Wrap(
                  spacing: spacing,
                  runSpacing: DymTokenSpace.s3,
                  children: [
                    for (final aisle in vm.aisles)
                      SizedBox(
                        width: tile,
                        height: tile + 40 * scale.clamp(1, 1.3),
                        child: DymAisleTile(
                          image:
                              DymIllustrations.aisle(aisle.icon) ??
                              DymIllustrations.storeOpened,
                          label: aisle.label.resolve(locale),
                          tint: c.tintVertTendre,
                          onTap: () => onOpenAisle(aisle.id),
                        ),
                      ),
                  ],
                ),
                if (onGroupBuys case final groups?) ...[
                  const SizedBox(height: DymTokenSpace.s4),
                  DymMenuGroup(
                    children: [
                      DymMenuRow(
                        icon: Icons.diversity_3_outlined,
                        label: l10n.accountGroupBuys,
                        onTap: groups,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: DymTokenSpace.s5),
                DymSectionHeader(title: l10n.homeOpenStores),
                const SizedBox(height: DymTokenSpace.s1),
                if (stores.isEmpty)
                  Text(
                    l10n.homeNoOpenStore,
                    style: t.body.copyWith(color: c.textSecondary),
                  )
                else
                  for (final (i, store) in stores.indexed) ...[
                    if (i > 0) Divider(color: c.hairline),
                    StoreRow(
                      store: store,
                      service: vm.service,
                      config: vm.config,
                      onTap: () => onOpenStore(store.id),
                    ),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}
