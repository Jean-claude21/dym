import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_delivery/features/missions/missions_service.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Refus affichés à l'écran.
enum MissionError {
  taken,
  tooMany,
  suspended,
  invalidPhone,
  invalidZones,
  codeLocked,
  offline,
  generic,
}

MissionError missionErrorOf(Failure failure) => switch (failure) {
  NetworkFailure() => MissionError.offline,
  _ when failure.message == 'mission_taken' => MissionError.taken,
  _ when failure.message == 'too_many_missions' => MissionError.tooMany,
  _ when failure.message == 'courier_suspended' => MissionError.suspended,
  _ when failure.message == 'invalid_phone' => MissionError.invalidPhone,
  _ when failure.message == 'invalid_zones' => MissionError.invalidZones,
  _ when failure.message == 'code_locked' => MissionError.codeLocked,
  _ => MissionError.generic,
};

String missionErrorText(DymLocalizations l10n, MissionError error) =>
    switch (error) {
      MissionError.taken => l10n.missionTaken,
      MissionError.tooMany => l10n.missionTooMany,
      MissionError.suspended => l10n.courierSuspended,
      MissionError.invalidPhone => l10n.courierInvalidPhone,
      MissionError.invalidZones => l10n.courierInvalidZones,
      MissionError.codeLocked => l10n.handoverLocked,
      MissionError.offline => l10n.errorOffline,
      MissionError.generic => l10n.errorGeneric,
    };

String vehicleLabel(DymLocalizations l10n, CourierVehicle v) => switch (v) {
  CourierVehicle.foot => l10n.courierVehicleFoot,
  CourierVehicle.bike => l10n.courierVehicleBike,
  CourierVehicle.moto => l10n.courierVehicleMoto,
  CourierVehicle.car => l10n.courierVehicleCar,
};

// ---------------------------------------------------------------- inscription

class CourierOnboardingViewModel extends BaseViewModel {
  new({required this.service, String? firstName})
    : nameController = TextEditingController(text: firstName ?? '');

  final MissionsService service;
  final TextEditingController nameController;
  final phoneController = TextEditingController();
  CourierVehicle vehicle = CourierVehicle.moto;
  final zoneIds = <String>{};
  CountryConfig? config;
  Failure? failure;
  MissionError? problem;
  bool saving = false;

  Future<void> load() async {
    failure = null;
    setBusy(true);
    switch (await service.countryConfig()) {
      case Ok(:final value):
        config = value;
      case Err(failure: final f):
        failure = f;
    }
    setBusy(false);
  }

  void chooseVehicle(CourierVehicle v) {
    vehicle = v;
    notifyListeners();
  }

  void toggleZone(String id) {
    zoneIds.contains(id) ? zoneIds.remove(id) : zoneIds.add(id);
    notifyListeners();
  }

  String get name => nameController.text;
  String get phone => phoneController.text;

  /// Champ modifié : le bouton suit.
  void edited() => notifyListeners();

  bool get canSave =>
      name.trim().length >= 2 && phone.trim().length >= 8 && zoneIds.isNotEmpty;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<bool> save() async {
    if (saving || !canSave) return false;
    saving = true;
    problem = null;
    notifyListeners();
    final result = await service.become(
      name: name.trim(),
      phone: phone.trim(),
      vehicle: vehicle,
      zoneIds: zoneIds.toList(),
    );
    saving = false;
    if (result case Err(failure: final f)) problem = missionErrorOf(f);
    notifyListeners();
    return result.isOk;
  }
}

/// Devenir livreur : nom, téléphone, moyen, zones.
class CourierOnboardingView extends StackedView<CourierOnboardingViewModel> {
  const new({
    required this.service,
    required this.onDone,
    this.firstName,
    super.key,
  });

  final MissionsService service;
  final VoidCallback onDone;
  final String? firstName;

  @override
  CourierOnboardingViewModel viewModelBuilder(BuildContext context) =>
      CourierOnboardingViewModel(service: service, firstName: firstName);

  @override
  void onViewModelReady(CourierOnboardingViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(
    BuildContext context,
    CourierOnboardingViewModel vm,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final config = vm.config;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(l10n.courierBecomeTitle),
      ),
      body: SafeArea(
        child: config == null
            ? LoadState(
                failure: vm.isBusy ? null : vm.failure,
                onRetry: vm.load,
              )
            : ListView(
                padding: EdgeInsets.fromLTRB(
                  DymLayout.gutter(context),
                  DymTokenSpace.s2,
                  DymLayout.gutter(context),
                  DymTokenSpace.s5,
                ),
                children: [
                  DymContentWidth.form(
                    child: Text(
                      l10n.courierBecomeBody,
                      style: t.body.copyWith(color: c.textSecondary),
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  DymContentWidth.form(
                    child: DymTextField(
                      label: l10n.courierName,
                      controller: vm.nameController,
                      onChanged: (_) => vm.edited(),
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s4),
                  DymContentWidth.form(
                    child: DymTextField(
                      label: l10n.courierPhone,
                      keyboardType: TextInputType.phone,
                      controller: vm.phoneController,
                      onChanged: (_) => vm.edited(),
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  DymContentWidth.form(
                    child: DymSectionHeader(title: l10n.courierVehicle),
                  ),
                  const SizedBox(height: DymTokenSpace.s4),
                  DymContentWidth.form(
                    child: Wrap(
                      spacing: DymTokenSpace.s2,
                      runSpacing: DymTokenSpace.s2,
                      children: [
                        for (final v in CourierVehicle.values)
                          ChoiceChip(
                            label: Text(vehicleLabel(l10n, v)),
                            selected: vm.vehicle == v,
                            onSelected: (_) => vm.chooseVehicle(v),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  DymContentWidth.form(
                    child: DymSectionHeader(title: l10n.courierZones),
                  ),
                  for (final city in config.cities)
                    DymContentWidth.form(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: DymTokenSpace.s2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(city.name, style: t.label),
                            const SizedBox(height: DymTokenSpace.s1),
                            Wrap(
                              spacing: DymTokenSpace.s2,
                              runSpacing: DymTokenSpace.s3,
                              children: [
                                for (final z in config.zonesOf(city.id))
                                  FilterChip(
                                    label: Text(z.name),
                                    selected: vm.zoneIds.contains(z.id),
                                    onSelected: (_) => vm.toggleZone(z.id),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (vm.problem case final p?)
                    DymContentWidth.form(
                      child: Text(
                        missionErrorText(l10n, p),
                        style: t.body.copyWith(color: c.pimentStrong),
                      ),
                    ),
                  const SizedBox(height: DymTokenSpace.s3),
                  DymContentWidth.form(
                    child: DymButton(
                      label: l10n.courierBecomeAction,
                      icon: Icons.two_wheeler_rounded,
                      loading: vm.saving,
                      onPressed: vm.canSave
                          ? () async {
                              if (await vm.save()) onDone();
                            }
                          : null,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------- missions

/// Rafraîchissement du terrain (spec 066) : le push n'est pas garanti et le
/// réseau est instable ; la liste se recharge au retour dans l'app et à
/// intervalle régulier tant que le livreur est actif et l'app au premier plan.
class FieldRefresher {
  new(this._reload, {required this._active, Duration? every}) {
    _life = AppLifecycleListener(onResume: _tick);
    _timer = Timer.periodic(every ?? const Duration(seconds: 30), (_) {
      final state = WidgetsBinding.instance.lifecycleState;
      if (_active() && (state == null || state == AppLifecycleState.resumed)) {
        _tick();
      }
    });
  }

  final Future<void> Function() _reload;
  final bool Function() _active;
  late final AppLifecycleListener _life;
  late final Timer _timer;
  bool _running = false;

  void _tick() {
    if (_running) return;
    _running = true;
    unawaited(_reload().whenComplete(() => _running = false));
  }

  void dispose() {
    _timer.cancel();
    _life.dispose();
  }
}

class MissionsViewModel extends BaseViewModel {
  new({required this.service});

  final MissionsService service;

  /// Courses proposées rechargées tant que le livreur est en ligne.
  FieldRefresher? _refresher;

  StreamSubscription<LiveSignal>? _live;

  /// Démarre le chargement, le temps réel (spec 067) et, en filet, une
  /// relecture régulière.
  Future<void> start() {
    _live ??= watchLive(
      service.live,
      when: (s) =>
          s.kind == 'order_status' ||
          s.notificationKind == 'mission_available' ||
          s.notificationKind == 'order_ready_pickup',
      reload: () => unawaited(load()),
    );
    _refresher ??= FieldRefresher(
      load,
      active: () => profile?.isOnline ?? false,
      every: const Duration(seconds: 60),
    );
    return load();
  }

  @override
  void dispose() {
    unawaited(_live?.cancel());
    _refresher?.dispose();
    super.dispose();
  }

  CourierProfile? profile;
  CountryConfig? config;
  List<Mission>? missions;
  Failure? failure;
  MissionError? problem;
  String? accepting;

  Future<void> load() async {
    failure = null;
    config ??= (await service.countryConfig()).valueOrNull;
    switch (await service.profile()) {
      case Ok(:final value):
        profile = value;
      case Err(failure: final f):
        failure = f;
        notifyListeners();
        return;
    }
    switch (await service.available()) {
      case Ok(:final value):
        missions = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  String money(int minor) => config?.money(minor).format() ?? '';

  Future<void> setOnline({required bool online}) async {
    problem = null;
    switch (await service.setOnline(online: online)) {
      case Ok(:final value):
        profile = value;
        await load();
      case Err(failure: final f):
        problem = missionErrorOf(f);
        notifyListeners();
    }
  }

  /// `true` : mission obtenue (l'écran passe à « Mes courses »).
  Future<bool> accept(Mission mission) async {
    if (accepting != null) return false;
    accepting = mission.orderId;
    problem = null;
    notifyListeners();
    final result = await service.accept(mission);
    accepting = null;
    if (result case Err(failure: final f)) problem = missionErrorOf(f);
    await load();
    return result.isOk;
  }
}

/// Missions proposées : interrupteur en ligne, liste, acceptation.
class MissionsView extends StackedView<MissionsViewModel> {
  const new({
    required this.service,
    required this.onAccepted,
    super.key,
    this.active,
  });

  final MissionsService service;
  final VoidCallback onAccepted;

  /// Course en cours (tournée), posée au-dessus des propositions.
  final Widget? active;

  @override
  MissionsViewModel viewModelBuilder(BuildContext context) =>
      MissionsViewModel(service: service);

  @override
  void onViewModelReady(MissionsViewModel viewModel) =>
      unawaited(viewModel.start());

  @override
  Widget builder(BuildContext context, MissionsViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final missions = vm.missions;
    final online = vm.profile?.isOnline ?? false;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            DymLayout.gutter(context),
            DymTokenSpace.s3,
            DymLayout.gutter(context),
            DymTokenSpace.s5,
          ),
          children: [
            // Titre et « En ligne » sur une ligne (planche 05).
            DymContentWidth(
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(l10n.missionsTitle, style: t.display),
                    ),
                  ),
                  MergeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          online ? l10n.courierOnline : l10n.courierOffline,
                          style: t.body,
                        ),
                        const SizedBox(width: DymTokenSpace.s2),
                        Switch(
                          value: online,
                          onChanged: vm.profile == null
                              ? null
                              : (on) => vm.setOnline(online: on),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DymContentWidth(
              child: Text(
                online ? l10n.courierOnlineHint : l10n.courierOfflineHint,
                style: t.label.copyWith(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (active case final a?) DymContentWidth(child: a),
            if (vm.problem case final p?)
              DymContentWidth(
                child: Padding(
                  padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                  child: Text(
                    missionErrorText(l10n, p),
                    style: t.body.copyWith(color: c.pimentStrong),
                  ),
                ),
              ),
            const SizedBox(height: DymTokenSpace.s3),
            if (missions == null)
              LoadState(failure: vm.failure, onRetry: vm.load)
            else if (missions.isEmpty)
              DymStateView(
                kind: DymStateKind.empty,
                title: online ? l10n.missionsNone : l10n.missionsGoOnline,
                message: online
                    ? l10n.missionsNoneHint
                    : l10n.courierOfflineHint,
              )
            else
              for (final m in missions)
                DymContentWidth(
                  child: MissionCard(
                    mission: m,
                    money: vm.money,
                    action: DymButton(
                      label: l10n.missionAccept,
                      icon: Icons.check_rounded,
                      loading: vm.accepting == m.orderId,
                      onPressed: vm.accepting != null
                          ? null
                          : () async {
                              if (await vm.accept(m)) onAccepted();
                            },
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'une mission : boutique, cliente, articles, frais.
class MissionCard extends StatelessWidget {
  const new({
    required this.mission,
    required this.money,
    this.action,
    this.secondary,
    super.key,
  });

  final Mission mission;
  final String Function(int minor) money;
  final Widget? action;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    Widget place(IconData icon, String title, MissionPlace p) => ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, color: c.textSecondary),
      title: Text(title, style: t.label.copyWith(color: c.textSecondary)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [?p.name, ?p.zoneName].join(' · '),
            style: t.body.copyWith(color: c.textPrimary),
          ),
          if (p.landmark case final landmark?) Text(landmark),
          if (p.phone case final phone?) SelectableText(phone),
        ],
      ),
    );
    final route = [
      ?mission.store.name,
      [?mission.customer.name, ?mission.customer.zoneName].join(' · '),
    ].where((e) => e.isNotEmpty).join(' → ');
    return Container(
      margin: const EdgeInsets.only(bottom: DymTokenSpace.s3),
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.tintVertTendre,
                  borderRadius: BorderRadius.circular(DymTokenRadius.chip),
                ),
                child: Text(
                  missionStatusLabel(l10n, mission.status),
                  style: t.label.copyWith(color: c.brandDeep),
                ),
              ),
              const Spacer(),
              Text(
                l10n.missionItems(mission.itemCount),
                style: t.label.copyWith(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s2),
          if (route.isNotEmpty)
            Text(
              route,
              style: t.body.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: DymTokenSpace.s2),
          Wrap(
            spacing: DymTokenSpace.s2,
            runSpacing: DymTokenSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${l10n.missionFeeLabel} ',
                      style: t.body.copyWith(color: c.textSecondary),
                    ),
                    TextSpan(
                      text: money(mission.deliveryFeeMinor),
                      style: t.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              // Cash à encaisser : le jaune est réservé au cash.
              if (mission.cashToCollectMinor > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.plantain,
                    borderRadius: BorderRadius.circular(DymTokenRadius.chip),
                  ),
                  child: Text(
                    l10n.missionCashToCollect(
                      money(mission.cashToCollectMinor),
                    ),
                    style: t.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
          if (mission.scheduledStart case final start?)
            _MissionFact(
              icon: Icons.event_outlined,
              text: l10n.missionSlot(
                missionSlotLabel(context, start, mission.scheduledEnd),
              ),
            ),
          if (mission.runSize > 1 || mission.storage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: DymTokenSpace.s2),
              child: Wrap(
                spacing: DymTokenSpace.s2,
                runSpacing: DymTokenSpace.s1,
                children: [
                  if (mission.runSize > 1)
                    _Hint(
                      icon: Icons.alt_route_rounded,
                      label: l10n.missionRun(mission.runSize),
                    ),
                  for (final h in mission.storage)
                    _Hint(icon: storageIcon(h), label: storageLabel(l10n, h)),
                ],
              ),
            ),
          const SizedBox(height: DymTokenSpace.s1),
          Divider(height: DymTokenSpace.s4, color: c.hairline),
          place(Icons.storefront_outlined, l10n.missionPickup, mission.store),
          place(Icons.home_outlined, l10n.missionDropoff, mission.customer),
          if (action case final a?) ...[
            const SizedBox(height: DymTokenSpace.s2),
            a,
          ],
          if (secondary case final s?) ...[
            const SizedBox(height: DymTokenSpace.s2),
            s,
          ],
        ],
      ),
    );
  }
}

/// Consigne (au frais, fragile, tournée) : icône et libellé sur menthe.
class _Hint extends StatelessWidget {
  const new({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.muted,
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c.textPrimary),
          const SizedBox(width: 4),
          Text(label, style: context.dym.text.label),
        ],
      ),
    );
  }
}

IconData storageIcon(StorageHint s) => switch (s) {
  StorageHint.ambient => Icons.wb_sunny_rounded,
  StorageHint.cool => Icons.ac_unit_rounded,
  StorageHint.frozen => Icons.severe_cold_rounded,
  StorageHint.fragile => Icons.egg_rounded,
};

String storageLabel(DymLocalizations l10n, StorageHint s) => switch (s) {
  StorageHint.ambient => l10n.storageAmbient,
  StorageHint.cool => l10n.storageCool,
  StorageHint.frozen => l10n.storageFrozen,
  StorageHint.fragile => l10n.storageFragile,
};

String missionStatusLabel(DymLocalizations l10n, String status) =>
    switch (status) {
      'accepted' || 'preparing' => l10n.missionPreparing,
      'ready' => l10n.missionReady,
      'out_for_delivery' => l10n.missionOnTheWay,
      'delivered' => l10n.missionDelivered,
      _ => l10n.missionPreparing,
    };

// ---------------------------------------------------------------- mes courses

class MyRunsViewModel extends BaseViewModel {
  new({required this.service});

  final MissionsService service;

  /// Courses en cours rechargées (commande prête, annulée) ; l'historique
  /// n'en a pas besoin.
  FieldRefresher? _refresher;

  StreamSubscription<LiveSignal>? _live;

  /// Démarre le chargement ; [live] : courses en cours suivies en direct
  /// (spec 067), avec une relecture régulière en filet.
  Future<void> start({required bool live}) {
    if (live) {
      _live ??= watchLive(
        service.live,
        when: (s) => s.kind == 'order_status' || s.kind == 'notification',
        reload: () => unawaited(load()),
      );
      _refresher ??= FieldRefresher(
        load,
        active: () => runs?.any((r) => r.status != 'delivered') ?? false,
        every: const Duration(seconds: 60),
      );
    }
    return load();
  }

  @override
  void dispose() {
    unawaited(_live?.cancel());
    _refresher?.dispose();
    super.dispose();
  }

  CountryConfig? config;
  List<Mission>? runs;
  Failure? failure;
  MissionError? problem;
  String? acting;

  Future<void> load() async {
    failure = null;
    config ??= (await service.countryConfig()).valueOrNull;
    switch (await service.mine()) {
      case Ok(:final value):
        runs = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  String money(int minor) => config?.money(minor).format() ?? '';

  Future<void> advance(Mission mission, String to) async {
    if (acting != null) return;
    acting = mission.orderId;
    problem = null;
    notifyListeners();
    final result = await service.advance(mission, to);
    acting = null;
    if (result case Err(failure: final f)) problem = missionErrorOf(f);
    await load();
  }

  /// Remise : `null` si livrée, sinon essais restants.
  Future<int?> deliver(Mission mission, String code) async {
    if (acting != null) return null;
    acting = mission.orderId;
    problem = null;
    notifyListeners();
    final result = await service.deliver(mission, code.trim());
    acting = null;
    int? left;
    switch (result) {
      case Ok(:final value) when value.ok:
        left = null;
      case Ok(:final value):
        left = value.attemptsLeft;
      case Err(failure: final f):
        problem = missionErrorOf(f);
        left = 0;
    }
    await load();
    return left;
  }

  Future<void> release(Mission mission) async {
    if (await service.release(mission) case Err(failure: final f)) {
      problem = missionErrorOf(f);
    }
    await load();
  }
}

/// Courses du livreur : en cours (récupérer, livrer, rendre), posées dans
/// « Missions » ([embedded]), ou terminées dans « Historique ».
class MyRunsView extends StackedView<MyRunsViewModel> {
  const new({required this.service, super.key, this.history = false})
    : embedded = !history;

  final MissionsService service;

  /// Historique : courses livrées seulement, page à part entière.
  final bool history;

  /// En cours : liste sans en-tête ni défilement, dans « Missions ».
  final bool embedded;

  @override
  MyRunsViewModel viewModelBuilder(BuildContext context) =>
      MyRunsViewModel(service: service);

  @override
  void onViewModelReady(MyRunsViewModel viewModel) =>
      unawaited(viewModel.start(live: embedded));

  @override
  Widget builder(BuildContext context, MyRunsViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final all = vm.runs;
    final runs = all?.where((m) => m.delivered == history).toList();
    Widget card(Mission m) => MissionCard(
      mission: m,
      money: vm.money,
      action: switch (m.next.firstOrNull) {
        'out_for_delivery' => DymButton(
          label: l10n.missionPickedUp,
          icon: Icons.inventory_2_outlined,
          loading: vm.acting == m.orderId,
          onPressed: () => vm.advance(m, 'out_for_delivery'),
        ),
        'delivered' => DymButton(
          label: l10n.missionHandedOver,
          icon: Icons.task_alt_rounded,
          loading: vm.acting == m.orderId,
          onPressed: () => _askCode(context, vm, m),
        ),
        _ when !m.delivered => Text(
          l10n.missionWaitReady,
          style: t.body.copyWith(color: c.textSecondary),
        ),
        _ => null,
      },
      secondary: m.releasable
          ? DymButton(
              label: l10n.missionRelease,
              icon: Icons.undo_rounded,
              variant: DymButtonVariant.secondary,
              onPressed: () => vm.release(m),
            )
          : null,
    );
    if (embedded) {
      // Rien en cours : la section disparaît.
      if (runs == null || runs.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: DymTokenSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.runsActiveTitle,
              style: t.body.copyWith(fontWeight: FontWeight.w600),
            ),
            if (vm.problem case final p?)
              Text(
                missionErrorText(l10n, p),
                style: t.body.copyWith(color: c.pimentStrong),
              ),
            const SizedBox(height: DymTokenSpace.s2),
            for (final m in runs) card(m),
          ],
        ),
      );
    }
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            DymLayout.gutter(context),
            DymTokenSpace.s3,
            DymLayout.gutter(context),
            DymTokenSpace.s5,
          ),
          children: [
            DymContentWidth(
              child: Semantics(
                header: true,
                child: Text(l10n.runsHistoryTitle, style: t.display),
              ),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            if (runs == null)
              LoadState(failure: vm.failure, onRetry: vm.load)
            else if (runs.isEmpty)
              DymStateView(
                kind: DymStateKind.empty,
                icon: Icons.history_rounded,
                title: l10n.runsHistoryTitle,
                message: l10n.runsHistoryNone,
              )
            else
              for (final m in runs) DymContentWidth(child: card(m)),
          ],
        ),
      ),
    );
  }
}

/// Chargement, puis erreur ou hors ligne avec « Réessayer ».
class LoadState extends StatelessWidget {
  const new({required this.failure, required this.onRetry, super.key});

  final Failure? failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final f = failure;
    if (f == null) {
      return Padding(
        padding: const EdgeInsets.all(DymTokenSpace.s5),
        child: Center(
          child: Semantics(
            label: l10n.startupPreparing,
            child: const CircularProgressIndicator(),
          ),
        ),
      );
    }
    final offline = f is NetworkFailure;
    return DymStateView(
      kind: offline ? DymStateKind.offline : DymStateKind.error,
      title: offline ? l10n.errorOffline : l10n.errorGeneric,
      message: l10n.retryHint,
      actionLabel: l10n.retry,
      onAction: onRetry,
    );
  }
}

/// Code de remise demandé à la cliente ; la base le vérifie.
Future<void> _askCode(
  BuildContext context,
  MyRunsViewModel vm,
  Mission m,
) async {
  final l10n = DymLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final code = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CodeSheet(
      cash: m.cashToCollectMinor > 0 ? vm.money(m.cashToCollectMinor) : null,
    ),
  );
  if (code == null || code.trim().isEmpty) return;
  final left = await vm.deliver(m, code);
  if (left != null && vm.problem == null) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.handoverWrong(left))));
  }
}

/// Remise (planche 05) : quatre cases, clavier géant, cash à encaisser.
class _CodeSheet extends StatefulWidget {
  const new({this.cash});

  /// Cash à encaisser auprès de la cliente, formaté ; nul : déjà payé.
  final String? cash;

  @override
  State<_CodeSheet> createState() => _CodeSheetState();
}

class _CodeSheetState extends State<_CodeSheet> {
  static const _length = 4;
  String _code = '';

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return SafeArea(
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
            Text(l10n.handoverTitle, style: t.title),
            const SizedBox(height: DymTokenSpace.s1),
            Text(
              l10n.handoverBody,
              style: t.label.copyWith(
                color: c.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            Semantics(
              label: l10n.handoverCode,
              value: _code,
              liveRegion: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _length; i++)
                    Container(
                      width: 56,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(
                          DymTokenRadius.field,
                        ),
                        border: Border.all(
                          color: i == _code.length ? c.brand : c.lineStrong,
                          width: i == _code.length ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        i < _code.length ? _code[i] : '',
                        style: t.display.copyWith(fontSize: 28),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            DymKeypad(
              onDigit: (d) => setState(() {
                if (_code.length < _length) _code += d;
              }),
              onErase: () => setState(() {
                if (_code.isNotEmpty) {
                  _code = _code.substring(0, _code.length - 1);
                }
              }),
              eraseLabel: l10n.tillErase,
            ),
            if (widget.cash case final cash?) ...[
              const SizedBox(height: DymTokenSpace.s1),
              // Jaune : réservé au cash.
              Container(
                padding: const EdgeInsets.all(DymTokenSpace.s3),
                decoration: BoxDecoration(
                  color: c.plantain,
                  borderRadius: BorderRadius.circular(DymTokenRadius.button),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, color: c.textPrimary),
                    const SizedBox(width: DymTokenSpace.s2),
                    Expanded(
                      child: Text(
                        l10n.missionCashToCollect(cash),
                        style: t.body.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: DymTokenSpace.s3),
            DymButton(
              label: l10n.handoverConfirm,
              icon: Icons.task_alt_rounded,
              onPressed: _code.length == _length
                  ? () => Navigator.pop(context, _code)
                  : null,
            ),
            const SizedBox(height: DymTokenSpace.s3),
            DymButton(
              label: l10n.handoverCancel,
              variant: DymButtonVariant.secondary,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Créneau lisible : « 12 nov., 08:00–10:00 », dans l'heure de l'appareil.
String missionSlotLabel(BuildContext context, DateTime start, DateTime? end) {
  final m = MaterialLocalizations.of(context);
  String time(DateTime at) => m.formatTimeOfDay(
    TimeOfDay.fromDateTime(at.toLocal()),
    alwaysUse24HourFormat: true,
  );
  return [
    m.formatShortMonthDay(start.toLocal()),
    [time(start), if (end != null) time(end)].join('–'),
  ].join(', ');
}

class _MissionFact extends StatelessWidget {
  const new({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Padding(
      padding: const EdgeInsets.only(top: DymTokenSpace.s2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.textSecondary),
          const SizedBox(width: DymTokenSpace.s2),
          Expanded(child: Text(text, style: context.dym.text.label)),
        ],
      ),
    );
  }
}
