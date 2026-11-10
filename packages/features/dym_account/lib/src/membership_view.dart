import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Formules (spec 052) de la cliente (DYM+) ou de la boutique (Pro,
/// visibilité) : remplaçable en test.
abstract interface class MembershipService {
  Future<Result<CountryConfig>> countryConfig();

  Future<Result<MembershipOffer>> offer();

  Future<Result<MembershipOffer>> subscribe(MembershipPlan plan, String key);
}

class NeonMembershipService implements MembershipService {
  new({
    required this._repository,
    required this._audience,
    required this._config,
  });

  final MembershipRepository _repository;

  /// `client` ou `vendor`.
  final String _audience;
  final Future<Result<CountryConfig>> Function() _config;

  @override
  Future<Result<CountryConfig>> countryConfig() => _config();

  @override
  Future<Result<MembershipOffer>> offer() => _repository.offer(_audience);

  @override
  Future<Result<MembershipOffer>> subscribe(MembershipPlan plan, String key) =>
      _repository.subscribe(plan.id, key);
}

class MembershipViewModel extends BaseViewModel {
  new({required this.service});

  final MembershipService service;
  CountryConfig? config;
  MembershipOffer? offer;
  Failure? failure;
  String? problem;
  String? _pendingKey;

  Future<void> load() async {
    failure = null;
    config ??= (await service.countryConfig()).valueOrNull;
    switch (await service.offer()) {
      case Ok(:final value):
        offer = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  String money(int minor) => config?.money(minor).format() ?? '';

  /// Une clé par achat : rejouée telle quelle après une coupure réseau.
  Future<bool> subscribe(MembershipPlan plan) async {
    problem = null;
    setBusyForObject(plan.id, true);
    final key = _pendingKey ??= Uuid.v4();
    final result = await service.subscribe(plan, key);
    setBusyForObject(plan.id, false);
    switch (result) {
      case Ok(:final value):
        _pendingKey = null;
        offer = value;
        notifyListeners();
        return true;
      case Err(failure: final f):
        if (f is! NetworkFailure) _pendingKey = null;
        problem = f is NetworkFailure ? 'offline' : f.message;
        notifyListeners();
        return false;
    }
  }
}

/// Avantages d'une formule, lisibles.
List<String> membershipBenefits(DymLocalizations l10n, MembershipPlan plan) => [
  if (plan.flag('delivery_refund')) l10n.membershipDeliveryRefund,
  if (plan.bps('cashback_bonus_bps') > 0)
    l10n.membershipCashback(plan.bps('cashback_bonus_bps') / 100),
  if (plan.bps('commission_discount_bps') > 0)
    l10n.membershipCommission(plan.bps('commission_discount_bps') / 100),
  if (plan.flag('sponsored')) l10n.membershipSponsored,
];

class MembershipView extends StackedView<MembershipViewModel> {
  const new({
    required this.service,
    required this.title,
    required this.onBack,
    super.key,
  });

  final MembershipService service;
  final String title;
  final VoidCallback onBack;

  @override
  MembershipViewModel viewModelBuilder(BuildContext context) =>
      MembershipViewModel(service: service);

  @override
  void onViewModelReady(MembershipViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, MembershipViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final offer = vm.offer;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(title),
        leading: IconButton(
          tooltip: l10n.authBack,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: offer == null
            ? Center(
                child: vm.failure == null
                    ? const CircularProgressIndicator()
                    : TextButton(onPressed: vm.load, child: Text(l10n.retry)),
              )
            : ListView(
                padding: EdgeInsets.fromLTRB(
                  DymLayout.gutter(context),
                  DymTokenSpace.s2,
                  DymLayout.gutter(context),
                  DymTokenSpace.s6,
                ),
                children: [
                  DymContentWidth(
                    child: Text(
                      l10n.membershipWallet(vm.money(offer.walletBalanceMinor)),
                      style: t.label.copyWith(color: c.textSecondary),
                    ),
                  ),
                  if (vm.problem case final p?)
                    DymContentWidth(
                      child: Text(switch (p) {
                        'wallet_insufficient' =>
                          l10n.membershipWalletInsufficient,
                        'offline' => l10n.errorOffline,
                        _ => l10n.errorGeneric,
                      }, style: t.body.copyWith(color: c.pimentStrong)),
                    ),
                  const SizedBox(height: DymTokenSpace.s3),
                  if (offer.plans.isEmpty)
                    DymContentWidth(
                      child: Text(
                        l10n.membershipNone,
                        style: t.body.copyWith(color: c.textSecondary),
                      ),
                    ),
                  for (final plan in offer.plans)
                    DymContentWidth(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: DymTokenSpace.s3),
                        child: Padding(
                          padding: const EdgeInsets.all(DymTokenSpace.s3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.workspace_premium_rounded,
                                    color: c.brand,
                                  ),
                                  const SizedBox(width: DymTokenSpace.s2),
                                  Expanded(
                                    child: Text(
                                      plan.name.resolve(locale),
                                      style: t.title,
                                    ),
                                  ),
                                ],
                              ),
                              if (plan.description case final d?)
                                Text(d.resolve(locale)),
                              const SizedBox(height: DymTokenSpace.s2),
                              for (final b in membershipBenefits(l10n, plan))
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: c.brand,
                                    ),
                                    const SizedBox(width: DymTokenSpace.s1),
                                    Expanded(child: Text(b)),
                                  ],
                                ),
                              const SizedBox(height: DymTokenSpace.s2),
                              Text(
                                l10n.membershipPrice(
                                  vm.money(plan.priceMinor),
                                  plan.periodDays,
                                ),
                                style: t.title.copyWith(color: c.brandDeep),
                              ),
                              if (plan.activeUntil case final until?)
                                Text(
                                  l10n.membershipActiveUntil(
                                    MaterialLocalizations.of(context)
                                        .formatMediumDate(until.toLocal()),
                                  ),
                                  style: t.label.copyWith(color: c.brandDeep),
                                ),
                              const SizedBox(height: DymTokenSpace.s2),
                              DymButton(
                                label: plan.active
                                    ? l10n.membershipExtend
                                    : l10n.membershipSubscribe,
                                icon: Icons.account_balance_wallet_rounded,
                                loading: vm.busy(plan.id),
                                onPressed: vm.busy(plan.id)
                                    ? null
                                    : () => vm.subscribe(plan),
                              ),
                            ],
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
