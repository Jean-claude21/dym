import 'dart:async';

import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_client/features/spaces/spaces_service.dart';
import 'package:dym_client/features/spaces/spaces_viewmodels.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

String spaceErrorLabel(DymLocalizations l10n, SpaceError error) =>
    switch (error) {
      SpaceError.name => l10n.spaceErrorName,
      SpaceError.budget => l10n.spaceErrorBudget,
      SpaceError.unknownCode => l10n.spaceErrorUnknownCode,
      SpaceError.otherCountry => l10n.spaceErrorOtherCountry,
      SpaceError.full => l10n.spaceErrorFull,
      SpaceError.tooMany => l10n.spaceErrorTooMany,
      SpaceError.cartEmpty => l10n.spaceErrorCartEmpty,
      SpaceError.budgetExceeded => l10n.spaceErrorBudgetExceeded,
      SpaceError.notPayer => l10n.spaceErrorNotPayer,
      SpaceError.pocketInsufficient => l10n.spaceErrorPocketInsufficient,
      SpaceError.walletInsufficient => l10n.walletErrorInsufficient,
      SpaceError.spaceBalance => l10n.spaceErrorSpaceBalance,
      SpaceError.amount => l10n.walletErrorAmount,
      SpaceError.offline => l10n.errorOffline,
      SpaceError.generic => l10n.errorGeneric,
    };

String spaceRoleLabel(DymLocalizations l10n, SpaceRole role) => switch (role) {
  SpaceRole.payer => l10n.spaceRolePayer,
  SpaceRole.member => l10n.spaceRoleMember,
};

// ------------------------------------------------------------------ liste

/// « Mes espaces » (spec 031).
class SpacesView extends StackedView<SpacesViewModel> {
  const new({
    required this.service,
    required this.onBack,
    required this.onOpen,
    super.key,
  });

  final SpacesService service;
  final VoidCallback onBack;

  /// Ouvre un espace ; au retour, la liste est rechargée.
  final Future<void> Function(String spaceId) onOpen;

  @override
  SpacesViewModel viewModelBuilder(BuildContext context) =>
      SpacesViewModel(service: service);

  @override
  void onViewModelReady(SpacesViewModel viewModel) =>
      unawaited(viewModel.load());

  Future<void> _open(SpacesViewModel vm, String id) async {
    await onOpen(id);
    await vm.load();
  }

  @override
  Widget builder(BuildContext context, SpacesViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final Widget body;
    if (!vm.ready) {
      body = DiscoveryState(
        failure: vm.isBusy ? null : vm.failure,
        onRetry: vm.load,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            DymContentWidth.form(
              child: Text(
                l10n.spacesIntro,
                style: t.body.copyWith(color: c.textSecondary),
              ),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            DymContentWidth.form(
              child: Row(
                children: [
                  Expanded(
                    child: DymButton(
                      label: l10n.spaceCreate,
                      icon: Icons.add_rounded,
                      onPressed: vm.acting
                          ? null
                          : () async {
                              final space = await _create(context, vm);
                              if (space != null) await _open(vm, space.id);
                            },
                    ),
                  ),
                  const SizedBox(width: DymTokenSpace.s2),
                  Expanded(
                    child: DymButton(
                      label: l10n.spaceJoin,
                      icon: Icons.group_add_rounded,
                      variant: DymButtonVariant.secondary,
                      onPressed: vm.acting
                          ? null
                          : () async {
                              final code = await _ask(
                                context,
                                title: l10n.spaceJoin,
                                hint: l10n.spaceCodeHint,
                                caps: true,
                              );
                              if (code == null) return;
                              final space = await vm.join(code);
                              if (space != null) await _open(vm, space.id);
                            },
                    ),
                  ),
                ],
              ),
            ),
            if (vm.problem case final p?)
              DymContentWidth.form(
                child: Padding(
                  padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                  child: CartIssue(label: spaceErrorLabel(l10n, p)),
                ),
              ),
            const SizedBox(height: DymTokenSpace.s4),
            if (vm.spaces.isEmpty)
              DymContentWidth.form(
                child: DymStateView(
                  kind: DymStateKind.empty,
                  title: l10n.spacesTitle,
                  message: l10n.spacesEmpty,
                ),
              ),
            for (final s in vm.spaces)
              DymContentWidth.form(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
                  child: Material(
                    color: c.card,
                    borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      minTileHeight: 72,
                      onTap: () => _open(vm, s.id),
                      leading: CircleAvatar(
                        backgroundColor: c.tintVertTendre,
                        child: Icon(Icons.groups_rounded, color: c.brandDeep),
                      ),
                      title: Text(
                        s.name,
                        style: t.title.copyWith(fontSize: 17),
                      ),
                      subtitle: Text(
                        [
                          l10n.spaceMembersCount(s.membersCount),
                          l10n.shoppingItemsCount(s.itemsCount),
                          spaceRoleLabel(l10n, s.myRole),
                        ].join(' · '),
                        style: t.label.copyWith(color: c.textSecondary),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(title: l10n.spacesTitle, onBack: onBack),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  static Future<Space?> _create(
    BuildContext context,
    SpacesViewModel vm,
  ) async {
    final values = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _CreateDialog(),
    );
    if (values == null) return null;
    return await vm.create(values.$1, values.$2);
  }
}

class _CreateDialog extends StatefulWidget {
  const new();

  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  final _name = TextEditingController();
  final _budget = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.spaceCreate),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: Space.maxNameLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.spaceName,
              hintText: l10n.spaceNameHint,
            ),
          ),
          TextField(
            controller: _budget,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.spaceBudget,
              hintText: l10n.spaceBudgetHint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop((_name.text, _budget.text)),
          child: Text(l10n.spaceCreateAction),
        ),
      ],
    );
  }
}

/// Une saisie courte (code) ; `null` : annulée.
Future<String?> _ask(
  BuildContext context, {
  required String title,
  required String hint,
  bool caps = false,
  bool number = false,
  String? action,
}) => showDialog<String>(
  context: context,
  builder: (dialog) {
    final text = TextEditingController();
    final l10n = DymLocalizations.of(dialog);
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: text,
        autofocus: true,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        textCapitalization: caps
            ? TextCapitalization.characters
            : TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.of(dialog).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(text.text),
          child: Text(action ?? l10n.spaceJoinAction),
        ),
      ],
    );
  },
);

// ------------------------------------------------------------------ espace

/// Un espace : budget, code d'invitation, membres, panier commun.
class SpaceView extends StackedView<SpaceViewModel> {
  const new({
    required this.service,
    required this.spaceId,
    required this.onBack,
    required this.onValidated,
    super.key,
  });

  final SpacesService service;
  final String spaceId;
  final VoidCallback onBack;

  /// Articles passés au panier : ouvrir le panier.
  final VoidCallback onValidated;

  @override
  SpaceViewModel viewModelBuilder(BuildContext context) =>
      SpaceViewModel(service: service, spaceId: spaceId);

  @override
  void onViewModelReady(SpaceViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, SpaceViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final space = vm.space;
    final Widget body;
    if (space == null) {
      body = DiscoveryState(
        failure: vm.isBusy ? null : vm.failure,
        onRetry: vm.load,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (space.monthlyBudgetMinor != null)
              DymContentWidth.form(
                child: _BudgetCard(vm: vm, space: space),
              ),
            DymContentWidth.form(
              child: _PocketCard(vm: vm, space: space),
            ),
            DymContentWidth.form(child: _CodeCard(code: space.joinCode)),
            const SizedBox(height: DymTokenSpace.s3),
            DymContentWidth.form(
              child: DymSectionHeader(title: l10n.spaceMembers),
            ),
            for (final m in space.members)
              DymContentWidth.form(
                child: _MemberRow(vm: vm, space: space, member: m),
              ),
            const SizedBox(height: DymTokenSpace.s3),
            DymContentWidth.form(
              child: DymSectionHeader(
                title: l10n.spaceBasket,
                actionLabel: l10n.spaceSendCart,
                onAction: vm.acting ? null : vm.sendCart,
              ),
            ),
            if (space.items.isEmpty)
              DymContentWidth.form(
                child: Text(
                  l10n.spaceBasketEmpty,
                  style: t.body.copyWith(color: c.textSecondary),
                ),
              ),
            for (final item in space.items)
              DymContentWidth.form(
                child: _ItemRow(vm: vm, item: item),
              ),
            if (vm.problem case final p?)
              DymContentWidth.form(
                child: CartIssue(label: spaceErrorLabel(l10n, p)),
              ),
            if (vm.skipped.isNotEmpty)
              DymContentWidth.form(
                child: CartIssue(
                  label: l10n.basketSkipped(vm.skipped.join(', ')),
                  blocking: false,
                ),
              ),
            if (space.items.isNotEmpty) ...[
              const Divider(height: DymTokenSpace.s5),
              DymContentWidth.form(
                child: Text(
                  l10n.spaceTotal(vm.money(space.totalMinor) ?? ''),
                  style: t.title.copyWith(color: c.brandDeep),
                ),
              ),
              const SizedBox(height: DymTokenSpace.s3),
              if (space.canValidate && space.pocketBalanceMinor > 0)
                DymContentWidth.form(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: vm.usePocket,
                    onChanged: vm.acting
                        ? null
                        : (v) => vm.setUsePocket(value: v),
                    title: Text(l10n.spaceUsePocket, style: t.body),
                    subtitle: Text(
                      l10n.spaceUsePocketHint,
                      style: t.label.copyWith(color: c.textSecondary),
                    ),
                  ),
                ),
              DymContentWidth.form(
                child: space.canValidate
                    ? DymButton(
                        label: l10n.spaceValidate,
                        icon: Icons.check_circle_rounded,
                        loading: vm.acting,
                        onPressed: vm.acting
                            ? null
                            : () async {
                                if (await vm.validate() && vm.skipped.isEmpty) {
                                  onValidated();
                                }
                              },
                      )
                    : Text(
                        l10n.spaceWaitPayer,
                        style: t.body.copyWith(color: c.textSecondary),
                      ),
              ),
            ],
            const SizedBox(height: DymTokenSpace.s5),
            DymContentWidth.form(
              child: Center(
                child: TextButton.icon(
                  onPressed: () => _leaveOrDelete(context, vm, space),
                  icon: Icon(
                    space.isOwner ? Icons.delete_rounded : Icons.logout_rounded,
                    color: c.pimentStrong,
                  ),
                  label: Text(
                    space.isOwner ? l10n.spaceDelete : l10n.spaceLeave,
                    style: TextStyle(color: c.pimentStrong),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(title: space?.name ?? l10n.spacesTitle, onBack: onBack),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Future<void> _leaveOrDelete(
    BuildContext context,
    SpaceViewModel vm,
    Space space,
  ) async {
    final l10n = DymLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(
          space.isOwner
              ? l10n.spaceDeleteConfirm(space.name)
              : l10n.spaceLeaveConfirm(space.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(space.isOwner ? l10n.spaceDelete : l10n.spaceLeave),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final me = space.members.where((m) => m.isMe).firstOrNull;
    final done = space.isOwner
        ? await vm.delete()
        : me != null && await vm.remove(me);
    if (done) onBack();
  }
}

class _BudgetCard extends StatelessWidget {
  const new({required this.vm, required this.space});

  final SpaceViewModel vm;
  final Space space;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final budget = space.monthlyBudgetMinor!;
    final ratio = (space.spentMonthMinor / budget).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: DymTokenSpace.s3),
      padding: const EdgeInsets.all(DymTokenSpace.s4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.spaceBudgetTitle, style: t.title.copyWith(fontSize: 17)),
          const SizedBox(height: DymTokenSpace.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: // Jauge déjà dite en texte.
            ExcludeSemantics(
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                color: space.overBudget ? c.pimentStrong : c.brand,
                backgroundColor: c.tintVertTendre,
              ),
            ),
          ),
          const SizedBox(height: DymTokenSpace.s2),
          Text(
            l10n.spaceBudgetMeta(
              vm.money(space.spentMonthMinor) ?? '',
              vm.money(budget) ?? '',
              vm.money(space.remainingMinor) ?? '',
            ),
            style: t.label,
          ),
          if (space.overBudget)
            Text(
              l10n.spaceErrorBudgetExceeded,
              style: t.label.copyWith(color: c.pimentStrong),
            ),
        ],
      ),
    );
  }
}

class _PocketCard extends StatelessWidget {
  const new({required this.vm, required this.space});

  final SpaceViewModel vm;
  final Space space;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: DymTokenSpace.s3),
      padding: const EdgeInsets.all(DymTokenSpace.s4),
      decoration: BoxDecoration(
        color: c.brand,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.spacePocket,
                  style: t.label.copyWith(color: c.onBrand),
                ),
                Text(
                  vm.money(space.pocketBalanceMinor) ?? '',
                  style: t.display.copyWith(color: c.onBrand, fontSize: 28),
                ),
              ],
            ),
          ),
          DymButton(
            label: l10n.spaceContribute,
            icon: Icons.add_rounded,
            variant: DymButtonVariant.secondary,
            expanded: false,
            compact: true,
            onPressed: vm.acting
                ? null
                : () async {
                    final text = await _ask(
                      context,
                      title: l10n.spaceContributeTitle,
                      hint: l10n.spaceBudgetHint,
                      action: l10n.spaceContribute,
                      number: true,
                    );
                    if (text != null) await vm.contribute(text);
                  },
          ),
        ],
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const new({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DymTokenSpace.s4,
        DymTokenSpace.s2,
        DymTokenSpace.s2,
        DymTokenSpace.s2,
      ),
      decoration: BoxDecoration(
        color: c.tintVertTendre,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.spaceInvite, style: t.label),
                SelectableText(
                  code,
                  style: t.title.copyWith(letterSpacing: 3, color: c.brandDeep),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.spaceCopyCode,
            onPressed: () async {
              final messenger = ScaffoldMessenger.maybeOf(context);
              await Clipboard.setData(ClipboardData(text: code));
              messenger?.showSnackBar(
                SnackBar(content: Text(l10n.spaceCodeCopied)),
              );
            },
            icon: Icon(Icons.copy_rounded, color: c.brandDeep),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const new({required this.vm, required this.space, required this.member});

  final SpaceViewModel vm;
  final Space space;
  final SpaceMember member;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final manage = space.isOwner && !member.isOwner;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 56,
      leading: CircleAvatar(
        backgroundColor: c.tintVertTendre,
        child: Text(
          member.firstName.characters.first.toUpperCase(),
          style: t.title.copyWith(color: c.brandDeep),
        ),
      ),
      title: Text(
        member.isMe ? l10n.spaceMe(member.firstName) : member.firstName,
        style: t.body,
      ),
      subtitle: Text(
        [
          if (member.isOwner)
            l10n.spaceOwner
          else
            spaceRoleLabel(l10n, member.role),
          if (member.contributedMonthMinor > 0)
            l10n.spaceContributedMonth(
              vm.money(member.contributedMonthMinor) ?? '',
            ),
        ].join(' · '),
        style: t.label.copyWith(color: c.textSecondary),
      ),
      trailing: manage
          ? PopupMenuButton<String>(
              tooltip: l10n.spaceManage(member.firstName),
              onSelected: (action) async {
                switch (action) {
                  case 'payer':
                    await vm.setRole(member, SpaceRole.payer);
                  case 'member':
                    await vm.setRole(member, SpaceRole.member);
                  case 'remove':
                    await vm.remove(member);
                }
              },
              itemBuilder: (_) => [
                if (member.role == SpaceRole.member)
                  PopupMenuItem(
                    value: 'payer',
                    child: Text(l10n.spaceMakePayer),
                  )
                else
                  PopupMenuItem(
                    value: 'member',
                    child: Text(l10n.spaceMakeMember),
                  ),
                PopupMenuItem(
                  value: 'remove',
                  child: Text(l10n.spaceRemoveMember),
                ),
              ],
            )
          : null,
    );
  }
}

class _ItemRow extends StatelessWidget {
  const new({required this.vm, required this.item});

  final SpaceViewModel vm;
  final SpaceItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s1),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DymTokenRadius.tile / 2),
            child: SizedBox.square(
              dimension: 52,
              child: item.photoKey == null
                  ? ColoredBox(color: c.tintVertTendre)
                  : Image(
                      image: vm.service.photo(item.photoKey!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          ColoredBox(color: c.tintVertTendre),
                    ),
            ),
          ),
          const SizedBox(width: DymTokenSpace.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: t.title.copyWith(fontSize: 16)),
                Text(
                  [
                    ?vm.money(item.unitPriceMinor * item.quantity),
                    if (item.addedBy case final who?) l10n.spaceAddedBy(who),
                    if (!item.available) l10n.spaceUnavailable,
                  ].join(' · '),
                  style: t.label.copyWith(
                    color: item.available ? c.textSecondary : c.pimentStrong,
                  ),
                ),
              ],
            ),
          ),
          DymQuantityStepper(
            quantity: item.quantity,
            dense: true,
            decreaseLabel: l10n.shoppingLess(item.name),
            increaseLabel: l10n.shoppingMoreQty(item.name),
            onChanged: vm.acting ? (_) {} : (q) => vm.setQuantity(item, q),
          ),
        ],
      ),
    );
  }
}

/// « Envoyer à un espace » depuis le panier : choix de l'espace, puis
/// message ; renvoie l'espace choisi si l'envoi a réussi.
Future<String?> sendCartToSpace(
  BuildContext context,
  SpacesService service,
) async {
  final l10n = DymLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final spaces = (await service.spaces()).valueOrNull ?? const [];
  if (!context.mounted) return null;
  if (spaces.isEmpty) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.spacesEmptyShort)));
    return null;
  }
  final chosen = await showModalBottomSheet<SpaceSummary>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l10n.spaceSendCartTitle, style: sheet.dym.text.title),
          ),
          for (final s in spaces)
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.groups_rounded),
              title: Text(s.name),
              onTap: () => Navigator.of(sheet).pop(s),
            ),
        ],
      ),
    ),
  );
  if (chosen == null) return null;
  final result = await service.sendCart(chosen.id);
  messenger?.showSnackBar(
    SnackBar(
      content: Text(switch (result) {
        Ok() => l10n.spaceCartSent(chosen.name),
        Err(:final failure) => spaceErrorLabel(l10n, spaceErrorOf(failure)),
      }),
    ),
  );
  return result.isOk ? chosen.id : null;
}
