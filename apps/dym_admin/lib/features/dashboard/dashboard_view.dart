import 'package:dym_admin/features/dashboard/admin_charts.dart';
import 'package:dym_admin/features/dashboard/ai_health_view.dart';
import 'package:dym_admin/features/ops/admin_metric.dart';
import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_admin/ui/admin_theme.dart';
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
    final actions = [
      AdminSegmented(
        options: [
          (false, l10n.adminDashboardOverview),
          (true, l10n.adminDashboardAi),
        ],
        selected: vm.ai,
        onSelect: (v) => vm.selectAi(value: v),
      ),
      if (!vm.ai)
        AdminSegmented(
          options: [
            ('day', l10n.dashboardDay),
            ('week', l10n.dashboardWeek),
            ('month', l10n.dashboardMonth),
          ],
          selected: vm.period,
          onSelect: vm.selectPeriod,
        ),
    ];
    AdminPage page(Widget child) => AdminPage(
      title: l10n.adminNavDashboard,
      subtitle: l10n.adminDashboardSubtitle,
      actions: actions,
      child: child,
    );
    if (vm.ai) return page(AdminAiHealthView(service: service));
    if (!vm.ready || d == null) {
      return page(
        AdminState(failure: vm.isBusy ? null : vm.failure, onRetry: vm.load),
      );
    }
    const gap = SizedBox(height: 14);
    return page(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminCardGrid(
            children: [
              _SalesCard(vm: vm),
              _StoresCard(vm: vm, onOpen: onOpen),
              _DeliveryCard(vm: vm),
              _TodoCard(vm: vm, onOpen: onOpen),
              if (vm.overview != null) _DailyCard(vm: vm),
              if (vm.overview case final o?) _JourneyCard(funnel: o.funnel),
            ],
          ),
          gap,
          if (vm.overview != null) ...[
            AdminRow(
              items: [
                (8, _TrendCard(vm: vm)),
                if (vm.overview case final o?)
                  (4, _OutcomesCard(outcomes: o.outcomes)),
              ],
            ),
            gap,
          ],
          AdminRow(
            items: [
              if (vm.exchanges case final x?) (4, _StoresByTypeCard(x: x)),
              if (vm.exchanges case final x?) (4, _ExchangesCard(x: x)),
              (4, _AudienceCard(data: d, coverage: vm.coverage)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ventes : montant livré, commandes livrées, panier moyen, rayons.
class _SalesCard extends StatelessWidget {
  const new({required this.vm});

  final AdminDashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final d = vm.data!;
    final o = vm.overview;
    final code = vm.currency;
    final sales = code == null ? null : o?.current.salesIn(code);
    final basket = code == null ? null : o?.current.basketIn(code);
    final total = d.topCategories.fold(0, (s, x) => s + x.quantity);
    final top = d.topCategories.fold(
      1,
      (m, x) => x.quantity > m ? x.quantity : m,
    );
    return AdminMetricCard(
      icon: Icons.eco_outlined,
      hue: AdminPalette.green,
      title: l10n.adminCardSales,
      metrics: [
        (
          value: sales == null ? '—' : vm.money(sales, code),
          unit: null,
          label: l10n.adminMetricSales,
        ),
        (
          value: '${o?.current.delivered ?? '—'}',
          unit: null,
          label: l10n.adminMetricDelivered,
        ),
        (
          value: basket == null ? '—' : vm.money(basket, code),
          unit: null,
          label: l10n.adminMetricBasket,
        ),
      ],
      caption: d.topCategories.isEmpty ? null : l10n.adminSoldByAisle,
      note: l10n.adminNoteSales,
      child: d.topCategories.isEmpty
          ? AdminEmpty(l10n.adminNoData)
          : Column(
              children: [
                for (final cat in d.topCategories.take(5))
                  AdminBarRow(
                    label: cat.label.resolve(locale),
                    value: '${cat.quantity}',
                    extra: l10n.adminPercent(
                      total == 0 ? 0 : (cat.quantity * 100 / total).round(),
                    ),
                    fraction: cat.quantity / top,
                    hue: AdminPalette.green,
                  ),
              ],
            ),
    );
  }
}

/// Boutiques : actives, à valider, clientes actives, les plus actives.
class _StoresCard extends StatelessWidget {
  const new({required this.vm, required this.onOpen});

  final AdminDashboardViewModel vm;
  final ValueChanged<DashboardLink> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final d = vm.data!;
    final top = d.topStores.fold(
      1,
      (m, s) => s.salesMinor > m ? s.salesMinor : m,
    );
    return AdminMetricCard(
      icon: Icons.storefront_outlined,
      hue: AdminPalette.blue,
      title: l10n.adminCardStores,
      action: TextButton(
        onPressed: () => onOpen(DashboardLink.stores),
        child: Text(l10n.adminSeeAll),
      ),
      metrics: [
        (
          value: '${d.activeVendors}',
          unit: null,
          label: l10n.adminMetricActive,
        ),
        (
          value: '${d.draftStores}',
          unit: null,
          label: l10n.adminMetricToValidate,
        ),
        (
          value: '${d.activeClients}',
          unit: null,
          label: l10n.adminMetricActiveClients,
        ),
      ],
      caption: d.topStores.isEmpty ? null : l10n.adminMostActiveStores,
      note: l10n.adminNoteStores,
      child: d.topStores.isEmpty
          ? AdminEmpty(l10n.adminNoData)
          : Column(
              children: [
                for (final s in d.topStores.take(5))
                  AdminBarRow(
                    label: s.name,
                    value: vm.money(s.salesMinor, s.currencyCode),
                    extra: l10n.adminOrdersCount(s.orders),
                    extraWidth: 96,
                    fraction: s.salesMinor / top,
                    hue: AdminPalette.blue,
                  ),
              ],
            ),
    );
  }
}

/// Livraison : taux de réussite, livreurs en ligne, prise en charge, issues.
class _DeliveryCard extends StatelessWidget {
  const new({required this.vm});

  final AdminDashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final d = vm.data!;
    final x = vm.dispatch;
    final out = vm.overview?.outcomes;
    final rate = d.deliveries.percent;
    final parts = out == null
        ? const <(String, int, AdminHue)>[]
        : [
            (l10n.adminOutcomeDelivered, out.delivered, AdminPalette.teal),
            (l10n.adminOutcomeInProgress, out.inProgress, AdminPalette.blue),
            (l10n.adminOutcomeRefused, out.refused, AdminPalette.rose),
            (l10n.adminOutcomeCancelled, out.cancelled, AdminPalette.amber),
          ];
    final sum = parts.fold(0, (s, p) => s + p.$2);
    final median = x?.medianAcceptMinutes;
    return AdminMetricCard(
      icon: Icons.two_wheeler_outlined,
      hue: AdminPalette.teal,
      title: l10n.adminCardDelivery,
      metrics: [
        (
          value: rate == null ? '—' : '$rate',
          unit: rate == null ? null : '%',
          label: l10n.adminMetricDeliveryRate,
        ),
        (
          value: x == null ? '—' : '${x.couriersOnline}',
          unit: x == null ? null : '/ ${x.couriersActive}',
          label: l10n.adminMetricCouriers,
        ),
        (
          value: switch (median) {
            null => '—',
            final m when m < 120 => '$m',
            final m when m < 2880 => '${(m / 60).round()}',
            final m => '${(m / 1440).round()}',
          },
          unit: switch (median) {
            null => null,
            final m when m < 120 => l10n.adminUnitMinutes,
            final m when m < 2880 => l10n.adminUnitHours,
            _ => l10n.adminUnitDays,
          },
          label: l10n.adminMetricAccept,
        ),
      ],
      caption: parts.isEmpty ? null : l10n.adminOrdersOutcome,
      note: x == null
          ? null
          : l10n.adminNoteDelivery('${x.relaunches}', '${x.autoRefused}'),
      child: parts.isEmpty
          ? AdminEmpty(l10n.adminNoData)
          : Column(
              children: [
                for (final (label, n, hue) in parts)
                  AdminBarRow(
                    label: label,
                    value: '$n',
                    extra: l10n.adminPercent(
                      sum == 0 ? 0 : (n * 100 / sum).round(),
                    ),
                    fraction: sum == 0 ? 0 : n / sum,
                    hue: hue,
                  ),
              ],
            ),
    );
  }
}

/// Ligne de « À traiter ».
typedef _Todo = ({
  int count,
  String label,
  String? late,
  String pill,
  AdminTone tone,
  DashboardLink link,
});

/// À traiter : chaque ligne ouvre l'écran où agir.
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
    final waiting = vm.dispatch?.waiting ?? 0;
    final rows = <_Todo>[
      if (d.stuckOrders > 0)
        (
          count: d.stuckOrders,
          label: l10n.adminStuckOrders,
          late: null,
          pill: l10n.adminPillOrder,
          tone: AdminTone.danger,
          link: DashboardLink.stuckOrders,
        ),
      if (waiting > 0)
        (
          count: waiting,
          label: l10n.adminMissionsWaiting,
          late: null,
          pill: l10n.adminPillCourier,
          tone: AdminTone.danger,
          link: DashboardLink.live,
        ),
      if (d.openDisputes > 0)
        (
          count: d.openDisputes,
          label: l10n.adminPendingDisputes,
          late: d.lateDisputes > 0
              ? l10n.adminLateDisputes(d.lateDisputes)
              : null,
          pill: l10n.adminPillDispute,
          tone: AdminTone.danger,
          link: DashboardLink.disputes,
        ),
      if (d.openTickets > 0)
        (
          count: d.openTickets,
          label: l10n.adminOpenTickets,
          late: d.lateTickets > 0 ? l10n.adminLateTickets(d.lateTickets) : null,
          pill: l10n.adminPillTicket,
          tone: AdminTone.warning,
          link: DashboardLink.tickets,
        ),
      if (d.draftStores > 0)
        (
          count: d.draftStores,
          label: l10n.adminDraftStores,
          late: null,
          pill: l10n.adminPillStore,
          tone: AdminTone.warning,
          link: DashboardLink.drafts,
        ),
    ];
    return AdminMetricCard(
      icon: Icons.warning_amber_rounded,
      hue: AdminPalette.rose,
      title: l10n.adminTodoTitle,
      metrics: [
        (
          value: '${d.openDisputes}',
          unit: null,
          label: l10n.adminMetricDisputes,
        ),
        (value: '${d.openTickets}', unit: null, label: l10n.adminMetricTickets),
        (value: '${d.stuckOrders}', unit: null, label: l10n.adminMetricStuck),
      ],
      note: rows.isEmpty ? null : l10n.adminNoteTodo,
      child: rows.isEmpty
          ? Row(
              children: [
                Icon(Icons.check_circle_rounded, color: c.brand, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.adminTodoNone,
                    style: t.body.copyWith(
                      color: c.brandDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                for (final row in rows)
                  InkWell(
                    onTap: () => onOpen(row.link),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AdminPalette.line),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 34,
                            child: Text(
                              '${row.count}',
                              style: t.title.copyWith(fontSize: 16),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  row.label,
                                  style: t.label.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (row.late case final late?)
                                  Text(
                                    late,
                                    style: t.label.copyWith(
                                      fontSize: 12,
                                      color: AdminPalette.rose.$1,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          AdminPill(row.pill, tone: row.tone),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AdminPalette.ink3,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Commandes dans le temps : une barre par point de la période.
class _DailyCard extends StatelessWidget {
  const new({required this.vm});

  final AdminDashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final o = vm.overview!;
    final values = [for (final p in o.series) p.orders];
    final peak = values.fold(0, (m, v) => v > m ? v : m);
    final hourly = vm.period == 'day';
    final every = values.length <= 8 ? 1 : (values.length / 5).ceil();
    String? at(int i) {
      if (i % every != 0 && i != values.length - 1) return null;
      final d = o.series[i].at.toLocal();
      return hourly
          ? material.formatTimeOfDay(TimeOfDay.fromDateTime(d))
          : material.formatShortMonthDay(d);
    }

    return AdminMetricCard(
      icon: Icons.bar_chart_rounded,
      hue: AdminPalette.blue,
      title: l10n.adminCardDaily,
      metrics: [
        (
          value: '${o.current.orders}',
          unit: null,
          label: l10n.adminMetricOrders,
        ),
        (
          value: '${o.current.delivered}',
          unit: null,
          label: l10n.adminMetricDelivered,
        ),
        (value: '$peak', unit: null, label: l10n.adminMetricPeak),
      ],
      note: l10n.adminNoteDaily,
      child: values.isEmpty
          ? AdminEmpty(l10n.adminNoData)
          : AdminColumnChart(
              values: values,
              hue: AdminPalette.blue,
              label: at,
              semanticLabel: l10n.adminCardDaily,
            ),
    );
  }
}

/// Parcours des clientes : de la visite à la livraison.
class _JourneyCard extends StatelessWidget {
  const new({required this.funnel});

  final AdminFunnel funnel;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final steps = [
      (l10n.adminFunnelActive, funnel.active),
      (l10n.adminFunnelViewed, funnel.viewed),
      (l10n.adminFunnelAdded, funnel.added),
      (l10n.adminFunnelOrdered, funnel.ordered),
      (l10n.adminFunnelDelivered, funnel.delivered),
    ];
    final top = steps.fold(1, (m, s) => s.$2 > m ? s.$2 : m);
    final conversion = funnel.active == 0
        ? null
        : (funnel.ordered * 100 / funnel.active).round();
    return AdminMetricCard(
      icon: Icons.route_outlined,
      hue: AdminPalette.orange,
      title: l10n.adminCardJourney,
      metrics: [
        (
          value: '${funnel.active}',
          unit: null,
          label: l10n.adminMetricVisitors,
        ),
        (
          value: '${funnel.ordered}',
          unit: null,
          label: l10n.adminFunnelOrdered,
        ),
        (
          value: conversion == null ? '—' : '$conversion',
          unit: conversion == null ? null : '%',
          label: l10n.adminMetricConversion,
        ),
      ],
      note: l10n.adminFunnelHelp,
      child: Column(
        children: [
          for (final (label, n) in steps)
            AdminBarRow(
              label: label,
              value: '$n',
              extra: l10n.adminPercent((n * 100 / top).round()),
              fraction: n / top,
              hue: AdminPalette.orange,
            ),
        ],
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
          AdminSegmented(
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

/// Grand chiffre avec son libellé, sur fond gris clair.
class _Stat extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AdminPalette.muted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: t.display.copyWith(fontSize: 20)),
          ),
          Text(
            label,
            maxLines: 2,
            style: t.label.copyWith(fontSize: 12, color: AdminPalette.ink3),
          ),
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
