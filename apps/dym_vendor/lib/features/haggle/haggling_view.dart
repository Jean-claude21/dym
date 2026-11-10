import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Marchandage de la vendeuse (spec 050) : remplaçable en test.
abstract interface class HagglingService {
  Future<Result<CountryConfig>> countryConfig();

  Future<Result<HagglingSettings>> settings();

  Future<Result<HagglingSettings>> setLimit(int? percent, {String? productId});
}

class NeonHagglingService implements HagglingService {
  new({required this._repository, required this._config});

  final HaggleRepository _repository;
  final Future<Result<CountryConfig>> Function() _config;

  @override
  Future<Result<CountryConfig>> countryConfig() => _config();

  @override
  Future<Result<HagglingSettings>> settings() => _repository.settings();

  @override
  Future<Result<HagglingSettings>> setLimit(
    int? percent, {
    String? productId,
  }) => _repository.setLimit(percent, productId: productId);
}

/// Limites proposées (la base accepte 1 à 50 %).
const hagglingChoices = [5, 10, 15, 20, 30];

class HagglingViewModel extends BaseViewModel {
  new({required this.service});

  final HagglingService service;
  CountryConfig? config;
  HagglingSettings? settings;
  Failure? failure;

  Future<void> load() async {
    failure = null;
    config ??= (await service.countryConfig()).valueOrNull;
    _apply(await service.settings());
  }

  void _apply(Result<HagglingSettings> result) {
    switch (result) {
      case Ok(:final value):
        settings = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  String money(int minor) => config?.money(minor).format() ?? '';

  Future<void> setStore(int? percent) async =>
      _apply(await service.setLimit(percent));

  Future<void> setProduct(String productId, int? percent) async =>
      _apply(await service.setLimit(percent, productId: productId));
}

class HagglingView extends StackedView<HagglingViewModel> {
  const new({required this.service, required this.onBack, super.key});

  final HagglingService service;
  final VoidCallback onBack;

  @override
  HagglingViewModel viewModelBuilder(BuildContext context) =>
      HagglingViewModel(service: service);

  @override
  void onViewModelReady(HagglingViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, HagglingViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final s = vm.settings;
    String percentLabel(int? p) => switch (p) {
      null => l10n.hagglingLikeStore,
      0 => l10n.hagglingNever,
      _ => l10n.hagglingPercent(p),
    };
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(l10n.hagglingTitle),
        leading: IconButton(
          tooltip: l10n.authBack,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: s == null
            ? Center(
                child: vm.failure == null
                    ? const CircularProgressIndicator()
                    : TextButton(onPressed: vm.load, child: Text(l10n.retry)),
              )
            : RefreshIndicator(
                onRefresh: vm.load,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    DymLayout.gutter(context),
                    DymTokenSpace.s2,
                    DymLayout.gutter(context),
                    DymTokenSpace.s6,
                  ),
                  children: [
                    DymContentWidth(child: Text(l10n.hagglingHint)),
                    const SizedBox(height: DymTokenSpace.s3),
                    DymContentWidth(
                      child: DymSectionHeader(title: l10n.hagglingStoreLimit),
                    ),
                    DymContentWidth(
                      child: Wrap(
                        spacing: DymTokenSpace.s2,
                        runSpacing: DymTokenSpace.s1,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.hagglingOff),
                            selected: s.storePercent == null,
                            onSelected: (_) => vm.setStore(null),
                          ),
                          for (final p in hagglingChoices)
                            ChoiceChip(
                              label: Text(l10n.hagglingPercent(p)),
                              selected: s.storePercent == p,
                              onSelected: (_) => vm.setStore(p),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DymTokenSpace.s2),
                    DymContentWidth(
                      child: Text(
                        l10n.hagglingWeek(s.concludedWeek),
                        style: t.title.copyWith(color: c.brandDeep),
                      ),
                    ),
                    if (s.storePercent != null && s.products.isNotEmpty) ...[
                      const SizedBox(height: DymTokenSpace.s4),
                      DymContentWidth(
                        child: DymSectionHeader(title: l10n.hagglingProducts),
                      ),
                      for (final p in s.products)
                        DymContentWidth(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(p.name),
                            trailing: PopupMenuButton<int>(
                              tooltip: l10n.hagglingProducts,
                              onSelected: (v) =>
                                  vm.setProduct(p.id, v < 0 ? null : v),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: -1,
                                  child: Text(l10n.hagglingLikeStore),
                                ),
                                PopupMenuItem(
                                  value: 0,
                                  child: Text(l10n.hagglingNever),
                                ),
                                for (final v in hagglingChoices)
                                  PopupMenuItem(
                                    value: v,
                                    child: Text(l10n.hagglingPercent(v)),
                                  ),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.all(DymTokenSpace.s2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(percentLabel(p.percent)),
                                    const Icon(Icons.arrow_drop_down_rounded),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: DymTokenSpace.s4),
                    DymContentWidth(
                      child: DymSectionHeader(title: l10n.hagglingRecent),
                    ),
                    if (s.recent.isEmpty)
                      DymContentWidth(
                        child: Text(
                          l10n.hagglingEmpty,
                          style: t.body.copyWith(color: c.textSecondary),
                        ),
                      ),
                    for (final h in s.recent)
                      DymContentWidth(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.handshake_rounded),
                          title: Text(h.productName),
                          subtitle: Text(
                            l10n.hagglingLine(
                              h.quantity,
                              vm.money(h.offerMinor),
                              vm.money(h.priceMinor),
                            ),
                          ),
                          trailing: Text(switch (h.status) {
                            'accepted' => l10n.hagglingStatusAccepted,
                            'countered' => l10n.hagglingStatusCountered,
                            'used' => l10n.hagglingStatusUsed,
                            _ => l10n.hagglingStatusExpired,
                          }, style: t.label),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
