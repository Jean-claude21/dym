import 'dart:async';

import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/discovery_viewmodels.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Écran 02 : accueil (quartier, estimation, boutiques ouvertes, rayons).
class DiscoveryHomeView extends StackedView<DiscoveryHomeViewModel> {
  const new({
    required this.service,
    required this.onSearch,
    required this.onOpenStore,
    required this.onOpenAisle,
    super.key,
    this.onCopilot,
    this.stories,
    this.onReorder,
    this.onOpenProduct,
    this.onShoppingLists,
  });

  /// Mes courses (spec 029) ; absent : tuile masquée.
  final VoidCallback? onShoppingLists;

  /// Recommander une commande livrée (spec 027) ; absent : carte masquée.
  final ValueChanged<String>? onReorder;

  /// Fiche produit, depuis les rangées du fil personnel.
  final ValueChanged<String>? onOpenProduct;

  /// Rangée des stories du quartier (spec 020), si le flag est actif.
  final Widget? stories;

  /// Copilote d'intention (spec 019), proposé si le flag est actif.
  final VoidCallback? onCopilot;

  final DiscoveryService service;
  final VoidCallback onSearch;
  final ValueChanged<String> onOpenStore;
  final ValueChanged<String> onOpenAisle;

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
    final open = vm.result.openStores;
    final closed = vm.result.stores.where((s) => !s.openNow).toList();
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(
        top: DymTokenSpace.s5,
        bottom: DymTokenSpace.s3,
      ),
      child: Semantics(
        header: true,
        child: Text(title, style: t.title.copyWith(fontSize: 22)),
      ),
    );
    Widget productRow(List<CatalogItem> items, ValueChanged<String> open) =>
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: DymTokenSpace.s3),
            itemBuilder: (context, i) => SizedBox(
              width: 168,
              child: ProductTile(
                item: items[i],
                service: vm.service,
                config: vm.config,
                onTap: () => open(items[i].id),
              ),
            ),
          ),
        );
    Widget storeRow(List<PublicStore> stores) => SizedBox(
      height: 252 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.3),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stores.length,
        separatorBuilder: (_, _) => const SizedBox(width: DymTokenSpace.s3),
        itemBuilder: (context, i) => StoreTile(
          store: stores[i],
          service: vm.service,
          config: vm.config,
          onTap: () => onOpenStore(stores[i].id),
        ),
      ),
    );
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, box) {
          final inset = DymLayout.sideInset(
            box.maxWidth,
            gutter: DymLayout.gutter(context),
          );
          final inner = box.maxWidth - inset * 2;
          const spacing = DymTokenSpace.s2;
          final columns = DymLayout.columns(
            inner,
            minTileWidth: 84 * MediaQuery.textScalerOf(context).scale(1),
            spacing: spacing,
            max: 8,
            itemCount: vm.aisles.length,
          );
          final tile = (inner - spacing * (columns - 1)) / columns;
          final tints = tileTints(c);
          final locale = Localizations.localeOf(context).languageCode;
          return RefreshIndicator(
            onRefresh: vm.load,
            child: ListView(
              padding: EdgeInsets.fromLTRB(inset, 12, inset, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: DymTokenSpace.s2,
                        runSpacing: DymTokenSpace.s2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _ZoneButton(viewModel: vm),
                          if (vm.result.estimateMinutes != null)
                            DymDeliveryPill(
                              label: l10n.homeDeliveredIn(
                                vm.result.estimateMinutes!,
                              ),
                              zem: DymIllustrations.zem,
                            ),
                        ],
                      ),
                    ),
                    const CartButton(),
                  ],
                ),
                const SizedBox(height: DymTokenSpace.s4),
                Semantics(
                  header: true,
                  child: Text(l10n.homeWhatToEat, style: t.display),
                ),
                const SizedBox(height: DymTokenSpace.s3),
                DymSearchBar(hint: l10n.homeSearchHint, onTap: onSearch),
                if (onCopilot case final open?
                    when vm.config?.isEnabled('intent_copilot') ?? false) ...[
                  const SizedBox(height: DymTokenSpace.s2),
                  Material(
                    color: c.tintVertTendre,
                    borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      minTileHeight: 64,
                      onTap: open,
                      leading: Icon(
                        Icons.auto_awesome_rounded,
                        color: c.brandDeep,
                      ),
                      title: Text(
                        l10n.copilotEntry,
                        style: t.body.copyWith(color: c.brandDeep),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_rounded,
                        color: c.brandDeep,
                      ),
                    ),
                  ),
                ],
                if (stories case final row?) ...[
                  const SizedBox(height: DymTokenSpace.s4),
                  row,
                ],
                if (onShoppingLists case final open?)
                  Padding(
                    padding: const EdgeInsets.only(top: DymTokenSpace.s4),
                    child: _ShoppingTile(onTap: open),
                  ),
                if (vm.feed.lastOrder case final last? when onReorder != null)
                  Padding(
                    padding: const EdgeInsets.only(top: DymTokenSpace.s4),
                    child: _ReorderCard(
                      order: last,
                      onReorder: () => onReorder!(last.orderId),
                    ),
                  ),
                if (onOpenProduct case final open?) ...[
                  if (vm.feed.popular.isNotEmpty) ...[
                    section(l10n.homePopular),
                    productRow(vm.feed.popular, open),
                  ],
                  if (vm.feed.fresh.isNotEmpty) ...[
                    section(l10n.homeFresh),
                    productRow(vm.feed.fresh, open),
                  ],
                ],
                section(l10n.homeOpenStores),
                if (open.isEmpty)
                  Text(
                    l10n.homeNoOpenStore,
                    style: t.body.copyWith(color: c.textSecondary),
                  )
                else
                  storeRow(open),
                if (closed.isNotEmpty) ...[
                  section(l10n.homeOtherStores),
                  storeRow(closed),
                ],
                section(l10n.homeAisles),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final (i, aisle) in vm.aisles.indexed)
                      SizedBox(
                        width: tile,
                        height: tile * 1.15,
                        child: DymAisleTile(
                          image:
                              DymIllustrations.aisle(aisle.icon) ??
                              DymIllustrations.storeOpened,
                          label: aisle.label.resolve(locale),
                          tint: tints[i % tints.length],
                          onTap: () => onOpenAisle(aisle.id),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ZoneButton extends StatelessWidget {
  const new({required this.viewModel});

  final DiscoveryHomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final zone = viewModel.zone?.name ?? '';
    final city = viewModel.cityName;
    final label = city == null ? zone : '$zone, $city';
    return Semantics(
      button: true,
      label: l10n.homeChangeZone(label),
      excludeSemantics: true,
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
        child: InkWell(
          borderRadius: BorderRadius.circular(DymTokenRadius.chip),
          onTap: () => showZonePicker(context, viewModel),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded, color: c.brand),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: t.title.copyWith(fontSize: 17),
                    ),
                  ),
                  const Icon(Icons.expand_more_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Choix du quartier : position proposée (à confirmer) ou recherche.
Future<void> showZonePicker(
  BuildContext context,
  DiscoveryHomeViewModel viewModel,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheet) => ListenableBuilder(
    listenable: viewModel,
    builder: (sheet, _) {
      final c = sheet.dym.colors;
      final t = sheet.dym.text;
      final l10n = DymLocalizations.of(sheet);
      final config = viewModel.config;
      final suggestion = viewModel.suggestion;
      Future<void> pick(String zoneId) async {
        Navigator.pop(sheet);
        await viewModel.selectZone(zoneId);
      }

      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (sheet, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(l10n.zonePickerTitle, style: t.display.copyWith(fontSize: 28)),
            const SizedBox(height: DymTokenSpace.s3),
            if (suggestion != null)
              Container(
                padding: const EdgeInsets.all(DymTokenSpace.s3),
                decoration: BoxDecoration(
                  color: c.tintVertTendre,
                  borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.zoneSuggestion(suggestion.zoneName),
                      style: t.title.copyWith(fontSize: 19),
                    ),
                    const SizedBox(height: DymTokenSpace.s2),
                    DymButton(
                      label: l10n.zoneConfirm,
                      icon: Icons.check_rounded,
                      onPressed: () => pick(suggestion.zoneId),
                    ),
                  ],
                ),
              ),
            if (suggestion != null) const SizedBox(height: DymTokenSpace.s3),
            DymPlacePicker(
              places: [
                for (final city in config?.cities ?? const <City>[])
                  for (final zone in config!.zonesOf(city.id))
                    DymPlace(id: zone.id, name: zone.name, detail: city.name),
              ],
              selectedId: viewModel.zoneId,
              onSelected: (id) => unawaited(pick(id)),
              searchLabel: l10n.zoneSearchLabel,
              searchHint: l10n.zoneSearchHint,
              noResultLabel: l10n.zoneNoResult,
              onLocate: suggestion == null ? viewModel.locate : null,
              locateLabel: viewModel.locating
                  ? l10n.zoneLocating
                  : l10n.zoneUseLocation,
              locating: viewModel.locating,
              message: viewModel.locationUnavailable
                  ? l10n.zoneLocationUnavailable
                  : null,
            ),
          ],
        ),
      );
    },
  ),
);

/// Tuile « Mes listes de courses » (spec 029).
class _ShoppingTile extends StatelessWidget {
  const new({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minTileHeight: 72,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: c.tintVertTendre,
          child: Icon(Icons.checklist_rounded, color: c.brandDeep),
        ),
        title: Text(
          l10n.shoppingHomeTile,
          style: t.title.copyWith(fontSize: 17),
        ),
        subtitle: Text(
          l10n.shoppingHomeTileHint,
          style: t.label.copyWith(color: c.textSecondary),
        ),
        trailing: Icon(Icons.arrow_forward_rounded, color: c.brandDeep),
      ),
    );
  }
}

/// Carte « Recommander tes dernières courses » (spec 027).
class _ReorderCard extends StatelessWidget {
  const new({required this.order, required this.onReorder});

  final LastOrder order;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(DymTokenSpace.s4),
      decoration: BoxDecoration(
        color: c.tintPlantainClair,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: Row(
        children: [
          Icon(Icons.replay_rounded, color: c.brandDeep, size: 32),
          const SizedBox(width: DymTokenSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeReorderTitle, style: t.title),
                Text(
                  l10n.homeReorderMeta(order.storeName, order.itemCount),
                  style: t.label.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: DymTokenSpace.s2),
          DymButton(
            label: l10n.homeReorderAction,
            expanded: false,
            compact: true,
            onPressed: onReorder,
          ),
        ],
      ),
    );
  }
}
