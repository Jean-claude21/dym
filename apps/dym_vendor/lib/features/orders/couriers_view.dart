import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/orders/orders_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

/// Mes livreurs (spec 096) : livreurs DYM que la boutique fait travailler en
/// direct, ajoutés par leur numéro.
class StoreCouriersViewModel extends BaseViewModel {
  new({required this.service});

  final OrdersService service;
  List<StoreCourierInfo>? couriers;
  Failure? failure;
  Failure? addFailure;

  Future<void> load() async {
    failure = null;
    switch (await service.storeCouriers()) {
      case Ok(:final value):
        couriers = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  /// Vrai si le livreur est ajouté.
  Future<bool> add(String phone) async {
    addFailure = null;
    final result = await runBusyFuture(service.addStoreCourier(phone.trim()));
    switch (result) {
      case Ok(:final value):
        couriers = value;
      case Err(failure: final f):
        addFailure = f;
    }
    notifyListeners();
    return result.isOk;
  }

  Future<void> remove(StoreCourierInfo courier) async {
    if (await service.removeStoreCourier(courier.courierId) case Ok(
      :final value,
    )) {
      couriers = value;
      notifyListeners();
    }
  }
}

class StoreCouriersView extends StackedView<StoreCouriersViewModel> {
  const new({required this.service, super.key});

  final OrdersService service;

  @override
  StoreCouriersViewModel viewModelBuilder(BuildContext context) =>
      StoreCouriersViewModel(service: service);

  @override
  void onViewModelReady(StoreCouriersViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(
    BuildContext context,
    StoreCouriersViewModel vm,
    Widget? child,
  ) {
    final l10n = DymLocalizations.of(context);
    final t = context.dym.text;
    final c = context.dym.colors;
    final couriers = vm.couriers;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.storeCouriersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, vm),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(l10n.storeCouriersAdd),
      ),
      body: couriers == null
          ? (vm.failure == null
                ? const Center(child: CircularProgressIndicator())
                : DymStateView(
                    kind: DymStateKind.error,
                    title: vm.failure is NetworkFailure
                        ? l10n.errorOffline
                        : l10n.errorLoadMessage,
                    message: '',
                    actionLabel: l10n.retry,
                    onAction: vm.load,
                  ))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Text(
                  l10n.storeCouriersHint,
                  style: t.body.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: DymTokenSpace.s3),
                if (couriers.isEmpty)
                  DymStateView(
                    kind: DymStateKind.empty,
                    title: l10n.storeCouriersEmpty,
                    message: l10n.storeCouriersHint,
                  )
                else
                  DymMenuGroup(
                    children: [
                      for (final courier in couriers)
                        DymMenuRow(
                          icon: courier.isOnline
                              ? Icons.two_wheeler_rounded
                              : Icons.bedtime_outlined,
                          label: courier.name,
                          value: courier.busy
                              ? l10n.storeCourierBusy
                              : (courier.isOnline
                                    ? l10n.courierOnline
                                    : l10n.courierOffline),
                          onTap: () => _remove(context, vm, courier),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }

  Future<void> _add(BuildContext context, StoreCouriersViewModel vm) async {
    final l10n = DymLocalizations.of(context);
    final phone = await showDialog<String>(
      context: context,
      builder: (dialog) {
        final field = TextEditingController();
        return AlertDialog(
          title: Text(l10n.storeCouriersAdd),
          content: TextField(
            controller: field,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l10n.storeCourierPhone),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, field.text),
              child: Text(l10n.storeCouriersAdd),
            ),
          ],
        );
      },
    );
    if (phone == null || phone.trim().isEmpty) return;
    final ok = await vm.add(phone);
    if (!context.mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vm.addFailure?.message == 'courier_not_found'
              ? l10n.storeCourierNotFound
              : l10n.errorGeneric,
        ),
      ),
    );
  }

  Future<void> _remove(
    BuildContext context,
    StoreCouriersViewModel vm,
    StoreCourierInfo courier,
  ) async {
    final l10n = DymLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(courier.name),
        content: Text(courier.phone),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.storeCourierRemove),
          ),
        ],
      ),
    );
    if (yes ?? false) await vm.remove(courier);
  }
}

/// Lit le QR du livreur (`dym-pickup:<code>`) ; sans caméra, saisie du code.
Future<String?> scanPickupCode(BuildContext context) => Navigator.of(context)
    .push<String>(MaterialPageRoute(builder: (_) => const _PickupScanPage()));

class _PickupScanPage extends StatelessWidget {
  const new();

  static String? _code(String raw) {
    final value = raw.trim().replaceFirst('dym-pickup:', '');
    return RegExp(r'^\d{6}$').hasMatch(value) ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final manual = _ManualCode(onCode: (c) => Navigator.pop(context, c));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pickupScanTitle)),
      body: Column(
        children: [
          Expanded(
            child: QrScanView(
              onCode: (raw) {
                if (_code(raw) case final code?) Navigator.pop(context, code);
              },
              fallback: manual,
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: manual),
        ],
      ),
    );
  }
}

class _ManualCode extends StatefulWidget {
  const new({required this.onCode});

  final ValueChanged<String> onCode;

  @override
  State<_ManualCode> createState() => _ManualCodeState();
}

class _ManualCodeState extends State<_ManualCode> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _field,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l10n.pickupCodeManual),
          ),
        ),
        const SizedBox(width: DymTokenSpace.s2),
        FilledButton(
          onPressed: () {
            if (_field.text.length == 6) widget.onCode(_field.text);
          },
          child: Text(l10n.pickupCodeValidate),
        ),
      ],
    );
  }
}
