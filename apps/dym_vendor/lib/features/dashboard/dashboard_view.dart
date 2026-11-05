import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/dashboard/dashboard_service.dart';
import 'package:dym_vendor/features/dashboard/dashboard_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Accueil de la vendeuse (maquette 59).
class DashboardView extends StackedView<DashboardViewModel> {
  const new({
    required this.service,
    required this.onOrders,
    required this.onProducts,
    super.key,
  });

  final DashboardService service;
  final VoidCallback onOrders;
  final VoidCallback onProducts;

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
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(DymLayout.gutter(context)),
          children: [
            DymContentWidth.form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.dashboardTitle,
                    textAlign: TextAlign.center,
                    style: t.display.copyWith(color: c.brandDeep),
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  if (vm.failure != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
                      child: Text(
                        vm.offline
                            ? l.dashboardOffline
                            : l.dashboardRefreshFailed,
                        style: t.label.copyWith(color: c.textSecondary),
                      ),
                    ),
                  if (summary.criticalNotifications > 0) ...[
                    _Alert(
                      title: l.dashboardCritical(summary.criticalNotifications),
                      action: l.dashboardCriticalAction,
                      onTap: onOrders,
                    ),
                    const SizedBox(height: DymTokenSpace.s3),
                  ],
                  _Periods(vm: vm),
                  const SizedBox(height: DymTokenSpace.s3),
                  _Revenue(vm: vm, summary: summary),
                  const SizedBox(height: DymTokenSpace.s4),
                  Text(l.dashboardToDo, style: t.title.copyWith(fontSize: 24)),
                  const SizedBox(height: DymTokenSpace.s2),
                  _Action(
                    icon: Icons.shopping_cart_rounded,
                    tint: c.tintVertTendre,
                    color: c.brand,
                    title: l.dashboardNewOrders(summary.pendingOrders),
                    subtitle: l.dashboardNewOrdersHint,
                    onTap: onOrders,
                  ),
                  _Action(
                    icon: Icons.inventory_2_rounded,
                    tint: c.tintPlantainClair,
                    color: c.huile,
                    title: l.dashboardActiveOrders(summary.activeOrders),
                    subtitle: l.dashboardActiveOrdersHint,
                    onTap: onOrders,
                  ),
                  _Action(
                    icon: Icons.warning_rounded,
                    tint: summary.outOfStock > 0
                        ? c.tintPimentClair
                        : c.tintVertTendre,
                    color: summary.outOfStock > 0 ? c.pimentStrong : c.brand,
                    title: l.dashboardStock(summary.outOfStock),
                    subtitle: l.dashboardStockHint,
                    onTap: onProducts,
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  Text(
                    l.dashboardRecapHint,
                    textAlign: TextAlign.center,
                    style: t.label.copyWith(color: c.textSecondary),
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

class _Alert extends StatelessWidget {
  const new({required this.title, required this.action, required this.onTap});

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Material(
      color: c.tintPimentClair,
      borderRadius: BorderRadius.circular(DymTokenRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s3),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: c.card,
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: c.pimentStrong,
                  size: 30,
                ),
              ),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.title.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      action,
                      style: t.label.copyWith(
                        color: c.pimentStrong,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _Periods extends StatelessWidget {
  const new({required this.vm});

  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l = DymLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
      ),
      child: Row(
        children: [
          for (final period in DashboardPeriod.values)
            Expanded(
              child: Semantics(
                selected: vm.period == period,
                button: true,
                child: Material(
                  color: vm.period == period ? c.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(DymTokenRadius.card),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => vm.selectPeriod(period),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        switch (period) {
                          DashboardPeriod.day => l.dashboardDay,
                          DashboardPeriod.week => l.dashboardWeek,
                          DashboardPeriod.month => l.dashboardMonth,
                        },
                        textAlign: TextAlign.center,
                        style: t.title.copyWith(
                          fontSize: 16,
                          color: vm.period == period
                              ? c.onBrand
                              : c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Revenue extends StatelessWidget {
  const new({required this.vm, required this.summary});

  final DashboardViewModel vm;
  final VendorDashboard summary;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l = DymLocalizations.of(context);
    Widget tile(
      IconData icon,
      Color tint,
      Color color,
      int count,
      String label,
    ) => Container(
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: DymTokenSpace.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count', style: t.display.copyWith(fontSize: 30)),
                Text(label, style: t.body),
              ],
            ),
          ),
        ],
      ),
    );
    final orders = tile(
      Icons.shopping_cart_rounded,
      c.tintVertTendre,
      c.brand,
      summary.orderCount,
      l.dashboardOrderCount(summary.orderCount),
    );
    final payments = tile(
      Icons.payments_rounded,
      c.tintPeche,
      c.huile,
      summary.pendingPayments,
      l.dashboardPendingPayments(summary.pendingPayments),
    );
    return Container(
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: c.brand,
                child: Icon(Icons.savings_rounded, color: c.onBrand, size: 34),
              ),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.dashboardRevenue, style: t.title),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: MoneyText(vm.revenue!, size: 34),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s3),
          LayoutBuilder(
            builder: (context, box) => box.maxWidth < 300
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      orders,
                      const SizedBox(height: DymTokenSpace.s2),
                      payments,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: orders),
                      const SizedBox(width: DymTokenSpace.s2),
                      Expanded(child: payments),
                    ],
                  ),
          ),
          const SizedBox(height: DymTokenSpace.s2),
          Text(
            l.dashboardRevenueExplanation,
            style: t.label.copyWith(color: c.textSecondary),
          ),
          if (summary.orderCount == 0) ...[
            const SizedBox(height: DymTokenSpace.s2),
            Text(l.dashboardEmpty, style: t.body),
          ],
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const new({
    required this.icon,
    required this.tint,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(DymTokenSpace.s3),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: tint,
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: DymTokenSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: t.title.copyWith(fontSize: 18)),
                      Text(
                        subtitle,
                        style: t.body.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
