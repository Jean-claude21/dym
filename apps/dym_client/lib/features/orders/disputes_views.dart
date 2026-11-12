import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_client/features/orders/order_texts.dart';
import 'package:dym_client/features/orders/orders_service.dart';
import 'package:dym_client/features/orders/orders_viewmodels.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

String disputeReasonLabel(DymLocalizations l10n, DisputeReason r) =>
    switch (r) {
      DisputeReason.missingItem => l10n.disputeReasonMissingItem,
      DisputeReason.wrongItem => l10n.disputeReasonWrongItem,
      DisputeReason.damaged => l10n.disputeReasonDamaged,
      DisputeReason.quality => l10n.disputeReasonQuality,
      DisputeReason.notDelivered => l10n.disputeReasonNotDelivered,
      _ => l10n.disputeReasonOther,
    };

IconData _reasonIcon(DisputeReason r) => switch (r) {
  DisputeReason.missingItem => Icons.shopping_bag_rounded,
  DisputeReason.wrongItem => Icons.inventory_2_rounded,
  DisputeReason.damaged => Icons.broken_image_rounded,
  DisputeReason.quality => Icons.sentiment_dissatisfied_rounded,
  DisputeReason.notDelivered => Icons.local_shipping_rounded,
  _ => Icons.more_horiz_rounded,
};

// ------------------------------------------------------------------ 49

/// Écran 49 : signaler un problème sur une commande.
class ReportProblemView extends StackedView<ReportProblemViewModel> {
  const new({
    required this.service,
    required this.orderId,
    required this.storeName,
    required this.onBack,
    required this.onSent,
    super.key,
  });

  final OrdersService service;
  final String orderId;
  final String storeName;
  final VoidCallback onBack;
  final void Function(Dispute dispute) onSent;

  @override
  ReportProblemViewModel viewModelBuilder(BuildContext context) =>
      ReportProblemViewModel(
        service: service,
        orderId: orderId,
        onSent: onSent,
      );

  @override
  Widget builder(
    BuildContext context,
    ReportProblemViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final error = switch (vm.failure) {
      ValidationFailure(message: 'dispute_already_open') =>
        l10n.disputeAlreadyOpen,
      ValidationFailure(message: 'dispute_not_allowed') =>
        l10n.disputeNotAllowed,
      NetworkFailure() => l10n.errorOffline,
      null => null,
      _ => l10n.errorGeneric,
    };
    final children = <Widget>[
      Text(l10n.disputeWhatHappened, style: t.title.copyWith(fontSize: 20)),
      const SizedBox(height: DymTokenSpace.s2),
      RadioGroup<DisputeReason>(
        groupValue: vm.reason,
        onChanged: (r) => vm.selectReason(r ?? vm.reason),
        child: Column(
          children: [
            for (final r in const [
              DisputeReason.missingItem,
              DisputeReason.wrongItem,
              DisputeReason.damaged,
              DisputeReason.quality,
              DisputeReason.notDelivered,
              DisputeReason.other,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: DymTokenSpace.s1),
                child: Material(
                  color: c.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                    side: BorderSide(
                      color: vm.reason == r ? c.brand : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: RadioListTile<DisputeReason>(
                    value: r,
                    activeColor: c.brand,
                    controlAffinity: ListTileControlAffinity.trailing,
                    secondary: Icon(_reasonIcon(r), color: c.brandDeep),
                    title: Text(
                      disputeReasonLabel(l10n, r),
                      style: t.title.copyWith(fontSize: 16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: DymTokenSpace.s3),
      DymTextField(
        label: l10n.disputeTellUs,
        minLines: 3,
        maxLines: 6,
        maxLength: 500,
        textCapitalization: TextCapitalization.sentences,
        onChanged: vm.setDescription,
        status: vm.showErrors && !vm.descriptionValid
            ? DymFieldStatus.error
            : DymFieldStatus.none,
        message: vm.showErrors && !vm.descriptionValid
            ? l10n.disputeDescriptionInvalid
            : null,
      ),
      Row(
        children: [
          Icon(Icons.info_rounded, color: c.brand, size: 20),
          const SizedBox(width: DymTokenSpace.s1),
          Expanded(
            child: Text(
              l10n.disputeWhoAnswers,
              style: t.label.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
      if (error != null) CartIssue(label: error),
    ];
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(
              title: l10n.disputeReport,
              subtitle: storeName,
              onBack: onBack,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  for (final w in children) DymContentWidth.form(child: w),
                ],
              ),
            ),
            DymContentWidth.form(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: DymButton(
                  label: l10n.disputeSend,
                  icon: Icons.send_rounded,
                  loading: vm.isBusy,
                  onPressed: vm.isBusy ? null : vm.send,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ 50

/// Écran 50 : mon signalement (fil, décision, réponse).
class DisputeView extends StackedView<DisputeViewModel> {
  const new({
    required this.service,
    required this.orderId,
    required this.onBack,
    super.key,
    this.clock = DateTime.now,
  });

  final OrdersService service;
  final String orderId;
  final VoidCallback onBack;
  final DateTime Function() clock;

  @override
  DisputeViewModel viewModelBuilder(BuildContext context) =>
      DisputeViewModel(service: service, orderId: orderId);

  @override
  void onViewModelReady(DisputeViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    DisputeViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final d = vm.dispute;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(
              title: l10n.disputeMine,
              subtitle: d?.storeName,
              onBack: onBack,
            ),
            Expanded(
              child: !vm.ready || d == null
                  ? DiscoveryState(
                      failure: vm.isBusy ? null : vm.failure,
                      onRetry: vm.load,
                    )
                  : _Thread(vm: vm, dispute: d, now: clock()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thread extends StatefulWidget {
  const new({required this.vm, required this.dispute, required this.now});

  final DisputeViewModel vm;
  final Dispute dispute;
  final DateTime now;

  @override
  State<_Thread> createState() => _ThreadState();
}

class _ThreadState extends State<_Thread> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final d = widget.dispute;
    final vm = widget.vm;
    final refund = d.refundMinor == null ? null : vm.money(d.refundMinor!);
    final children = <Widget>[
      CartCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DymTokenSpace.s2,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: d.isOpen ? c.tintVertTendre : c.muted,
                borderRadius: BorderRadius.circular(DymTokenRadius.chip),
              ),
              child: Text(
                d.isOpen ? l10n.disputeOpenStatus : l10n.disputeResolvedStatus,
                style: t.label.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: DymTokenSpace.s1),
            Text(
              '${disputeReasonLabel(l10n, d.reason)} · '
              '${timeAgo(l10n, d.createdAt, widget.now)}',
              style: t.label.copyWith(color: c.textSecondary, fontSize: 15),
            ),
            if (!d.isOpen)
              Padding(
                padding: const EdgeInsets.only(top: DymTokenSpace.s1),
                child: Text(
                  refund == null
                      ? l10n.disputeNoAction
                      : l10n.disputeRefunded(refund.format()),
                  style: t.title.copyWith(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: DymTokenSpace.s3),
      for (final m in d.messages)
        Padding(
          padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
          child: Container(
            padding: const EdgeInsets.all(DymTokenSpace.s3),
            decoration: BoxDecoration(
              color: switch (m.authorRole) {
                'vendor' => c.tintVertTendre,
                'admin' => c.muted,
                _ => c.card,
              },
              borderRadius: BorderRadius.circular(DymTokenRadius.tile),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(switch (m.authorRole) {
                  'vendor' => d.storeName ?? '',
                  'admin' => l10n.disputeTeam,
                  _ => l10n.disputeYou,
                }, style: t.title.copyWith(fontSize: 15, color: c.brandDeep)),
                Text(m.body, style: t.body),
                Text(
                  timeAgo(l10n, m.createdAt, widget.now),
                  style: t.label.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ),
      if (vm.sendFailure != null)
        CartIssue(
          label: vm.sendFailure is NetworkFailure
              ? l10n.errorOffline
              : l10n.errorGeneric,
        ),
    ];
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              for (final w in children) DymContentWidth.form(child: w),
            ],
          ),
        ),
        if (d.isOpen)
          DymContentWidth.form(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: DymTextField(
                      label: l10n.disputeWriteMessage,
                      hint: l10n.disputeWriteMessage,
                      controller: _text,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: DymTokenSpace.s2),
                  IconButton.filled(
                    tooltip: l10n.disputeSendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: c.brand,
                      minimumSize: const Size(52, 52),
                    ),
                    onPressed: vm.sending
                        ? null
                        : () async {
                            if (await vm.send(_text.text)) _text.clear();
                          },
                    icon: Icon(Icons.send_rounded, color: c.onBrand),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
