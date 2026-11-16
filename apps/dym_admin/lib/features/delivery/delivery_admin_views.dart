import 'dart:async';

import 'package:dym_admin/features/delivery/delivery_admin_service.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

// ------------------------------------------------------------------ livraison

/// Réglages de livraison d'un pays (spec 096) : tarif au km ou par tranches,
/// minimum, plafond, arrondi, longue distance, majorations horaires,
/// distance maximale, rayon proposé par ville, simulateur.
class AdminDeliveryViewModel extends BaseViewModel {
  new({required this.service});

  final DeliveryAdminService service;
  List<Country> countries = const [];
  String? country;
  DeliveryConfig? config;
  Failure? failure;
  String? saved;
  (int?, int)? simulation;

  Future<void> load() async {
    failure = null;
    setBusy(true);
    switch (await service.countries()) {
      case Ok(:final value):
        countries = value;
        country ??= value.firstOrNull?.code;
      case Err(failure: final f):
        failure = f;
    }
    if (country case final c?) await _read(c);
    setBusy(false);
  }

  Future<void> _read(String code) async {
    switch (await service.config(code)) {
      case Ok(:final value):
        config = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  Future<void> selectCountry(String code) async {
    country = code;
    config = null;
    simulation = null;
    notifyListeners();
    await _read(code);
  }

  Future<bool> _save(Future<Result<void>> Function(String c) work) async {
    final c = country;
    if (c == null) return false;
    final result = await runBusyFuture(work(c));
    if (result case Err(failure: final f)) failure = f;
    if (result.isOk) await _read(c);
    return result.isOk;
  }

  Future<bool> savePricing(DeliveryPricing p) =>
      _save((c) => service.savePricing(c, p));

  Future<bool> saveSurcharges(List<DeliverySurcharge> list) =>
      _save((c) => service.saveSurcharges(c, list));

  Future<bool> saveBands(List<FeeBand> bands) =>
      _save((c) => service.saveBands(c, bands));

  Future<bool> saveMaxDistance(int meters) =>
      _save((c) => service.saveMaxDistance(c, meters));

  Future<bool> saveCityRadius(String cityId, int meters) =>
      _save((_) => service.saveCityRadius(cityId, meters));

  Future<void> simulate(int meters, {required bool longDistance}) async {
    final c = country;
    if (c == null) return;
    if (await service.preview(c, meters: meters, longDistance: longDistance)
        case Ok(:final value)) {
      simulation = value;
      notifyListeners();
    }
  }
}

class AdminDeliveryView extends StackedView<AdminDeliveryViewModel> {
  const new({required this.service, super.key});

  final DeliveryAdminService service;

  @override
  AdminDeliveryViewModel viewModelBuilder(BuildContext context) =>
      AdminDeliveryViewModel(service: service);

  @override
  void onViewModelReady(AdminDeliveryViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(
    BuildContext context,
    AdminDeliveryViewModel vm,
    Widget? child,
  ) {
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final config = vm.config;
    return AdminPage(
      title: l10n.adminDeliveryTitle,
      subtitle: l10n.adminFeeBandsHint,
      actions: [
        if (vm.countries.isNotEmpty)
          DropdownButton<String>(
            value: vm.country,
            items: [
              for (final c in vm.countries)
                DropdownMenuItem(
                  value: c.code,
                  child: Text(c.name.resolve(locale)),
                ),
            ],
            onChanged: (c) => c == null ? null : vm.selectCountry(c),
          ),
      ],
      child: config == null
          ? (vm.failure == null
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : AdminState(failure: vm.failure, onRetry: vm.load))
          : _DeliveryForms(
              key: ValueKey(config.countryCode),
              vm: vm,
              config: config,
            ),
    );
  }
}

int? _int(String text) => int.tryParse(text.replaceAll(RegExp(r'\s'), ''));

class _NumberField extends StatelessWidget {
  const new({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
    ),
  );
}

class _DeliveryForms extends StatefulWidget {
  const new({required this.vm, required this.config, super.key});

  final AdminDeliveryViewModel vm;
  final DeliveryConfig config;

  @override
  State<_DeliveryForms> createState() => _DeliveryFormsState();
}

class _DeliveryFormsState extends State<_DeliveryForms> {
  late final DeliveryPricing _p =
      widget.config.pricing ?? const DeliveryPricing();
  late String _mode = _p.mode;
  late final _base = TextEditingController(text: '${_p.baseFeeMinor}');
  late final _included = TextEditingController(text: '${_p.includedM}');
  late final _perKm = TextEditingController(text: '${_p.perKmMinor}');
  late final _min = TextEditingController(text: '${_p.minFeeMinor}');
  late final _max = TextEditingController(
    text: _p.maxFeeMinor?.toString() ?? '',
  );
  late final _rounding = TextEditingController(text: '${_p.roundingMinor}');
  late final _long = TextEditingController(
    text: '${_p.longDistanceSurchargeMinor}',
  );
  late final _maxDistance = TextEditingController(
    text: '${widget.config.maxDistanceM}',
  );
  late final List<DeliverySurcharge> _surcharges = [
    ...widget.config.surcharges,
  ];
  late final List<FeeBand> _bands = [...widget.config.bands];
  late final Map<String, TextEditingController> _cities = {
    for (final c in widget.config.cities)
      c.cityId: TextEditingController(text: c.meters?.toString() ?? ''),
  };
  final _simDistance = TextEditingController(text: '3000');
  bool _simLong = false;

  @override
  void dispose() {
    for (final c in [
      _base,
      _included,
      _perKm,
      _min,
      _max,
      _rounding,
      _long,
      _maxDistance,
      _simDistance,
      ..._cities.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _done(bool ok) {
    if (!mounted) return;
    final l10n = DymLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? l10n.adminSaved : l10n.errorGeneric)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final vm = widget.vm;
    final config = widget.config;
    final currency = vm.countries
        .where((c) => c.code == config.countryCode)
        .firstOrNull
        ?.currencyCode;
    const gap = SizedBox(height: DymTokenSpace.s4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminCard(
          title: l10n.adminDeliveryMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'per_km',
                    label: Text(l10n.adminDeliveryPerKm),
                  ),
                  ButtonSegment(
                    value: 'bands',
                    label: Text(l10n.adminDeliveryBands),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const SizedBox(height: DymTokenSpace.s3),
              Wrap(
                spacing: DymTokenSpace.s3,
                runSpacing: DymTokenSpace.s2,
                children: [
                  if (_mode == 'per_km') ...[
                    _NumberField(
                      label: l10n.adminDeliveryBase,
                      controller: _base,
                    ),
                    _NumberField(
                      label: l10n.adminDeliveryIncluded,
                      controller: _included,
                    ),
                    _NumberField(
                      label: l10n.adminDeliveryPerKmFee,
                      controller: _perKm,
                    ),
                  ],
                  _NumberField(label: l10n.adminDeliveryMin, controller: _min),
                  _NumberField(
                    label: l10n.adminDeliveryMaxFee,
                    controller: _max,
                  ),
                  _NumberField(
                    label: l10n.adminDeliveryRounding,
                    controller: _rounding,
                  ),
                  _NumberField(
                    label: l10n.adminDeliveryLongSurcharge,
                    controller: _long,
                  ),
                ],
              ),
              if (_mode == 'bands') ...[
                const SizedBox(height: DymTokenSpace.s3),
                for (final (i, b) in _bands.indexed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '≤ ${b.maxDistanceM} m · ${b.feeMinor} ${currency ?? ''}',
                    ),
                    trailing: IconButton(
                      tooltip: l10n.storeCourierRemove,
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => setState(() => _bands.removeAt(i)),
                    ),
                  ),
                TextButton.icon(
                  onPressed: _addBand,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.adminFeeBandAdd),
                ),
              ],
              const SizedBox(height: DymTokenSpace.s3),
              FilledButton.icon(
                onPressed: vm.isBusy ? null : _savePricing,
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.adminSave),
              ),
            ],
          ),
        ),
        gap,
        AdminCard(
          title: l10n.adminDeliverySurcharges,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, s) in _surcharges.indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${s.label} · +${s.percent} %'),
                  subtitle: Text(
                    '${s.startsAt} → ${s.endsAt} · ${s.weekdays.join(', ')}',
                  ),
                  trailing: IconButton(
                    tooltip: l10n.storeCourierRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => setState(() => _surcharges.removeAt(i)),
                  ),
                ),
              Wrap(
                spacing: DymTokenSpace.s2,
                children: [
                  TextButton.icon(
                    onPressed: _addSurcharge,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.adminDeliverySurchargeAdd),
                  ),
                  FilledButton.icon(
                    onPressed: vm.isBusy
                        ? null
                        : () async =>
                              _done(await vm.saveSurcharges(_surcharges)),
                    icon: const Icon(Icons.save_outlined),
                    label: Text(l10n.adminSave),
                  ),
                ],
              ),
            ],
          ),
        ),
        gap,
        AdminCard(
          title: l10n.adminDeliveryMaxDistance,
          child: Wrap(
            spacing: DymTokenSpace.s3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _NumberField(
                label: l10n.adminDeliveryMaxDistance,
                controller: _maxDistance,
              ),
              FilledButton.icon(
                onPressed: vm.isBusy
                    ? null
                    : () async {
                        final m = _int(_maxDistance.text);
                        if (m != null) _done(await vm.saveMaxDistance(m));
                      },
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.adminSave),
              ),
            ],
          ),
        ),
        gap,
        AdminCard(
          title: l10n.adminDeliveryCityRadius,
          child: Column(
            children: [
              for (final c in config.cities)
                Padding(
                  padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
                  child: Row(
                    children: [
                      Expanded(child: Text(c.name)),
                      _NumberField(
                        label: l10n.adminFeeBandUpTo,
                        controller: _cities[c.cityId]!,
                      ),
                      IconButton(
                        tooltip: l10n.adminSave,
                        icon: const Icon(Icons.save_outlined),
                        onPressed: () async {
                          final m = _int(_cities[c.cityId]!.text);
                          if (m != null) {
                            _done(await vm.saveCityRadius(c.cityId, m));
                          }
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        gap,
        AdminCard(
          title: l10n.adminDeliverySimulator,
          child: Wrap(
            spacing: DymTokenSpace.s3,
            runSpacing: DymTokenSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _NumberField(
                label: l10n.adminDeliverySimDistance,
                controller: _simDistance,
              ),
              FilterChip(
                label: Text(l10n.adminDeliverySimLong),
                selected: _simLong,
                onSelected: (v) => setState(() => _simLong = v),
              ),
              FilledButton.icon(
                onPressed: () {
                  final m = _int(_simDistance.text);
                  if (m != null) {
                    unawaited(vm.simulate(m, longDistance: _simLong));
                  }
                },
                icon: const Icon(Icons.calculate_outlined),
                label: Text(l10n.adminDeliverySimulate),
              ),
              if (vm.simulation case (final fee, final percent))
                Text(
                  l10n.adminDeliverySimResult(
                    fee == null
                        ? '—'
                        : '$fee ${currency ?? ''}'
                              '${percent > 0 ? ' (+$percent %)' : ''}',
                  ),
                  style: context.dym.text.title,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _savePricing() async {
    final p = DeliveryPricing(
      mode: _mode,
      baseFeeMinor: _int(_base.text) ?? 0,
      includedM: _int(_included.text) ?? 0,
      perKmMinor: _int(_perKm.text) ?? 0,
      minFeeMinor: _int(_min.text) ?? 0,
      maxFeeMinor: _int(_max.text),
      roundingMinor: (_int(_rounding.text) ?? 1).clamp(1, 1000000),
      longDistanceSurchargeMinor: _int(_long.text) ?? 0,
    );
    var ok = await widget.vm.savePricing(p);
    if (ok && _mode == 'bands') ok = await widget.vm.saveBands(_bands);
    _done(ok);
  }

  Future<void> _addBand() async {
    final l10n = DymLocalizations.of(context);
    final upTo = TextEditingController();
    final fee = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l10n.adminFeeBandAdd),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NumberField(label: l10n.adminFeeBandUpTo, controller: upTo),
            _NumberField(label: l10n.adminFeeBandFee, controller: fee),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text(l10n.adminFeeBandAdd),
          ),
        ],
      ),
    );
    final m = _int(upTo.text);
    final f = _int(fee.text);
    upTo.dispose();
    fee.dispose();
    if (ok != true || m == null || f == null) return;
    setState(() {
      _bands
        ..add(FeeBand(maxDistanceM: m, feeMinor: f))
        ..sort((a, b) => a.maxDistanceM.compareTo(b.maxDistanceM));
    });
  }

  Future<void> _addSurcharge() async {
    final l10n = DymLocalizations.of(context);
    final label = TextEditingController();
    final start = TextEditingController(text: '20:00');
    final end = TextEditingController(text: '23:00');
    final percent = TextEditingController(text: '20');
    final days = <int>{1, 2, 3, 4, 5, 6, 7};
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, set) => AlertDialog(
          title: Text(l10n.adminDeliverySurchargeAdd),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: label,
                decoration: InputDecoration(
                  labelText: l10n.adminDeliverySurcharges,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: start,
                      decoration: const InputDecoration(labelText: 'HH:MM'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: end,
                      decoration: const InputDecoration(labelText: 'HH:MM'),
                    ),
                  ),
                ],
              ),
              _NumberField(label: '%', controller: percent),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: [
                  for (var day = 1; day <= 7; day++)
                    FilterChip(
                      label: Text('$day'),
                      selected: days.contains(day),
                      onSelected: (v) =>
                          set(() => v ? days.add(day) : days.remove(day)),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(l10n.adminDeliverySurchargeAdd),
            ),
          ],
        ),
      ),
    );
    final p = _int(percent.text);
    final time = RegExp(r'^\d{2}:\d{2}$');
    if (ok == true &&
        p != null &&
        label.text.trim().length >= 2 &&
        time.hasMatch(start.text) &&
        time.hasMatch(end.text) &&
        days.isNotEmpty) {
      setState(
        () => _surcharges.add(
          DeliverySurcharge(
            label: label.text.trim(),
            startsAt: start.text,
            endsAt: end.text,
            percent: p,
            weekdays: days.toList()..sort(),
          ),
        ),
      );
    }
    for (final c in [label, start, end, percent]) {
      c.dispose();
    }
  }
}

// ------------------------------------------------------------------ comptes

class AdminAccountsViewModel extends BaseViewModel {
  new({required this.service});

  final DeliveryAdminService service;
  List<PendingAccount>? accounts;
  Failure? failure;

  Future<void> load() async {
    failure = null;
    switch (await service.pendingAccounts()) {
      case Ok(:final value):
        accounts = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  Future<void> review(
    PendingAccount a, {
    required bool approve,
    String? note,
  }) async {
    if (await runBusyFuture(service.review(a, approve: approve, note: note))
        case Err(failure: final f)) {
      failure = f;
    }
    await load();
  }
}

class AdminAccountsView extends StackedView<AdminAccountsViewModel> {
  const new({required this.service, super.key});

  final DeliveryAdminService service;

  @override
  AdminAccountsViewModel viewModelBuilder(BuildContext context) =>
      AdminAccountsViewModel(service: service);

  @override
  void onViewModelReady(AdminAccountsViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(
    BuildContext context,
    AdminAccountsViewModel vm,
    Widget? child,
  ) {
    final l10n = DymLocalizations.of(context);
    final accounts = vm.accounts;
    return AdminPage(
      title: l10n.adminAccountsTitle,
      child: accounts == null
          ? (vm.failure == null
                ? const Center(child: CircularProgressIndicator())
                : AdminState(failure: vm.failure, onRetry: vm.load))
          : accounts.isEmpty
          ? AdminEmpty(l10n.adminAccountsEmpty)
          : Column(
              children: [
                for (final a in accounts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DymTokenSpace.s3),
                    child: AdminCard(
                      title: a.name,
                      trailing: AdminPill(
                        a.kind == 'store'
                            ? l10n.adminAccountStore
                            : l10n.adminAccountCourier,
                        icon: a.kind == 'store'
                            ? Icons.storefront_outlined
                            : Icons.two_wheeler_rounded,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [a.countryCode, ?a.detail, ?a.contact].join(' · '),
                          ),
                          const SizedBox(height: DymTokenSpace.s2),
                          Wrap(
                            spacing: DymTokenSpace.s2,
                            children: [
                              FilledButton.icon(
                                onPressed: vm.isBusy
                                    ? null
                                    : () => vm.review(a, approve: true),
                                icon: const Icon(Icons.check_rounded),
                                label: Text(l10n.adminAccountApprove),
                              ),
                              OutlinedButton.icon(
                                onPressed: vm.isBusy
                                    ? null
                                    : () async {
                                        final note = await showReasonDialog(
                                          context,
                                          title: l10n.adminAccountReason,
                                          confirmLabel: l10n.adminAccountReject,
                                          destructive: true,
                                        );
                                        if (note != null) {
                                          await vm.review(
                                            a,
                                            approve: false,
                                            note: note,
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.close_rounded),
                                label: Text(l10n.adminAccountReject),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ------------------------------------------------------------------ incidents

class AdminIncidentsViewModel extends BaseViewModel {
  new({required this.service});

  final DeliveryAdminService service;
  List<DeliveryIncident>? incidents;
  Failure? failure;
  Timer? _timer;

  Future<void> start() async {
    // SOS : relu toutes les 30 s tant que la page est ouverte.
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => load());
    await load();
  }

  Future<void> load() async {
    failure = null;
    switch (await service.incidents()) {
      case Ok(:final value):
        incidents = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  Future<void> resolve(DeliveryIncident i) async {
    await service.resolve(i);
    await load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class AdminIncidentsView extends StackedView<AdminIncidentsViewModel> {
  const new({required this.service, super.key});

  final DeliveryAdminService service;

  @override
  AdminIncidentsViewModel viewModelBuilder(BuildContext context) =>
      AdminIncidentsViewModel(service: service);

  @override
  void onViewModelReady(AdminIncidentsViewModel viewModel) =>
      unawaited(viewModel.start());

  @override
  Widget builder(
    BuildContext context,
    AdminIncidentsViewModel vm,
    Widget? child,
  ) {
    final l10n = DymLocalizations.of(context);
    final list = vm.incidents;
    final c = context.dym.colors;
    return AdminPage(
      title: l10n.adminIncidentsTitle,
      child: list == null
          ? (vm.failure == null
                ? const Center(child: CircularProgressIndicator())
                : AdminState(failure: vm.failure, onRetry: vm.load))
          : list.isEmpty
          ? AdminEmpty(l10n.adminIncidentsEmpty)
          : Column(
              children: [
                for (final i in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DymTokenSpace.s3),
                    child: AdminCard(
                      borderColor: i.sos ? c.piment : null,
                      title: i.courierName,
                      trailing: AdminPill(
                        i.sos
                            ? l10n.adminIncidentSos
                            : l10n.adminIncidentUnreachable,
                        tone: i.sos ? AdminTone.danger : AdminTone.warning,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(i.courierPhone),
                          Text(
                            [
                              TimeOfDay.fromDateTime(i.createdAt.toLocal())
                                  .format(context),
                              if (i.position case final p?)
                                [
                                  p.latitude.toStringAsFixed(5),
                                  p.longitude.toStringAsFixed(5),
                                ].join(', '),
                              ?i.note,
                            ].join(' · '),
                          ),
                          const SizedBox(height: DymTokenSpace.s2),
                          OutlinedButton.icon(
                            onPressed: () => vm.resolve(i),
                            icon: const Icon(Icons.task_alt_rounded),
                            label: Text(l10n.adminIncidentResolve),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
