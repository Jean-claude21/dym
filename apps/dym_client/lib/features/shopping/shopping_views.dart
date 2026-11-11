import 'dart:async';

import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_client/features/shopping/shopping_service.dart';
import 'package:dym_client/features/shopping/shopping_viewmodels.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

String shoppingErrorLabel(DymLocalizations l10n, ShoppingError error) =>
    switch (error) {
      ShoppingError.name => l10n.shoppingErrorName,
      ShoppingError.items => l10n.shoppingErrorItems,
      ShoppingError.tooMany => l10n.shoppingErrorTooMany,
      ShoppingError.offline => l10n.errorOffline,
      ShoppingError.generic => l10n.errorGeneric,
    };

String shoppingPeriodLabel(DymLocalizations l10n, ShoppingPeriod? period) =>
    switch (period) {
      null => l10n.shoppingNoRepeat,
      ShoppingPeriod.weekly => l10n.shoppingEvery7,
      ShoppingPeriod.biweekly => l10n.shoppingEvery14,
      ShoppingPeriod.monthly => l10n.shoppingEvery30,
    };

String _date(BuildContext context, DateTime d) =>
    MaterialLocalizations.of(context).formatMediumDate(d);

// ------------------------------------------------------------------ listes

/// « Mes courses » (spec 029) : listes nommées librement, liste habituelle,
/// liste décrite à l'IA ; chaque liste compose un panier à valider.
class ShoppingListsView extends StackedView<ShoppingListsViewModel> {
  const new({
    required this.service,
    required this.onBack,
    required this.onEdit,
    required this.onOpen,
    super.key,
  });

  final ShoppingService service;
  final VoidCallback onBack;

  /// Ouvre l'édition ; `true` si la liste a été enregistrée.
  final Future<bool> Function(ShoppingDraft draft) onEdit;

  /// Panier proposé pour la liste.
  final ValueChanged<ShoppingList> onOpen;

  @override
  ShoppingListsViewModel viewModelBuilder(BuildContext context) =>
      ShoppingListsViewModel(service: service);

  @override
  void onViewModelReady(ShoppingListsViewModel viewModel) =>
      unawaited(viewModel.load());

  Future<void> _edit(ShoppingListsViewModel vm, ShoppingDraft draft) async {
    if (await onEdit(draft)) await vm.load();
  }

  @override
  Widget builder(
    BuildContext context,
    ShoppingListsViewModel vm,
    Widget? child,
  ) {
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
                l10n.shoppingIntro,
                style: t.body.copyWith(color: c.textSecondary),
              ),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            DymContentWidth.form(
              child: _Action(
                icon: Icons.add_rounded,
                title: l10n.shoppingNew,
                onTap: vm.acting
                    ? null
                    : () => _edit(vm, const ShoppingDraft()),
              ),
            ),
            DymContentWidth.form(
              child: _Action(
                icon: Icons.history_rounded,
                title: l10n.shoppingFromHabits,
                subtitle: l10n.shoppingFromHabitsHint,
                onTap: vm.acting
                    ? null
                    : () async {
                        final draft = await vm.fromHabits(
                          l10n.shoppingFromHabits,
                        );
                        if (draft != null) await _edit(vm, draft);
                      },
              ),
            ),
            if (vm.aiEnabled)
              DymContentWidth.form(
                child: _Action(
                  icon: Icons.auto_awesome_rounded,
                  title: l10n.shoppingDescribe,
                  subtitle: l10n.shoppingDescribeHint,
                  onTap: vm.acting
                      ? null
                      : () async {
                          final text = await _describe(context);
                          if (text == null) return;
                          final draft = await vm.describe(text);
                          if (draft != null) await _edit(vm, draft);
                        },
                ),
              ),
            if (vm.acting)
              const Padding(
                padding: EdgeInsets.all(DymTokenSpace.s2),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_message(l10n, vm) case final message?)
              DymContentWidth.form(
                child: CartIssue(label: message, blocking: false),
              ),
            const SizedBox(height: DymTokenSpace.s3),
            if (vm.lists.isEmpty)
              DymContentWidth.form(
                child: DymStateView(
                  kind: DymStateKind.empty,
                  icon: Icons.checklist_rounded,
                  title: l10n.shoppingTitle,
                  message: l10n.shoppingEmpty,
                ),
              ),
            for (final list in vm.lists)
              DymContentWidth.form(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: DymTokenSpace.s3),
                  child: _ListCard(
                    list: list,
                    onOpen: () => onOpen(list),
                    onEdit: vm.acting
                        ? null
                        : () => _edit(vm, ShoppingDraft(list: list)),
                    onDelete: vm.acting
                        ? null
                        : () async {
                            if (await _confirmDelete(context, list.name)) {
                              await vm.delete(list);
                            }
                          },
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
            CartHeader(title: l10n.shoppingTitle, onBack: onBack),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  static String? _message(DymLocalizations l10n, ShoppingListsViewModel vm) {
    if (vm.noHabits) return l10n.shoppingNoHabits;
    if (vm.aiNothing) return l10n.shoppingAiNothing;
    if (vm.aiFailed) return l10n.shoppingAiUnavailable;
    if (vm.problem case final e?) return shoppingErrorLabel(l10n, e);
    return null;
  }

  static Future<bool> _confirmDelete(BuildContext context, String name) async {
    final l10n = DymLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: Text(l10n.shoppingDeleteConfirm(name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialog).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialog).pop(true),
                child: Text(l10n.shoppingDelete),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Description libre ; `null` : annulée.
  static Future<String?> _describe(BuildContext context) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const _DescribeSheet(),
      );
}

class _Action extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          side: BorderSide(color: c.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          minTileHeight: 64,
          enabled: onTap != null,
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: c.tintVertTendre,
            child: Icon(icon, color: c.brandDeep),
          ),
          title: Text(title, style: t.title.copyWith(fontSize: 17)),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  style: t.label.copyWith(color: c.textSecondary),
                ),
          trailing: Icon(Icons.chevron_right_rounded, color: c.textSecondary),
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const new({
    required this.list,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final ShoppingList list;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final next = list.nextDueOn;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DymTokenSpace.s4,
        DymTokenSpace.s2,
        DymTokenSpace.s1,
        DymTokenSpace.s4,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(list.name, style: t.title.copyWith(fontSize: 19)),
              ),
              PopupMenuButton<bool>(
                tooltip: l10n.shoppingMore(list.name),
                enabled: onEdit != null,
                onSelected: (edit) => (edit ? onEdit : onDelete)?.call(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: true,
                    child: ListTile(
                      leading: const Icon(Icons.edit_rounded),
                      title: Text(l10n.shoppingEdit),
                    ),
                  ),
                  PopupMenuItem(
                    value: false,
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_rounded,
                        color: c.pimentStrong,
                      ),
                      title: Text(l10n.shoppingDelete),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            list.items.map((i) => i.label).join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.body.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: DymTokenSpace.s1),
          Wrap(
            spacing: DymTokenSpace.s2,
            children: [
              Text(l10n.shoppingItemsCount(list.items.length), style: t.label),
              if (list.period case final p?) ...[
                Text(
                  '· ${shoppingPeriodLabel(l10n, p)}',
                  style: t.label.copyWith(color: c.brandDeep),
                ),
                if (next != null)
                  Text(
                    '· ${l10n.shoppingNextOn(_date(context, next))}',
                    style: t.label,
                  ),
              ],
            ],
          ),
          const SizedBox(height: DymTokenSpace.s3),
          Padding(
            padding: const EdgeInsets.only(right: DymTokenSpace.s3),
            child: DymButton(
              label: l10n.shoppingOpen,
              icon: Icons.auto_awesome_rounded,
              onPressed: onOpen,
            ),
          ),
        ],
      ),
    );
  }
}

class _DescribeSheet extends StatefulWidget {
  const new();

  @override
  State<_DescribeSheet> createState() => _DescribeSheetState();
}

class _DescribeSheetState extends State<_DescribeSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    if (_text.text.trim().length >= 2) Navigator.of(context).pop(_text.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DymTextField(
            label: l10n.shoppingDescribe,
            hint: l10n.shoppingDescribeHint,
            controller: _text,
            autofocus: true,
            maxLength: 300,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: DymTokenSpace.s3),
          DymButton(
            label: l10n.shoppingDescribeAction,
            icon: Icons.auto_awesome_rounded,
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ édition

/// Édition d'une liste : nom libre, articles et quantités, rappel.
class ShoppingEditView extends StackedView<ShoppingEditViewModel> {
  const new({
    required this.service,
    required this.draft,
    required this.onBack,
    required this.onSaved,
    super.key,
    this.today,
  });

  final ShoppingService service;
  final ShoppingDraft draft;
  final VoidCallback onBack;
  final ValueChanged<ShoppingList> onSaved;

  /// Date du jour (tests).
  final DateTime? today;

  @override
  ShoppingEditViewModel viewModelBuilder(BuildContext context) =>
      ShoppingEditViewModel(service: service, draft: draft, today: today);

  @override
  Widget builder(
    BuildContext context,
    ShoppingEditViewModel vm,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final first = vm.firstReminder;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(title: l10n.shoppingEditTitle, onBack: onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  DymContentWidth.form(child: _NameField(vm: vm)),
                  const SizedBox(height: DymTokenSpace.s4),
                  DymContentWidth.form(
                    child: DymSectionHeader(
                      title:
                          '${l10n.shoppingItemsTitle} · '
                          '${l10n.shoppingItemsCount(vm.items.length)}',
                    ),
                  ),
                  for (final (i, item) in vm.items.indexed)
                    DymContentWidth.form(
                      child: _ItemRow(vm: vm, index: i, item: item),
                    ),
                  if (vm.canAdd) DymContentWidth.form(child: _AddItem(vm: vm)),
                  const SizedBox(height: DymTokenSpace.s4),
                  DymContentWidth.form(
                    child: DymSectionHeader(title: l10n.shoppingRepeatTitle),
                  ),
                  DymContentWidth.form(
                    child: Wrap(
                      spacing: DymTokenSpace.s2,
                      runSpacing: DymTokenSpace.s2,
                      children: [
                        for (final p in [null, ...ShoppingPeriod.values])
                          ChoiceChip(
                            label: Text(shoppingPeriodLabel(l10n, p)),
                            selected: vm.period == p,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            onSelected: (_) => vm.setPeriod(p),
                          ),
                      ],
                    ),
                  ),
                  if (first != null) ...[
                    const SizedBox(height: DymTokenSpace.s2),
                    DymContentWidth.form(
                      child: Row(
                        children: [
                          Icon(Icons.event_rounded, color: c.brandDeep),
                          const SizedBox(width: DymTokenSpace.s2),
                          Expanded(
                            child: Text(
                              l10n.shoppingStartsOn(_date(context, first)),
                              style: t.body,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: first,
                                firstDate: vm.today,
                                lastDate: vm.today.add(
                                  const Duration(days: 60),
                                ),
                              );
                              if (picked != null) vm.setStartsOn(picked);
                            },
                            child: Text(l10n.shoppingPickDate),
                          ),
                        ],
                      ),
                    ),
                    DymContentWidth.form(
                      child: Text(
                        l10n.shoppingRepeatNote,
                        style: t.label.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ],
                  if (vm.problem case final e?) ...[
                    const SizedBox(height: DymTokenSpace.s3),
                    DymContentWidth.form(
                      child: CartIssue(label: shoppingErrorLabel(l10n, e)),
                    ),
                  ],
                  const SizedBox(height: DymTokenSpace.s4),
                  DymContentWidth.form(
                    child: DymButton(
                      label: l10n.shoppingSave,
                      icon: Icons.check_rounded,
                      loading: vm.saving,
                      onPressed: vm.saving
                          ? null
                          : () async {
                              if (await vm.save() case final saved?) {
                                onSaved(saved);
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameField extends StatefulWidget {
  const new({required this.vm});

  final ShoppingEditViewModel vm;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final _text = TextEditingController(text: widget.vm.name);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return DymTextField(
      label: l10n.shoppingName,
      hint: l10n.shoppingNameHint,
      controller: _text,
      maxLength: ShoppingList.maxNameLength,
      textCapitalization: TextCapitalization.sentences,
      onChanged: widget.vm.setName,
    );
  }
}

class _ItemRow extends StatelessWidget {
  const new({required this.vm, required this.index, required this.item});

  final ShoppingEditViewModel vm;
  final int index;
  final ShoppingItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DymTokenSpace.s1),
      child: Row(
        children: [
          Expanded(child: Text(item.label, style: t.body)),
          DymQuantityStepper(
            quantity: item.quantity,
            min: ShoppingItem.minQuantity,
            max: ShoppingItem.maxQuantity,
            dense: true,
            decreaseLabel: l10n.shoppingLess(item.label),
            increaseLabel: l10n.shoppingMoreQty(item.label),
            onChanged: (q) => vm.setQuantity(index, q),
          ),
          IconButton(
            tooltip: l10n.shoppingRemoveItem(item.label),
            onPressed: () => vm.remove(index),
            icon: Icon(Icons.close_rounded, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AddItem extends StatefulWidget {
  const new({required this.vm});

  final ShoppingEditViewModel vm;

  @override
  State<_AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<_AddItem> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _add() {
    widget.vm.add(_text.text);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DymTextField(
            label: l10n.shoppingItemHint,
            controller: _text,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
          ),
        ),
        const SizedBox(width: DymTokenSpace.s2),
        Padding(
          padding: const EdgeInsets.only(top: DymTokenSpace.s1),
          child: DymButton(
            label: l10n.shoppingAddItem,
            icon: Icons.add_rounded,
            expanded: false,
            compact: true,
            onPressed: _add,
          ),
        ),
      ],
    );
  }
}
