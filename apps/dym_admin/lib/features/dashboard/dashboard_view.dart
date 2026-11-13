import 'package:dym_admin/features/dashboard/admin_charts.dart';
import 'package:dym_admin/features/dashboard/ai_health_view.dart';
import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Chiffre clé du pilotage (spec 073).
enum KpiKind { sales, orders, basket, deliveries, payments, signups }

/// Série affichée sur la courbe.
enum TrendMetric { orders, sales, delivered }

/// Destination ouverte depuis le tableau de bord.
enum DashboardLink {
  stuckOrders,
  disputes,
  tickets,
  drafts,
  orders,
  finance,
  clients,
  stores,
  live,
}

/// Chiffre prêt à afficher : valeur, valeur précédente, évolution.
class DashboardKpi {
  const new({
    required this.kind,
    required this.value,
    required this.previous,
    required this.spark,
    required this.link,
    this.delta,
    this.higherIsBetter = true,
  });

  final KpiKind kind;

  /// Texte de la valeur (montant, nombre, pourcentage) ; nul : pas de donnée.
  final String? value;
  final String? previous;

  /// Évolution en points de pourcentage ou en pour cent ; nulle : pas de
  /// comparaison possible.
  final int? delta;
  final List<double> spark;
  final DashboardLink link;
  final bool higherIsBetter;

  /// Nouveau : rien sur la période précédente.
  bool get isNew => delta == null && previous == null && value != null;
}

/// Tableau de bord de l'équipe (écran 67, refait par la spec 073).
class AdminDashboardViewModel extends AdminViewModel {
  new({required this.service, this.ai = false});

  final AdminService service;

  String period = 'day';
  AdminDashboard? data;

  /// Période comparée, courbe, entonnoir (spec 073).
  AdminOverview? overview;

  /// Positions hors zone (spec 065) ; absente si l'appel échoue.
  AdminCoverage? coverage;

  /// Livreurs et relances (spec 066) ; absente si l'appel échoue.
  AdminDispatch? dispatch;

  /// Messages, boutiques par origine, notifications (specs 070 à 072).
  AdminExchanges? exchanges;

  /// Section affichée : vue générale ou IA et paiements (77).
  bool ai;

  TrendMetric metric = TrendMetric.orders;

  void selectAi({required bool value}) {
    ai = value;
    notifyListeners();
  }

  void selectMetric(TrendMetric value) {
    metric = value;
    notifyListeners();
  }

  bool get ready => data != null && !failed;

  Future<void> load() => run(service.currencies, () async {
    final (result, over, cover, delivery, talk) = await (
      service.dashboard(period),
      service.overview(period),
      service.coverage(period),
      service.dispatch(period),
      service.exchanges(period),
    ).wait;
    if (result case Ok(:final value)) data = value;
    overview = over.valueOrNull;
    coverage = cover.valueOrNull;
    dispatch = delivery.valueOrNull;
    exchanges = talk.valueOrNull;
    return result.failureOrNull;
  });

  Future<void> selectPeriod(String value) async {
    period = value;
    await load();
  }

  /// Devise des montants du pilotage.
  String? get currency =>
      overview?.mainCurrency ?? data?.revenue.firstOrNull?.currencyCode;

  /// Unités d'une unité de compte dans la devise (100 pour deux décimales).
  int get _scale {
    final c = currencies[currency];
    if (c == null) return 1;
    var s = 1;
    for (var i = 0; i < c.minorUnits; i++) {
      s *= 10;
    }
    return s;
  }

  /// Évolution en % entre deux valeurs (nulle sans base).
  static int? change(num current, num previous) =>
      previous == 0 ? null : ((current - previous) * 100 / previous).round();

  /// Les six chiffres clés, comparés à la période précédente.
  List<DashboardKpi> get kpis {
    final o = overview;
    final code = currency;
    if (o == null) return const [];
    final cur = o.current;
    final prev = o.previous;
    final series = o.series;
    String? money(int? minor) =>
        minor == null || code == null ? null : this.money(minor, code);
    final salesCur = code == null ? 0 : cur.salesIn(code);
    final salesPrev = code == null ? 0 : prev.salesIn(code);
    final basketCur = code == null ? null : cur.basketIn(code);
    final basketPrev = code == null ? null : prev.basketIn(code);
    final delivCur = cur.deliveries.percent;
    final delivPrev = prev.deliveries.percent;
    final payCur = cur.payments.percent;
    final payPrev = prev.payments.percent;
    return [
      DashboardKpi(
        kind: KpiKind.sales,
        value: money(salesCur),
        previous: salesPrev == 0 ? null : money(salesPrev),
        delta: change(salesCur, salesPrev),
        spark: [
          if (code != null)
            for (final p in series) p.salesIn(code) / _scale,
        ],
        link: DashboardLink.finance,
      ),
      DashboardKpi(
        kind: KpiKind.orders,
        value: '${cur.orders}',
        previous: prev.orders == 0 ? null : '${prev.orders}',
        delta: change(cur.orders, prev.orders),
        spark: [for (final p in series) p.orders.toDouble()],
        link: DashboardLink.orders,
      ),
      DashboardKpi(
        kind: KpiKind.basket,
        value: money(basketCur),
        previous: money(basketPrev),
        delta: basketCur == null || basketPrev == null
            ? null
            : change(basketCur, basketPrev),
        spark: const [],
        link: DashboardLink.finance,
      ),
      DashboardKpi(
        kind: KpiKind.deliveries,
        value: delivCur?.toString(),
        previous: delivPrev?.toString(),
        // Taux : écart en points.
        delta: delivCur == null || delivPrev == null
            ? null
            : delivCur - delivPrev,
        spark: [for (final p in series) p.delivered.toDouble()],
        link: DashboardLink.orders,
      ),
      DashboardKpi(
        kind: KpiKind.payments,
        value: payCur?.toString(),
        previous: payPrev?.toString(),
        delta: payCur == null || payPrev == null ? null : payCur - payPrev,
        spark: const [],
        link: DashboardLink.finance,
      ),
      DashboardKpi(
        kind: KpiKind.signups,
        value: '${cur.signups}',
        previous: prev.signups == 0 ? null : '${prev.signups}',
        delta: change(cur.signups, prev.signups),
        spark: const [],
        link: DashboardLink.clients,
      ),
    ];
  }

  /// Valeurs de la courbe (ventes en unités de la devise).
  List<double> get trend {
    final o = overview;
    final code = currency;
    if (o == null) return const [];
    return [
      for (final p in o.series)
        switch (metric) {
          TrendMetric.orders => p.orders.toDouble(),
          TrendMetric.delivered => p.delivered.toDouble(),
          TrendMetric.sales => code == null ? 0 : p.salesIn(code) / _scale,
        },
    ];
  }

  /// Valeur d'un point formatée (info-bulle).
  String trendValue(int i) {
    final o = overview;
    final code = currency;
    if (o == null || i >= o.series.length) return '';
    final p = o.series[i];
    return switch (metric) {
      TrendMetric.orders => '${p.orders}',
      TrendMetric.delivered => '${p.delivered}',
      TrendMetric.sales => code == null ? '' : money(p.salesIn(code), code),
    };
  }

  /// Nombre compact pour l'axe (1 200 → 1,2 k).
  static String compact(double v) {
    if (v >= 1000000) return '${_trim(v / 1000000)} M';
    if (v >= 1000) return '${_trim(v / 1000)} k';
    return _trim(v);
  }

  static String _trim(double v) {
    final s = v >= 10 || v == v.roundToDouble()
        ? v.round().toString()
        : v.toStringAsFixed(1).replaceAll('.', ',');
    return s;
  }

  /// Rien à traiter (aucune alerte ouverte).
  bool get nothingToDo {
    final d = data;
    return d != null &&
        d.stuckOrders == 0 &&
        d.openDisputes == 0 &&
        d.openTickets == 0 &&
        d.draftStores == 0 &&
        (dispatch?.waiting ?? 0) == 0;
  }
}

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
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final d = vm.data;
    final toolbar = Wrap(
      spacing: DymTokenSpace.s4,
      runSpacing: DymTokenSpace.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Segmented(
          options: [
            (false, l10n.adminDashboardOverview),
            (true, l10n.adminDashboardAi),
          ],
          selected: vm.ai,
          onSelect: (v) => vm.selectAi(value: v),
        ),
        if (!vm.ai)
          _Segmented(
            options: [
              ('day', l10n.dashboardDay),
              ('week', l10n.dashboardWeek),
              ('month', l10n.dashboardMonth),
            ],
            selected: vm.period,
            onSelect: vm.selectPeriod,
          ),
      ],
    );
    if (vm.ai) {
      return AdminPage(
        title: l10n.adminNavDashboard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            toolbar,
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
            toolbar,
            const SizedBox(height: DymTokenSpace.s3),
            AdminState(
              failure: vm.isBusy ? null : vm.failure,
              onRetry: vm.load,
            ),
          ],
        ),
      );
    }
    const gap = SizedBox(height: DymTokenSpace.s3);
    return AdminPage(
      title: l10n.adminNavDashboard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          toolbar,
          gap,
          _TodoCard(vm: vm, onOpen: onOpen),
          gap,
          if (vm.overview != null) ...[
            _KpiGrid(vm: vm, onOpen: onOpen),
            gap,
            AdminRow(
              items: [
                (8, _TrendCard(vm: vm)),
                (4, _FunnelCard(funnel: vm.overview!.funnel)),
              ],
            ),
            gap,
          ],
          AdminRow(
            items: [
              if (vm.overview case final o?)
                (4, _OutcomesCard(outcomes: o.outcomes)),
              if (vm.dispatch case final x?)
                (4, _DeliveryCard(dispatch: x, onOpen: onOpen)),
              if (vm.exchanges case final x?) (4, _StoresByTypeCard(x: x)),
            ],
          ),
          gap,
          AdminRow(
            items: [
              if (vm.exchanges case final x?) (6, _ExchangesCard(x: x)),
              (6, _AudienceCard(data: d, coverage: vm.coverage)),
            ],
          ),
          gap,
          AdminRow(
            items: [
              (7, _TopStoresCard(vm: vm, onOpen: onOpen)),
              (5, _TopCategoriesCard(data: d)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Choix exclusif compact (période, section).
class _Segmented<T> extends StatelessWidget {
  const new({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
        border: Border.all(color: c.hairline),
      ),
      child: Wrap(
        children: [
          for (final (value, label) in options)
            Semantics(
              selected: value == selected,
              button: true,
              child: Material(
                color: value == selected ? c.brand : Colors.transparent,
                borderRadius: BorderRadius.circular(DymTokenRadius.chip - 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(DymTokenRadius.chip - 2),
                  onTap: () => onSelect(value),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 40),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DymTokenSpace.s3,
                        vertical: 8,
                      ),
                      child: Text(
                        label,
                        style: t.label.copyWith(
                          fontWeight: FontWeight.w600,
                          color: value == selected ? c.onBrand : c.textPrimary,
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

/// Alertes à traiter, chacune ouvre l'écran où agir.
class _TodoCard extends StatelessWidget {
  const new({required this.vm, required this.onOpen});

  final AdminDashboardViewModel vm;
  final ValueChanged<DashboardLink> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final d = vm.data!;
    if (vm.nothingToDo) {
      return AdminCard(
        color: c.tintVertTendre,
        borderColor: c.tintVertTendre,
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: c.brandDeep),
            const SizedBox(width: DymTokenSpace.s2),
            Text(
              l10n.adminTodoNone,
              style: t.body.copyWith(
                color: c.brandDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    final items = [
      if (d.stuckOrders > 0)
        _TodoItem(
          icon: Icons.error_rounded,
          count: d.stuckOrders,
          label: l10n.adminStuckOrders,
          danger: true,
          onTap: () => onOpen(DashboardLink.stuckOrders),
        ),
      if ((vm.dispatch?.waiting ?? 0) > 0)
        _TodoItem(
          icon: Icons.two_wheeler_rounded,
          count: vm.dispatch!.waiting,
          label: l10n.adminMissionsWaiting,
          danger: true,
          onTap: () => onOpen(DashboardLink.live),
        ),
      if (d.openDisputes > 0)
        _TodoItem(
          icon: Icons.gavel_rounded,
          count: d.openDisputes,
          label: l10n.adminPendingDisputes,
          note: d.lateDisputes > 0
              ? l10n.adminLateDisputes(d.lateDisputes)
              : null,
          onTap: () => onOpen(DashboardLink.disputes),
        ),
      if (d.openTickets > 0)
        _TodoItem(
          icon: Icons.forum_rounded,
          count: d.openTickets,
          label: l10n.adminOpenTickets,
          note: d.lateTickets > 0 ? l10n.adminLateTickets(d.lateTickets) : null,
          onTap: () => onOpen(DashboardLink.tickets),
        ),
      if (d.draftStores > 0)
        _TodoItem(
          icon: Icons.storefront_rounded,
          count: d.draftStores,
          label: l10n.adminDraftStores,
          onTap: () => onOpen(DashboardLink.drafts),
        ),
    ];
    return AdminCard(
      title: l10n.adminTodoTitle,
      child: Wrap(
        spacing: DymTokenSpace.s3,
        runSpacing: DymTokenSpace.s3,
        children: items,
      ),
    );
  }
}

class _TodoItem extends StatelessWidget {
  const new({
    required this.icon,
    required this.count,
    required this.label,
    required this.onTap,
    this.note,
    this.danger = false,
  });

  final IconData icon;
  final int count;
  final String label;
  final String? note;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final (bg, fg) = danger
        ? (c.tintPimentClair, c.pimentStrong)
        : (c.tintPeche, c.originMaisonFg);
    return SizedBox(
      width: 260,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        child: InkWell(
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(DymTokenSpace.s3),
            child: Row(
              children: [
                Icon(icon, color: fg),
                const SizedBox(width: DymTokenSpace.s2),
                Text(
                  '$count',
                  style: t.title.copyWith(fontSize: 28, color: fg),
                ),
                const SizedBox(width: DymTokenSpace.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: t.label.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (note case final n?)
                        Text(
                          n,
                          style: t.label.copyWith(color: fg, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: fg, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Six chiffres clés : 6 colonnes sur grand écran, 3 sur tablette, 2 sur
/// téléphone.
class _KpiGrid extends StatelessWidget {
  const new({required this.vm, required this.onOpen});

  final AdminDashboardViewModel vm;
  final ValueChanged<DashboardLink> onOpen;

  @override
  Widget build(BuildContext context) {
    final kpis = vm.kpis;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final cols = w >= 1200
            ? 6
            : w >= 720
            ? 3
            : (w >= 340 ? 2 : 1);
        const gap = DymTokenSpace.s3;
        final width = (w - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final k in kpis)
              SizedBox(
                width: width,
                child: _KpiCard(
                  kpi: k,
                  period: vm.period,
                  onTap: () => onOpen(k.link),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const new({required this.kpi, required this.period, required this.onTap});

  final DashboardKpi kpi;
  final String period;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final (icon, label) = switch (kpi.kind) {
      KpiKind.sales => (Icons.payments_rounded, l10n.adminKpiSales),
      KpiKind.orders => (Icons.shopping_bag_rounded, l10n.adminKpiOrders),
      KpiKind.basket => (Icons.shopping_basket_rounded, l10n.adminKpiBasket),
      KpiKind.deliveries => (
        Icons.local_shipping_rounded,
        l10n.adminKpiDeliveries,
      ),
      KpiKind.payments => (Icons.credit_card_rounded, l10n.adminKpiPayments),
      KpiKind.signups => (Icons.person_add_rounded, l10n.adminKpiSignups),
    };
    final rate = kpi.kind == KpiKind.deliveries || kpi.kind == KpiKind.payments;
    String show(String? v) =>
        v == null ? '—' : (rate ? l10n.adminPercent(int.parse(v)) : v);
    final vs = switch (period) {
      'week' => l10n.adminVsWeek,
      'month' => l10n.adminVsMonth,
      _ => l10n.adminVsDay,
    };
    final delta = kpi.delta;
    final good = delta == null || delta == 0
        ? null
        : (delta > 0) == kpi.higherIsBetter;
    final (dbg, dfg) = switch (good) {
      true => (c.tintVertTendre, c.brandDeep),
      false => (c.tintPimentClair, c.pimentStrong),
      null => (c.muted, c.textSecondary),
    };
    final deltaText = switch (delta) {
      null => kpi.isNew ? l10n.adminDeltaNew : '—',
      0 => '= ${rate ? l10n.adminPoints(0) : l10n.adminPercent(0)}',
      final d => [
        if (d > 0) '▲' else '▼',
        if (rate) l10n.adminPoints(d.abs()) else l10n.adminPercent(d.abs()),
      ].join(' '),
    };
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        side: BorderSide(color: c.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: c.tintVertTendre,
                    child: Icon(icon, size: 18, color: c.brandDeep),
                  ),
                  const SizedBox(width: DymTokenSpace.s2),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      style: t.label.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DymTokenSpace.s2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  show(kpi.value),
                  style: t.display.copyWith(fontSize: 30, height: 1.1),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: dbg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      deltaText,
                      style: t.label.copyWith(
                        fontSize: 12,
                        color: dfg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    vs,
                    style: t.label.copyWith(
                      fontSize: 12,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DymTokenSpace.s2),
              if (kpi.spark.length > 1)
                AdminSparkline(values: kpi.spark, color: c.brand)
              else
                const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const new({required this.vm});

  final AdminDashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final series = vm.overview!.series;
    final hourly = vm.period == 'day';
    String at(int i) {
      final d = series[i].at.toLocal();
      return hourly
          ? material.formatTimeOfDay(TimeOfDay.fromDateTime(d))
          : material.formatShortMonthDay(d);
    }

    final label = switch (vm.metric) {
      TrendMetric.orders => l10n.adminTrendOrders,
      TrendMetric.sales => l10n.adminTrendSales,
      TrendMetric.delivered => l10n.adminTrendDelivered,
    };
    return AdminCard(
      title: l10n.adminTrendTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Segmented(
            options: [
              (TrendMetric.orders, l10n.adminTrendOrders),
              (TrendMetric.sales, l10n.adminTrendSales),
              (TrendMetric.delivered, l10n.adminTrendDelivered),
            ],
            selected: vm.metric,
            onSelect: vm.selectMetric,
          ),
          const SizedBox(height: DymTokenSpace.s3),
          AdminTrendChart(
            values: vm.trend,
            semanticLabel: '${l10n.adminTrendTitle} · $label',
            xLabel: at,
            yLabel: AdminDashboardViewModel.compact,
            tooltip: (i) => '${at(i)} · $label : ${vm.trendValue(i)}',
          ),
        ],
      ),
    );
  }
}

class _FunnelCard extends StatelessWidget {
  const new({required this.funnel});

  final AdminFunnel funnel;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return AdminCard(
      title: l10n.adminFunnelTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminFunnelChart(
            percent: l10n.adminPercent,
            steps: [
              (label: l10n.adminFunnelActive, value: funnel.active),
              (label: l10n.adminFunnelViewed, value: funnel.viewed),
              (label: l10n.adminFunnelAdded, value: funnel.added),
              (label: l10n.adminFunnelOrdered, value: funnel.ordered),
              (label: l10n.adminFunnelDelivered, value: funnel.delivered),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s3),
          Text(
            l10n.adminFunnelHelp,
            style: t.label.copyWith(fontSize: 12, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _OutcomesCard extends StatelessWidget {
  const new({required this.outcomes});

  final AdminOutcomes outcomes;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return AdminCard(
      title: l10n.adminOutcomesTitle,
      child: AdminDonut(
        centerLabel: l10n.adminOutcomesCenter,
        percent: l10n.adminPercent,
        parts: [
          (
            label: l10n.adminOutcomeDelivered,
            value: outcomes.delivered,
            color: c.brand,
          ),
          (
            label: l10n.adminOutcomeInProgress,
            value: outcomes.inProgress,
            color: c.plantain,
          ),
          (
            label: l10n.adminOutcomeRefused,
            value: outcomes.refused,
            color: c.pimentStrong,
          ),
          (
            label: l10n.adminOutcomeCancelled,
            value: outcomes.cancelled,
            color: c.textSecondary,
          ),
        ],
      ),
    );
  }
}

/// Grand chiffre avec son libellé (cliquable si [onTap]).
class _Stat extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    this.danger = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final fg = danger ? c.pimentStrong : c.textPrimary;
    return Material(
      color: danger ? c.tintPimentClair : c.background,
      borderRadius: BorderRadius.circular(DymTokenRadius.chip),
      child: InkWell(
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: t.title.copyWith(fontSize: 24, color: fg),
                ),
              ),
              Text(
                label,
                maxLines: 2,
                style: t.label.copyWith(
                  fontSize: 12,
                  color: danger ? fg : c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const new({required this.dispatch, required this.onOpen});

  final AdminDispatch dispatch;
  final ValueChanged<DashboardLink> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final x = dispatch;
    return AdminCard(
      title: l10n.adminDispatchTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: l10n.adminStatOnline,
                  value: l10n.adminCouriersOnlineValue(
                    x.couriersOnline,
                    x.couriersActive,
                  ),
                  onTap: () => onOpen(DashboardLink.live),
                ),
              ),
              const SizedBox(width: DymTokenSpace.s2),
              Expanded(
                child: _Stat(
                  label: l10n.adminStatWaiting,
                  value: '${x.waiting}',
                  danger: x.waiting > 0,
                  onTap: () => onOpen(DashboardLink.live),
                ),
              ),
              const SizedBox(width: DymTokenSpace.s2),
              Expanded(
                child: _Stat(
                  label: l10n.adminStatMedian,
                  value: switch (x.medianAcceptMinutes) {
                    final m? => l10n.adminMinutesValue(m),
                    null => '—',
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s3),
          AdminField(
            l10n.adminRelaunches,
            l10n.adminRelaunchesValue(x.relaunches, x.widened),
          ),
          AdminField(l10n.adminAutoRefused, '${x.autoRefused}'),
          AdminField(l10n.adminReadyAlerts, '${x.readyAlerts}'),
        ],
      ),
    );
  }
}

class _StoresByTypeCard extends StatelessWidget {
  const new({required this.x});

  final AdminExchanges x;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final palette = [
      c.brand,
      c.plantain,
      c.originMaisonFg,
      c.brandDeep,
      c.textSecondary,
    ];
    return AdminCard(
      title: l10n.adminStoresByOrigin,
      child: AdminDonut(
        centerLabel: l10n.adminStoresCenter,
        percent: l10n.adminPercent,
        parts: [
          for (final (i, o) in x.storesByOrigin.indexed)
            (
              label: o.label.resolve(locale),
              value: o.stores,
              color: palette[i % palette.length],
            ),
        ],
      ),
    );
  }
}

class _ExchangesCard extends StatelessWidget {
  const new({required this.x});

  final AdminExchanges x;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final total = x.pushSent + x.pushSkipped + x.pushFailed;
    final parts = [
      (l10n.adminPushLegendSent, x.pushSent, c.brand),
      (l10n.adminPushLegendHeld, x.pushSkipped, c.plantain),
      (l10n.adminPushLegendFailed, x.pushFailed, c.pimentStrong),
    ];
    return AdminCard(
      title: l10n.adminExchangesTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: l10n.adminStatMessages,
                  value: '${x.messages}',
                ),
              ),
              const SizedBox(width: DymTokenSpace.s2),
              Expanded(
                child: _Stat(
                  label: l10n.adminMessagesWithOrder,
                  value: '${x.messagesWithOrder}',
                ),
              ),
              const SizedBox(width: DymTokenSpace.s2),
              Expanded(
                child: _Stat(
                  label: l10n.adminStatConversations,
                  value: '${x.conversationsActive}',
                ),
              ),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s3),
          Text(
            l10n.adminPushSent,
            style: t.label.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              child: total == 0
                  ? ColoredBox(color: c.muted)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (_, v, color) in parts)
                          if (v > 0)
                            Expanded(
                              flex: v,
                              child: ColoredBox(color: color),
                            ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: DymTokenSpace.s3,
            runSpacing: 4,
            children: [
              for (final (label, v, color) in parts)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('$label · $v', style: t.label),
                  ],
                ),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s2),
          AdminField(l10n.adminQuietNightUsers, '${x.quietNightUsers}'),
        ],
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  const new({required this.data, required this.coverage});

  final AdminDashboard data;
  final AdminCoverage? coverage;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final cover = coverage;
    return AdminCard(
      title: l10n.adminActiveUsers7d,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: l10n.adminNavClients,
                  value: '${data.activeClients}',
                ),
              ),
              const SizedBox(width: DymTokenSpace.s2),
              Expanded(
                child: _Stat(
                  label: l10n.adminVendors,
                  value: '${data.activeVendors}',
                ),
              ),
            ],
          ),
          if (cover != null) ...[
            const SizedBox(height: DymTokenSpace.s3),
            Text(
              l10n.adminCoverageTitle,
              style: t.label.copyWith(
                color: c.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            AdminField(l10n.adminCoverageTotal, '${cover.total}'),
            for (final country in cover.countries)
              AdminField(
                country.countryCode,
                [
                  l10n.adminCoverageMisses(country.misses),
                  if (country.medianKm case final km?)
                    l10n.adminCoverageMedianKm(km),
                ].join(' · '),
              ),
            Text(
              l10n.adminCoverageHelp,
              style: t.label.copyWith(fontSize: 12, color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopStoresCard extends StatelessWidget {
  const new({required this.vm, required this.onOpen});

  final AdminDashboardViewModel vm;
  final ValueChanged<DashboardLink> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final stores = vm.data!.topStores;
    final head = t.label.copyWith(
      color: c.textSecondary,
      fontWeight: FontWeight.w600,
    );
    return AdminCard(
      title: l10n.adminTopStores,
      trailing: TextButton(
        onPressed: () => onOpen(DashboardLink.stores),
        child: Text(l10n.adminSeeAll),
      ),
      child: stores.isEmpty
          ? AdminEmpty(l10n.adminNoData)
          // Téléphone : une ligne par boutique plutôt qu'un tableau serré.
          : MediaQuery.sizeOf(context).width < 640
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, s) in stores.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${i + 1}',
                            style: t.label.copyWith(
                              color: c.brandDeep,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: t.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                [
                                  l10n.adminOrdersCount(s.orders),
                                  vm.money(s.salesMinor, s.currencyCode),
                                  if (s.rating case final r?)
                                    '★ ${r.toStringAsFixed(1)}',
                                ].join(' · '),
                                style: t.label.copyWith(color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          : Table(
              columnWidths: const {
                0: FixedColumnWidth(32),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(1.4),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(1.2),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.hairline)),
                  ),
                  children: [
                    const SizedBox(height: 32),
                    Text(l10n.adminColStore, style: head),
                    Text(
                      l10n.adminColOrders,
                      style: head,
                      textAlign: TextAlign.end,
                    ),
                    Text(
                      l10n.adminColSales,
                      style: head,
                      textAlign: TextAlign.end,
                    ),
                    Text(
                      l10n.adminColRating,
                      style: head,
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
                for (final (i, s) in stores.indexed)
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.hairline)),
                    ),
                    children: [
                      SizedBox(
                        height: 44,
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: t.label.copyWith(
                              color: c.brandDeep,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${s.orders}',
                        style: t.body,
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        vm.money(s.salesMinor, s.currencyCode),
                        style: t.body,
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        s.rating == null
                            ? '—'
                            : '★ ${s.rating!.toStringAsFixed(1)}',
                        style: t.body,
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _TopCategoriesCard extends StatelessWidget {
  const new({required this.data});

  final AdminDashboard data;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final total = data.topCategories.fold(0, (s, x) => s + x.quantity);
    final maxProduct = data.topProducts.fold(
      1,
      (m, x) => x.quantity > m ? x.quantity : m,
    );
    return AdminCard(
      title: l10n.adminTopCategories,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.topCategories.isEmpty) AdminEmpty(l10n.adminNoData),
          AdminBarList(
            rows: [
              for (final cat in data.topCategories)
                (
                  cat.label.resolve(locale),
                  l10n.adminPercent(
                    total == 0 ? 0 : (cat.quantity * 100 / total).round(),
                  ),
                  total == 0 ? 0 : cat.quantity / total,
                ),
            ],
          ),
          if (data.topProducts.isNotEmpty) ...[
            const SizedBox(height: DymTokenSpace.s3),
            Text(
              l10n.adminTopProducts,
              style: t.label.copyWith(
                color: c.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            AdminBarList(
              rows: [
                for (final p in data.topProducts)
                  (
                    [p.label.resolve(locale), ?p.detail].join(' · '),
                    '${p.quantity}',
                    p.quantity / maxProduct,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
