import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/store/store_service.dart';
import 'package:dym_vendor/features/store/widgets/store_widgets.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Rôles du personnel (spec 087), du plus large au plus restreint.
const staffRoles = ['manager', 'preparer', 'cashier'];

/// Libellé d'un rôle de boutique ; un rôle inconnu garde son code.
String staffRoleLabel(DymLocalizations l10n, String role) => switch (role) {
  'owner' => l10n.staffRoleOwner,
  'manager' => l10n.staffRoleManager,
  'preparer' => l10n.staffRolePreparer,
  'cashier' => l10n.staffRoleCashier,
  _ => role,
};

/// Ce que le rôle permet, en une phrase (aide au choix).
String staffRoleHint(DymLocalizations l10n, String role) => switch (role) {
  'manager' => l10n.staffRoleManagerHint,
  'preparer' => l10n.staffRolePreparerHint,
  'cashier' => l10n.staffRoleCashierHint,
  _ => '',
};

/// Équipe de la boutique (propriétaire) : inviter par email avec un rôle,
/// retirer. L'argent, les réglages et l'équipe restent à la propriétaire.
class StaffViewModel extends BaseViewModel {
  new({required this.service});

  final StoreService service;

  List<StoreStaffMember> _staff = const [];
  Failure? _failure;
  Failure? _actionFailure;
  bool _acting = false;

  List<StoreStaffMember> get staff => _staff;
  Failure? get failure => _failure;
  Failure? get actionFailure => _actionFailure;
  bool get acting => _acting;

  Future<void> load() async {
    setBusy(true);
    final result = await service.myStaff();
    switch (result) {
      case Ok(:final value):
        _staff = value;
        _failure = null;
      case Err(:final failure):
        _failure = failure;
    }
    setBusy(false);
  }

  Future<bool> invite(String email, String role) =>
      _act(() => service.inviteStaff(email.trim().toLowerCase(), role));

  Future<bool> remove(StoreStaffMember member) =>
      _act(() => service.removeStaff(member.email));

  Future<bool> _act(
    Future<Result<List<StoreStaffMember>>> Function() gesture,
  ) async {
    if (_acting) return false;
    _acting = true;
    _actionFailure = null;
    notifyListeners();
    final result = await gesture();
    switch (result) {
      case Ok(:final value):
        _staff = value;
      case Err(:final failure):
        _actionFailure = failure;
    }
    _acting = false;
    notifyListeners();
    return result is Ok;
  }
}

class StaffView extends StackedView<StaffViewModel> {
  const new({required this.service, super.key});

  final StoreService service;

  @override
  StaffViewModel viewModelBuilder(BuildContext context) =>
      StaffViewModel(service: service);

  @override
  void onViewModelReady(StaffViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, StaffViewModel vm, Widget? child) {
    final t = context.dym.text;
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, box) {
          final inset = DymLayout.sideInset(
            box.maxWidth,
            gutter: DymLayout.gutter(context),
            maxWidth: DymTokenLayout.formMax,
          );
          return ListView(
            padding: EdgeInsets.fromLTRB(inset, 16, inset, 24),
            children: [
              Semantics(
                header: true,
                child: Text(l10n.staffTitle, style: t.display),
              ),
              const SizedBox(height: DymTokenSpace.s2),
              Text(
                l10n.staffHelp,
                style: t.body.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: DymTokenSpace.s4),
              _InviteForm(vm: vm),
              StoreErrorBanner(failure: vm.actionFailure),
              const SizedBox(height: DymTokenSpace.s4),
              if (vm.isBusy)
                const Center(child: CircularProgressIndicator())
              else if (vm.failure case final failure?)
                DymStateView(
                  kind: failure is NetworkFailure
                      ? DymStateKind.offline
                      : DymStateKind.error,
                  title: failure is NetworkFailure
                      ? l10n.errorOffline
                      : l10n.errorGeneric,
                  message: l10n.errorLoadMessage,
                  actionLabel: l10n.retry,
                  onAction: vm.load,
                )
              else if (vm.staff.isEmpty)
                DymStateView(
                  kind: DymStateKind.empty,
                  title: l10n.staffEmpty,
                  message: l10n.staffEmptyHint,
                )
              else
                DymMenuGroup(
                  children: [
                    for (final m in vm.staff)
                      ListTile(
                        leading: Icon(
                          m.invited
                              ? Icons.schedule_send_rounded
                              : Icons.badge_outlined,
                          color: m.invited ? c.textSecondary : c.brandDeep,
                        ),
                        title: Text(m.firstName ?? m.email),
                        subtitle: Text(
                          [
                            staffRoleLabel(l10n, m.role),
                            if (m.firstName != null) m.email,
                            if (m.invited) l10n.staffInvited,
                          ].join(' · '),
                        ),
                        trailing: IconButton(
                          tooltip: l10n.staffRemove,
                          icon: const Icon(Icons.person_remove_rounded),
                          onPressed: vm.acting ? null : () => vm.remove(m),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InviteForm extends StatefulWidget {
  const new({required this.vm});

  final StaffViewModel vm;

  @override
  State<_InviteForm> createState() => _InviteFormState();
}

class _InviteFormState extends State<_InviteForm> {
  final _email = TextEditingController();
  String _role = 'preparer';

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final email = _email.text.trim();
    if (!email.contains('@')) return;
    if (await widget.vm.invite(email, _role)) _email.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DymTextField(
          label: l10n.authEmailLabel,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          onSubmitted: (_) => _invite(),
        ),
        const SizedBox(height: DymTokenSpace.s3),
        Text(l10n.staffRoleLabel, style: t.label),
        const SizedBox(height: DymTokenSpace.s2),
        for (final role in staffRoles)
          Padding(
            padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
            child: Material(
              color: _role == role ? c.tintVertTendre : c.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                side: BorderSide(color: _role == role ? c.brand : c.hairline),
              ),
              child: ListTile(
                selected: _role == role,
                onTap: () => setState(() => _role = role),
                leading: Icon(
                  _role == role
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: _role == role ? c.brandDeep : c.textSecondary,
                ),
                title: Text(
                  staffRoleLabel(l10n, role),
                  style: t.body.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  staffRoleHint(l10n, role),
                  style: t.label.copyWith(color: c.textSecondary),
                ),
              ),
            ),
          ),
        const SizedBox(height: DymTokenSpace.s2),
        DymButton(
          label: l10n.staffInvite,
          icon: Icons.person_add_alt_1_rounded,
          loading: widget.vm.acting,
          onPressed: _invite,
        ),
      ],
    );
  }
}
