import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_texts.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Finances (écran 57) : remboursements à exécuter, effectués ou échoués ;
/// paiements en attente.
class AdminFinanceViewModel extends AdminViewModel {
  new({required this.service});

  final AdminService service;

  RefundStatus _status = RefundStatus.pending;
  List<AdminRefund> _refunds = const [];
  List<AdminPendingPayment> _payments = const [];
  String? _actingId;
  Failure? _actionFailure;

  RefundStatus get status => _status;
  List<AdminRefund> get refunds => _refunds;
  List<AdminPendingPayment> get payments => _payments;
  bool get ready => !failed && !isBusy;
  String? get actingId => _actingId;
  Failure? get actionFailure => _actionFailure;

  Future<void> load() => run(service.currencies, () async {
    final refunds = await service.refunds(_status);
    final payments = await service.pendingPayments();
    if (refunds case Ok(:final value)) _refunds = value;
    if (payments case Ok(:final value)) _payments = value;
    return refunds.failureOrNull ?? payments.failureOrNull;
  });

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

/// Écran 57.
class AdminFinanceView extends StackedView<AdminFinanceViewModel> {
  const new({required this.service, super.key, this.clock = DateTime.now});

  final AdminService service;
  final DateTime Function() clock;

  @override
  AdminFinanceViewModel viewModelBuilder(BuildContext context) =>
      AdminFinanceViewModel(service: service);

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
    return AdminPage(
      title: l10n.adminNavFinance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: DymTokenSpace.s3),
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
                      (Text('${l10n.adminOnlinePayment} · ${p.reference}'), 2),
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
