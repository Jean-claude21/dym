import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/till/till_service.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Fin de marché et partage de la boutique (spec 048).
class EndOfMarketViewModel extends BaseViewModel {
  new({required this.service});

  final TillService service;
  EndOfMarket? state;
  int percent = 20;
  int hours = 3;
  String? problem;

  static const percents = [10, 20, 30, 50];
  static const durations = [1, 2, 3, 4];

  Future<void> load() async {
    state = (await service.endOfMarket()).valueOrNull;
    notifyListeners();
  }

  void choose({int? percent, int? hours}) {
    if (percent != null) this.percent = percent;
    if (hours != null) this.hours = hours;
    notifyListeners();
  }

  Future<void> _apply(Future<Result<EndOfMarket>> work) async {
    problem = null;
    setBusy(true);
    switch (await work) {
      case Ok(:final value):
        state = value;
      case Err(failure: final f):
        problem = f is NetworkFailure ? 'offline' : f.message;
    }
    setBusy(false);
  }

  Future<void> start() => _apply(service.startEndOfMarket(percent, hours));

  Future<void> stop() => _apply(service.stopEndOfMarket());

  Future<void> share(String Function(Uri link) message) async {
    if (await service.shareStore(message) case Err(failure: final f)) {
      problem = f is NetworkFailure ? 'offline' : f.message;
      notifyListeners();
    }
  }
}

class EndOfMarketView extends StackedView<EndOfMarketViewModel> {
  const new({required this.service, required this.onBack, super.key});

  final TillService service;
  final VoidCallback onBack;

  @override
  EndOfMarketViewModel viewModelBuilder(BuildContext context) =>
      EndOfMarketViewModel(service: service);

  @override
  void onViewModelReady(EndOfMarketViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, EndOfMarketViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final state = vm.state;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(l10n.studioTitle),
        leading: IconButton(
          tooltip: l10n.authBack,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(DymLayout.gutter(context)),
          children: [
            DymContentWidth.form(
              child: DymSectionHeader(title: l10n.studioShareTitle),
            ),
            DymContentWidth.form(child: Text(l10n.studioShareHint)),
            const SizedBox(height: DymTokenSpace.s2),
            DymContentWidth.form(
              child: DymButton(
                label: l10n.studioShare,
                icon: Icons.share_rounded,
                onPressed: () =>
                    vm.share((link) => l10n.studioShareText(link.toString())),
              ),
            ),
            const SizedBox(height: DymTokenSpace.s5),
            DymContentWidth.form(child: DymSectionHeader(title: l10n.eomTitle)),
            DymContentWidth.form(child: Text(l10n.eomHint)),
            const SizedBox(height: DymTokenSpace.s3),
            if (state?.active ?? false) ...[
              DymContentWidth.form(
                child: Text(
                  l10n.eomActive(
                    state!.percent ?? 0,
                    state.products,
                    TimeOfDay.fromDateTime(state.until!.toLocal())
                        .format(context),
                  ),
                  style: t.title,
                ),
              ),
              const SizedBox(height: DymTokenSpace.s3),
              DymContentWidth.form(
                child: DymButton(
                  label: l10n.eomStop,
                  variant: DymButtonVariant.secondary,
                  loading: vm.isBusy,
                  onPressed: vm.stop,
                ),
              ),
            ] else ...[
              DymContentWidth.form(
                child: Text(l10n.eomPercent, style: t.label),
              ),
              DymContentWidth.form(
                child: Wrap(
                  spacing: DymTokenSpace.s2,
                  children: [
                    for (final p in EndOfMarketViewModel.percents)
                      ChoiceChip(
                        label: Text('-$p %'),
                        selected: vm.percent == p,
                        onSelected: (_) => vm.choose(percent: p),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: DymTokenSpace.s2),
              DymContentWidth.form(
                child: Text(l10n.eomDuration, style: t.label),
              ),
              DymContentWidth.form(
                child: Wrap(
                  spacing: DymTokenSpace.s2,
                  children: [
                    for (final h in EndOfMarketViewModel.durations)
                      ChoiceChip(
                        label: Text(l10n.eomHours(h)),
                        selected: vm.hours == h,
                        onSelected: (_) => vm.choose(hours: h),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: DymTokenSpace.s3),
              DymContentWidth.form(
                child: DymButton(
                  label: l10n.eomStart(vm.percent),
                  icon: Icons.local_offer_rounded,
                  loading: vm.isBusy,
                  onPressed: vm.start,
                ),
              ),
            ],
            if (vm.problem != null)
              DymContentWidth.form(
                child: Padding(
                  padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                  child: Text(
                    vm.problem == 'offline'
                        ? l10n.errorOffline
                        : l10n.errorGeneric,
                    style: t.body.copyWith(color: c.pimentStrong),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
