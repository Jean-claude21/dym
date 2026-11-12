import 'package:dym_admin/features/disputes/disputes_viewmodel.dart';
import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_texts.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

IconData _reasonIcon(DisputeReason r) => switch (r) {
  DisputeReason.missingItem => Icons.priority_high_rounded,
  DisputeReason.wrongItem => Icons.swap_horiz_rounded,
  DisputeReason.damaged => Icons.inventory_2_rounded,
  DisputeReason.quality => Icons.sentiment_dissatisfied_rounded,
  DisputeReason.notDelivered => Icons.local_shipping_rounded,
  _ => Icons.help_outline_rounded,
};

/// Écran 54 : litiges ouverts, conversation et décision.
class AdminDisputesView extends StackedView<AdminDisputesViewModel> {
  const new({
    required this.service,
    super.key,
    this.initialId,
    this.clock = DateTime.now,
  });

  final AdminService service;
  final String? initialId;
  final DateTime Function() clock;

  @override
  AdminDisputesViewModel viewModelBuilder(BuildContext context) =>
      AdminDisputesViewModel(service: service, initialId: initialId);

  @override
  void onViewModelReady(AdminDisputesViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    AdminDisputesViewModel viewModel,
    Widget? child,
  ) {
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final now = clock();
    if (vm.failed || (vm.isBusy && vm.rows.isEmpty)) {
      return AdminPage(
        title: l10n.adminOpenDisputes,
        child: AdminState(
          failure: vm.isBusy ? null : vm.failure,
          onRetry: vm.load,
        ),
      );
    }
    final list = ListView(
      children: [
        if (vm.rows.isEmpty) AdminEmpty(l10n.adminNoDisputes),
        for (final r in vm.rows)
          _DisputeTile(
            row: r,
            selected: r.id == vm.selectedId,
            now: now,
            onTap: () => vm.select(r.id),
          ),
      ],
    );
    final selected = vm.selectedId;
    return AdminPage(
      title: l10n.adminOpenDisputes,
      scrollable: false,
      child: AdminSplit(
        list: list,
        detail: selected == null
            ? null
            : (vm.detail == null
                  ? AdminState(
                      failure: vm.loadingDetail ? null : vm.actionFailure,
                      onRetry: () => vm.select(selected),
                    )
                  : _Detail(vm: vm, now: now)),
        onCloseDetail: vm.close,
      ),
    );
  }
}

class _DisputeTile extends StatelessWidget {
  const new({
    required this.row,
    required this.selected,
    required this.now,
    required this.onTap,
  });

  final AdminDisputeRow row;
  final bool selected;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final late = now.difference(row.createdAt) > const Duration(hours: 24);
    return Padding(
      padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
      child: Material(
        color: selected ? c.tintVertTendre : c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          side: BorderSide(
            color: selected ? c.brand : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(DymTokenSpace.s3),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: late ? c.tintPimentClair : c.tintPeche,
                  child: Icon(
                    _reasonIcon(row.reason),
                    color: late ? c.pimentStrong : c.textPrimary,
                  ),
                ),
                const SizedBox(width: DymTokenSpace.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disputeReasonLabel(l10n, row.reason),
                        style: t.title.copyWith(fontSize: 16),
                      ),
                      Text(
                        '${row.storeName} · '
                        '${agoLabel(l10n, row.createdAt, now)}',
                        style: t.label.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (late) AdminPill(l10n.adminOver24h, tone: AdminTone.danger),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatefulWidget {
  const new({required this.vm, required this.now});

  final AdminDisputesViewModel vm;
  final DateTime now;

  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  final _reply = TextEditingController();

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = widget.vm;
    final d = vm.detail!;
    final dispute = d.dispute;
    final order = d.order;
    final total = vm.money(order.totalMinor, order.currencyCode);
    final locale = Localizations.localeOf(context).languageCode;
    final method = order.paymentMethod?.label.resolve(locale) ?? '';
    String author(DisputeMessage m) => switch (m.authorRole) {
      'client' => l10n.adminAuthorClient(dispute.customerFirstName ?? ''),
      'vendor' => l10n.adminAuthorVendor(dispute.storeName ?? ''),
      _ => l10n.disputeTeam,
    };
    final decided = dispute.refundMinor == null
        ? l10n.disputeNoAction
        : l10n.disputeRefunded(
            vm.money(dispute.refundMinor!, order.currencyCode),
          );
    return SingleChildScrollView(
      child: AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              disputeReasonLabel(l10n, dispute.reason),
              style: t.display.copyWith(fontSize: 28),
            ),
            Text(
              [
                l10n.adminOrderTitle(shortRef(order.id)),
                ?dispute.customerFirstName,
                ?dispute.storeName,
                l10n.adminPaidWith(total, method),
              ].join(' · '),
              style: t.body.copyWith(color: c.textSecondary),
            ),
            const Divider(height: DymTokenSpace.s5),
            for (final m in dispute.messages)
              Padding(
                padding: const EdgeInsets.only(bottom: DymTokenSpace.s3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author(m), style: t.title.copyWith(fontSize: 14)),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(DymTokenSpace.s2),
                      decoration: BoxDecoration(
                        color: switch (m.authorRole) {
                          'vendor' => c.tintVertTendre,
                          'admin' => c.tintVertTendre,
                          _ => c.background,
                        },
                        borderRadius: BorderRadius.circular(
                          DymTokenRadius.chip,
                        ),
                      ),
                      child: Text(m.body, style: t.body),
                    ),
                    Text(
                      agoLabel(l10n, m.createdAt, widget.now),
                      style: t.label.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            if (vm.actionFailure case final failure?)
              AdminAlert(adminFailureLabel(l10n, failure)),
            if (dispute.isOpen) ...[
              Row(
                children: [
                  Expanded(
                    child: DymTextField(
                      label: l10n.adminReplyHint,
                      controller: _reply,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  IconButton.filled(
                    tooltip: l10n.disputeSendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: c.brand,
                      minimumSize: const Size(52, 52),
                    ),
                    onPressed: vm.acting
                        ? null
                        : () async {
                            if (await vm.reply(_reply.text)) _reply.clear();
                          },
                    icon: Icon(Icons.send_rounded, color: c.onBrand),
                  ),
                ],
              ),
              const SizedBox(height: DymTokenSpace.s3),
              _Decision(vm: vm, total: total),
            ] else
              AdminAlert(decided, tone: AdminTone.warning),
          ],
        ),
      ),
    );
  }
}

class _Decision extends StatelessWidget {
  const new({required this.vm, required this.total});

  final AdminDisputesViewModel vm;
  final String total;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final symbol = vm.currencies[vm.detail!.order.currencyCode]?.symbol;
    return Container(
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        border: Border.all(color: c.background, width: 2),
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.adminDecision, style: t.title.copyWith(fontSize: 22)),
          RadioGroup<DisputeResolution>(
            groupValue: vm.resolution,
            onChanged: (r) => vm.setResolution(r ?? vm.resolution),
            child: Column(
              children: [
                RadioListTile<DisputeResolution>(
                  value: DisputeResolution.noAction,
                  contentPadding: EdgeInsets.zero,
                  activeColor: c.brand,
                  title: Text(l10n.adminCloseNoAction),
                ),
                RadioListTile<DisputeResolution>(
                  value: DisputeResolution.partialRefund,
                  contentPadding: EdgeInsets.zero,
                  activeColor: c.brand,
                  title: Text(l10n.adminRefundPart),
                ),
                if (vm.resolution == DisputeResolution.partialRefund)
                  Padding(
                    padding: const EdgeInsets.only(left: DymTokenSpace.s5),
                    child: DymTextField(
                      label: l10n.adminRefundAmount,
                      keyboardType: TextInputType.number,
                      suffixText: symbol,
                      onChanged: vm.setAmount,
                      message: l10n.adminRefundMax(total),
                    ),
                  ),
                RadioListTile<DisputeResolution>(
                  value: DisputeResolution.fullRefund,
                  contentPadding: EdgeInsets.zero,
                  activeColor: c.brand,
                  title: Text(l10n.adminRefundAll(total)),
                ),
              ],
            ),
          ),
          CheckboxListTile(
            value: vm.warnVendor,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: c.brand,
            onChanged: (v) => vm.setWarnVendor(value: v ?? false),
            title: Text(l10n.adminWarnVendor),
          ),
          DymTextField(
            label: l10n.adminInternalNote,
            minLines: 2,
            maxLines: 4,
            maxLength: 1000,
            onChanged: (v) => vm.note = v,
          ),
          const SizedBox(height: DymTokenSpace.s4),
          DymButton(
            label: l10n.adminResolve,
            icon: Icons.gavel_rounded,
            loading: vm.acting,
            onPressed: vm.canResolve ? vm.resolve : null,
          ),
        ],
      ),
    );
  }
}
