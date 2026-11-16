import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/store/my_store/my_store_viewmodel.dart';
import 'package:dym_vendor/features/store/onboarding/store_onboarding_viewmodel.dart';
import 'package:dym_vendor/features/store/staff/staff_view.dart';
import 'package:dym_vendor/features/store/store_format.dart';
import 'package:dym_vendor/features/store/store_service.dart';
import 'package:dym_vendor/features/store/store_summary.dart';
import 'package:dym_vendor/features/store/widgets/store_widgets.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Écran 23 : « Ma boutique » (interrupteur d'ouverture et réglages).
class MyStoreView extends StackedView<MyStoreViewModel> {
  const new({
    required this.service,
    required this.onEdit,
    super.key,
    this.onReviews,
    this.onCourierCash,
    this.onTill,
    this.onCredit,
    this.onStudio,
    this.onWholesale,
    this.onHaggling,
    this.onGroupOffers,
    this.onMembership,
    this.onContents,
    this.onBroadcast,
    this.onAccount,
    this.onStaff,
    this.onStoreSwitched,
  });

  /// « Mon compte » (aide, langue, déconnexion) ; nul : masqué.
  /// Équipe de la boutique (propriétaire, spec 087).
  final VoidCallback? onStaff;

  /// Boutique active changée : l'app recharge tout.
  final VoidCallback? onStoreSwitched;

  final VoidCallback? onAccount;

  /// Relancer mes clientes (spec 021) ; nul : non affiché.
  final VoidCallback? onBroadcast;

  /// Mes contenus (spec 020) ; nul : non affiché.
  final VoidCallback? onContents;

  final StoreService service;
  final Future<void> Function(StoreStep step) onEdit;

  /// Mes avis (écran 65) ; nul : non affiché.
  final VoidCallback? onReviews;

  /// Cash encaissé par les livreurs DYM (spec 043) ; absent : masqué.
  final VoidCallback? onCourierCash;

  /// « Ma caisse » (spec 045) ; absente : masquée.
  final VoidCallback? onTill;

  /// Ardoise (spec 047) ; absente : masquée.
  final VoidCallback? onCredit;

  /// Partage et fin de marché (spec 048) ; absents : masqués.
  final VoidCallback? onStudio;

  /// Achat de gros (spec 049) ; absent : masqué.
  final VoidCallback? onWholesale;

  /// Marchandage (spec 050) ; absent : masqué.
  final VoidCallback? onHaggling;

  /// Offres groupées (spec 051) ; absent : masqué.
  final VoidCallback? onGroupOffers;

  /// Pro et visibilité (spec 052) ; absent : masqué.
  final VoidCallback? onMembership;

  @override
  MyStoreViewModel viewModelBuilder(BuildContext context) =>
      MyStoreViewModel(service: service, onEdit: onEdit);

  @override
  void onViewModelReady(MyStoreViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    MyStoreViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final store = viewModel.store;
    final config = viewModel.config;
    if (store == null || config == null) {
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
    final summary = StoreSummary(
      store,
      config,
      Localizations.localeOf(context).languageCode,
    );
    final origin = summary.origin;
    final rows = [
      (Icons.edit_note_outlined, l10n.storeSummaryName, null, StoreStep.name),
      (
        Icons.storefront_outlined,
        l10n.myStoreRowOrigin,
        summary.originLabel,
        StoreStep.origin,
      ),
      (
        Icons.location_on_outlined,
        l10n.storeAddressLabel,
        l10n.myStoreAddressPrivate,
        StoreStep.address,
      ),
      (
        Icons.category_outlined,
        l10n.myStoreRowCategory,
        config.categories
            .where((cat) => cat.id == store.mainCategoryId)
            .firstOrNull
            ?.label
            .resolve(summary.locale),
        StoreStep.category,
      ),
      (
        Icons.delivery_dining_outlined,
        l10n.myStoreRowDelivery,
        l10n.myStoreDeliveryValue(
          summary.deliveryZoneCount,
          prepLabel(l10n, store.prepTimeMinutes),
        ),
        StoreStep.delivery,
      ),
      (
        Icons.account_balance_wallet_outlined,
        l10n.myStoreRowPayment,
        summary.paymentLabels.isEmpty ? null : summary.paymentLabels,
        StoreStep.payment,
      ),
      (
        Icons.schedule_outlined,
        l10n.myStoreRowHours,
        hoursSummary(context, store.hours),
        StoreStep.hours,
      ),
    ];
    Widget group(String? title, List<Widget> rows) => rows.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: DymTokenSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
                    child: Text(
                      title,
                      style: t.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                DymMenuGroup(children: rows),
              ],
            ),
          );
    DymMenuRow row(IconData icon, String label, VoidCallback onTap) =>
        DymMenuRow(icon: icon, label: label, onTap: onTap);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, box) {
          final inset = DymLayout.sideInset(
            box.maxWidth,
            gutter: DymLayout.gutter(context),
            maxWidth: DymTokenLayout.formMax,
          );
          return ListView(
            padding: EdgeInsets.fromLTRB(inset, 16, inset, 24),
            children: [
              Semantics(
                header: true,
                child: Text(l10n.navStore, style: t.display),
              ),
              const SizedBox(height: DymTokenSpace.s3),
              // La boutique et son ouverture, en un geste.
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: c.tintVertTendre,
                    child: Text(
                      summary.initial,
                      style: t.title.copyWith(color: c.brandDeep),
                    ),
                  ),
                  const SizedBox(width: DymTokenSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: t.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (origin != null && summary.originLabel != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: DymOriginBadge(
                              origin: origin,
                              label: summary.originLabel!,
                              dense: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DymTokenSpace.s3),
              DymSwitchTile(
                title: viewModel.closedByHours
                    ? l10n.myStoreClosedByHours
                    : store.isOpen
                    ? l10n.myStoreOpen
                    : l10n.myStoreClosed,
                subtitle: viewModel.closedByHours
                    ? l10n.myStoreClosedByHoursHint
                    : store.isOpen
                    ? l10n.myStoreOpenHint
                    : l10n.myStoreClosedHint,
                value: store.isOpen,
                onChanged:
                    viewModel.suspended ||
                        viewModel.toggling ||
                        !store.can('orders')
                    ? null
                    : (open) => viewModel.setOpen(open: open),
              ),
              if (viewModel.suspended)
                StorePrivacyNote(text: l10n.myStoreSuspended)
              else
                StoreErrorBanner(failure: viewModel.toggleFailure),
              if (!store.isOwner)
                Padding(
                  padding: const EdgeInsets.only(top: DymTokenSpace.s3),
                  child: StorePrivacyNote(
                    text: l10n.staffYouAre(
                      staffRoleLabel(l10n, store.staffRole),
                    ),
                  ),
                ),
              group(l10n.storeGroupMoney, [
                if (onTill case final till? when store.can('till'))
                  row(Icons.point_of_sale_outlined, l10n.tillTitle, till),
                if (onCredit case final credit? when store.can('till'))
                  row(Icons.menu_book_outlined, l10n.creditTitle, credit),
                if (onCourierCash case final cash? when store.can('orders'))
                  row(Icons.two_wheeler_outlined, l10n.courierCashTitle, cash),
              ]),
              group(l10n.storeGroupSell, [
                if (onHaggling case final haggling? when store.can('offers'))
                  row(Icons.handshake_outlined, l10n.hagglingTitle, haggling),
                if (onGroupOffers case final groups? when store.can('offers'))
                  row(Icons.diversity_3_outlined, l10n.groupOfferTitle, groups),
                if (onWholesale case final wholesale? when store.can('offers'))
                  row(Icons.warehouse_outlined, l10n.wholesaleTitle, wholesale),
                if (onMembership case final membership? when store.isOwner)
                  row(
                    Icons.workspace_premium_outlined,
                    l10n.membershipVendorTitle,
                    membership,
                  ),
                if (onStudio case final studio? when store.isOwner)
                  row(Icons.campaign_outlined, l10n.studioTitle, studio),
                if (onContents case final contents? when store.isOwner)
                  row(
                    Icons.play_circle_outline_rounded,
                    l10n.contentMine,
                    contents,
                  ),
                if (onBroadcast case final broadcast? when store.isOwner)
                  row(Icons.send_outlined, l10n.broadcastEntry, broadcast),
                if (onReviews case final reviews? when store.can('orders'))
                  row(Icons.star_outline_rounded, l10n.reviewMine, reviews),
              ]),
              group(l10n.storeGroupSettings, [
                if (store.isOwner)
                  for (final (icon, label, value, step) in rows)
                    DymMenuRow(
                      icon: icon,
                      label: label,
                      value: value,
                      onTap: () => viewModel.edit(step),
                    ),
                if (store.isOwner)
                  DymMenuRow(
                    icon: Icons.radar_rounded,
                    label: l10n.storeDeliveryRadius,
                    value: l10n.distanceKilometers(
                      '${(store.deliveryRadiusM / 1000).round()}',
                    ),
                    onTap: () => _editRadius(context, viewModel),
                  ),
              ]),
              group(l10n.staffGroupTeam, [
                if (onStaff case final staff? when store.isOwner)
                  row(Icons.groups_2_outlined, l10n.staffTitle, staff),
                if (viewModel.stores.length > 1)
                  DymMenuRow(
                    icon: Icons.swap_horiz_rounded,
                    label: l10n.staffSwitchStore,
                    value: store.name,
                    onTap: () => _pickStore(context, viewModel),
                  ),
              ]),
              group(null, [
                if (onAccount case final account?)
                  row(
                    Icons.person_outline_rounded,
                    l10n.storeMyAccount,
                    account,
                  ),
              ]),
            ],
          );
        },
      ),
    );
  }

  /// Liste des boutiques ; choisir recharge l'app sur la nouvelle.
  Future<void> _pickStore(BuildContext context, MyStoreViewModel vm) async {
    final l10n = DymLocalizations.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in vm.stores)
              ListTile(
                leading: Icon(
                  s.active
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                ),
                title: Text(s.name),
                subtitle: Text(staffRoleLabel(l10n, s.role)),
                onTap: () => Navigator.of(sheet).pop(s.id),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    if (await vm.switchStore(picked)) onStoreSwitched?.call();
  }
}

/// Rayon de livraison (spec 094) : de 1 à 30 km autour de la boutique.
Future<void> _editRadius(BuildContext context, MyStoreViewModel vm) async {
  final l10n = DymLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final chosen = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (_) => _RadiusSheet(initialKm: vm.store!.deliveryRadiusM ~/ 1000),
  );
  if (chosen == null) return;
  final ok = await vm.setDeliveryRadius(chosen * 1000);
  messenger?.showSnackBar(
    SnackBar(
      content: Text(ok ? l10n.storeDeliveryRadiusSaved : l10n.errorGeneric),
    ),
  );
}

class _RadiusSheet extends StatefulWidget {
  const new({required this.initialKm});

  final int initialKm;

  @override
  State<_RadiusSheet> createState() => _RadiusSheetState();
}

class _RadiusSheetState extends State<_RadiusSheet> {
  late double _km = widget.initialKm.clamp(1, 30).toDouble();

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final t = context.dym.text;
    final c = context.dym.colors;
    final label = l10n.distanceKilometers('${_km.round()}');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DymTokenSpace.s4,
          0,
          DymTokenSpace.s4,
          DymTokenSpace.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.storeDeliveryRadius, style: t.title),
            const SizedBox(height: DymTokenSpace.s2),
            Text(
              l10n.storeDeliveryRadiusHint,
              style: t.body.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: DymTokenSpace.s4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: t.display.copyWith(color: c.brand),
            ),
            Slider(
              value: _km,
              min: 1,
              max: 30,
              divisions: 29,
              label: label,
              onChanged: (v) => setState(() => _km = v),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            DymButton(
              label: l10n.adminSave,
              onPressed: () => Navigator.of(context).pop(_km.round()),
            ),
          ],
        ),
      ),
    );
  }
}
