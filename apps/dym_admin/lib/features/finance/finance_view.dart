import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_texts.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Section des finances (écrans 70 et 57).
enum FinanceSection { revenue, refunds, payments }

/// Finances : revenus de la période (70), remboursements à exécuter,
/// effectués ou échoués, et paiements en attente (57).
class AdminFinanceViewModel extends AdminViewModel {
  new({
    required this.service,
    FinanceSection initialSection = FinanceSection.revenue,
  }) : _section = initialSection;

  final AdminService service;

  FinanceSection _section;
  String _period = 'month';
  AdminRevenue? _revenue;
  RefundStatus _status = RefundStatus.pending;
  List<AdminRefund> _refunds = const [];
  List<AdminPendingPayment> _payments = const [];
  String? _actingId;
  Failure? _actionFailure;

  FinanceSection get section => _section;
  String get period => _period;
  AdminRevenue? get revenue => _revenue;
  RefundStatus get status => _status;
  List<AdminRefund> get refunds => _refunds;
  List<AdminPendingPayment> get payments => _payments;
  bool get ready => !failed && !isBusy;
  String? get actingId => _actingId;
  Failure? get actionFailure => _actionFailure;

  Future<void> load() => run(service.currencies, () async {
    final revenue = await service.revenue(_period);
    final refunds = await service.refunds(_status);
    final payments = await service.pendingPayments();
    if (revenue case Ok(:final value)) _revenue = value;
    if (refunds case Ok(:final value)) _refunds = value;
    if (payments case Ok(:final value)) _payments = value;
    return revenue.failureOrNull ??
        refunds.failureOrNull ??
        payments.failureOrNull;
  });

  void selectSection(FinanceSection value) {
    _section = value;
    notifyListeners();
  }

  Future<void> selectPeriod(String value) async {
    _period = value;
    await load();
  }

  Future<void> selectStatus(RefundStatus value) async {
    _status = value;
    await load();
  }

  /// Exécution par le fournisseur, ou remis en main propre pour le cash.
  Future<void> settle(AdminRefund refund) async {
    if (_actingId != null) return;
    _actingId = refund.id;
    _actionFailure = null;
    notifyListeners();
    final result = refund.isCash
        ? await service.markCashRefund(refund.id)
        : await service.executeRefund(refund.id);
    _actionFailure = result.failureOrNull;
    if (await service.refunds(_status) case Ok(:final value)) _refunds = value;
    _actingId = null;
    notifyListeners();
  }
}

/// Écrans 70 et 57.
class AdminFinanceView extends StackedView<AdminFinanceViewModel> {
  const new({
    required this.service,
    super.key,
    this.clock = DateTime.now,
    this.initialSection = FinanceSection.revenue,
  });

  final AdminService service;
  final DateTime Function() clock;
  final FinanceSection initialSection;

  @override
  AdminFinanceViewModel viewModelBuilder(BuildContext context) =>
      AdminFinanceViewModel(service: service, initialSection: initialSection);

  @override
  void onViewModelReady(AdminFinanceViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    AdminFinanceViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final now = clock();
    final wide = DymWindowClass.of(context) >= DymWindowClass.expanded;
    Widget row(List<(Widget, int)> cells) => Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s1),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.background)),
      ),
      child: wide
          ? Row(
              children: [
                for (final (w, flex) in cells)
                  Expanded(
                    flex: flex,
                    child: Align(alignment: Alignment.centerLeft, child: w),
                  ),
              ],
            )
          : Wrap(
              spacing: DymTokenSpace.s3,
              runSpacing: DymTokenSpace.s1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [for (final (w, _) in cells) w],
            ),
    );
    Text head(String s) => Text(
      s,
      style: t.label.copyWith(
        color: c.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
    if (!vm.ready) {
      return AdminPage(
        title: l10n.adminNavFinance,
        child: AdminState(
          failure: vm.isBusy ? null : vm.failure,
          onRetry: vm.load,
        ),
      );
    }
    final sections = Wrap(
      spacing: DymTokenSpace.s2,
      runSpacing: DymTokenSpace.s2,
      children: [
        for (final (s, label) in [
          (FinanceSection.revenue, l10n.adminRevenue),
          (FinanceSection.refunds, l10n.adminRefunds),
          (FinanceSection.payments, l10n.adminPendingPayments),
        ])
          DymFilterChip(
            label: label,
            selected: vm.section == s,
            onTap: () => vm.selectSection(s),
          ),
      ],
    );
    return AdminPage(
      title: l10n.adminNavFinance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sections,
          const SizedBox(height: DymTokenSpace.s3),
          if (vm.section == FinanceSection.revenue)
            _Revenue(vm: vm, row: row, head: head),
          if (vm.section == FinanceSection.refunds)
            AdminCard(
              title: l10n.adminRefunds,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: DymTokenSpace.s2,
                    runSpacing: DymTokenSpace.s2,
                    children: [
                      for (final s in const [
                        RefundStatus.pending,
                        RefundStatus.succeeded,
                        RefundStatus.failed,
                      ])
                        DymFilterChip(
                          label: switch (s) {
                            RefundStatus.pending => l10n.adminRefundPending,
                            RefundStatus.succeeded => l10n.adminRefundsDone,
                            _ => l10n.adminRefundsFailed,
                          },
                          selected: vm.status == s,
                          onTap: () => vm.selectStatus(s),
                        ),
                    ],
                  ),
                  const SizedBox(height: DymTokenSpace.s2),
                  if (vm.actionFailure case final failure?)
                    AdminAlert(adminFailureLabel(l10n, failure)),
                  if (vm.refunds.isEmpty)
                    AdminEmpty(l10n.adminNoRefunds)
                  else ...[
                    if (wide)
                      row([
                        (head(l10n.adminEntityOrder), 2),
                        (head(l10n.adminRefundReason), 2),
                        (head(l10n.adminRefundMethod), 2),
                        (head(l10n.adminColAmount), 2),
                        (head(l10n.adminRequested), 2),
                        (const SizedBox.shrink(), 3),
                      ]),
                    for (final r in vm.refunds)
                      row([
                        (
                          Text(
                            r.orderReference ?? '',
                            style: t.title.copyWith(
                              fontSize: 15,
                              color: c.brandDeep,
                            ),
                          ),
                          2,
                        ),
                        (
                          Text(
                            r.reason == 'dispute'
                                ? l10n.adminEntityDispute
                                : l10n.adminCancellation,
                          ),
                          2,
                        ),
                        (
                          Text(
                            r.isCash ? l10n.adminCash : l10n.adminOnlinePayment,
                          ),
                          2,
                        ),
                        (
                          Text(
                            vm.money(r.amountMinor, r.currencyCode),
                            style: t.title.copyWith(fontSize: 15),
                          ),
                          2,
                        ),
                        (Text(agoLabel(l10n, r.createdAt, now)), 2),
                        (
                          r.actionable
                              ? DymButton(
                                  label: r.isCash
                                      ? l10n.adminMarkCashRefunded
                                      : (r.status == RefundStatus.failed
                                            ? l10n.adminRetry
                                            : l10n.adminExecute),
                                  compact: true,
                                  expanded: false,
                                  variant: r.isCash
                                      ? DymButtonVariant.secondary
                                      : DymButtonVariant.primary,
                                  loading: vm.actingId == r.id,
                                  onPressed: vm.actingId == null
                                      ? () => vm.settle(r)
                                      : null,
                                )
                              : AdminPill(
                                  switch (r.status) {
                                    RefundStatus.succeeded =>
                                      l10n.adminRefundSucceeded,
                                    RefundStatus.processing =>
                                      l10n.adminRefundProcessing,
                                    _ => l10n.adminRefundFailed,
                                  },
                                  tone: r.status == RefundStatus.succeeded
                                      ? AdminTone.success
                                      : AdminTone.warning,
                                ),
                          3,
                        ),
                      ]),
                  ],
                ],
              ),
            ),
          if (vm.section == FinanceSection.payments)
            AdminCard(
              title: l10n.adminPendingPayments,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (vm.payments.isEmpty)
                    AdminEmpty(l10n.adminNoPendingPayments)
                  else ...[
                    if (wide)
                      row([
                        (head(l10n.adminEntityOrder), 3),
                        (head(l10n.adminRefundMethod), 2),
                        (head(l10n.adminColAmount), 2),
                        (head(l10n.adminColSince), 2),
                        (head(l10n.adminColStatus), 2),
                      ]),
                    for (final p in vm.payments)
                      row([
                        (
                          Text(
                            [
                              for (final o in p.orders)
                                '${o.reference} · ${o.storeName}',
                            ].join('\n'),
                            style: t.title.copyWith(
                              fontSize: 15,
                              color: c.brandDeep,
                            ),
                          ),
                          3,
                        ),
                        (
                          Text('${l10n.adminOnlinePayment} · ${p.reference}'),
                          2,
                        ),
                        (
                          Text(
                            vm.money(p.amountMinor, p.currencyCode),
                            style: t.title.copyWith(fontSize: 15),
                          ),
                          2,
                        ),
                        (Text(sinceLabel(l10n, p.createdAt, now)), 2),
                        (
                          AdminPill(
                            l10n.orderStatusPending,
                            tone: AdminTone.warning,
                            icon: Icons.schedule_rounded,
                          ),
                          2,
                        ),
                      ]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Revenus de la période (écran 70) : ventes encaissées, commission DYM, net
/// des vendeuses et remboursements, puis le détail par boutique. Tous les
/// montants viennent de la base.
class _Revenue extends StatelessWidget {
  const new({required this.vm, required this.row, required this.head});

  final AdminFinanceViewModel vm;
  final Widget Function(List<(Widget, int)> cells) row;
  final Text Function(String s) head;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final wide = DymWindowClass.of(context) >= DymWindowClass.expanded;
    final revenue = vm.revenue;
    final totals = revenue?.totals ?? const <RevenueTotal>[];
    String sum(int Function(RevenueTotal r) pick) => totals.isEmpty
        ? '—'
        : [for (final r in totals) vm.money(pick(r), r.currencyCode)]
              .join(' · ');
    Widget tile(
      IconData icon,
      String label,
      String value, {
      bool alert = false,
    }) => Container(
      width: 260,
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        border: Border.all(color: c.hairline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: alert ? c.tintPimentClair : c.tintVertTendre,
            child: Icon(icon, color: alert ? c.pimentStrong : c.brandDeep),
          ),
          const SizedBox(width: DymTokenSpace.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.label),
                Text(
                  value,
                  style: t.title.copyWith(
                    fontSize: 20,
                    color: alert ? c.pimentStrong : c.brandDeep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: DymTokenSpace.s2,
          runSpacing: DymTokenSpace.s2,
          children: [
            for (final (p, label) in [
              ('month', l10n.adminThisMonth),
              ('last_month', l10n.adminLastMonth),
              ('30d', l10n.admin30Days),
            ])
              DymFilterChip(
                label: label,
                selected: vm.period == p,
                onTap: () => vm.selectPeriod(p),
              ),
          ],
        ),
        const SizedBox(height: DymTokenSpace.s3),
        Wrap(
          spacing: DymTokenSpace.s3,
          runSpacing: DymTokenSpace.s3,
          children: [
            tile(
              Icons.bar_chart_rounded,
              l10n.adminSalesCollected,
              sum((r) => r.salesMinor),
            ),
            tile(
              Icons.savings_rounded,
              l10n.adminCommission,
              sum((r) => r.commissionMinor),
            ),
            tile(
              Icons.person_rounded,
              l10n.adminVendorNet,
              sum((r) => r.netMinor),
            ),
            tile(
              Icons.undo_rounded,
              l10n.adminRefunds,
              sum((r) => r.refundsMinor),
              alert: true,
            ),
          ],
        ),
        const SizedBox(height: DymTokenSpace.s3),
        AdminCard(
          title: l10n.adminByStore,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.adminCommissionNote,
                style: t.label.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: DymTokenSpace.s2),
              if (revenue == null || revenue.stores.isEmpty)
                AdminEmpty(l10n.adminNoData)
              else ...[
                if (wide)
                  row([
                    (head(l10n.adminColStore), 3),
                    (head(l10n.navOrders), 2),
                    (head(l10n.adminColSales), 2),
                    (head(l10n.adminCommission), 2),
                    (head(l10n.adminVendorNet), 2),
                  ]),
                for (final r in revenue.stores)
                  row([
                    (
                      Text(
                        r.storeName ?? '',
                        style: t.title.copyWith(
                          fontSize: 15,
                          color: c.brandDeep,
                        ),
                      ),
                      3,
                    ),
                    (
                      Text(
                        wide ? '${r.orders}' : l10n.adminOrdersCount(r.orders),
                      ),
                      2,
                    ),
                    (Text(vm.money(r.salesMinor, r.currencyCode)), 2),
                    (Text(vm.money(r.commissionMinor, r.currencyCode)), 2),
                    (
                      Text(
                        vm.money(r.netMinor, r.currencyCode),
                        style: t.title.copyWith(fontSize: 15),
                      ),
                      2,
                    ),
                  ]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
