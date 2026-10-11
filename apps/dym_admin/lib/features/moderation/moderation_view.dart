import 'dart:async';

import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_texts.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Modération (écran 76) : contenus, produits et avis signalés ; garder ou
/// retirer avec une raison, inscrite au journal.
class AdminModerationViewModel extends AdminViewModel {
  new({required this.service, this.selectedId});

  final AdminService service;

  bool decided = false;
  List<ModerationItem>? items;
  String? selectedId;
  bool acting = false;
  Failure? actionFailure;

  bool get ready => items != null && !failed;
  ModerationItem? get selected =>
      items?.where((i) => i.targetId == selectedId).firstOrNull;

  Future<void> load() => run(service.currencies, () async {
    final result = await service.reports(decided: decided);
    if (result case Ok(:final value)) items = value;
    return result.failureOrNull;
  });

  Future<void> selectDecided({required bool value}) async {
    decided = value;
    selectedId = null;
    await load();
  }

  void select(String? id) {
    selectedId = id;
    actionFailure = null;
    notifyListeners();
  }

  Future<bool> decide(
    ModerationItem item, {
    required bool remove,
    required String reason,
  }) async {
    if (acting) return false;
    acting = true;
    actionFailure = null;
    notifyListeners();
    final result = await service.moderate(
      item.target,
      item.targetId,
      remove: remove,
      reason: reason.trim(),
    );
    acting = false;
    if (result.isOk) {
      selectedId = null;
      await load();
    } else {
      actionFailure = result.failureOrNull;
      notifyListeners();
    }
    return result.isOk;
  }
}

class AdminModerationView extends StackedView<AdminModerationViewModel> {
  const new({
    required this.service,
    super.key,
    this.clock = DateTime.now,
    this.initialId,
  });

  final AdminService service;
  final DateTime Function() clock;
  final String? initialId;

  @override
  AdminModerationViewModel viewModelBuilder(BuildContext context) =>
      AdminModerationViewModel(service: service, selectedId: initialId);

  @override
  void onViewModelReady(AdminModerationViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(
    BuildContext context,
    AdminModerationViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final now = clock();
    final items = vm.items;
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: DymTokenSpace.s2,
          runSpacing: DymTokenSpace.s2,
          children: [
            DymFilterChip(
              label: !vm.decided && items != null
                  ? '${l10n.moderationOpen} · ${items.length}'
                  : l10n.moderationOpen,
              selected: !vm.decided,
              onTap: () => vm.selectDecided(value: false),
            ),
            DymFilterChip(
              label: l10n.moderationDecided,
              selected: vm.decided,
              onTap: () => vm.selectDecided(value: true),
            ),
          ],
        ),
        const SizedBox(height: DymTokenSpace.s2),
        Expanded(
          child: !vm.ready || items == null
              ? AdminState(
                  failure: vm.isBusy ? null : vm.failure,
                  onRetry: vm.load,
                )
              : ListView(
                  children: [
                    if (items.isEmpty) AdminEmpty(l10n.moderationEmpty),
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: DymTokenSpace.s2,
                        ),
                        child: Material(
                          color: item.targetId == vm.selectedId
                              ? c.tintPimentClair
                              : c.card,
                          borderRadius: BorderRadius.circular(
                            DymTokenRadius.tile,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            minTileHeight: 64,
                            onTap: () => vm.select(item.targetId),
                            leading: Icon(_icon(item), color: c.brandDeep),
                            title: Text(
                              [
                                _targetLabel(l10n, item),
                                ?item.storeName,
                              ].join(' · '),
                              style: t.title.copyWith(fontSize: 15),
                            ),
                            subtitle: Text(
                              [
                                for (final r in item.reasons)
                                  moderationReasonLabel(l10n, r),
                                agoLabel(l10n, item.firstAt, now),
                              ].join(' · '),
                            ),
                            trailing: vm.decided
                                ? AdminPill(
                                    item.status == 'removed'
                                        ? l10n.moderationRemoved
                                        : l10n.moderationKept,
                                    tone: item.status == 'removed'
                                        ? AdminTone.danger
                                        : AdminTone.success,
                                  )
                                : AdminPill(
                                    l10n.moderationReports(item.count),
                                    tone: item.count > 1
                                        ? AdminTone.danger
                                        : AdminTone.warning,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
    final selected = vm.selected;
    return AdminPage(
      title: l10n.adminNavModeration,
      scrollable: false,
      child: AdminSplit(
        list: list,
        detail: selected == null ? null : _Preview(vm: vm, item: selected),
        onCloseDetail: () => vm.select(null),
      ),
    );
  }
}

IconData _icon(ModerationItem item) => switch (item.target) {
  ReportTarget.content => Icons.play_circle_rounded,
  ReportTarget.product => Icons.inventory_2_rounded,
  ReportTarget.review => Icons.star_rounded,
};

String _targetLabel(DymLocalizations l10n, ModerationItem item) =>
    switch (item.target) {
      ReportTarget.content =>
        item.contentKind == ContentKind.story
            ? l10n.moderationStory
            : l10n.moderationVideo,
      ReportTarget.product => l10n.moderationProduct,
      ReportTarget.review => l10n.moderationReview,
    };

class _Preview extends StatefulWidget {
  const new({required this.vm, required this.item});

  final AdminModerationViewModel vm;
  final ModerationItem item;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = widget.vm;
    final item = widget.item;
    final open = item.status == 'open';
    return SingleChildScrollView(
      child: AdminCard(
        title: l10n.moderationPreview,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: c.brandDeep,
                borderRadius: BorderRadius.circular(DymTokenRadius.tile),
              ),
              alignment: Alignment.center,
              child: Icon(
                item.isVideo ? Icons.play_circle_fill_rounded : _icon(item),
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: DymTokenSpace.s2),
            AdminField(_targetLabel(l10n, item), item.storeName ?? ''),
            if (item.title.isNotEmpty)
              AdminField(l10n.moderationCaption, item.title),
            if (item.tags.isNotEmpty)
              AdminField(l10n.moderationTagged, item.tags.join(', ')),
            AdminField(
              l10n.moderationReason,
              [for (final r in item.reasons) moderationReasonLabel(l10n, r)]
                  .join(', '),
            ),
            for (final note in item.notes) AdminField('', note),
            if (item.decisionReason case final reason?)
              AdminField(l10n.moderationDecision, reason),
            if (vm.actionFailure case final f?)
              AdminAlert(adminFailureLabel(l10n, f)),
            if (open) ...[
              const SizedBox(height: DymTokenSpace.s2),
              DymTextField(
                label: l10n.moderationReasonRequired,
                controller: _reason,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: DymTokenSpace.s2),
              ListenableBuilder(
                listenable: _reason,
                builder: (context, _) {
                  final ready = !vm.acting && _reason.text.trim().isNotEmpty;
                  return Wrap(
                    spacing: DymTokenSpace.s2,
                    runSpacing: DymTokenSpace.s2,
                    children: [
                      DymButton(
                        label: l10n.moderationKeep,
                        icon: Icons.check_rounded,
                        variant: DymButtonVariant.secondary,
                        expanded: false,
                        onPressed: ready
                            ? () => vm.decide(
                                item,
                                remove: false,
                                reason: _reason.text,
                              )
                            : null,
                      ),
                      DymButton(
                        label: l10n.moderationRemove,
                        icon: Icons.block_rounded,
                        variant: DymButtonVariant.destructive,
                        expanded: false,
                        loading: vm.acting,
                        onPressed: ready
                            ? () => vm.decide(
                                item,
                                remove: true,
                                reason: _reason.text,
                              )
                            : null,
                      ),
                    ],
                  );
                },
              ),
            ],
            Text(
              l10n.adminReadOnlyAudited,
              style: t.label.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
