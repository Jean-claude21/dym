import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_texts.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Support (écran 69) : demandes, réponse de l'équipe, clôture ; délai de
/// première réponse visé : une heure.
class AdminSupportViewModel extends AdminViewModel {
  new({required this.service, this.selectedId});

  final AdminService service;

  TicketStatus status = TicketStatus.open;
  List<SupportTicket>? tickets;
  String? selectedId;
  bool acting = false;
  Failure? actionFailure;

  bool get ready => tickets != null && !failed;
  SupportTicket? get selected =>
      tickets?.where((t) => t.id == selectedId).firstOrNull;

  Future<void> load() => run(service.currencies, () async {
    final result = await service.tickets(status);
    if (result case Ok(:final value)) tickets = value;
    return result.failureOrNull;
  });

  Future<void> selectStatus(TicketStatus value) async {
    status = value;
    selectedId = null;
    await load();
  }

  void select(String? id) {
    selectedId = id;
    actionFailure = null;
    notifyListeners();
  }

  Future<bool> reply(String body) =>
      _act((id) => service.replyTicket(id, body.trim()), keep: true);

  Future<bool> close() => _act(service.closeTicket, keep: false);

  /// Brouillon de l'agent support ; nul en cas d'échec (message affiché).
  Future<String?> draft() async {
    final id = selectedId;
    if (id == null || acting) return null;
    acting = true;
    actionFailure = null;
    notifyListeners();
    final result = await service.draftReply(id);
    acting = false;
    actionFailure = result.failureOrNull;
    notifyListeners();
    return result.valueOrNull;
  }

  Future<bool> _act(
    Future<Result<SupportTicket>> Function(String id) gesture, {
    required bool keep,
  }) async {
    final id = selectedId;
    if (id == null || acting) return false;
    acting = true;
    actionFailure = null;
    notifyListeners();
    final result = await gesture(id);
    switch (result) {
      case Ok(:final value):
        tickets = [
          for (final t in tickets ?? const <SupportTicket>[])
            if (t.id == id) value else t,
        ];
        if (!keep || value.status != status) {
          tickets = [
            for (final t in tickets ?? const <SupportTicket>[])
              if (t.id != id) t,
          ];
          selectedId = null;
        }
      case Err(:final failure):
        actionFailure = failure;
    }
    acting = false;
    notifyListeners();
    return result.isOk;
  }
}

class AdminSupportView extends StackedView<AdminSupportViewModel> {
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
  AdminSupportViewModel viewModelBuilder(BuildContext context) =>
      AdminSupportViewModel(service: service, selectedId: initialId);

  @override
  void onViewModelReady(AdminSupportViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    AdminSupportViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final now = clock();
    final tickets = vm.tickets;
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: DymTokenSpace.s2,
          runSpacing: DymTokenSpace.s2,
          children: [
            for (final (s, label) in [
              (TicketStatus.open, l10n.adminTicketsOpen),
              (TicketStatus.pending, l10n.adminTicketsPending),
              (TicketStatus.closed, l10n.adminTicketsClosed),
            ])
              DymFilterChip(
                label: label,
                selected: vm.status == s,
                onTap: () => vm.selectStatus(s),
              ),
          ],
        ),
        const SizedBox(height: DymTokenSpace.s2),
        Expanded(
          child: !vm.ready || tickets == null
              ? AdminState(
                  failure: vm.isBusy ? null : vm.failure,
                  onRetry: vm.load,
                )
              : ListView(
                  children: [
                    if (tickets.isEmpty) AdminEmpty(l10n.adminNoTickets),
                    for (final tk in tickets)
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Material(
                          color: tk.id == vm.selectedId
                              ? c.tintVertTendre
                              : Colors.transparent,
                          shape: Border(bottom: BorderSide(color: c.hairline)),
                          child: ListTile(
                            minTileHeight: 64,
                            onTap: () => vm.select(tk.id),
                            title: Text(
                              tk.messages.isEmpty ? '' : tk.messages.first.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.title.copyWith(fontSize: 15),
                            ),
                            subtitle: Text(
                              [
                                _who(l10n, tk),
                                agoLabel(l10n, tk.createdAt, now),
                              ].join(' · '),
                            ),
                            trailing:
                                tk.firstResponseAt == null &&
                                    tk.status != TicketStatus.closed &&
                                    now.difference(tk.createdAt) >
                                        const Duration(hours: 1)
                                ? AdminPill(
                                    l10n.adminOver1h,
                                    tone: AdminTone.danger,
                                  )
                                : null,
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
      title: l10n.adminNavSupport,
      scrollable: false,
      child: AdminSplit(
        list: list,
        detail: selected == null
            ? null
            : _Detail(vm: vm, ticket: selected, now: now),
        onCloseDetail: () => vm.select(null),
      ),
    );
  }
}

String _who(DymLocalizations l10n, SupportTicket t) => t.app == 'vendor'
    ? l10n.adminAuthorVendor(t.storeName ?? t.userFirstName ?? '')
    : l10n.adminAuthorClient(t.userFirstName ?? '');

class _Detail extends StatefulWidget {
  const new({required this.vm, required this.ticket, required this.now});

  final AdminSupportViewModel vm;
  final SupportTicket ticket;
  final DateTime now;

  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = widget.vm;
    final tk = widget.ticket;
    return SingleChildScrollView(
      child: AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tk.messages.isEmpty ? '' : tk.messages.first.body,
              style: t.display.copyWith(fontSize: 24),
            ),
            Text(
              [
                _who(l10n, tk),
                subjectLabel(l10n, tk.subject),
                if (tk.orderReference case final r?) l10n.adminOrderTitle(r),
                agoLabel(l10n, tk.createdAt, widget.now),
              ].join(' · '),
              style: t.body.copyWith(color: c.textSecondary),
            ),
            const Divider(height: DymTokenSpace.s5),
            for (final m in tk.messages)
              Align(
                alignment: m.authorRole == 'team'
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  margin: const EdgeInsets.only(bottom: DymTokenSpace.s2),
                  padding: const EdgeInsets.all(DymTokenSpace.s2),
                  decoration: BoxDecoration(
                    color: m.authorRole == 'team'
                        ? c.tintVertTendre
                        : c.background,
                    borderRadius: BorderRadius.circular(DymTokenRadius.chip),
                  ),
                  child: Text(m.body, style: t.body),
                ),
              ),
            if (vm.actionFailure case final failure?)
              AdminAlert(adminFailureLabel(l10n, failure)),
            if (tk.status != TicketStatus.closed) ...[
              DymTextField(
                label: l10n.adminWriteReply,
                controller: _text,
                minLines: 2,
                maxLines: 5,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: DymTokenSpace.s2),
              Wrap(
                spacing: DymTokenSpace.s2,
                runSpacing: DymTokenSpace.s2,
                children: [
                  ListenableBuilder(
                    listenable: _text,
                    builder: (context, _) => DymButton(
                      label: l10n.disputeReply,
                      icon: Icons.send_rounded,
                      expanded: false,
                      loading: vm.acting,
                      onPressed: vm.acting || _text.text.trim().isEmpty
                          ? null
                          : () async {
                              if (await vm.reply(_text.text)) _text.clear();
                            },
                    ),
                  ),
                  DymButton(
                    label: l10n.adminSupportDraft,
                    icon: Icons.auto_awesome_rounded,
                    variant: DymButtonVariant.secondary,
                    expanded: false,
                    onPressed: vm.acting
                        ? null
                        : () async {
                            final draft = await vm.draft();
                            if (draft != null) _text.text = draft;
                          },
                  ),
                  DymButton(
                    label: l10n.adminCloseTicket,
                    icon: Icons.check_circle_outline_rounded,
                    variant: DymButtonVariant.secondary,
                    expanded: false,
                    onPressed: vm.acting ? null : vm.close,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
