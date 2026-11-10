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
                  const SizedBox(height: DymTokenSpace.s3),
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
                              runSpacing: DymTokenSpace.s2,
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

class MissionsViewModel extends BaseViewModel {
  new({required this.service});

  final MissionsService service;
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
  const new({required this.service, required this.onAccepted, super.key});

  final MissionsService service;
  final VoidCallback onAccepted;

  @override
  MissionsViewModel viewModelBuilder(BuildContext context) =>
      MissionsViewModel(service: service);

  @override
  void onViewModelReady(MissionsViewModel viewModel) =>
      unawaited(viewModel.load());

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
            DymContentWidth(child: Text(l10n.missionsTitle, style: t.display)),
            const SizedBox(height: DymTokenSpace.s2),
            DymContentWidth(
              child: DymSwitchTile(
                large: true,
                title: online ? l10n.courierOnline : l10n.courierOffline,
                subtitle: online
                    ? l10n.courierOnlineHint
                    : l10n.courierOfflineHint,
                value: online,
                onChanged: vm.profile == null
                    ? null
                    : (on) => vm.setOnline(online: on),
              ),
            ),
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
      leading: Icon(icon, color: c.brandDeep),
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
    return Card(
      margin: const EdgeInsets.only(bottom: DymTokenSpace.s3),
      child: Padding(
        padding: const EdgeInsets.all(DymTokenSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    missionStatusLabel(l10n, mission.status),
                    style: t.title,
                  ),
                ),
                Text(money(mission.deliveryFeeMinor), style: t.title),
              ],
            ),
            Text(
              l10n.missionItems(mission.itemCount),
              style: t.label.copyWith(color: c.textSecondary),
            ),
            if (mission.runSize > 1 || mission.storage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                child: Wrap(
                  spacing: DymTokenSpace.s2,
                  runSpacing: DymTokenSpace.s1,
                  children: [
                    if (mission.runSize > 1)
                      Chip(
                        avatar: const Icon(Icons.alt_route_rounded, size: 18),
                        label: Text(l10n.missionRun(mission.runSize)),
                      ),
                    for (final s in mission.storage)
                      Chip(
                        avatar: Icon(storageIcon(s), size: 18),
                        label: Text(storageLabel(l10n, s)),
                      ),
                  ],
                ),
              ),
            place(Icons.storefront_rounded, l10n.missionPickup, mission.store),
            place(Icons.home_rounded, l10n.missionDropoff, mission.customer),
            ?action,
            if (secondary case final s?) ...[
              const SizedBox(height: DymTokenSpace.s2),
              s,
            ],
          ],
        ),
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

/// Mes courses : récupérer, livrer, rendre.
class MyRunsView extends StackedView<MyRunsViewModel> {
  const new({required this.service, super.key});

  final MissionsService service;

  @override
  MyRunsViewModel viewModelBuilder(BuildContext context) =>
      MyRunsViewModel(service: service);

  @override
  void onViewModelReady(MyRunsViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, MyRunsViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final runs = vm.runs;
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
            DymContentWidth(child: Text(l10n.myRunsTitle, style: t.display)),
            if (vm.problem case final p?)
              DymContentWidth(
                child: Text(
                  missionErrorText(l10n, p),
                  style: t.body.copyWith(color: c.pimentStrong),
                ),
              ),
            const SizedBox(height: DymTokenSpace.s3),
            if (runs == null)
              LoadState(failure: vm.failure, onRetry: vm.load)
            else if (runs.isEmpty)
              DymStateView(
                kind: DymStateKind.empty,
                title: l10n.myRunsNone,
                message: l10n.myRunsNoneHint,
              )
            else
              for (final m in runs)
                DymContentWidth(
                  child: MissionCard(
                    mission: m,
                    money: vm.money,
                    action: switch (m.next.firstOrNull) {
                      'out_for_delivery' => DymButton(
                        label: l10n.missionPickedUp,
                        icon: Icons.inventory_2_rounded,
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
                  ),
                ),
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
    builder: (_) => const _CodeSheet(),
  );
  if (code == null || code.trim().isEmpty) return;
  final left = await vm.deliver(m, code);
  if (left != null && vm.problem == null) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.handoverWrong(left))));
  }
}

/// Saisie du code : le champ garde son contrôleur jusqu'à la fermeture.
class _CodeSheet extends StatefulWidget {
  const new();

  @override
  State<_CodeSheet> createState() => _CodeSheetState();
}

class _CodeSheetState extends State<_CodeSheet> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          DymTokenSpace.s4,
          0,
          DymTokenSpace.s4,
          DymTokenSpace.s4 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.handoverTitle, style: context.dym.text.title),
            const SizedBox(height: DymTokenSpace.s2),
            Text(l10n.handoverBody),
            const SizedBox(height: DymTokenSpace.s3),
            DymTextField(
              label: l10n.handoverCode,
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 4,
              autofocus: true,
            ),
            const SizedBox(height: DymTokenSpace.s3),
            DymButton(
              label: l10n.handoverConfirm,
              icon: Icons.task_alt_rounded,
              onPressed: () => Navigator.pop(context, _code.text),
            ),
            const SizedBox(height: DymTokenSpace.s2),
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
