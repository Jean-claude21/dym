import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/dashboard/dashboard_service.dart';
import 'package:dym_vendor/features/dashboard/dashboard_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// « Aujourd'hui » de la vendeuse (design « Épuré », planche 04) : encaisser
/// en premier, ventes de la période, ce qui demande une action.
class DashboardView extends StackedView<DashboardViewModel> {
  const new({
    required this.service,
    required this.onOrders,
    required this.onProducts,
    super.key,
    this.onMessages,
    this.onTill,
    this.onCharge,
    this.greeting,
  });

  final DashboardService service;
  final VoidCallback onOrders;
  final VoidCallback onProducts;

  /// Messages (V-DASH-04) ; nul : non affiché.
  final VoidCallback? onMessages;

  /// « Vente cash » : la caisse (spec 045), ventes hors app.
  final VoidCallback? onTill;

  /// « Encaisser » : QR ou code pour la cliente (spec 046).
  final VoidCallback? onCharge;

  /// « Bonjour Fatou » ; nul : titre de la page.
  final String? greeting;

  @override
  DashboardViewModel viewModelBuilder(BuildContext context) =>
      DashboardViewModel(service: service);

  @override
  void onViewModelReady(DashboardViewModel viewModel) => viewModel.load();

  @override
  Widget builder(BuildContext context, DashboardViewModel vm, Widget? child) {
    final l = DymLocalizations.of(context);
    final c = context.dym.colors;
    final t = context.dym.text;
    if (!vm.ready) {
      return SafeArea(
        child: vm.failure == null
            ? Center(child: CircularProgressIndicator(color: c.brand))
            : DymStateView(
                kind: vm.offline ? DymStateKind.offline : DymStateKind.error,
                title: vm.offline ? l.errorOffline : l.errorGeneric,
                message: l.storeSaveError,
                actionLabel: l.retry,
                onAction: vm.load,
              ),
      );
    }
    final summary = vm.summary!;
    final todo = <Widget>[
      _Row(
        icon: Icons.shopping_cart_outlined,
        title: l.dashboardNewOrders(summary.pendingOrders),
        alert: summary.pendingOrders > 0 || summary.criticalNotifications > 0,
        onTap: onOrders,
      ),
      _Row(
        icon: Icons.inventory_2_outlined,
        title: l.dashboardActiveOrders(summary.activeOrders),
        onTap: onOrders,
      ),
      _Row(
        icon: Icons.remove_shopping_cart_outlined,
        title: l.dashboardStock(summary.outOfStock),
        alert: summary.outOfStock > 0,
        onTap: onProducts,
      ),
      if (onMessages case final messages?)
        _Row(
          icon: Icons.chat_bubble_outline_rounded,
          title: l.dashboardUnreadMessages(vm.unreadMessages),
          alert: vm.unreadMessages > 0,
          onTap: messages,
        ),
    ];
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            DymLayout.gutter(context),
            16,
            DymLayout.gutter(context),
            24,
          ),
          children: [
            DymContentWidth.form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(greeting ?? l.navToday, style: t.display),
                  ),
                  const SizedBox(height: DymTokenSpace.s4),
                  // Encaisser en premier (PARCOURS, Fatou).
                  Row(
                    children: [
                      if (onCharge case final charge?)
                        Expanded(
                          child: DymButton(
                            label: l.vendorCharge,
                            icon: Icons.qr_code_2_rounded,
                            onPressed: charge,
                          ),
                        ),
                      if (onCharge != null && onTill != null)
                        const SizedBox(width: DymTokenSpace.s2),
                      if (onTill case final till?)
                        Expanded(
                          child: DymButton(
                            label: l.vendorCashSale,
                            icon: Icons.payments_outlined,
                            variant: DymButtonVariant.secondary,
                            onPressed: till,
                          ),
                        ),
                    ],
                  ),
                  if (vm.failure != null)
                    Padding(
                      padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                      child: Text(
                        vm.offline
                            ? l.dashboardOffline
                            : l.dashboardRefreshFailed,
                        style: t.label.copyWith(color: c.textSecondary),
                      ),
                    ),
                  const SizedBox(height: DymTokenSpace.s4),
                  Divider(height: 1, color: c.hairline),
                  const SizedBox(height: DymTokenSpace.s3),
                  _Periods(vm: vm),
                  const SizedBox(height: DymTokenSpace.s3),
                  Text(
                    l.dashboardRevenue,
                    style: t.body.copyWith(color: c.textSecondary),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      vm.revenue?.format() ?? '',
                      style: t.display.copyWith(
                        fontSize: 38,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  Text(
                    l.dashboardTotals(
                      summary.orderCount,
                      summary.pendingPayments,
                    ),
                    style: t.label.copyWith(
                      color: c.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (summary.orderCount == 0) ...[
                    const SizedBox(height: DymTokenSpace.s1),
                    Text(
                      l.dashboardEmpty,
                      style: t.label.copyWith(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  const SizedBox(height: DymTokenSpace.s4),
                  Text(
                    l.dashboardToDo,
                    style: t.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  for (final (i, row) in todo.indexed) ...[
                    if (i == 0) const SizedBox(height: DymTokenSpace.s1),
                    Divider(height: 1, color: c.hairline),
                    row,
                  ],
                  Divider(height: 1, color: c.hairline),
                  const SizedBox(height: DymTokenSpace.s3),
                  Text(
                    l.dashboardRecapHint,
                    style: t.label.copyWith(
                      color: c.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Jour · semaine · mois : puces au rayon des boutons.
class _Periods extends StatelessWidget {
  const new({required this.vm});

  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = DymLocalizations.of(context);
    return Wrap(
      spacing: DymTokenSpace.s2,
      children: [
        for (final period in DashboardPeriod.values)
          DymFilterChip(
            label: switch (period) {
              DashboardPeriod.day => l.dashboardDay,
              DashboardPeriod.week => l.dashboardWeek,
              DashboardPeriod.month => l.dashboardMonth,
            },
            selected: vm.period == period,
            onTap: () => vm.selectPeriod(period),
          ),
      ],
    );
  }
}

/// Ligne « À traiter » : icône au trait, texte, point rouge si urgent.
class _Row extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.onTap,
    this.alert = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            Icon(icon, color: c.textPrimary),
            const SizedBox(width: DymTokenSpace.s3),
            Expanded(child: Text(title, style: t.body)),
            if (alert)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: DymTokenSpace.s2),
                decoration: BoxDecoration(
                  color: c.piment,
                  shape: BoxShape.circle,
                ),
              ),
            Icon(Icons.chevron_right_rounded, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
