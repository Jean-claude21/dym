import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Cash que les livreurs DYM doivent à la boutique (spec 043).
abstract interface class CourierCashService {
  Future<Result<CountryConfig>> countryConfig();

  Future<Result<List<StoreCourierCash>>> owed();

  /// Tout le cash de ce livreur est reçu.
  Future<Result<List<StoreCourierCash>>> confirm(StoreCourierCash line);
}

class NeonCourierCashService implements CourierCashService {
  new({required this._couriers, required this._config});

  final CourierRepository _couriers;
  final Future<Result<CountryConfig>> Function() _config;

  @override
  Future<Result<CountryConfig>> countryConfig() => _config();

  @override
  Future<Result<List<StoreCourierCash>>> owed() => _couriers.storeCash();

  @override
  Future<Result<List<StoreCourierCash>>> confirm(StoreCourierCash line) =>
      _couriers.confirmStoreCash(line.courierId, key: Uuid.v4());
}

class MemoryCourierCashService implements CourierCashService {
  new({required this.config, List<StoreCourierCash>? lines})
    : lines = lines ?? [];

  final CountryConfig config;
  final List<StoreCourierCash> lines;

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(config);

  @override
  Future<Result<List<StoreCourierCash>>> owed() async => Ok(List.of(lines));

  @override
  Future<Result<List<StoreCourierCash>>> confirm(StoreCourierCash line) async {
    lines.removeWhere((l) => l.courierId == line.courierId);
    return Ok(List.of(lines));
  }
}

class CourierCashViewModel extends BaseViewModel {
  new({required this.service});

  final CourierCashService service;
  CountryConfig? config;
  List<StoreCourierCash>? lines;
  Failure? failure;
  String? confirming;

  Future<void> load() async {
    failure = null;
    config ??= (await service.countryConfig()).valueOrNull;
    switch (await service.owed()) {
      case Ok(:final value):
        lines = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  String money(int minor) => config?.money(minor).format() ?? '';

  Future<void> confirm(StoreCourierCash line) async {
    if (confirming != null) return;
    confirming = line.courierId;
    notifyListeners();
    switch (await service.confirm(line)) {
      case Ok(:final value):
        lines = value;
      case Err(failure: final f):
        failure = f;
    }
    confirming = null;
    notifyListeners();
  }
}

class CourierCashView extends StackedView<CourierCashViewModel> {
  const new({required this.service, required this.onBack, super.key});

  final CourierCashService service;
  final VoidCallback onBack;

  @override
  CourierCashViewModel viewModelBuilder(BuildContext context) =>
      CourierCashViewModel(service: service);

  @override
  void onViewModelReady(CourierCashViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, CourierCashViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final lines = vm.lines;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(l10n.courierCashTitle),
        leading: IconButton(
          tooltip: l10n.authBack,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: lines == null
            ? Center(
                child: vm.failure == null
                    ? const CircularProgressIndicator()
                    : TextButton(onPressed: vm.load, child: Text(l10n.retry)),
              )
            : ListView(
                padding: EdgeInsets.all(DymLayout.gutter(context)),
                children: [
                  DymContentWidth(
                    child: Text(
                      l10n.courierCashHint,
                      style: t.body.copyWith(color: c.textSecondary),
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  if (lines.isEmpty)
                    DymStateView(
                      kind: DymStateKind.empty,
                      title: l10n.courierCashNone,
                      message: l10n.courierCashNoneHint,
                    )
                  else
                    for (final line in lines)
                      DymContentWidth(
                        child: Card(
                          child: ListTile(
                            minTileHeight: 72,
                            leading: const Icon(Icons.two_wheeler_rounded),
                            title: Text(line.courierName ?? ''),
                            subtitle: Text(vm.money(line.amountMinor)),
                            trailing: FilledButton.icon(
                              onPressed: vm.confirming == null
                                  ? () => vm.confirm(line)
                                  : null,
                              icon: const Icon(Icons.check_rounded),
                              label: Text(l10n.courierCashReceived),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
      ),
    );
  }
}
