import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_texts.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_admin/features/stores/stores_viewmodel.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Écran 55 : boutiques, profil et actions de l'équipe.
class AdminStoresView extends StackedView<AdminStoresViewModel> {
  const new({required this.service, super.key});

  final AdminService service;

  @override
  AdminStoresViewModel viewModelBuilder(BuildContext context) =>
      AdminStoresViewModel(service: service);

  @override
  void onViewModelReady(AdminStoresViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    AdminStoresViewModel viewModel,
    Widget? child,
  ) {
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final page = vm.page;
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DymTextField(
          label: l10n.adminStoreSearch,
          icon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
          onSubmitted: vm.search,
        ),
        const SizedBox(height: DymTokenSpace.s2),
        Wrap(
          spacing: DymTokenSpace.s2,
          runSpacing: DymTokenSpace.s2,
          children: [
            for (final s in const [
              AdminStoreStatus.active,
              AdminStoreStatus.draft,
              AdminStoreStatus.suspended,
            ])
              DymFilterChip(
                label: switch (s) {
                  AdminStoreStatus.active => l10n.adminStoresActive,
                  AdminStoreStatus.draft => l10n.adminStoresDraft,
                  _ => l10n.adminStoresSuspended,
                }(page?.count(s) ?? 0),
                selected: vm.status == s,
                onTap: () => vm.selectStatus(s),
              ),
          ],
        ),
        const SizedBox(height: DymTokenSpace.s2),
        Expanded(
          child: !vm.ready || page == null
              ? AdminState(
                  failure: vm.isBusy ? null : vm.failure,
                  onRetry: vm.load,
                )
              : ListView(
                  children: [
                    if (page.stores.isEmpty) AdminEmpty(l10n.adminNoStores),
                    for (final s in page.stores)
                      _StoreTile(
                        row: s,
                        selected: s.id == vm.selectedId,
                        onTap: () => vm.select(s.id),
                      ),
                  ],
                ),
        ),
      ],
    );
    final selected = vm.selectedId;
    return AdminPage(
      title: l10n.navStores,
      scrollable: false,
      child: AdminSplit(
        list: list,
        detail: selected == null
            ? null
            : (vm.store == null
                  ? AdminState(
                      failure: vm.loadingStore ? null : vm.actionFailure,
                      onRetry: () => vm.select(selected),
                    )
                  : _Profile(vm: vm)),
        onCloseDetail: vm.close,
      ),
    );
  }
}

class _StoreTile extends StatelessWidget {
  const new({required this.row, required this.selected, required this.onTap});

  final AdminStoreRow row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final origin =
        row.originLabel?.resolve(
          Localizations.localeOf(context).languageCode,
        ) ??
        '';
    return Material(
      color: selected ? c.tintVertTendre : c.card,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(
            horizontal: DymTokenSpace.s3,
            vertical: DymTokenSpace.s2,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.background)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: c.tintPlantainClair,
                child: Text(
                  row.name.characters.first,
                  style: t.title.copyWith(color: c.brandDeep),
                ),
              ),
              const SizedBox(width: DymTokenSpace.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.name, style: t.title.copyWith(fontSize: 16)),
                    Text(
                      row.ownerFirstName ?? '',
                      style: t.label.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              if (origin.isNotEmpty)
                Flexible(child: AdminPill(origin, tone: AdminTone.warning)),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _Profile extends StatelessWidget {
  const new({required this.vm});

  final AdminStoresViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final s = vm.store!;
    final row = s.row;
    final suspended = row.status == AdminStoreStatus.suspended;
    Widget stat(
      IconData icon,
      String label,
      String value, {
      bool alert = false,
    }) => Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: alert ? c.tintPimentClair : c.tintVertTendre,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: alert ? c.pimentStrong : c.brandDeep),
          const SizedBox(width: DymTokenSpace.s2),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.label),
                Text(
                  value,
                  style: t.title.copyWith(
                    fontSize: 22,
                    color: alert ? c.pimentStrong : c.brandDeep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    Future<void> toggle() async {
      final reason = await showReasonDialog(
        context,
        title: suspended ? l10n.adminReactivateStore : l10n.adminSuspendStore,
        confirmLabel: suspended
            ? l10n.adminReactivateStore
            : l10n.adminSuspendStore,
        destructive: !suspended,
      );
      if (reason != null) await vm.setSuspended(reason, suspended: !suspended);
    }

    Future<void> remove() async {
      final reason = await showReasonDialog(
        context,
        title: l10n.adminDeleteVendor,
        confirmLabel: l10n.adminDeleteVendor,
        destructive: true,
      );
      if (reason != null) await vm.deleteVendor(reason);
    }

    Future<void> asVendor() => showDialog<void>(
      context: context,
      builder: (_) => _VendorViewDialog(vm: vm),
    );

    Future<void> edit() async {
      unawaitedZones();
      await showDialog<void>(
        context: context,
        builder: (_) => _EditDialog(vm: vm),
      );
    }

    return SingleChildScrollView(
      child: AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: DymTokenSpace.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(row.name, style: t.display.copyWith(fontSize: 28)),
                AdminPill(
                  switch (row.status) {
                    AdminStoreStatus.active => l10n.adminStoreActive,
                    AdminStoreStatus.draft => l10n.adminStoreDraft,
                    _ => l10n.adminStoreSuspended,
                  },
                  tone: switch (row.status) {
                    AdminStoreStatus.active => AdminTone.success,
                    AdminStoreStatus.suspended => AdminTone.danger,
                    _ => AdminTone.neutral,
                  },
                ),
              ],
            ),
            const SizedBox(height: DymTokenSpace.s1),
            AdminField(l10n.adminActorVendor, row.ownerFirstName ?? ''),
            AdminField(
              l10n.adminAddress,
              [?row.zoneName, ?row.cityName].join(', '),
            ),
            if (row.publishedAt case final at?)
              AdminField(
                l10n.adminOpenedOn,
                MaterialLocalizations.of(context)
                    .formatMediumDate(at.toLocal()),
              ),
            const Divider(height: DymTokenSpace.s5),
            Wrap(
              spacing: DymTokenSpace.s2,
              runSpacing: DymTokenSpace.s2,
              children: [
                stat(
                  Icons.shopping_cart_rounded,
                  l10n.adminOrders7d,
                  '${s.orders7d}',
                ),
                stat(
                  Icons.payments_rounded,
                  l10n.adminSales7d,
                  vm.money(s.sales7dMinor, s.currencyCode),
                ),
                stat(
                  Icons.inventory_2_rounded,
                  l10n.adminPublishedProducts,
                  '${s.publishedProducts}',
                ),
                stat(
                  Icons.warning_amber_rounded,
                  l10n.adminOpenDisputesCount,
                  '${s.openDisputes}',
                  alert: s.openDisputes > 0,
                ),
              ],
            ),
            const SizedBox(height: DymTokenSpace.s3),
            Text(l10n.adminTeamHistory, style: t.title.copyWith(fontSize: 18)),
            if (s.audit.isEmpty) AdminEmpty(l10n.adminNoHistory),
            for (final e in s.audit)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.history_rounded, color: c.textSecondary),
                title: Text(
                  [
                    MaterialLocalizations.of(context)
                        .formatShortMonthDay(e.occurredAt.toLocal()),
                    auditActionLabel(l10n, e.action),
                    ?e.reason,
                  ].join(' · '),
                ),
                subtitle: e.actorFirstName == null
                    ? null
                    : Text(e.actorFirstName!),
              ),
            if (vm.actionFailure case final failure?)
              AdminAlert(adminFailureLabel(l10n, failure)),
            const SizedBox(height: DymTokenSpace.s2),
            Wrap(
              spacing: DymTokenSpace.s2,
              runSpacing: DymTokenSpace.s2,
              children: [
                DymButton(
                  label: l10n.adminViewAsVendor,
                  icon: Icons.visibility_rounded,
                  variant: DymButtonVariant.secondary,
                  expanded: false,
                  onPressed: asVendor,
                ),
                DymButton(
                  label: l10n.adminEditStore,
                  icon: Icons.edit_rounded,
                  variant: DymButtonVariant.secondary,
                  expanded: false,
                  onPressed: vm.acting ? null : edit,
                ),
                DymButton(
                  label: suspended
                      ? l10n.adminReactivateStore
                      : l10n.adminSuspendStore,
                  icon: suspended
                      ? Icons.play_arrow_rounded
                      : Icons.block_rounded,
                  variant: suspended
                      ? DymButtonVariant.primary
                      : DymButtonVariant.destructive,
                  expanded: false,
                  loading: vm.acting,
                  onPressed: vm.acting ? null : toggle,
                ),
              ],
            ),
            if (row.publishedAt == null)
              Padding(
                padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DymButton(
                    label: l10n.adminDeleteVendor,
                    icon: Icons.delete_forever_rounded,
                    variant: DymButtonVariant.destructive,
                    expanded: false,
                    onPressed: vm.acting ? null : remove,
                  ),
                ),
              ),
            if (!suspended)
              Padding(
                padding: const EdgeInsets.only(top: DymTokenSpace.s1),
                child: Text(
                  l10n.adminSuspendHelp,
                  style: t.label.copyWith(color: c.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void unawaitedZones() {
    // Les quartiers arrivent pendant que le dialogue s'ouvre.
    // ignore: discarded_futures
    vm.loadZones();
  }
}

/// Ce que voit la vendeuse (A-VEN-06) : produits, prix, stock et dernières
/// commandes, en lecture seule.
class _VendorViewDialog extends StatefulWidget {
  const new({required this.vm});

  final AdminStoresViewModel vm;

  @override
  State<_VendorViewDialog> createState() => _VendorViewDialogState();
}

class _VendorViewDialogState extends State<_VendorViewDialog> {
  late Future<Result<AdminVendorView>> _view = widget.vm.vendorView();

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = widget.vm;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: FutureBuilder(
          future: _view,
          builder: (context, snapshot) {
            final result = snapshot.data;
            final Widget content;
            switch (result) {
              case null:
                content = AdminState(failure: null, onRetry: () {});
              case Err(:final failure):
                content = AdminState(
                  failure: failure,
                  onRetry: () => setState(() => _view = vm.vendorView()),
                );
              case Ok(:final value):
                final v = value;
                content = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      v.store.row.name,
                      style: t.display.copyWith(fontSize: 24),
                    ),
                    Text(
                      [
                        if (v.rating case final r?)
                          l10n.reviewAverage(r.toStringAsFixed(1)),
                        l10n.reviewCount(v.reviewCount),
                      ].join(' · '),
                      style: t.body.copyWith(color: c.textSecondary),
                    ),
                    const Divider(height: DymTokenSpace.s4),
                    Text(
                      l10n.navProducts,
                      style: t.title.copyWith(fontSize: 18),
                    ),
                    if (v.products.isEmpty) AdminEmpty(l10n.adminNoData),
                    for (final p in v.products)
                      AdminField(
                        p.name,
                        [
                          if ((p.priceMinor, v.store.currencyCode) case (
                            final m?,
                            final code?,
                          ))
                            vm.money(m, code),
                          if (!p.isAvailable) l10n.adminOutOfStock,
                          if (p.stock case final n?) l10n.adminStock(n),
                        ].join(' · '),
                      ),
                    const SizedBox(height: DymTokenSpace.s3),
                    Text(
                      l10n.adminLastOrders,
                      style: t.title.copyWith(fontSize: 18),
                    ),
                    if (v.recentOrders.isEmpty) AdminEmpty(l10n.adminNoOrders),
                    for (final o in v.recentOrders)
                      AdminField(
                        o.reference,
                        '${orderStatusLabel(l10n, o.status)} · '
                        '${vm.money(o.totalMinor, o.currencyCode)}',
                      ),
                    const SizedBox(height: DymTokenSpace.s2),
                    Text(
                      l10n.adminReadOnlyAudited,
                      style: t.label.copyWith(color: c.textSecondary),
                    ),
                  ],
                );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(DymTokenSpace.s4),
                    child: content,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(DymTokenSpace.s3),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: DymButton(
                      label: l10n.adminClose,
                      variant: DymButtonVariant.secondary,
                      expanded: false,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  const new({required this.vm});

  final AdminStoresViewModel vm;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final AdminStore _s = widget.vm.store!;
  late final _name = TextEditingController(text: _s.row.name);
  late final _description = TextEditingController(text: _s.description);
  late final _prep = TextEditingController(text: '${_s.prepTimeMinutes}');
  final _reason = TextEditingController();
  late String? _zone = _s.zoneId;
  late bool _pickup = _s.offersPickup;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _prep.dispose();
    _reason.dispose();
    super.dispose();
  }

  Map<String, Object?> get _patch => {
    if (_name.text.trim() != _s.row.name) 'name': _name.text.trim(),
    if (_description.text.trim() != (_s.description ?? ''))
      'description': _description.text.trim(),
    if (_zone != _s.zoneId) 'zone_id': _zone,
    if (int.tryParse(_prep.text.trim()) case final p?
        when p != _s.prepTimeMinutes)
      'prep_time_minutes': p,
    if (_pickup != _s.offersPickup) 'offers_pickup': _pickup,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.vm,
        _name,
        _description,
        _prep,
        _reason,
      ]),
      builder: (context, _) {
        final zones = widget.vm.zones;
        return AlertDialog(
          backgroundColor: context.dym.colors.card,
          title: Text(l10n.adminEditStore),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DymTextField(label: l10n.adminStoreName, controller: _name),
                  const SizedBox(height: DymTokenSpace.s2),
                  DymTextField(
                    label: l10n.adminStoreDescription,
                    controller: _description,
                    maxLines: 3,
                    maxLength: 280,
                  ),
                  if (zones.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: zones.any((z) => z.id == _zone)
                          ? _zone
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.adminEntityZone,
                      ),
                      items: [
                        for (final z in zones)
                          DropdownMenuItem(value: z.id, child: Text(z.name)),
                      ],
                      onChanged: (v) => setState(() => _zone = v),
                    ),
                  const SizedBox(height: DymTokenSpace.s2),
                  DymTextField(
                    label: l10n.adminPrepMinutes,
                    controller: _prep,
                    keyboardType: TextInputType.number,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _pickup,
                    title: Text(l10n.adminOffersPickup),
                    onChanged: (v) => setState(() => _pickup = v),
                  ),
                  DymTextField(
                    label: l10n.adminReasonLabel,
                    controller: _reason,
                    maxLength: 200,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            DymButton(
              label: l10n.adminSave,
              expanded: false,
              loading: widget.vm.acting,
              onPressed:
                  _patch.isEmpty ||
                      _reason.text.trim().length < 3 ||
                      widget.vm.acting
                  ? null
                  : () async {
                      final ok = await widget.vm.update(
                        _patch,
                        _reason.text.trim(),
                      );
                      if (ok && context.mounted) Navigator.pop(context);
                    },
            ),
          ],
        );
      },
    );
  }
}
