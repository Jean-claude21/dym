import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/store/my_store/my_store_viewmodel.dart';
import 'package:dym_vendor/features/store/onboarding/store_onboarding_viewmodel.dart';
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
    this.onContents,
    this.onBroadcast,
  });

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
      (Icons.edit_note_rounded, l10n.storeSummaryName, null, StoreStep.name),
      (
        Icons.storefront_rounded,
        l10n.myStoreRowOrigin,
        summary.originLabel,
        StoreStep.origin,
      ),
      (
        Icons.location_on_rounded,
        l10n.storeAddressLabel,
        l10n.myStoreAddressPrivate,
        StoreStep.address,
      ),
      (
        Icons.category_rounded,
        l10n.myStoreRowCategory,
        config.categories
            .where((cat) => cat.id == store.mainCategoryId)
            .firstOrNull
            ?.label
            .resolve(summary.locale),
        StoreStep.category,
      ),
      (
        Icons.delivery_dining_rounded,
        l10n.myStoreRowDelivery,
        l10n.myStoreDeliveryValue(
          summary.deliveryZoneCount,
          prepLabel(l10n, store.prepTimeMinutes),
        ),
        StoreStep.delivery,
      ),
      (
        Icons.account_balance_wallet_rounded,
        l10n.myStoreRowPayment,
        summary.paymentLabels.isEmpty ? null : summary.paymentLabels,
        StoreStep.payment,
      ),
      (
        Icons.schedule_rounded,
        l10n.myStoreRowHours,
        hoursSummary(context, store.hours),
        StoreStep.hours,
      ),
    ];
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, box) {
          final inset = DymLayout.sideInset(
            box.maxWidth,
            gutter: DymLayout.gutter(context),
            maxWidth: DymTokenLayout.formMax,
          );
          return ListView(
            padding: EdgeInsets.fromLTRB(inset, 12, inset, 24),
            children: [
              Text(
                l10n.appNameVendor,
                textAlign: TextAlign.center,
                style: t.title.copyWith(color: c.brandDeep),
              ),
              Semantics(
                header: true,
                child: Text(
                  l10n.myStoreTitle,
                  textAlign: TextAlign.center,
                  style: t.display.copyWith(fontSize: 40, color: c.brandDeep),
                ),
              ),
              const SizedBox(height: DymTokenSpace.s4),
              StoreSection(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: c.tintPeche,
                        child: Text(
                          summary.initial,
                          style: t.display.copyWith(
                            fontSize: 34,
                            color: c.originMaisonFg,
                          ),
                        ),
                      ),
                      const SizedBox(width: DymTokenSpace.s4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.name,
                              style: t.display.copyWith(fontSize: 28),
                            ),
                            if (origin != null &&
                                summary.originLabel != null) ...[
                              const SizedBox(height: DymTokenSpace.s1),
                              DymOriginBadge(
                                origin: origin,
                                label: summary.originLabel!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    height: DymTokenSpace.s5,
                    color: c.textSecondary.withValues(alpha: 0.12),
                  ),
                  DymSwitchTile(
                    large: true,
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
                    onChanged: viewModel.suspended || viewModel.toggling
                        ? null
                        : (open) => viewModel.setOpen(open: open),
                  ),
                ],
              ),
              const SizedBox(height: DymTokenSpace.s3),
              if (viewModel.suspended)
                StorePrivacyNote(text: l10n.myStoreSuspended)
              else
                StoreErrorBanner(failure: viewModel.toggleFailure),
              if (onBroadcast case final broadcast?) ...[
                DymMenuRow(
                  icon: Icons.campaign_rounded,
                  label: l10n.broadcastEntry,
                  onTap: broadcast,
                ),
                const SizedBox(height: DymTokenSpace.s2),
              ],
              if (onContents case final contents?) ...[
                DymMenuRow(
                  icon: Icons.play_circle_rounded,
                  label: l10n.contentMine,
                  onTap: contents,
                ),
                const SizedBox(height: DymTokenSpace.s2),
              ],
              if (onTill case final till?) ...[
                DymMenuRow(
                  icon: Icons.point_of_sale_rounded,
                  label: l10n.tillTitle,
                  onTap: till,
                ),
                const SizedBox(height: DymTokenSpace.s2),
              ],
              if (onGroupOffers case final groups?) ...[
                DymMenuRow(
                  icon: Icons.diversity_3_rounded,
                  label: l10n.groupOfferTitle,
                  onTap: groups,
                ),
                const SizedBox(height: DymTokenSpace.s2),
              ],
              if (onHaggling case final haggling?) ...[
                DymMenuRow(
                  icon: Icons.handshake_rounded,
                  label: l10n.hagglingTitle,
                  onTap: haggling,
                ),
                const SizedBox(height: DymTokenSpace.s2),
              ],
              if (onWholesale case final wholesale?) ...[
                DymMenuRow(
                  icon: Icons.warehouse_rounded,
                  label: l10n.wholesaleTitle,
                  onTap: wholesale,
                ),
                const SizedBox(height: DymTokenSpace.s2),
              ],
              if (onStudio case final studio?) ...[
                DymMenuRow(
                  icon: Icons.campaign_rounded,
                  label: l10n.studioTitle,
                  onTap: studio,
                ),
                const SizedBox(height: DymTokenSpace.s2),
              ],
              if (onCredit case final credit?) ...[
                DymMenuRow(
                  icon: Icons.menu_book_rounded,
                  label: l10n.creditTitle,
                  onTap: credit,
                ),
                const SizedBox(height: DymTokenSpace.s2),
              ],
              if (onCourierCash case final cash?) ...[
                DymMenuRow(
                  icon: Icons.two_wheeler_rounded,
                  label: l10n.courierCashTitle,
                  onTap: cash,
                ),
                const SizedBox(height: DymTokenSpace.s2),
              ],
              if (onReviews case final reviews?) ...[
                DymMenuRow(
                  icon: Icons.star_rounded,
                  label: l10n.reviewMine,
                  onTap: reviews,
                ),
                const SizedBox(height: DymTokenSpace.s2),
              ],
              for (final (icon, label, value, step) in rows) ...[
                DymMenuRow(
                  icon: icon,
                  label: label,
                  value: value,
                  onTap: () => viewModel.edit(step),
                ),
                const SizedBox(height: DymTokenSpace.s2),
              ],
            ],
          );
        },
      ),
    );
  }
}
