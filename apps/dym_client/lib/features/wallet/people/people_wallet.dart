import 'dart:async';

import 'package:dym_chat/dym_chat.dart' show minorFromText, textFromMinor;
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Avoir entre personnes (spec 100), simulé : jamais de retrait.
abstract interface class PeopleWalletService {
  Future<Result<CountryConfig>> countryConfig();
  Future<Result<PeopleWallet>> overview();
  Future<Result<String?>> recipient(String handle);
  Future<Result<void>> send(String handle, int amountMinor, {String? note});
  Future<Result<void>> request(String handle, int amountMinor, {String? note});
  Future<Result<void>> answer(String requestId, {required bool pay});
  Future<Result<void>> topupFor(String handle, int amountMinor);
  Future<Result<Family>> family();
  Future<Result<Family>> invite(String handle);
  Future<Result<Family>> accept(String parentId);
  Future<Result<Family>> setRules(
    String childId, {
    int? allowanceMinor,
    int everyDays = 7,
    int? dailyLimitMinor,
  });

  /// Rayons autorisés pour un enfant (spec 104) ; vide : tous.
  Future<Result<Family>> setCategories(String childId, List<String> ids);
}

class NeonPeopleWalletService implements PeopleWalletService {
  new(this._repository, {required this._config});

  final PeopleWalletRepository _repository;
  final Future<Result<CountryConfig>> Function() _config;

  @override
  Future<Result<CountryConfig>> countryConfig() => _config();

  @override
  Future<Result<PeopleWallet>> overview() => _repository.overview();

  @override
  Future<Result<String?>> recipient(String handle) =>
      _repository.recipient(handle);

  @override
  Future<Result<void>> send(String handle, int amountMinor, {String? note}) =>
      _repository.send(
        handle,
        amountMinor,
        note: note,
        idempotencyKey: Uuid.v4(),
      );

  @override
  Future<Result<void>> request(
    String handle,
    int amountMinor, {
    String? note,
  }) => _repository.request(handle, amountMinor, note: note);

  @override
  Future<Result<void>> answer(String requestId, {required bool pay}) =>
      _repository.answer(requestId, pay: pay, idempotencyKey: Uuid.v4());

  @override
  Future<Result<void>> topupFor(String handle, int amountMinor) =>
      _repository.topupFor(handle, amountMinor, idempotencyKey: Uuid.v4());

  @override
  Future<Result<Family>> family() => _repository.family();

  @override
  Future<Result<Family>> invite(String handle) => _repository.invite(handle);

  @override
  Future<Result<Family>> accept(String parentId) =>
      _repository.accept(parentId);

  @override
  Future<Result<Family>> setRules(
    String childId, {
    int? allowanceMinor,
    int everyDays = 7,
    int? dailyLimitMinor,
  }) => _repository.setRules(
    childId,
    allowanceMinor: allowanceMinor,
    everyDays: everyDays,
    dailyLimitMinor: dailyLimitMinor,
  );

  @override
  Future<Result<Family>> setCategories(String childId, List<String> ids) =>
      _repository.setCategories(childId, ids);
}

/// Gestes possibles depuis l'écran « Entre proches ».
enum PeopleAction { send, request, topupFor }

class PeopleWalletViewModel extends BaseViewModel {
  new({required this.service});

  final PeopleWalletService service;
  PeopleWallet? wallet;
  Family? family;
  CountryConfig? config;
  Failure? failure;
  Failure? actionFailure;

  Future<void> load() async {
    failure = null;
    config ??= (await service.countryConfig()).valueOrNull;
    final (w, f) = await (service.overview(), service.family()).wait;
    switch (w) {
      case Ok(:final value):
        wallet = value;
      case Err(failure: final e):
        failure = e;
    }
    family = f.valueOrNull ?? family;
    notifyListeners();
  }

  String money(int minor) => config?.money(minor).format() ?? '$minor';

  int? minor(String text) =>
      minorFromText(text, config?.currency.minorUnits ?? 0);

  Future<bool> _act(Future<Result<Object?>> Function() work) async {
    actionFailure = null;
    final result = await runBusyFuture(work());
    if (result case Err(:final failure)) actionFailure = failure;
    await load();
    return result.isOk;
  }

  Future<bool> run(
    PeopleAction action,
    String handle,
    int amountMinor, {
    String? note,
  }) => _act(
    () => switch (action) {
      PeopleAction.send => service.send(handle, amountMinor, note: note),
      PeopleAction.request => service.request(handle, amountMinor, note: note),
      PeopleAction.topupFor => service.topupFor(handle, amountMinor),
    },
  );

  Future<bool> answer(PeopleRequest r, {required bool pay}) =>
      _act(() => service.answer(r.id, pay: pay));

  Future<bool> invite(String handle) => _act(() => service.invite(handle));

  Future<bool> accept(FamilyMember parent) =>
      _act(() => service.accept(parent.userId));

  Future<bool> setRules(
    FamilyMember child, {
    int? allowanceMinor,
    int everyDays = 7,
    int? dailyLimitMinor,
  }) => _act(
    () => service.setRules(
      child.userId,
      allowanceMinor: allowanceMinor,
      everyDays: everyDays,
      dailyLimitMinor: dailyLimitMinor,
    ),
  );

  Future<bool> setCategories(FamilyMember child, List<String> ids) =>
      _act(() => service.setCategories(child.userId, ids));
}

/// Message d'un refus de la base.
String peopleErrorText(DymLocalizations l10n, Failure? f) =>
    switch (f?.message) {
      'wallet_insufficient' => l10n.walletErrorInsufficient,
      'recipient_unknown' => l10n.peopleUnknownCode,
      'child_daily_limit' => l10n.peopleChildLimit,
      'child_category_blocked' => l10n.peopleChildCategory,
      'currency_mismatch' => l10n.peopleCurrencyMismatch,
      _ => f is NetworkFailure ? l10n.errorOffline : l10n.errorGeneric,
    };

/// Entre proches : mon QR, envoyer, demander, recharger, famille.
class PeopleWalletView extends StackedView<PeopleWalletViewModel> {
  const new({required this.service, super.key});

  final PeopleWalletService service;

  @override
  PeopleWalletViewModel viewModelBuilder(BuildContext context) =>
      PeopleWalletViewModel(service: service);

  @override
  void onViewModelReady(PeopleWalletViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(
    BuildContext context,
    PeopleWalletViewModel vm,
    Widget? child,
  ) {
    final l10n = DymLocalizations.of(context);
    final t = context.dym.text;
    final c = context.dym.colors;
    final wallet = vm.wallet;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.peopleTitle)),
      body: wallet == null
          ? (vm.failure == null
                ? const Center(child: CircularProgressIndicator())
                : DymStateView(
                    kind: DymStateKind.error,
                    title: peopleErrorText(l10n, vm.failure),
                    message: '',
                    actionLabel: l10n.retry,
                    onAction: vm.load,
                  ))
          : RefreshIndicator(
              onRefresh: vm.load,
              child: ListView(
                padding: const EdgeInsets.all(DymTokenSpace.s4),
                children: [
                  Text(
                    l10n.peopleSimulatedNote,
                    style: t.label.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  Center(
                    child: Column(
                      children: [
                        DymQrImage(data: wallet.qr, size: 180),
                        const SizedBox(height: DymTokenSpace.s2),
                        SelectableText(
                          wallet.handle,
                          style: t.display.copyWith(
                            fontSize: 26,
                            letterSpacing: 4,
                          ),
                        ),
                        Text(l10n.peopleMyCodeHint, style: t.label),
                      ],
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s4),
                  Wrap(
                    spacing: DymTokenSpace.s2,
                    runSpacing: DymTokenSpace.s2,
                    children: [
                      for (final (action, icon, label) in [
                        (
                          PeopleAction.send,
                          Icons.send_rounded,
                          l10n.peopleSend,
                        ),
                        (
                          PeopleAction.request,
                          Icons.call_received_rounded,
                          l10n.peopleRequest,
                        ),
                        (
                          PeopleAction.topupFor,
                          Icons.volunteer_activism_outlined,
                          l10n.peopleTopupFor,
                        ),
                      ])
                        DymButton(
                          label: label,
                          icon: icon,
                          variant: action == PeopleAction.send
                              ? DymButtonVariant.primary
                              : DymButtonVariant.secondary,
                          onPressed: vm.isBusy
                              ? null
                              : () => _flow(context, vm, action),
                        ),
                    ],
                  ),
                  if (vm.actionFailure != null) ...[
                    const SizedBox(height: DymTokenSpace.s2),
                    Text(
                      peopleErrorText(l10n, vm.actionFailure),
                      style: t.body.copyWith(color: c.pimentStrong),
                    ),
                  ],
                  if (wallet.requests.isNotEmpty) ...[
                    const SizedBox(height: DymTokenSpace.s4),
                    DymSectionHeader(title: l10n.peopleRequests),
                    for (final r in wallet.requests)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          r.toPay
                              ? l10n.peopleAsksYou(
                                  r.otherName,
                                  vm.money(r.amountMinor),
                                )
                              : l10n.peopleYouAsked(
                                  r.otherName,
                                  vm.money(r.amountMinor),
                                ),
                        ),
                        subtitle: r.note == null ? null : Text(r.note!),
                        trailing: r.toPay
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => vm.answer(r, pay: false),
                                    child: Text(l10n.pushActionDecline),
                                  ),
                                  FilledButton(
                                    onPressed: () => vm.answer(r, pay: true),
                                    child: Text(l10n.peoplePay),
                                  ),
                                ],
                              )
                            : null,
                      ),
                  ],
                  const SizedBox(height: DymTokenSpace.s4),
                  DymMenuGroup(
                    children: [
                      DymMenuRow(
                        icon: Icons.family_restroom_rounded,
                        label: l10n.familyTitle,
                        value: '${vm.family?.children.length ?? 0}',
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(builder: (_) => FamilyView(vm: vm)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DymTokenSpace.s4),
                  DymSectionHeader(title: l10n.peopleHistory),
                  if (wallet.transfers.isEmpty)
                    Text(
                      l10n.peopleHistoryEmpty,
                      style: t.body.copyWith(color: c.textSecondary),
                    ),
                  for (final tr in wallet.transfers)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        tr.incoming
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        color: tr.incoming ? c.brand : c.textSecondary,
                      ),
                      title: Text(
                        tr.incoming
                            ? l10n.peopleFrom(tr.otherName)
                            : l10n.peopleTo(tr.otherName),
                      ),
                      subtitle: tr.note == null ? null : Text(tr.note!),
                      trailing: Text(
                        '${tr.incoming ? '+' : '−'}${vm.money(tr.amountMinor)}',
                        style: t.title.copyWith(
                          color: tr.incoming ? c.brand : c.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  /// Code (saisi ou scanné), confirmation du prénom, montant.
  Future<void> _flow(
    BuildContext context,
    PeopleWalletViewModel vm,
    PeopleAction action,
  ) async {
    final l10n = DymLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final code = await _askCode(context);
    if (code == null || !context.mounted) return;
    final name = (await vm.service.recipient(code)).valueOrNull;
    if (!context.mounted) return;
    if (name == null) {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.peopleUnknownCode)));
      return;
    }
    final amount = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(switch (action) {
          PeopleAction.send => l10n.peopleSendTo(name),
          PeopleAction.request => l10n.peopleRequestFrom(name),
          PeopleAction.topupFor => l10n.peopleTopupForName(name),
        }),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.chatAmount(vm.config?.currency.symbol ?? ''),
              ),
            ),
            if (action != PeopleAction.topupFor)
              TextField(
                controller: note,
                maxLength: 140,
                decoration: InputDecoration(labelText: l10n.peopleNote),
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
            child: Text(l10n.chatSend),
          ),
        ],
      ),
    );
    final minor = vm.minor(amount.text);
    final text = note.text.trim();
    amount.dispose();
    note.dispose();
    if (ok != true || minor == null || minor <= 0) return;
    final done = await vm.run(
      action,
      code,
      minor,
      note: text.isEmpty ? null : text,
    );
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          done ? l10n.peopleDone : peopleErrorText(l10n, vm.actionFailure),
        ),
      ),
    );
  }
}

/// Code de la personne : tapé, ou lu sur son QR.
Future<String?> _askCode(BuildContext context) async {
  final l10n = DymLocalizations.of(context);
  final field = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(l10n.peopleCodeTitle),
      content: TextField(
        controller: field,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(labelText: l10n.peopleCodeLabel),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            final scanned = await Navigator.of(d).push<String>(
              MaterialPageRoute(
                builder: (route) => Scaffold(
                  appBar: AppBar(title: Text(l10n.peopleScan)),
                  body: QrScanView(
                    onCode: (raw) => Navigator.of(route).pop(raw),
                    fallback: Center(child: Text(l10n.peopleCodeLabel)),
                  ),
                ),
              ),
            );
            if (scanned != null && d.mounted) Navigator.pop(d, scanned);
          },
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: Text(l10n.peopleScan),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(d, field.text.trim()),
          child: Text(l10n.peopleContinue),
        ),
      ],
    ),
  );
  field.dispose();
  return result == null || result.isEmpty ? null : result;
}

/// Famille : vue parentale (solde, dépenses du jour, règles) et invitations.
class FamilyView extends StatelessWidget {
  const new({required this.vm, super.key});

  final PeopleWalletViewModel vm;

  @override
  Widget build(BuildContext context) => ViewModelBuilder.reactive(
    viewModelBuilder: () => vm,
    disposeViewModel: false,
    builder: (context, vm, _) {
      final l10n = DymLocalizations.of(context);
      final t = context.dym.text;
      final c = context.dym.colors;
      final family = vm.family ?? const Family();
      return Scaffold(
        appBar: AppBar(title: Text(l10n.familyTitle)),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final code = await _askCode(context);
            if (code != null) await vm.invite(code);
          },
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: Text(l10n.familyInvite),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(
              l10n.familyHint,
              style: t.body.copyWith(color: c.textSecondary),
            ),
            for (final p in family.parents.where((p) => !p.active))
              Card(
                child: ListTile(
                  title: Text(l10n.familyInvitedBy(p.firstName)),
                  trailing: FilledButton(
                    onPressed: () => vm.accept(p),
                    child: Text(l10n.familyAccept),
                  ),
                ),
              ),
            const SizedBox(height: DymTokenSpace.s3),
            for (final child in family.children)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(DymTokenSpace.s3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.firstName, style: t.title),
                      if (!child.active)
                        Text(l10n.familyWaiting, style: t.label)
                      else ...[
                        Text(
                          l10n.familyBalance(vm.money(child.balanceMinor ?? 0)),
                        ),
                        Text(
                          l10n.familySpentToday(
                            vm.money(child.spentTodayMinor ?? 0),
                            child.dailyLimitMinor == null
                                ? '—'
                                : vm.money(child.dailyLimitMinor!),
                          ),
                        ),
                        if (child.allowanceMinor case final a?)
                          Text(
                            l10n.familyAllowance(
                              vm.money(a),
                              child.allowanceEveryDays,
                            ),
                          ),
                        TextButton.icon(
                          onPressed: () => _rules(context, child),
                          icon: const Icon(Icons.tune_rounded),
                          label: Text(l10n.familyRules),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  Future<void> _rules(BuildContext context, FamilyMember child) async {
    final l10n = DymLocalizations.of(context);
    final units = vm.config?.currency.minorUnits ?? 0;
    String text(int? minor) => minor == null ? '' : textFromMinor(minor, units);

    final allowance = TextEditingController(text: text(child.allowanceMinor));
    final limit = TextEditingController(text: text(child.dailyLimitMinor));
    var every = child.allowanceEveryDays;
    final allowed = {...child.allowedCategories};
    final locale = Localizations.localeOf(context).languageCode;
    final aisles = vm.config?.topCategories ?? const <Category>[];
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, set) => AlertDialog(
          title: Text(l10n.familyRules),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: allowance,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.familyAllowanceLabel,
                  ),
                ),
                DropdownButton<int>(
                  value: every,
                  items: [
                    for (final d in const [1, 7, 30])
                      DropdownMenuItem(
                        value: d,
                        child: Text(switch (d) {
                          1 => l10n.familyEveryDay,
                          30 => l10n.familyEveryMonth,
                          _ => l10n.familyEveryWeek,
                        }),
                      ),
                  ],
                  onChanged: (v) => set(() => every = v ?? 7),
                ),
                TextField(
                  controller: limit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: l10n.familyLimitLabel),
                ),
                if (aisles.isNotEmpty) ...[
                  const SizedBox(height: DymTokenSpace.s3),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.familyCategoriesLabel),
                  ),
                  const SizedBox(height: DymTokenSpace.s1),
                  Wrap(
                    spacing: DymTokenSpace.s1,
                    runSpacing: DymTokenSpace.s1,
                    children: [
                      for (final a in aisles)
                        FilterChip(
                          label: Text(a.label.resolve(locale)),
                          selected: allowed.contains(a.id),
                          onSelected: (on) => set(
                            () => on ? allowed.add(a.id) : allowed.remove(a.id),
                          ),
                        ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      allowed.isEmpty
                          ? l10n.familyCategoriesAll
                          : l10n.familyCategoriesSome(allowed.length),
                      style: context.dym.text.label,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(l10n.adminSave),
            ),
          ],
        ),
      ),
    );
    final a = vm.minor(allowance.text);
    final l = vm.minor(limit.text);
    allowance.dispose();
    limit.dispose();
    if (ok ?? false) {
      await vm.setRules(
        child,
        allowanceMinor: a,
        everyDays: every,
        dailyLimitMinor: l,
      );
      final before = {...child.allowedCategories};
      if (before.length != allowed.length || !before.containsAll(allowed)) {
        await vm.setCategories(child, allowed.toList());
      }
    }
  }
}
