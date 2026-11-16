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
    this.onPublish,
    this.greeting,
    this.bell,
  });

  /// Cloche des notifications (spec 097) ; nulle : masquée.
  final Widget? bell;

  final DashboardService service;
  final VoidCallback onOrders;
  final VoidCallback onProducts;

  /// Messages (V-DASH-04) ; nul : non affiché.
  final VoidCallback? onMessages;

  /// « Vente cash » : la caisse (spec 045), ventes hors app.
  final VoidCallback? onTill;

  /// « Encaisser » : QR ou code pour la cliente (spec 046).
  final VoidCallback? onCharge;

  /// Publier un statut (statuts actifs seulement, spec 077).
  final VoidCallback? onPublish;

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
                message: l.errorLoadMessage,
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
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(greeting ?? l.navToday, style: t.display),
                        ),
                      ),
                      ?bell,
                    ],
                  ),
                  // Commandes en attente : d'abord, et en couleur (spec 076).
                  if (summary.pendingOrders > 0) ...[
                    const SizedBox(height: DymTokenSpace.s3),
                    _Urgent(
                      count: summary.pendingOrders,
                      respondBy: summary.respondBy,
                      onTap: onOrders,
                    ),
                  ],
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
                  if (onPublish case final publish?) ...[
                    const SizedBox(height: DymTokenSpace.s2),
                    DymButton(
                      label: l.vendorPublishStatus,
                      icon: Icons.add_a_photo_outlined,
                      variant: DymButtonVariant.secondary,
                      onPressed: publish,
                    ),
                  ],
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
                  if (summary.revenueChange case final change?) ...[
                    const SizedBox(height: 4),
                    _Delta(
                      change: change,
                      vs: switch (vm.period) {
                        DashboardPeriod.week => l.vendorVsWeek,
                        DashboardPeriod.month => l.vendorVsMonth,
                        DashboardPeriod.day => l.vendorVsDay,
                      },
                    ),
                    const SizedBox(height: 4),
                  ],
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
                  if (vm.insights case final insights?)
                    _Insights(
                      insights: insights,
                      money: (minor) => vm.config?.money(minor).format() ?? '',
                      onProducts: onProducts,
                    ),
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

/// Commandes qui attendent une réponse : carte pêche, heure limite, bouton.
class _Urgent extends StatelessWidget {
  const new({required this.count, required this.respondBy, this.onTap});

  final int count;
  final DateTime? respondBy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l = DymLocalizations.of(context);
    final by = respondBy;
    return Material(
      color: c.tintPeche,
      borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      child: InkWell(
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s3),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: c.originMaisonFg,
                size: 30,
              ),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.vendorUrgentTitle(count),
                      style: t.title.copyWith(
                        fontSize: 18,
                        color: c.originMaisonFg,
                      ),
                    ),
                    if (by != null)
                      Text(
                        l.vendorRespondBefore(
                          TimeOfDay.fromDateTime(by.toLocal()).format(context),
                        ),
                        style: t.label.copyWith(color: c.originMaisonFg),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: DymTokenSpace.s2),
              Text(
                l.vendorUrgentAction,
                style: t.label.copyWith(
                  color: c.originMaisonFg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: c.originMaisonFg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Évolution « ▲ 12 % vs hier à la même heure ».
class _Delta extends StatelessWidget {
  const new({required this.change, required this.vs});

  final int change;
  final String vs;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l = DymLocalizations.of(context);
    final up = change > 0;
    final (bg, fg) = change == 0
        ? (c.muted, c.textSecondary)
        : up
        ? (c.tintVertTendre, c.brandDeep)
        : (c.tintPimentClair, c.pimentStrong);
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            [
              if (change > 0) '▲' else if (change < 0) '▼' else '=',
              l.adminPercent(change.abs()),
            ].join(' '),
            style: t.label.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ),
        Text(vs, style: t.label.copyWith(color: c.textSecondary)),
      ],
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
      runSpacing: DymTokenSpace.s2,
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

/// Accueil poussé (spec 098) : tendance jour par jour, panier moyen,
/// clientes, meilleurs produits, clientes fidèles, alertes de stock.
class _Insights extends StatelessWidget {
  const new({
    required this.insights,
    required this.money,
    required this.onProducts,
  });

  final VendorInsights insights;
  final String Function(int minor) money;
  final VoidCallback onProducts;

  @override
  Widget build(BuildContext context) {
    final l = DymLocalizations.of(context);
    final t = context.dym.text;
    final c = context.dym.colors;
    final days = insights.days;
    final peak = days.fold<int>(
      0,
      (m, d) => d.revenueMinor > m ? d.revenueMinor : m,
    );
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(
        top: DymTokenSpace.s4,
        bottom: DymTokenSpace.s1,
      ),
      child: Text(title, style: t.body.copyWith(fontWeight: FontWeight.w600)),
    );
    Widget tile(IconData icon, String value, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(DymTokenSpace.s3),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          border: Border.all(color: c.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: c.brand, size: 20),
            const SizedBox(height: DymTokenSpace.s1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: t.title),
            ),
            Text(label, style: t.label.copyWith(color: c.textSecondary)),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (days.length > 1) ...[
          section(l.insightsTrend),
          SizedBox(
            height: 96,
            child: Semantics(
              label: l.insightsTrend,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final d in days)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: peak == 0
                                  ? 2
                                  : 4 + 68 * d.revenueMinor / peak,
                              decoration: BoxDecoration(
                                color: d.revenueMinor == 0
                                    ? c.hairline
                                    : c.brand,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              days.length <= 7
                                  ? MaterialLocalizations.of(context)
                                        .narrowWeekdays[d.day.weekday % 7]
                                  : '',
                              style: t.label.copyWith(
                                color: c.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: DymTokenSpace.s3),
        Row(
          children: [
            tile(
              Icons.shopping_basket_outlined,
              money(insights.averageBasketMinor),
              l.insightsAverageBasket,
            ),
            const SizedBox(width: DymTokenSpace.s2),
            tile(
              Icons.people_outline_rounded,
              '${insights.customers}',
              l.insightsCustomers(insights.newCustomers),
            ),
          ],
        ),
        if (insights.lowStock.isNotEmpty) ...[
          section(l.insightsLowStock),
          for (final item in insights.lowStock.take(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(Icons.inventory_2_outlined, color: c.piment),
              title: Text(
                [item.name, ?item.variant].join(' · '),
                style: t.body,
              ),
              trailing: Text(
                l.insightsStockLeft('${item.stock}'),
                style: t.label.copyWith(color: c.pimentStrong),
              ),
              onTap: onProducts,
            ),
        ],
        if (insights.topProducts.isNotEmpty) ...[
          section(l.insightsTopProducts),
          for (final (i, p) in insights.topProducts.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: c.tintVertTendre,
                child: Text('${i + 1}', style: t.label),
              ),
              title: Text(p.name, style: t.body),
              trailing: Text(
                l.insightsSold('${p.quantity}', money(p.revenueMinor)),
                style: t.label.copyWith(color: c.textSecondary),
              ),
            ),
        ],
        if (insights.loyalCustomers.isNotEmpty) ...[
          section(l.insightsLoyal),
          Wrap(
            spacing: DymTokenSpace.s2,
            runSpacing: DymTokenSpace.s1,
            children: [
              for (final cust in insights.loyalCustomers)
                Chip(
                  avatar: Icon(
                    Icons.favorite_rounded,
                    size: 16,
                    color: c.piment,
                  ),
                  label: Text(l.insightsLoyalChip(cust.firstName, cust.orders)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
