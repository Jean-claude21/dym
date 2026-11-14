import 'package:dym_admin/features/ops/admin_metric.dart';
import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_texts.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_admin/features/stores/stores_viewmodel.dart';
import 'package:dym_admin/ui/admin_theme.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Écran 55 : boutiques en tableau, fiche à droite (spec 091).
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
    final t = context.dym.text;
    final vm = viewModel;
    final page = vm.page;
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    int count(AdminStoreStatus s) => page?.count(s) ?? 0;
    final total =
        count(AdminStoreStatus.active) +
        count(AdminStoreStatus.draft) +
        count(AdminStoreStatus.suspended);
    final search = SizedBox(
      width: wide ? 300 : double.infinity,
      child: TextField(
        textInputAction: TextInputAction.search,
        onSubmitted: vm.search,
        style: t.body,
        decoration: InputDecoration(
          isDense: true,
          hintText: l10n.adminStoreSearch,
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AdminPalette.lineStrong),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AdminPalette.lineStrong),
          ),
        ),
      ),
    );
    final tabs = AdminSegmented(
      options: [
        for (final s in const [
          AdminStoreStatus.active,
          AdminStoreStatus.draft,
          AdminStoreStatus.suspended,
        ])
          (
            s,
            switch (s) {
              AdminStoreStatus.active => l10n.adminStoresActive,
              AdminStoreStatus.draft => l10n.adminStoresDraft,
              _ => l10n.adminStoresSuspended,
            }(count(s)),
          ),
      ],
      selected: vm.status,
      onSelect: vm.selectStatus,
    );
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerLeft, child: tabs),
        const SizedBox(height: 14),
        if (wide) const _HeaderRow(),
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
                      _StoreRow(
                        row: s,
                        wide: wide,
                        selected: s.id == vm.selectedId,
                        onTap: () => vm.select(s.id),
                      ),
                  ],
                ),
        ),
      ],
    );
    final selected = vm.selectedId;
    final detail = selected == null
        ? null
        : (vm.store == null
              ? AdminState(
                  failure: vm.loadingStore ? null : vm.actionFailure,
                  onRetry: () => vm.select(selected),
                )
              : _Profile(vm: vm));
    return AdminPage(
      title: l10n.navStores,
      subtitle: page == null
          ? null
          : l10n.adminStoresSubtitle(
              total,
              '${count(AdminStoreStatus.active)}',
              '${count(AdminStoreStatus.draft)}',
            ),
      actions: [search],
      scrollable: false,
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: list),
                if (detail != null) ...[
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 380,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AdminPalette.line),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              tooltip: l10n.adminClose,
                              onPressed: vm.close,
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: AdminPalette.ink3,
                              ),
                            ),
                          ),
                          Expanded(child: detail),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            )
          : AdminSplit(list: list, detail: detail, onCloseDetail: vm.close),
    );
  }
}

/// Teinte d'avatar stable pour une boutique.
AdminHue _hueOf(String name) {
  const hues = [
    AdminPalette.green,
    AdminPalette.blue,
    AdminPalette.teal,
    AdminPalette.orange,
    AdminPalette.rose,
    AdminPalette.amber,
  ];
  return hues[name.codeUnits.fold(0, (a, b) => a + b) % hues.length];
}

class _Avatar extends StatelessWidget {
  const new({required this.name, this.size = 32});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hue = _hueOf(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hue.$1,
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: Text(
        name.characters.first.toUpperCase(),
        style: context.dym.text.title.copyWith(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final style = context.dym.text.label.copyWith(
      fontSize: 12,
      color: AdminPalette.ink3,
      fontWeight: FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(l10n.adminColStore, style: style)),
          Expanded(flex: 2, child: Text(l10n.adminColType, style: style)),
          Expanded(flex: 2, child: Text(l10n.adminColStatus, style: style)),
          Expanded(flex: 2, child: Text(l10n.adminActorVendor, style: style)),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  const new({
    required this.row,
    required this.wide,
    required this.selected,
    required this.onTap,
  });

  final AdminStoreRow row;
  final bool wide;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final origin =
        row.originLabel?.resolve(
          Localizations.localeOf(context).languageCode,
        ) ??
        '';
    final place = [?row.zoneName, ?row.cityName].join(' · ');
    final status = AdminPill(
      _statusLabel(l10n, row.status),
      tone: _statusTone(row.status),
    );
    final name = Row(
      children: [
        _Avatar(name: row.name),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                row.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.label.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              if (place.isNotEmpty || !wide)
                Text(
                  wide
                      ? place
                      : [
                          if (origin.isNotEmpty) origin,
                          ?row.ownerFirstName,
                        ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.label.copyWith(
                    fontSize: 12,
                    color: AdminPalette.ink3,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    return Material(
      color: selected ? const Color(0xFFF3F8F5) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              top: const BorderSide(color: AdminPalette.line),
              left: BorderSide(
                color: selected ? c.brand : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              if (wide) ...[
                Expanded(flex: 5, child: name),
                Expanded(
                  flex: 2,
                  child: Text(
                    origin,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.label,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(alignment: Alignment.centerLeft, child: status),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    row.ownerFirstName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.label,
                  ),
                ),
              ] else ...[
                Expanded(child: name),
                status,
              ],
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AdminPalette.ink3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _statusLabel(DymLocalizations l10n, AdminStoreStatus status) =>
    switch (status) {
      AdminStoreStatus.active => l10n.adminStoreActive,
      AdminStoreStatus.draft => l10n.adminStoreDraft,
      _ => l10n.adminStoreSuspended,
    };

AdminTone _statusTone(AdminStoreStatus status) => switch (status) {
  AdminStoreStatus.active => AdminTone.success,
  AdminStoreStatus.suspended => AdminTone.danger,
  _ => AdminTone.warning,
};

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
    final origin =
        row.originLabel?.resolve(
          Localizations.localeOf(context).languageCode,
        ) ??
        '';
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

    final stats = [
      (l10n.adminOrders7d, '${s.orders7d}', false),
      (l10n.adminSales7d, vm.money(s.sales7dMinor, s.currencyCode), false),
      (l10n.adminPublishedProducts, '${s.publishedProducts}', false),
      (l10n.adminOpenDisputesCount, '${s.openDisputes}', s.openDisputes > 0),
    ];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AdminPalette.line),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _Avatar(name: row.name, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              if (origin.isNotEmpty) origin,
                              [?row.zoneName, ?row.cityName].join(', '),
                            ].where((x) => x.isNotEmpty).join(' · '),
                            style: t.label.copyWith(
                              fontSize: 12,
                              color: AdminPalette.ink3,
                            ),
                          ),
                          Text(
                            row.name,
                            style: t.display.copyWith(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AdminPill(
                      _statusLabel(l10n, row.status),
                      tone: _statusTone(row.status),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AdminPalette.line),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              children: [
                for (final pair in [stats.sublist(0, 2), stats.sublist(2)])
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, (label, value, alert)) in pair.indexed)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: i == 0
                                      ? BorderSide.none
                                      : const BorderSide(
                                          color: AdminPalette.line,
                                        ),
                                  top: pair == stats.sublist(0, 2)
                                      ? BorderSide.none
                                      : const BorderSide(
                                          color: AdminPalette.line,
                                        ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: t.label.copyWith(
                                      fontSize: 12,
                                      color: AdminPalette.ink3,
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      value,
                                      style: t.display.copyWith(
                                        fontSize: 18,
                                        color: alert
                                            ? AdminPalette.rose.$1
                                            : c.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.adminTeamHistory, style: t.title),
          const SizedBox(height: 6),
          if (s.audit.isEmpty) AdminEmpty(l10n.adminNoHistory),
          for (final e in s.audit)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: AdminPalette.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: AdminPalette.ink3,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      [
                        MaterialLocalizations.of(context)
                            .formatShortMonthDay(e.occurredAt.toLocal()),
                        auditActionLabel(l10n, e.action),
                        ?e.reason,
                        ?e.actorFirstName,
                      ].join(' · '),
                      style: t.label,
                    ),
                  ),
                ],
              ),
            ),
          if (vm.actionFailure case final failure?)
            AdminAlert(adminFailureLabel(l10n, failure)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DymButton(
                label: l10n.adminViewAsVendor,
                icon: Icons.visibility_rounded,
                variant: DymButtonVariant.secondary,
                expanded: false,
                compact: true,
                onPressed: asVendor,
              ),
              DymButton(
                label: l10n.adminEditStore,
                icon: Icons.edit_rounded,
                variant: DymButtonVariant.secondary,
                expanded: false,
                compact: true,
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
                compact: true,
                loading: vm.acting,
                onPressed: vm.acting ? null : toggle,
              ),
              if (row.publishedAt == null)
                DymButton(
                  label: l10n.adminDeleteVendor,
                  icon: Icons.delete_forever_rounded,
                  variant: DymButtonVariant.destructive,
                  expanded: false,
                  compact: true,
                  onPressed: vm.acting ? null : remove,
                ),
            ],
          ),
          if (!suspended)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.adminSuspendHelp,
                style: t.label.copyWith(fontSize: 12, color: AdminPalette.ink3),
              ),
            ),
        ],
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
                  const SizedBox(height: DymTokenSpace.s4),
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
                  const SizedBox(height: DymTokenSpace.s4),
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
                  const SizedBox(height: DymTokenSpace.s4),
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
            const SizedBox(height: DymTokenSpace.s3),
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
