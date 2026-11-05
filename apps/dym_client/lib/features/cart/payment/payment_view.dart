import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/cart/cart_viewmodels.dart';
import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Écrans 39 (en attente du paiement) et 40 (paiement échoué). La réussite
/// ou le passage au cash mènent à l'écran 37 ([onSettled]).
class PaymentView extends StackedView<PaymentViewModel> {
  const new({
    required this.service,
    required this.purchase,
    required this.onSettled,
    required this.onBack,
    super.key,
    this.openAtStart = true,
  });

  final CartService service;
  final Purchase purchase;
  final void Function(Purchase purchase) onSettled;
  final VoidCallback onBack;
  final bool openAtStart;

  @override
  PaymentViewModel viewModelBuilder(BuildContext context) => PaymentViewModel(
    service: service,
    purchase: purchase,
    onSettled: onSettled,
    openAtStart: openAtStart,
  );

  @override
  void onViewModelReady(PaymentViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    PaymentViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(title: l10n.paymentTitle, onBack: onBack),
            Expanded(
              child: !vm.ready
                  ? DiscoveryState(
                      failure: vm.isBusy ? null : vm.failure,
                      onRetry: vm.load,
                    )
                  : vm.failedPayment
                  ? _Failed(vm: vm)
                  : _Waiting(vm: vm),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pictogramme rond (attente : plantain ; échec : piment).
class _Badge extends StatelessWidget {
  const new({required this.icon, required this.tint, required this.color});

  final IconData icon;
  final Color tint;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
      child: Icon(icon, size: 56, color: color),
    ),
  );
}

class _Layout extends StatelessWidget {
  const new({required this.content, required this.actions});

  final List<Widget> content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [for (final w in content) DymContentWidth.form(child: w)],
        ),
      ),
      DymContentWidth.form(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: actions,
          ),
        ),
      ),
    ],
  );
}

class _Waiting extends StatelessWidget {
  const new({required this.vm});

  final PaymentViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final p = vm.purchase;
    return _Layout(
      content: [
        const SizedBox(height: DymTokenSpace.s4),
        _Badge(
          icon: Icons.phone_android_rounded,
          tint: c.tintPlantainClair,
          color: c.brandDeep,
        ),
        const SizedBox(height: DymTokenSpace.s3),
        Text(
          l10n.paymentWaitingTitle,
          textAlign: TextAlign.center,
          style: t.display.copyWith(fontSize: 28),
        ),
        const SizedBox(height: DymTokenSpace.s1),
        Text(
          l10n.paymentWaitingBody,
          textAlign: TextAlign.center,
          style: t.body.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: DymTokenSpace.s4),
        CartCard(
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: c.brand),
                  const SizedBox(width: DymTokenSpace.s2),
                  Expanded(
                    child: Text(
                      p.paymentMethod.label.resolve(locale),
                      style: t.title.copyWith(fontSize: 17),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              SumRow(
                label: l10n.paymentAmount,
                amount: vm.money(p.totalMinor),
                strong: true,
              ),
              if (p.payment != null)
                _InfoRow(
                  label: l10n.paymentReference,
                  value: p.payment!.reference,
                ),
            ],
          ),
        ),
        const SizedBox(height: DymTokenSpace.s3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: c.brand),
            ),
            const SizedBox(width: DymTokenSpace.s2),
            Flexible(
              child: Text(
                vm.checkOffline ? l10n.errorOffline : l10n.paymentChecking,
                style: t.label.copyWith(color: c.textSecondary),
              ),
            ),
          ],
        ),
        if (vm.openFailed) CartIssue(label: l10n.paymentOpenFailed),
        if (vm.cashRefused) CartIssue(label: l10n.paymentCashNotAccepted),
        if (vm.actionFailure != null)
          CartIssue(
            label: vm.actionFailure is NetworkFailure
                ? l10n.errorOffline
                : l10n.errorGeneric,
          ),
      ],
      actions: [
        DymButton(
          label: l10n.paymentOpenPage,
          icon: Icons.open_in_new_rounded,
          onPressed: p.payment?.checkoutUrl == null ? null : vm.openPage,
        ),
        const SizedBox(height: DymTokenSpace.s2),
        DymButton(
          label: l10n.paymentPayOnDeliveryInstead,
          variant: DymButtonVariant.secondary,
          loading: vm.acting,
          onPressed: vm.acting ? null : vm.payOnDelivery,
        ),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const new({required this.vm});

  final PaymentViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final p = vm.purchase;
    return _Layout(
      content: [
        const SizedBox(height: DymTokenSpace.s4),
        _Badge(
          icon: Icons.priority_high_rounded,
          tint: c.pimentStrong.withValues(alpha: 0.12),
          color: c.pimentStrong,
        ),
        const SizedBox(height: DymTokenSpace.s3),
        Text(
          l10n.paymentFailedTitle,
          textAlign: TextAlign.center,
          style: t.display.copyWith(fontSize: 28),
        ),
        const SizedBox(height: DymTokenSpace.s1),
        Text(
          l10n.paymentFailedBody,
          textAlign: TextAlign.center,
          style: t.body.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: DymTokenSpace.s4),
        CartCard(
          child: Column(
            children: [
              for (final o in p.orders)
                SumRow(label: o.store.name, amount: vm.money(o.totalMinor)),
              const Divider(height: 20),
              SumRow(
                label: l10n.cartTotal,
                amount: vm.money(p.totalMinor),
                strong: true,
              ),
            ],
          ),
        ),
        if (vm.cashRefused) CartIssue(label: l10n.paymentCashNotAccepted),
        if (vm.actionFailure != null)
          CartIssue(
            label: vm.actionFailure is NetworkFailure
                ? l10n.errorOffline
                : l10n.errorGeneric,
          ),
      ],
      actions: [
        DymButton(
          label: l10n.paymentRetry,
          icon: Icons.refresh_rounded,
          loading: vm.acting,
          onPressed: vm.acting ? null : vm.retry,
        ),
        const SizedBox(height: DymTokenSpace.s2),
        DymButton(
          label: l10n.paymentPayOnDelivery,
          icon: Icons.payments_rounded,
          variant: DymButtonVariant.secondary,
          onPressed: vm.acting ? null : vm.payOnDelivery,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: t.label.copyWith(fontSize: 15, color: c.textSecondary),
            ),
          ),
          Text(
            value,
            style: t.title.copyWith(fontSize: 16, color: c.brandDeep),
          ),
        ],
      ),
    );
  }
}
