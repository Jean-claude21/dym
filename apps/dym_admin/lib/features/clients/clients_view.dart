import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_texts.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Clientes (écran 68) : recherche et profil en lecture (consultation auditée).
class AdminClientsViewModel extends AdminViewModel {
  new({required this.service});

  final AdminService service;

  List<AdminClientRow>? rows;
  String query = '';
  String? selectedId;
  AdminClient? client;
  bool loadingClient = false;
  Failure? clientFailure;

  bool get ready => rows != null && !failed;

  Future<void> load() => run(service.currencies, () async {
    final result = await service.clients(query: query.isEmpty ? null : query);
    if (result case Ok(:final value)) rows = value;
    return result.failureOrNull;
  });

  Future<void> search(String value) async {
    query = value.trim();
    await load();
  }

  Future<void> select(String id) async {
    selectedId = id;
    client = null;
    clientFailure = null;
    loadingClient = true;
    notifyListeners();
    final result = await service.client(id);
    if (selectedId != id) return;
    loadingClient = false;
    switch (result) {
      case Ok(:final value):
        client = value;
      case Err(:final failure):
        clientFailure = failure;
    }
    notifyListeners();
  }

  void close() {
    selectedId = null;
    client = null;
    notifyListeners();
  }
}

class AdminClientsView extends StackedView<AdminClientsViewModel> {
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
  AdminClientsViewModel viewModelBuilder(BuildContext context) =>
      AdminClientsViewModel(service: service);

  @override
  Future<void> onViewModelReady(AdminClientsViewModel viewModel) async {
    await viewModel.load();
    if (initialId case final id?) await viewModel.select(id);
  }

  @override
  Widget builder(
    BuildContext context,
    AdminClientsViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final rows = vm.rows;
    final dates = MaterialLocalizations.of(context);
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DymTextField(
          label: l10n.adminClientSearch,
          icon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
          onSubmitted: vm.search,
        ),
        const SizedBox(height: DymTokenSpace.s2),
        Expanded(
          child: !vm.ready || rows == null
              ? AdminState(
                  failure: vm.isBusy ? null : vm.failure,
                  onRetry: vm.load,
                )
              : ListView(
                  children: [
                    if (rows.isEmpty) AdminEmpty(l10n.adminNoClients),
                    for (final r in rows)
                      Material(
                        color: r.id == vm.selectedId
                            ? c.tintVertTendre
                            : c.card,
                        child: ListTile(
                          minTileHeight: 56,
                          leading: CircleAvatar(
                            backgroundColor: c.tintPlantainClair,
                            child: Text(
                              r.firstName.characters.first,
                              style: t.title.copyWith(color: c.brandDeep),
                            ),
                          ),
                          title: Text(r.firstName),
                          subtitle: Text(
                            [
                              l10n.adminOrdersCount(r.orders),
                              l10n.adminSince(
                                dates.formatShortMonthDay(
                                  r.createdAt.toLocal(),
                                ),
                              ),
                            ].join(' · '),
                          ),
                          onTap: () => vm.select(r.id),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
    final selected = vm.selectedId;
    return AdminPage(
      title: l10n.adminNavClients,
      scrollable: false,
      child: AdminSplit(
        list: list,
        detail: selected == null
            ? null
            : (vm.client == null
                  ? AdminState(
                      failure: vm.loadingClient ? null : vm.clientFailure,
                      onRetry: () => vm.select(selected),
                    )
                  : _Profile(vm: vm, client: vm.client!, now: clock())),
        onCloseDetail: vm.close,
      ),
    );
  }
}

class _Profile extends StatelessWidget {
  const new({required this.vm, required this.client, required this.now});

  final AdminClientsViewModel vm;
  final AdminClient client;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final cl = client;
    Widget stat(String label, String value) => Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: c.tintVertTendre,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: t.label),
          Text(
            value,
            style: t.title.copyWith(fontSize: 20, color: c.brandDeep),
          ),
        ],
      ),
    );
    return SingleChildScrollView(
      child: AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(cl.firstName, style: t.display.copyWith(fontSize: 28)),
            if (cl.email case final email?)
              SelectableText(email, style: t.body),
            Text(
              [?cl.zoneName, ?cl.cityName].join(', '),
              style: t.body.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            Wrap(
              spacing: DymTokenSpace.s2,
              runSpacing: DymTokenSpace.s2,
              children: [
                stat(l10n.navOrders, '${cl.orderCount}'),
                stat(
                  l10n.adminSpent,
                  cl.spent.isEmpty
                      ? '—'
                      : [
                          for (final s in cl.spent)
                            vm.money(s.minor, s.currencyCode),
                        ].join(' · '),
                ),
                stat(l10n.adminNavDisputes, '${cl.disputeCount}'),
                stat(l10n.adminTickets, '${cl.ticketCount}'),
              ],
            ),
            const Divider(height: DymTokenSpace.s5),
            Text(l10n.adminLastOrders, style: t.title.copyWith(fontSize: 18)),
            if (cl.orders.isEmpty) AdminEmpty(l10n.adminNoOrders),
            for (final o in cl.orders)
              AdminField(
                '${o.reference} · ${o.storeName}',
                '${orderStatusLabel(l10n, o.status)} · '
                    '${vm.money(o.totalMinor, o.currencyCode)}',
              ),
            const SizedBox(height: DymTokenSpace.s3),
            Text(l10n.adminAddresses, style: t.title.copyWith(fontSize: 18)),
            for (final a in cl.addresses)
              AdminField(a.label ?? a.zoneName, a.landmark),
            const SizedBox(height: DymTokenSpace.s3),
            Text(l10n.adminReviewsLeft, style: t.title.copyWith(fontSize: 18)),
            if (cl.reviews.isEmpty) AdminEmpty(l10n.reviewNone),
            for (final r in cl.reviews)
              AdminField(
                '${r.storeName} · ${l10n.reviewAverage('${r.rating}')}',
                r.comment ?? '',
              ),
            const SizedBox(height: DymTokenSpace.s3),
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
