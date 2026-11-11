import 'dart:async';

import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/discovery_viewmodels.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Accueil de la cliente (design « Épuré », PARCOURS §4.1) : quartier,
/// recherche avec micro, commande en cours, racheter, rayons, produits,
/// « À la une » et boutiques en liste.
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
    this.onNotifications,
    this.activeOrder,
  });

  /// Centre de notifications (cloche de l'en-tête) ; absent : masquée.
  final VoidCallback? onNotifications;

  /// Bandeau « Commande en cours » (design « Épuré »).
  final Widget? activeOrder;

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
    Widget section(String title, {String? action, VoidCallback? onAction}) =>
        Padding(
          padding: const EdgeInsets.only(
            top: DymTokenSpace.s5,
            bottom: DymTokenSpace.s2,
          ),
          child: DymSectionHeader(
            title: title,
            actionLabel: action,
            onAction: onAction,
          ),
        );
    Widget productRow(List<CatalogItem> items, ValueChanged<String> open) {
      final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);
      return SizedBox(
        height: 236 * scale,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: DymTokenSpace.s3),
          itemBuilder: (context, i) => SizedBox(
            width: 152,
            child: ProductTile(
              item: items[i],
              service: vm.service,
              config: vm.config,
              onTap: () => open(items[i].id),
            ),
          ),
        ),
      );
    }

    Widget storeList(List<PublicStore> stores) => Column(
      children: [
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
    );
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, box) {
          final inset = DymLayout.sideInset(
            box.maxWidth,
            gutter: DymLayout.gutter(context),
          );
          final locale = Localizations.localeOf(context).languageCode;
          final aisleSize =
              84 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);
          return RefreshIndicator(
            onRefresh: vm.load,
            child: ListView(
              padding: EdgeInsets.fromLTRB(inset, 8, inset, 96),
              children: [
                Row(
                  children: [
                    Expanded(child: _ZoneButton(viewModel: vm)),
                    if (onNotifications case final bell?)
                      IconButton(
                        tooltip: l10n.notificationsTitle,
                        onPressed: bell,
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                  ],
                ),
                const SizedBox(height: DymTokenSpace.s3),
                Semantics(
                  header: true,
                  child: Text(l10n.homeWhatToEat, style: t.display),
                ),
                const SizedBox(height: DymTokenSpace.s3),
                DymSearchBar(
                  hint: l10n.homeSearchHint,
                  onTap: onSearch,
                  onMic: onSearch,
                  micLabel: l10n.voiceSearchAction,
                ),
                if (activeOrder case final banner?) ...[
                  const SizedBox(height: DymTokenSpace.s3),
                  banner,
                ],
                if (onCopilot case final copilot?
                    when vm.config?.isEnabled('intent_copilot') ?? false) ...[
                  const SizedBox(height: DymTokenSpace.s3),
                  _LinkRow(
                    icon: Icons.auto_awesome_outlined,
                    label: l10n.copilotEntry,
                    onTap: copilot,
                    accent: true,
                  ),
                ],
                if (stories case final row?) ...[
                  const SizedBox(height: DymTokenSpace.s4),
                  row,
                ],
                if (vm.feed.lastOrder case final last? when onReorder != null)
                  Padding(
                    padding: const EdgeInsets.only(top: DymTokenSpace.s3),
                    child: _ReorderCard(
                      order: last,
                      onReorder: () => onReorder!(last.orderId),
                    ),
                  ),
                if (onShoppingLists case final lists?)
                  Padding(
                    padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                    child: _LinkRow(
                      icon: Icons.checklist_rounded,
                      label: l10n.shoppingHomeTile,
                      hint: l10n.shoppingHomeTileHint,
                      onTap: lists,
                    ),
                  ),
                if (vm.aisles.isNotEmpty) ...[
                  section(l10n.homeAisles),
                  SizedBox(
                    height: aisleSize + 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: vm.aisles.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: DymTokenSpace.s2),
                      itemBuilder: (context, i) {
                        final aisle = vm.aisles[i];
                        return SizedBox(
                          width: aisleSize,
                          child: DymAisleTile(
                            image:
                                DymIllustrations.aisle(aisle.icon) ??
                                DymIllustrations.storeOpened,
                            label: aisle.label.resolve(locale),
                            tint: c.tintVertTendre,
                            onTap: () => onOpenAisle(aisle.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (onOpenProduct case final openProduct?) ...[
                  if (vm.feed.popular.isNotEmpty) ...[
                    section(l10n.homePopular),
                    productRow(vm.feed.popular, openProduct),
                  ],
                  if (vm.feed.fresh.isNotEmpty) ...[
                    section(l10n.homeFresh),
                    productRow(vm.feed.fresh, openProduct),
                  ],
                ],
                if (vm.result.sponsored.isNotEmpty) ...[
                  section(l10n.homeSponsored),
                  Text(
                    l10n.homeSponsoredLabel,
                    style: t.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                    ),
                  ),
                  storeList(vm.result.sponsored),
                ],
                section(l10n.homeOpenStores),
                if (open.isEmpty && closed.isEmpty)
                  Text(
                    l10n.homeNoOpenStore,
                    style: t.body.copyWith(color: c.textSecondary),
                  )
                else
                  storeList([...open, ...closed]),
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
    final minutes = viewModel.result.estimateMinutes;
    return Semantics(
      button: true,
      label: l10n.homeChangeZone(label),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(DymTokenRadius.button),
        onTap: () => showZonePicker(context, viewModel),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  minutes == null
                      ? l10n.homeDeliverTo
                      : [
                          l10n.homeDeliverTo,
                          l10n.homeDeliveredIn(minutes),
                        ].join(' · '),
                  style: t.label.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.textSecondary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: t.title.copyWith(fontSize: 17),
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded, size: 22),
                  ],
                ),
              ],
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

/// Ligne d'accès (assistant, listes de courses) : icône dans un carré menthe,
/// libellé, chevron, carte à filet.
class _LinkRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.onTap,
    this.hint,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        side: BorderSide(color: c.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s3),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.tintVertTendre,
                  borderRadius: BorderRadius.circular(DymTokenRadius.field),
                ),
                child: Icon(icon, color: c.brandDeep, size: 22),
              ),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: t.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: accent ? c.brandDeep : c.textPrimary,
                      ),
                    ),
                    if (hint != null)
                      Text(
                        hint!,
                        style: t.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte « Racheter tes dernières courses » (spec 027).
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
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        border: Border.all(color: c.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.tintVertTendre,
              borderRadius: BorderRadius.circular(DymTokenRadius.field),
            ),
            child: Icon(Icons.replay_rounded, color: c.brandDeep, size: 22),
          ),
          const SizedBox(width: DymTokenSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeReorderTitle,
                  style: t.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  l10n.homeReorderMeta(order.storeName, order.itemCount),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.label.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DymTokenSpace.s2),
          DymButton(
            label: l10n.homeReorderAction,
            expanded: false,
            compact: true,
            variant: DymButtonVariant.secondary,
            onPressed: onReorder,
          ),
        ],
      ),
    );
  }
}
