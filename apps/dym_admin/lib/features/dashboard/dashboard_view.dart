import 'package:dym_admin/features/dashboard/ai_health_view.dart';
import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Tableau de bord de l'équipe (écran 67).
class AdminDashboardViewModel extends AdminViewModel {
  new({required this.service, this.ai = false});

  final AdminService service;

  String period = 'day';
  AdminDashboard? data;

  /// Section affichée : vue générale ou IA et paiements (77).
  bool ai;

  void selectAi({required bool value}) {
    ai = value;
    notifyListeners();
  }

  bool get ready => data != null && !failed;

  Future<void> load() => run(service.currencies, () async {
    final result = await service.dashboard(period);
    if (result case Ok(:final value)) data = value;
    return result.failureOrNull;
  });

  Future<void> selectPeriod(String value) async {
    period = value;
    await load();
  }
}

/// Destination ouverte depuis une alerte du tableau de bord.
enum DashboardLink { stuckOrders, disputes, tickets, drafts }

class AdminDashboardView extends StackedView<AdminDashboardViewModel> {
  const new({
    required this.service,
    required this.onOpen,
    super.key,
    this.initialAi = false,
  });

  /// Ouvre sur « IA et paiements » (lien d'alerte, galerie).
  final bool initialAi;

  final AdminService service;
  final ValueChanged<DashboardLink> onOpen;

  @override
  AdminDashboardViewModel viewModelBuilder(BuildContext context) =>
      AdminDashboardViewModel(service: service, ai: initialAi);

  @override
  void onViewModelReady(AdminDashboardViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    AdminDashboardViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final vm = viewModel;
    final d = vm.data;
    final chips = Wrap(
      spacing: DymTokenSpace.s2,
      runSpacing: DymTokenSpace.s2,
      children: [
        for (final (p, label) in [
          ('day', l10n.dashboardDay),
          ('week', l10n.dashboardWeek),
          ('month', l10n.dashboardMonth),
        ])
          DymFilterChip(
            label: label,
            selected: vm.period == p,
            onTap: () => vm.selectPeriod(p),
          ),
      ],
    );
    final sections = Wrap(
      spacing: DymTokenSpace.s2,
      runSpacing: DymTokenSpace.s2,
      children: [
        for (final (ai, label) in [
          (false, l10n.adminDashboardOverview),
          (true, l10n.adminDashboardAi),
        ])
          DymFilterChip(
            label: label,
            selected: vm.ai == ai,
            onTap: () => vm.selectAi(value: ai),
          ),
      ],
    );
    if (vm.ai) {
      return AdminPage(
        title: l10n.adminNavDashboard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sections,
            const SizedBox(height: DymTokenSpace.s3),
            AdminAiHealthView(service: service),
          ],
        ),
      );
    }
    if (!vm.ready || d == null) {
      return AdminPage(
        title: l10n.adminNavDashboard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sections,
            const SizedBox(height: DymTokenSpace.s2),
            chips,
            const SizedBox(height: DymTokenSpace.s3),
            AdminState(
              failure: vm.isBusy ? null : vm.failure,
              onRetry: vm.load,
            ),
          ],
        ),
      );
    }
    String percent(int? p) => p == null ? '—' : l10n.adminPercent(p);
    Widget tile(
      IconData icon,
      String label,
      String value, {
      String? note,
      bool alertNote = true,
      AdminTone tone = AdminTone.neutral,
      VoidCallback? onTap,
    }) {
      final (bg, fg) = switch (tone) {
        AdminTone.danger => (c.tintPimentClair, c.pimentStrong),
        AdminTone.warning => (c.tintPlantainClair, c.textPrimary),
        AdminTone.success => (c.tintVertTendre, c.brandDeep),
        AdminTone.neutral => (c.card, c.textPrimary),
      };
      return SizedBox(
        width: 240,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(DymTokenSpace.s3),
              child: Row(
                children: [
                  Icon(icon, color: tone == AdminTone.neutral ? c.brand : fg),
                  const SizedBox(width: DymTokenSpace.s2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: t.label.copyWith(color: fg)),
                        Text(
                          value,
                          style: t.title.copyWith(fontSize: 24, color: fg),
                        ),
                        if (note != null)
                          Text(
                            note,
                            style: t.label.copyWith(
                              color: alertNote ? c.pimentStrong : fg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_rounded, color: fg),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final revenue = d.revenue.isEmpty
        ? '—'
        : [for (final r in d.revenue) vm.money(r.minor, r.currencyCode)]
              .join(' · ');
    final maxOrders = d.series.fold(1, (m, x) => x.orders > m ? x.orders : m);
    final totalCategories = d.topCategories.fold(0, (s, x) => s + x.quantity);
    return AdminPage(
      title: l10n.adminNavDashboard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sections,
          const SizedBox(height: DymTokenSpace.s2),
          chips,
          const SizedBox(height: DymTokenSpace.s3),
          Wrap(
            spacing: DymTokenSpace.s3,
            runSpacing: DymTokenSpace.s3,
            children: [
              tile(
                Icons.shopping_cart_rounded,
                l10n.adminActiveOrders,
                '${d.activeOrders}',
              ),
              tile(Icons.bar_chart_rounded, l10n.adminRevenueLabel, revenue),
              tile(
                Icons.credit_card_rounded,
                l10n.adminPaymentsSucceeded,
                percent(d.payments24h.percent),
                note: l10n.adminPaymentsLastHour(percent(d.payments1h.percent)),
                alertNote: (d.payments1h.percent ?? 100) < 90,
              ),
              tile(
                Icons.local_shipping_rounded,
                l10n.adminDeliveriesSucceeded,
                percent(d.deliveries.percent),
              ),
              tile(
                Icons.error_rounded,
                l10n.adminStuckOrders,
                '${d.stuckOrders}',
                tone: d.stuckOrders > 0 ? AdminTone.danger : AdminTone.success,
                onTap: () => onOpen(DashboardLink.stuckOrders),
              ),
              tile(
                Icons.schedule_rounded,
                l10n.adminPendingDisputes,
                '${d.openDisputes}',
                note: d.lateDisputes > 0
                    ? l10n.adminLateDisputes(d.lateDisputes)
                    : null,
                tone: d.openDisputes > 0
                    ? AdminTone.warning
                    : AdminTone.success,
                onTap: () => onOpen(DashboardLink.disputes),
              ),
              tile(
                Icons.forum_rounded,
                l10n.adminOpenTickets,
                '${d.openTickets}',
                note: d.lateTickets > 0
                    ? l10n.adminLateTickets(d.lateTickets)
                    : null,
                tone: AdminTone.success,
                onTap: () => onOpen(DashboardLink.tickets),
              ),
              tile(
                Icons.storefront_rounded,
                l10n.adminDraftStores,
                '${d.draftStores}',
                tone: AdminTone.success,
                onTap: () => onOpen(DashboardLink.drafts),
              ),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s3),
          Wrap(
            spacing: DymTokenSpace.s3,
            runSpacing: DymTokenSpace.s3,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: AdminCard(
                  title: l10n.adminOrders30d,
                  child: SizedBox(
                    height: 160,
                    child: Semantics(
                      label: l10n.adminOrders30d,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final day in d.series)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                child: FractionallySizedBox(
                                  heightFactor: (day.orders / maxOrders).clamp(
                                    0.02,
                                    1,
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: c.brand.withValues(alpha: 0.6),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: AdminCard(
                  title: l10n.adminActiveUsers7d,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminField(l10n.adminNavClients, '${d.activeClients}'),
                      AdminField(l10n.adminVendors, '${d.activeVendors}'),
                      AdminField(l10n.adminNewSignups, '${d.newSignups}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s3),
          Wrap(
            spacing: DymTokenSpace.s3,
            runSpacing: DymTokenSpace.s3,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: AdminCard(
                  title: l10n.adminTopStores,
                  child: Column(
                    children: [
                      if (d.topStores.isEmpty) AdminEmpty(l10n.adminNoData),
                      for (final s in d.topStores)
                        AdminField(
                          s.name,
                          [
                            l10n.adminOrdersCount(s.orders),
                            vm.money(s.salesMinor, s.currencyCode),
                            if (s.rating case final r?)
                              l10n.reviewAverage(r.toStringAsFixed(1)),
                          ].join(' · '),
                        ),
                    ],
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: AdminCard(
                  title: l10n.adminTopCategories,
                  child: Column(
                    children: [
                      if (d.topCategories.isEmpty) AdminEmpty(l10n.adminNoData),
                      for (final cat in d.topCategories)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  cat.label.resolve(locale),
                                  style: t.body,
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: LinearProgressIndicator(
                                  value: totalCategories == 0
                                      ? 0
                                      : cat.quantity / totalCategories,
                                  color: c.plantain,
                                  backgroundColor: c.background,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: DymTokenSpace.s2),
                              Text(
                                l10n.adminPercent(
                                  totalCategories == 0
                                      ? 0
                                      : (cat.quantity * 100 / totalCategories)
                                            .round(),
                                ),
                                style: t.label,
                              ),
                            ],
                          ),
                        ),
                      for (final p in d.topProducts)
                        AdminField(
                          [p.label.resolve(locale), ?p.detail].join(' · '),
                          '${p.quantity}',
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
