import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_client/features/orders/order_texts.dart';
import 'package:dym_client/features/wallet/qr_pay_view.dart';
import 'package:dym_client/features/wallet/wallet_service.dart';
import 'package:dym_client/features/wallet/wallet_viewmodel.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// « Mon wallet » (spec 025) : solde, poches, mouvements ; recharge simulée en
/// test, transferts, poches libres.
class WalletView extends StackedView<WalletViewModel> {
  const new({required this.service, required this.onBack, super.key});

  final WalletService service;
  final VoidCallback onBack;

  @override
  WalletViewModel viewModelBuilder(BuildContext context) =>
      WalletViewModel(service: service);

  @override
  void onViewModelReady(WalletViewModel viewModel) => viewModel.load();

  @override
  Widget builder(BuildContext context, WalletViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final wallet = vm.wallet;
    final Widget body;
    if (!vm.ready || wallet == null) {
      body = DiscoveryState(
        failure: vm.isBusy ? null : vm.failure,
        onRetry: vm.load,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            DymContentWidth.form(
              child: _BalanceCard(vm: vm, wallet: wallet),
            ),
            if (vm.walletError != null)
              DymContentWidth.form(
                child: CartIssue(
                  label: walletErrorLabel(l10n, vm.walletError!),
                ),
              ),
            const SizedBox(height: DymTokenSpace.s4),
            DymContentWidth.form(
              child: DymSectionHeader(
                title: l10n.walletPockets,
                actionLabel: l10n.walletNewPocket,
                onAction: vm.acting ? null : () => _newPocket(context, vm),
              ),
            ),
            if (wallet.pockets.isEmpty)
              DymContentWidth.form(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: DymTokenSpace.s2,
                  ),
                  child: Text(
                    l10n.walletPocketsEmpty,
                    style: context.dym.text.body.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),
            for (final pocket in wallet.pockets)
              DymContentWidth.form(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: DymTokenSpace.s3),
                  child: _PocketCard(
                    pocket: pocket,
                    vm: vm,
                    onArchive: vm.acting ? null : () => vm.archive(pocket.id),
                  ),
                ),
              ),
            const SizedBox(height: DymTokenSpace.s4),
            DymContentWidth.form(
              child: DymSectionHeader(title: l10n.walletMovements),
            ),
            if (wallet.movements.isEmpty)
              DymContentWidth.form(
                child: DymStateView(
                  kind: DymStateKind.empty,
                  title: l10n.walletMovements,
                  message: l10n.walletMovementsEmpty,
                ),
              ),
            for (final m in wallet.movements)
              DymContentWidth.form(
                child: _MovementRow(movement: m, vm: vm),
              ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(title: l10n.walletTitle, onBack: onBack),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  static Future<void> _newPocket(BuildContext context, WalletViewModel vm) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _PocketSheet(vm: vm),
      );
}

String walletErrorLabel(DymLocalizations l10n, WalletError error) =>
    switch (error) {
      WalletError.insufficient => l10n.walletErrorInsufficient,
      WalletError.amount => l10n.walletErrorAmount,
      WalletError.topupDisabled => l10n.walletErrorTopupDisabled,
      WalletError.pocketLimit => l10n.walletErrorPocketLimit,
      WalletError.offline => l10n.errorOffline,
      WalletError.generic => l10n.errorGeneric,
    };

class _BalanceCard extends StatelessWidget {
  const new({required this.vm, required this.wallet});

  final WalletViewModel vm;
  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(DymTokenSpace.s5),
      decoration: BoxDecoration(
        color: c.brand,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.walletAvailable, style: t.body.copyWith(color: c.onBrand)),
          const SizedBox(height: DymTokenSpace.s1),
          Text(
            vm.money(wallet.balanceMinor)?.format() ?? '',
            style: t.display.copyWith(color: c.onBrand),
          ),
          if (wallet.pockets.isNotEmpty)
            Text(
              l10n.walletTotal(vm.money(wallet.totalMinor)?.format() ?? ''),
              style: t.label.copyWith(color: c.onBrand),
            ),
          const SizedBox(height: DymTokenSpace.s2),
          // Paiement chez une vendeuse par QR (spec 046).
          DymButton(
            label: l10n.walletQrPay,
            icon: Icons.qr_code_scanner_rounded,
            variant: DymButtonVariant.surface,
            onPressed: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (route) => QrPayView(
                    service: vm.service,
                    onDone: () => Navigator.of(route).pop(),
                  ),
                ),
              );
              await vm.load();
            },
          ),
          // Recharge en cash auprès d'un livreur DYM (spec 043).
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _cashCodeSheet(context, vm),
              style: TextButton.styleFrom(
                foregroundColor: c.onBrand,
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.payments_rounded),
              label: Text(l10n.walletCashTopup),
            ),
          ),
          const SizedBox(height: DymTokenSpace.s4),
          Row(
            children: [
              if (wallet.simulatedTopup)
                Expanded(
                  child: DymButton(
                    label: l10n.walletTopup,
                    icon: Icons.add_card_rounded,
                    variant: DymButtonVariant.secondary,
                    onPressed: vm.acting
                        ? null
                        : () => _amountSheet(
                            context,
                            title: l10n.walletTopup,
                            note: l10n.walletTopupSimulated,
                            onConfirm: vm.topup,
                          ),
                  ),
                ),
              if (wallet.simulatedWithdrawal) ...[
                const SizedBox(width: DymTokenSpace.s3),
                Expanded(
                  child: DymButton(
                    label: l10n.walletWithdraw,
                    icon: Icons.account_balance_rounded,
                    variant: DymButtonVariant.secondary,
                    onPressed: vm.acting
                        ? null
                        : () => _amountSheet(
                            context,
                            title: l10n.walletWithdraw,
                            note: l10n.walletWithdrawSimulated,
                            onConfirm: vm.withdraw,
                          ),
                  ),
                ),
              ],
              if (wallet.simulatedTopup && wallet.pockets.isNotEmpty)
                const SizedBox(width: DymTokenSpace.s3),
              if (wallet.pockets.isNotEmpty)
                Expanded(
                  child: DymButton(
                    label: l10n.walletMove,
                    icon: Icons.swap_horiz_rounded,
                    variant: DymButtonVariant.secondary,
                    onPressed: vm.acting
                        ? null
                        : () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => _TransferSheet(vm: vm),
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

Future<void> _amountSheet(
  BuildContext context, {
  required String title,
  required Future<bool> Function(String amount) onConfirm,
  String? note,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _AmountSheet(title: title, note: note, onConfirm: onConfirm),
);

class _PocketCard extends StatelessWidget {
  const new({required this.pocket, required this.vm, required this.onArchive});

  final WalletPocket pocket;
  final WalletViewModel vm;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final progress = pocket.progress;
    return Container(
      padding: const EdgeInsets.all(DymTokenSpace.s4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.savings_rounded, color: c.brand),
              const SizedBox(width: DymTokenSpace.s2),
              Expanded(child: Text(pocket.name, style: t.title)),
              Text(
                vm.money(pocket.balanceMinor)?.format() ?? '',
                style: t.title,
              ),
              PopupMenuButton<void>(
                itemBuilder: (_) => [
                  PopupMenuItem<void>(
                    onTap: onArchive,
                    child: Text(l10n.walletPocketArchive),
                  ),
                ],
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: DymTokenSpace.s2),
            ClipRRect(
              borderRadius: BorderRadius.circular(DymTokenRadius.tile),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: c.brand,
                backgroundColor: c.tintVertTendre,
              ),
            ),
            const SizedBox(height: DymTokenSpace.s1),
            Text(
              l10n.walletPocketGoal(vm.money(pocket.goalMinor)?.format() ?? ''),
              style: t.label.copyWith(color: c.textSecondary),
            ),
          ],
          if (pocket.roundUpMinor != null)
            Text(
              l10n.walletPocketRoundUp(
                vm.money(pocket.roundUpMinor)?.format() ?? '',
              ),
              style: t.label.copyWith(color: c.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const new({required this.movement, required this.vm});

  final WalletMovement movement;
  final WalletViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final pocketName = vm.wallet?.pockets
        .where((p) => p.id == movement.pocketId)
        .firstOrNull
        ?.name;
    final (icon, label) = switch (movement.kind) {
      WalletMovementKind.walletTopup => (
        Icons.add_card_rounded,
        l10n.walletKindTopup,
      ),
      WalletMovementKind.walletTransfer => (
        Icons.swap_horiz_rounded,
        switch (pocketName) {
          final name? when movement.amountMinor < 0 => l10n.walletToPocket(
            name,
          ),
          final name? => l10n.walletFromPocket(name),
          null => l10n.walletKindTransfer,
        },
      ),
      WalletMovementKind.paymentReceived => (
        Icons.shopping_basket_rounded,
        l10n.walletKindPayment,
      ),
      WalletMovementKind.refundPaid => (
        Icons.undo_rounded,
        l10n.walletKindRefund,
      ),
      WalletMovementKind.cashback => (
        Icons.redeem_rounded,
        l10n.walletKindCashback,
      ),
      WalletMovementKind.spaceContribution => (
        Icons.groups_rounded,
        l10n.walletKindSpaceContribution,
      ),
      WalletMovementKind.spacePayout => (
        Icons.groups_rounded,
        l10n.walletKindSpacePayout,
      ),
      WalletMovementKind.affiliateCommission => (
        Icons.volunteer_activism_rounded,
        l10n.walletKindAffiliate,
      ),
      WalletMovementKind.courierFee => (
        Icons.two_wheeler_rounded,
        l10n.walletKindCourierFee,
      ),
      WalletMovementKind.cashTopup => (
        Icons.payments_rounded,
        l10n.walletKindCashTopup,
      ),
      WalletMovementKind.walletWithdrawal => (
        Icons.account_balance_rounded,
        l10n.walletKindWithdrawal,
      ),
      WalletMovementKind.unknown => (
        Icons.sync_alt_rounded,
        l10n.walletKindOther,
      ),
    };
    final positive = movement.amountMinor > 0;
    final amount = vm.money(movement.amountMinor.abs())?.format() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s2),
      child: Row(
        children: [
          Icon(icon, color: c.textSecondary),
          const SizedBox(width: DymTokenSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.body),
                Text(
                  MaterialLocalizations.of(context)
                      .formatShortDate(movement.occurredAt.toLocal()),
                  style: t.label.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : '−'} $amount',
            style: t.title.copyWith(color: positive ? c.brand : c.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const new({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      16,
      16,
      16 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: context.dym.text.title),
        const SizedBox(height: DymTokenSpace.s4),
        ...children,
      ],
    ),
  );
}

class _AmountSheet extends StatefulWidget {
  const new({required this.title, required this.onConfirm, this.note});

  final String title;
  final String? note;
  final Future<bool> Function(String amount) onConfirm;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final done = await widget.onConfirm(_amount.text);
    if (done && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return _SheetFrame(
      title: widget.title,
      children: [
        if (widget.note != null) ...[
          Text(widget.note!, style: context.dym.text.label),
          const SizedBox(height: DymTokenSpace.s3),
        ],
        DymTextField(
          label: l10n.walletAmount,
          controller: _amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onSubmitted: (_) => _confirm(),
        ),
        const SizedBox(height: DymTokenSpace.s4),
        DymButton(label: l10n.walletConfirm, onPressed: _confirm),
      ],
    );
  }
}

class _PocketSheet extends StatefulWidget {
  const new({required this.vm});

  final WalletViewModel vm;

  @override
  State<_PocketSheet> createState() => _PocketSheetState();
}

class _PocketSheetState extends State<_PocketSheet> {
  final _name = TextEditingController();
  final _goal = TextEditingController();
  final _roundUp = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    _roundUp.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final done = await widget.vm.createPocket(
      name: _name.text,
      goalText: _goal.text,
      roundUpText: _roundUp.text,
    );
    if (done && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    const amount = TextInputType.numberWithOptions(decimal: true);
    return _SheetFrame(
      title: l10n.walletNewPocket,
      children: [
        DymTextField(
          label: l10n.walletPocketName,
          controller: _name,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: DymTokenSpace.s3),
        DymTextField(
          label: l10n.walletPocketGoalField,
          controller: _goal,
          keyboardType: amount,
        ),
        const SizedBox(height: DymTokenSpace.s3),
        DymTextField(
          label: l10n.walletPocketRoundUpField,
          controller: _roundUp,
          keyboardType: amount,
        ),
        const SizedBox(height: DymTokenSpace.s4),
        DymButton(label: l10n.walletConfirm, onPressed: _confirm),
      ],
    );
  }
}

class _TransferSheet extends StatefulWidget {
  const new({required this.vm});

  final WalletViewModel vm;

  @override
  State<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<_TransferSheet> {
  final _amount = TextEditingController();
  String? _from;
  String? _to;

  @override
  void initState() {
    super.initState();
    _to = widget.vm.wallet?.pockets.firstOrNull?.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final done = await widget.vm.transfer(
      amountText: _amount.text,
      fromPocket: _from,
      toPocket: _to,
    );
    if (done && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final pockets = widget.vm.wallet?.pockets ?? const <WalletPocket>[];
    List<DropdownMenuItem<String?>> items() => [
      DropdownMenuItem<String?>(child: Text(l10n.walletMain)),
      for (final p in pockets)
        DropdownMenuItem<String?>(value: p.id, child: Text(p.name)),
    ];
    return _SheetFrame(
      title: l10n.walletMove,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: _from,
          decoration: InputDecoration(labelText: l10n.walletFrom),
          items: items(),
          onChanged: (v) => setState(() => _from = v),
        ),
        const SizedBox(height: DymTokenSpace.s3),
        DropdownButtonFormField<String?>(
          initialValue: _to,
          decoration: InputDecoration(labelText: l10n.walletTo),
          items: items(),
          onChanged: (v) => setState(() => _to = v),
        ),
        const SizedBox(height: DymTokenSpace.s3),
        DymTextField(
          label: l10n.walletAmount,
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onSubmitted: (_) => _confirm(),
        ),
        const SizedBox(height: DymTokenSpace.s4),
        DymButton(label: l10n.walletConfirm, onPressed: _confirm),
      ],
    );
  }
}

/// Code à montrer au livreur : il prend le cash et crédite le wallet.
Future<void> _cashCodeSheet(BuildContext context, WalletViewModel vm) async {
  final l10n = DymLocalizations.of(context);
  final code = await vm.cashCode();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DymTokenSpace.s4,
          0,
          DymTokenSpace.s4,
          DymTokenSpace.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.walletCashTopup, style: sheet.dym.text.title),
            const SizedBox(height: DymTokenSpace.s2),
            if (code == null)
              Text(l10n.errorGeneric)
            else ...[
              Text(l10n.walletCashTopupHint),
              const SizedBox(height: DymTokenSpace.s3),
              Text(
                code.code,
                textAlign: TextAlign.center,
                style: sheet.dym.text.display.copyWith(
                  fontSize: 40,
                  letterSpacing: 8,
                ),
              ),
              Text(
                l10n.walletCashTopupExpires(shortTime(sheet, code.expiresAt)),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
