import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:dym_vendor/features/catalog/categories/store_categories_viewmodel.dart';
import 'package:dym_vendor/features/store/widgets/store_widgets.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Écran 27 : « Mes catégories ».
class StoreCategoriesView extends StackedView<StoreCategoriesViewModel> {
  const new({required this.service, required this.onBack, super.key});

  final CatalogService service;
  final VoidCallback onBack;

  @override
  StoreCategoriesViewModel viewModelBuilder(BuildContext context) =>
      StoreCategoriesViewModel(service: service);

  @override
  void onViewModelReady(StoreCategoriesViewModel viewModel) => viewModel.load();

  Future<void> _rename(
    BuildContext context,
    StoreCategoriesViewModel vm,
    StoreCategory category,
  ) async {
    final l10n = DymLocalizations.of(context);
    var name = category.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.categoriesRename),
        content: TextFormField(
          initialValue: category.name,
          autofocus: true,
          maxLength: StoreCategoriesViewModel.nameMax,
          onChanged: (value) => name = value,
          onFieldSubmitted: (_) => Navigator.pop(context, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.storeSave),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && name.trim().isNotEmpty) {
      await vm.rename(category, name);
    }
  }

  @override
  Widget builder(
    BuildContext context,
    StoreCategoriesViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final Widget body;
    if (!vm.ready) {
      body = vm.loadFailure == null
          ? Center(
              child: Semantics(
                label: l10n.startupPreparing,
                child: CircularProgressIndicator(color: c.brand),
              ),
            )
          : DymStateView(
              kind: vm.offline ? DymStateKind.offline : DymStateKind.error,
              title: vm.offline ? l10n.errorOffline : l10n.errorGeneric,
              message: l10n.errorLoadMessage,
              actionLabel: l10n.retry,
              onAction: vm.load,
            );
    } else {
      body = LayoutBuilder(
        builder: (context, box) {
          final inset = DymLayout.sideInset(
            box.maxWidth,
            gutter: DymLayout.gutter(context),
            maxWidth: DymTokenLayout.formMax,
          );
          return ListView(
            padding: EdgeInsets.fromLTRB(inset, 8, inset, 24),
            children: [
              Row(
                children: [
                  Material(
                    color: c.card,
                    shape: const CircleBorder(),
                    elevation: 0.5,
                    child: IconButton(
                      tooltip: l10n.authBack,
                      onPressed: onBack,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DymTokenSpace.s3),
              Semantics(
                header: true,
                child: Text(l10n.categoriesTitle, style: t.display),
              ),
              const SizedBox(height: DymTokenSpace.s1),
              Text(
                l10n.categoriesSubtitle,
                style: t.body.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: DymTokenSpace.s4),
              if (vm.active.isEmpty && vm.archived.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: DymTokenSpace.s4),
                  child: Text(
                    l10n.categoriesEmpty,
                    textAlign: TextAlign.center,
                    style: t.body.copyWith(color: c.textSecondary),
                  ),
                )
              else
                StoreSection(
                  children: [
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorderItem: vm.reorder,
                      children: [
                        for (final (i, category) in vm.active.indexed)
                          _CategoryRow(
                            key: ValueKey(category.id),
                            category: category,
                            handle: ReorderableDragStartListener(
                              index: i,
                              child: Semantics(
                                label: l10n.categoriesMove(category.name),
                                child: const SizedBox.square(
                                  dimension: 48,
                                  child: Icon(Icons.drag_indicator_rounded),
                                ),
                              ),
                            ),
                            trailing: IconButton(
                              tooltip: l10n.categoriesRename,
                              onPressed: () => _rename(context, vm, category),
                              icon: const Icon(Icons.edit_rounded),
                            ),
                            onArchive: () =>
                                vm.archive(category, archived: true),
                          ),
                      ],
                    ),
                    for (final category in vm.archived)
                      _CategoryRow(
                        key: ValueKey(category.id),
                        category: category,
                        handle: const SizedBox(width: 48),
                        trailing: TextButton(
                          onPressed: () =>
                              vm.archive(category, archived: false),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          child: Text(l10n.categoriesRestore),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: DymTokenSpace.s4),
              if (vm.duplicate)
                Padding(
                  padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
                  child: Row(
                    children: [
                      Icon(Icons.error_rounded, color: c.pimentStrong),
                      const SizedBox(width: DymTokenSpace.s2),
                      Expanded(
                        child: Text(
                          l10n.categoriesDuplicate,
                          style: t.label.copyWith(
                            color: c.pimentStrong,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                StoreErrorBanner(failure: vm.actionFailure),
              _NewCategory(viewModel: vm),
            ],
          );
        },
      );
    }
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(child: body),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const new({
    required this.category,
    required this.handle,
    required this.trailing,
    super.key,
    this.onArchive,
  });

  final StoreCategory category;
  final Widget handle;
  final Widget trailing;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final archived = category.isArchived;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Row(
        children: [
          IconTheme(
            data: IconThemeData(
              color: archived
                  ? c.textSecondary.withValues(alpha: 0.4)
                  : c.textSecondary,
            ),
            child: handle,
          ),
          const SizedBox(width: DymTokenSpace.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: t.title.copyWith(
                    fontSize: 19,
                    color: archived ? c.textSecondary : c.brandDeep,
                  ),
                ),
                Text(
                  archived
                      ? l10n.categoriesArchived
                      : l10n.categoriesProductCount(category.productCount),
                  style: t.body.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          trailing,
          if (onArchive != null)
            IconButton(
              tooltip: l10n.categoriesArchive,
              onPressed: onArchive,
              icon: Icon(Icons.archive_outlined, color: c.textSecondary),
            ),
        ],
      ),
    );
    return Material(color: Colors.transparent, child: row);
  }
}

class _NewCategory extends StatefulWidget {
  const new({required this.viewModel});

  final StoreCategoriesViewModel viewModel;

  @override
  State<_NewCategory> createState() => _NewCategoryState();
}

class _NewCategoryState extends State<_NewCategory> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (await widget.viewModel.add()) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final vm = widget.viewModel;
    final field = DymTextField(
      label: l10n.categoriesNewHint,
      hint: l10n.categoriesNewHint,
      controller: _controller,
      onChanged: vm.setNewName,
      onSubmitted: (_) => _add(),
      maxLength: StoreCategoriesViewModel.nameMax,
      textCapitalization: TextCapitalization.sentences,
    );
    final button = DymButton(
      label: l10n.categoriesAdd,
      icon: Icons.add_rounded,
      expanded: false,
      onPressed: vm.canAdd ? _add : null,
    );
    return LayoutBuilder(
      builder: (context, box) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        if (box.maxWidth / scale < 340) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field,
              const SizedBox(height: DymTokenSpace.s3),
              DymButton(
                label: l10n.categoriesAdd,
                icon: Icons.add_rounded,
                onPressed: vm.canAdd ? _add : null,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field),
            const SizedBox(width: DymTokenSpace.s3),
            button,
          ],
        );
      },
    );
  }
}
