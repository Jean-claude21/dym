import 'dart:convert';

import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_texts.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Journal d'audit (écran 58) : recherche, filtres, avant et après.
class AdminAuditViewModel extends AdminViewModel {
  new({required this.service});

  final AdminService service;
  static const pageSize = 50;

  String _query = '';
  String? _action;
  String? _entityType;
  int _offset = 0;
  AdminAuditPage? _page;
  AdminAuditEntry? _selected;

  String? get action => _action;
  String? get entityType => _entityType;
  int get offset => _offset;
  AdminAuditPage? get page => _page;
  bool get ready => _page != null && !failed;
  AdminAuditEntry? get selected => _selected;
  bool get hasPrevious => _offset > 0;
  bool get hasNext => (_page?.total ?? 0) > _offset + pageSize;

  Future<void> load() => run(service.currencies, () async {
    final result = await service.audit(
      query: _query.isEmpty ? null : _query,
      action: _action,
      entityType: _entityType,
      offset: _offset,
    );
    if (result case Ok(:final value)) _page = value;
    return result.failureOrNull;
  });

  Future<void> search(String value) async {
    _query = value.trim();
    _offset = 0;
    await load();
  }

  Future<void> selectAction(String? value) async {
    _action = value;
    _offset = 0;
    await load();
  }

  Future<void> selectEntityType(String? value) async {
    _entityType = value;
    _offset = 0;
    await load();
  }

  Future<void> nextPage() async {
    if (!hasNext) return;
    _offset += pageSize;
    await load();
  }

  Future<void> previousPage() async {
    if (!hasPrevious) return;
    _offset = (_offset - pageSize).clamp(0, _offset);
    await load();
  }

  void open(AdminAuditEntry? entry) {
    _selected = entry;
    notifyListeners();
  }
}

/// Écran 58.
class AdminAuditView extends StackedView<AdminAuditViewModel> {
  const new({required this.service, super.key});

  final AdminService service;

  @override
  AdminAuditViewModel viewModelBuilder(BuildContext context) =>
      AdminAuditViewModel(service: service);

  @override
  void onViewModelReady(AdminAuditViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    AdminAuditViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final page = vm.page;
    final wide = DymWindowClass.of(context) >= DymWindowClass.expanded;
    final filters = Wrap(
      spacing: DymTokenSpace.s2,
      runSpacing: DymTokenSpace.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 340,
          child: DymTextField(
            label: l10n.adminAuditSearch,
            icon: Icons.search_rounded,
            textInputAction: TextInputAction.search,
            onSubmitted: vm.search,
          ),
        ),
        SizedBox(
          width: 260,
          child: DropdownButtonFormField<String?>(
            initialValue: vm.action,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.adminAuditAction),
            items: [
              DropdownMenuItem<String?>(child: Text(l10n.adminAll)),
              for (final a in page?.actions ?? const <String>[])
                DropdownMenuItem(
                  value: a,
                  child: Text(auditActionLabel(l10n, a)),
                ),
            ],
            onChanged: vm.selectAction,
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String?>(
            initialValue: vm.entityType,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.adminAuditEntity),
            items: [
              DropdownMenuItem<String?>(child: Text(l10n.adminAll)),
              for (final e in page?.entityTypes ?? const <String>[])
                DropdownMenuItem(
                  value: e,
                  child: Text(auditEntityLabel(l10n, e)),
                ),
            ],
            onChanged: vm.selectEntityType,
          ),
        ),
      ],
    );
    Widget entry(AdminAuditEntry e) {
      final cells = [
        (dateTimeLabel(context, e.occurredAt), 2),
        (e.actorFirstName ?? '', 2),
        (auditActionLabel(l10n, e.action), 3),
        ([auditEntityLabel(l10n, e.entityType), ?e.entityId].join(' '), 3),
        (e.reason ?? '—', 3),
      ];
      final selected = vm.selected == e;
      return Material(
        color: selected ? c.tintVertTendre : Colors.transparent,
        child: InkWell(
          onTap: () => vm.open(e),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: DymTokenSpace.s3,
              vertical: DymTokenSpace.s2,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.background)),
            ),
            child: wide
                ? Row(
                    children: [
                      for (final (text, flex) in cells)
                        Expanded(
                          flex: flex,
                          child: Text(text, style: t.body),
                        ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cells[2].$1} · ${cells[3].$1}',
                        style: t.title.copyWith(fontSize: 15),
                      ),
                      Text(
                        '${cells[0].$1} · ${cells[1].$1} · ${cells[4].$1}',
                        style: t.label.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    final table = !vm.ready || page == null
        ? AdminState(failure: vm.isBusy ? null : vm.failure, onRetry: vm.load)
        : AdminCard(
            padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (page.entries.isEmpty) AdminEmpty(l10n.adminNoAudit),
                for (final e in page.entries) entry(e),
                Row(
                  children: [
                    const SizedBox(width: DymTokenSpace.s3),
                    Expanded(
                      child: Text(
                        l10n.adminPageRange(
                          page.total == 0 ? 0 : vm.offset + 1,
                          vm.offset + page.entries.length,
                          page.total,
                        ),
                        style: t.label.copyWith(color: c.textSecondary),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.adminPrevious,
                      onPressed: vm.hasPrevious ? vm.previousPage : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    IconButton(
                      tooltip: l10n.adminNext,
                      onPressed: vm.hasNext ? vm.nextPage : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ],
            ),
          );
    final selected = vm.selected;
    return AdminPage(
      title: l10n.adminAuditTitle,
      subtitle: l10n.adminAuditSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filters,
          const SizedBox(height: DymTokenSpace.s3),
          if (selected != null)
            Padding(
              padding: const EdgeInsets.only(bottom: DymTokenSpace.s3),
              child: _BeforeAfter(
                entry: selected,
                onClose: () => vm.open(null),
              ),
            ),
          table,
        ],
      ),
    );
  }
}

class _BeforeAfter extends StatelessWidget {
  const new({required this.entry, required this.onClose});

  final AdminAuditEntry entry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    const encoder = JsonEncoder.withIndent('  ');
    Widget block(String title, Map<String, dynamic>? data) => Container(
      constraints: const BoxConstraints(minWidth: 260),
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: t.title.copyWith(fontSize: 18)),
          SelectableText(
            data == null ? '—' : encoder.convert(data),
            style: t.label.copyWith(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
    return AdminCard(
      title: l10n.adminBeforeAfter,
      trailing: IconButton(
        tooltip: l10n.adminClose,
        onPressed: onClose,
        icon: const Icon(Icons.close_rounded),
      ),
      child: Wrap(
        spacing: DymTokenSpace.s3,
        runSpacing: DymTokenSpace.s3,
        children: [
          block(l10n.adminBefore, entry.before),
          block(l10n.adminAfter, entry.after),
        ],
      ),
    );
  }
}
