import 'dart:async';
import 'dart:math' as math;

import 'package:dym_admin/features/ops/admin_texts.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Centre d'opérations (spec 053) : remplaçable en test.
abstract interface class OpsCenterService {
  Future<Result<Map<String, Currency>>> currencies();

  Future<Result<List<String>>> countries();

  Future<Result<OpsLive>> live(String country);

  Future<Result<OpsSettings>> settings(String country);

  Future<Result<OpsSettings>> setThresholds(
    String country,
    Map<String, int> values,
  );

  Future<Result<OpsSettings>> setFeedWeights(
    String country,
    Map<String, int> weights,
  );

  Future<Result<OpsSettings>> savePlan(Map<String, Object?> plan);

  Future<Result<OpsSettings>> setScope(
    String email,
    String country, {
    required bool on,
  });

  Future<Result<int>> confirmCourierCash(CourierCashDue due, String key);
}

class NeonOpsCenterService implements OpsCenterService {
  new({required this._repository, required this._currencies});

  final OpsRepository _repository;
  final Future<Result<Map<String, Currency>>> Function() _currencies;

  @override
  Future<Result<Map<String, Currency>>> currencies() => _currencies();

  @override
  Future<Result<List<String>>> countries() => _repository.countries();

  @override
  Future<Result<OpsLive>> live(String country) => _repository.live(country);

  @override
  Future<Result<OpsSettings>> settings(String country) =>
      _repository.settings(country);

  @override
  Future<Result<OpsSettings>> setThresholds(
    String country,
    Map<String, int> values,
  ) => _repository.setThresholds(country, values);

  @override
  Future<Result<OpsSettings>> setFeedWeights(
    String country,
    Map<String, int> weights,
  ) => _repository.setFeedWeights(country, weights);

  @override
  Future<Result<OpsSettings>> savePlan(Map<String, Object?> plan) =>
      _repository.savePlan(plan);

  @override
  Future<Result<OpsSettings>> setScope(
    String email,
    String country, {
    required bool on,
  }) => _repository.setScope(email, country, on: on);

  @override
  Future<Result<int>> confirmCourierCash(CourierCashDue due, String key) =>
      _repository.confirmCourierCash(due.courierId, key);
}

/// Poids du fil réglables (0044).
const opsFeedWeightKeys = [
  'weight_recency',
  'weight_engagement',
  'weight_followed',
  'weight_local',
  'weight_affinity',
  'weight_shoppable',
];

class OpsCenterViewModel extends AdminViewModel {
  new({required this.service, Duration? refresh})
    : _refresh = refresh ?? const Duration(seconds: 30);

  final OpsCenterService service;
  final Duration _refresh;
  Timer? _timer;
  List<String> countries = const [];
  String? country;
  OpsLive? live;
  OpsSettings? settings;
  String? problem;
  final _cashKeys = <String, String>{};

  Future<void> load() => run(service.currencies, () async {
    if (country == null) {
      switch (await service.countries()) {
        case Ok(:final value):
          countries = value;
          country = value.firstOrNull;
        case Err(:final failure):
          return failure;
      }
    }
    final c = country;
    if (c == null) return null;
    final (l, s) = await (service.live(c), service.settings(c)).wait;
    if (l case Err(:final failure)) return failure;
    live = l.valueOrNull;
    settings = s.valueOrNull;
    _timer ??= Timer.periodic(_refresh, (_) => unawaited(refreshLive()));
    return null;
  });

  /// Rafraîchit la vue en direct sans bloquer l'écran.
  Future<void> refreshLive() async {
    final c = country;
    if (c == null) return;
    if (await service.live(c) case Ok(:final value)) {
      live = value;
      notifyListeners();
    }
  }

  Future<void> selectCountry(String code) async {
    country = code;
    live = null;
    settings = null;
    await load();
  }

  Future<bool> _apply(Future<Result<OpsSettings>> work) async {
    problem = null;
    switch (await work) {
      case Ok(:final value):
        settings = value;
        notifyListeners();
        await refreshLive();
        return true;
      case Err(:final failure):
        problem = failure is NetworkFailure ? 'offline' : failure.message;
        notifyListeners();
        return false;
    }
  }

  Map<String, int>? _ints(Map<String, String> texts) {
    final out = <String, int>{};
    for (final e in texts.entries) {
      final v = int.tryParse(e.value.trim());
      if (v == null || v < 0) return null;
      out[e.key] = v;
    }
    return out;
  }

  Future<bool> setThresholds(Map<String, String> texts) {
    final values = _ints(texts);
    if (values == null || country == null) {
      problem = 'invalid';
      notifyListeners();
      return Future.value(false);
    }
    return _apply(service.setThresholds(country!, values));
  }

  Future<bool> setFeedWeights(Map<String, String> texts) {
    final values = _ints(texts);
    if (values == null || country == null) {
      problem = 'invalid';
      notifyListeners();
      return Future.value(false);
    }
    return _apply(service.setFeedWeights(country!, values));
  }

  Future<bool> savePlan(OpsPlan plan, {String? priceText, bool? active}) {
    final currency = currencies[settings?.currencyCode];
    final price = priceText == null || currency == null
        ? null
        : Money.parseMajor(priceText, currency);
    if (priceText != null && (price == null || price <= 0)) {
      problem = 'invalid';
      notifyListeners();
      return Future.value(false);
    }
    return _apply(
      service.savePlan({
        'id': plan.id,
        'country_code': country,
        'price_minor': ?price,
        'is_active': ?active,
      }),
    );
  }

  Future<bool> setScope(String email, String code, {required bool on}) {
    if (!email.contains('@')) {
      problem = 'invalid';
      notifyListeners();
      return Future.value(false);
    }
    return _apply(service.setScope(email.trim(), code, on: on));
  }

  /// Une clé par remise : rejouée telle quelle après une coupure.
  Future<bool> confirmCash(CourierCashDue due) async {
    problem = null;
    final key = _cashKeys[due.courierId] ??= Uuid.v4();
    switch (await service.confirmCourierCash(due, key)) {
      case Ok():
        _cashKeys.remove(due.courierId);
        await refreshLive();
        return true;
      case Err(:final failure):
        if (failure is! NetworkFailure) _cashKeys.remove(due.courierId);
        problem = failure is NetworkFailure ? 'offline' : failure.message;
        notifyListeners();
        return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

String _problemLabel(DymLocalizations l10n, String code) => switch (code) {
  'invalid' => l10n.opsInvalid,
  'country_out_of_scope' => l10n.opsOutOfScope,
  'nothing_owed' => l10n.opsNothingOwed,
  'not_admin' => l10n.opsNotAdmin,
  'offline' => l10n.errorOffline,
  _ => l10n.errorGeneric,
};

/// Onglet « Opérations » de l'admin.
class OpsCenterView extends StackedView<OpsCenterViewModel> {
  const new({
    required this.service,
    required this.onOpenOrder,
    super.key,
    this.refresh,
  });

  final OpsCenterService service;
  final ValueChanged<String> onOpenOrder;

  /// Rafraîchissement de la vue en direct (30 s par défaut).
  final Duration? refresh;

  @override
  OpsCenterViewModel viewModelBuilder(BuildContext context) =>
      OpsCenterViewModel(service: service, refresh: refresh);

  @override
  void onViewModelReady(OpsCenterViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, OpsCenterViewModel vm, Widget? child) {
    final l10n = DymLocalizations.of(context);
    final live = vm.live;
    if (live == null) {
      return AdminPage(
        title: l10n.opsTitle,
        child: vm.failure != null
            ? AdminState(failure: vm.failure, onRetry: vm.load)
            : vm.isBusy || vm.country != null
            ? const Center(child: CircularProgressIndicator())
            : AdminEmpty(l10n.opsNoCountry),
      );
    }
    return DefaultTabController(
      length: 2,
      child: AdminPage(
        title: l10n.opsTitle,
        subtitle: l10n.opsSubtitle,
        actions: [
          Wrap(
            spacing: DymTokenSpace.s2,
            children: [
              for (final code in vm.countries)
                ChoiceChip(
                  label: Text(code),
                  selected: vm.country == code,
                  onSelected: (_) => vm.selectCountry(code),
                ),
            ],
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (vm.problem case final p?) AdminAlert(_problemLabel(l10n, p)),
            TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: l10n.opsLiveTab),
                Tab(text: l10n.opsSettingsTab),
              ],
            ),
            const SizedBox(height: DymTokenSpace.s3),
            Builder(
              builder: (context) {
                final controller = DefaultTabController.of(context);
                return ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => controller.index == 0
                      ? _Live(vm: vm, live: live, onOpenOrder: onOpenOrder)
                      : _Settings(vm: vm),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Live extends StatelessWidget {
  const new({required this.vm, required this.live, required this.onOpenOrder});

  final OpsCenterViewModel vm;
  final OpsLive live;
  final ValueChanged<String> onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final t = context.dym.text;
    final c = context.dym.colors;
    Widget tile(
      String label,
      String value, {
      AdminTone tone = AdminTone.neutral,
    }) => SizedBox(
      width: 168,
      child: AdminCard(
        padding: const EdgeInsets.all(DymTokenSpace.s3),
        borderColor: tone == AdminTone.danger ? c.pimentStrong : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: t.display.copyWith(fontSize: 28)),
            Text(label, style: t.label.copyWith(color: c.textSecondary)),
          ],
        ),
      ),
    );
    final active = [
      OrderStatus.pending,
      OrderStatus.accepted,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.opsLast24h, style: t.label.copyWith(color: c.textSecondary)),
        const SizedBox(height: DymTokenSpace.s2),
        Wrap(
          spacing: DymTokenSpace.s2,
          runSpacing: DymTokenSpace.s2,
          children: [
            for (final s in active)
              tile(orderStatusLabel(l10n, s), '${live.ordersByStatus[s] ?? 0}'),
            tile(
              l10n.opsDelivered,
              vm.money(live.deliveredMinor, live.currencyCode),
            ),
            tile(l10n.opsCouriersOnline, '${live.couriersOnline}'),
            tile(
              l10n.opsMissionsWaiting,
              '${live.missionsWaiting}',
              tone: live.missionsWaiting > 0 && live.couriersOnline == 0
                  ? AdminTone.danger
                  : AdminTone.neutral,
            ),
            tile(l10n.adminNavDisputes, '${live.openDisputes}'),
            tile(l10n.adminNavSupport, '${live.openTickets}'),
            tile(l10n.adminNavModeration, '${live.openReports}'),
          ],
        ),
        const SizedBox(height: DymTokenSpace.s4),
        AdminCard(
          title: l10n.opsAlerts,
          child: live.alerts.isEmpty
              ? AdminEmpty(l10n.opsNoAlert)
              : Column(
                  children: [
                    for (final a in live.alerts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.timer_rounded,
                          color: c.pimentStrong,
                        ),
                        title: Text(a.storeName),
                        subtitle: Text(
                          [
                            orderStatusLabel(l10n, a.status),
                            if (a.delivery && !a.hasCourier) l10n.opsNoCourier,
                          ].join(' · '),
                        ),
                        trailing: AdminPill(
                          l10n.opsMinutes(a.minutes),
                          tone: AdminTone.danger,
                        ),
                        onTap: () => onOpenOrder(a.orderId),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: DymTokenSpace.s4),
        AdminCard(
          title: l10n.opsCourierCash,
          child: live.courierCash.isEmpty
              ? AdminEmpty(l10n.opsNoCourierCash)
              : Column(
                  children: [
                    for (final d in live.courierCash)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.two_wheeler_rounded),
                        title: Text('${d.name} · ${d.phone}'),
                        subtitle: Text(vm.money(d.amountMinor, d.currencyCode)),
                        trailing: FilledButton.icon(
                          onPressed: () => vm.confirmCash(d),
                          icon: const Icon(Icons.payments_rounded),
                          label: Text(l10n.opsCashReceived),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Montant en unités principales, sans symbole (champ de saisie).
String _major(int minor, Currency? currency) => currency == null
    ? '$minor'
    : (minor / math.pow(10, currency.minorUnits)).toStringAsFixed(
        currency.minorUnits,
      );

class _Settings extends StatefulWidget {
  const new({required this.vm});

  final OpsCenterViewModel vm;

  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  final _thresholds = <String, TextEditingController>{};
  final _weights = <String, TextEditingController>{};
  final _prices = <String, TextEditingController>{};
  final _email = TextEditingController();

  TextEditingController _field(
    Map<String, TextEditingController> map,
    String key,
    String text,
  ) => map.putIfAbsent(key, () => TextEditingController(text: text));

  @override
  void dispose() {
    for (final c in [
      ..._thresholds.values,
      ..._weights.values,
      ..._prices.values,
      _email,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final vm = widget.vm;
    final s = vm.settings;
    if (s == null) return AdminEmpty(l10n.errorGeneric);
    Widget numbers(
      Map<String, TextEditingController> map,
      Map<String, int> values,
      List<String> keys,
      String Function(String) label,
    ) => Wrap(
      spacing: DymTokenSpace.s3,
      runSpacing: DymTokenSpace.s2,
      children: [
        for (final k in keys)
          SizedBox(
            width: 200,
            child: DymTextField(
              label: label(k),
              controller: _field(map, k, '${values[k] ?? 0}'),
              keyboardType: TextInputType.number,
            ),
          ),
      ],
    );
    final currency = vm.currencies[s.currencyCode];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminCard(
          title: l10n.opsThresholds,
          trailing: FilledButton(
            onPressed: () => vm.setThresholds({
              for (final e in _thresholds.entries) e.key: e.value.text,
            }),
            child: Text(l10n.opsSave),
          ),
          child: numbers(
            _thresholds,
            s.thresholds,
            const ['pending', 'ready', 'transit'],
            (k) => switch (k) {
              'pending' => l10n.opsThresholdPending,
              'ready' => l10n.opsThresholdReady,
              _ => l10n.opsThresholdTransit,
            },
          ),
        ),
        const SizedBox(height: DymTokenSpace.s3),
        AdminCard(
          title: l10n.opsFeedWeights,
          trailing: FilledButton(
            onPressed: () => vm.setFeedWeights({
              for (final e in _weights.entries) e.key: e.value.text,
            }),
            child: Text(l10n.opsSave),
          ),
          child: numbers(
            _weights,
            s.feedWeights,
            opsFeedWeightKeys,
            (k) => switch (k) {
              'weight_recency' => l10n.opsWeightRecency,
              'weight_engagement' => l10n.opsWeightEngagement,
              'weight_followed' => l10n.opsWeightFollowed,
              'weight_local' => l10n.opsWeightLocal,
              'weight_affinity' => l10n.opsWeightAffinity,
              _ => l10n.opsWeightShoppable,
            },
          ),
        ),
        const SizedBox(height: DymTokenSpace.s3),
        AdminCard(
          title: l10n.opsPlans,
          child: s.plans.isEmpty
              ? AdminEmpty(l10n.membershipNone)
              : Column(
                  children: [
                    for (final p in s.plans)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: DymTokenSpace.s2,
                        ),
                        child: Wrap(
                          spacing: DymTokenSpace.s3,
                          runSpacing: DymTokenSpace.s2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: 200,
                              child: Text(
                                '${p.name.resolve(locale)} · '
                                '${l10n.opsPeriod(p.periodDays)}',
                              ),
                            ),
                            SizedBox(
                              width: 160,
                              child: DymTextField(
                                label: l10n.opsPrice,
                                controller: _field(
                                  _prices,
                                  p.id,
                                  _major(p.priceMinor, currency),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            Switch(
                              value: p.isActive,
                              onChanged: (v) => vm.savePlan(p, active: v),
                            ),
                            TextButton(
                              onPressed: () => vm.savePlan(
                                p,
                                priceText: _prices[p.id]?.text,
                              ),
                              child: Text(l10n.opsSave),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        if (s.canManageScopes) ...[
          const SizedBox(height: DymTokenSpace.s3),
          AdminCard(
            title: l10n.opsScopes,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.opsScopesHint),
                for (final sc in s.scopes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(sc.email),
                    subtitle: Text(sc.countries.join(', ')),
                    trailing: sc.countries.contains(s.countryCode)
                        ? TextButton(
                            onPressed: () =>
                                vm.setScope(sc.email, s.countryCode, on: false),
                            child: Text(l10n.opsScopeRemove(s.countryCode)),
                          )
                        : null,
                  ),
                Row(
                  children: [
                    Expanded(
                      child: DymTextField(
                        label: l10n.opsScopeEmail,
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(width: DymTokenSpace.s2),
                    FilledButton(
                      onPressed: () =>
                          vm.setScope(_email.text, s.countryCode, on: true),
                      child: Text(l10n.opsScopeAdd(s.countryCode)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
