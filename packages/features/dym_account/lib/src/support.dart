import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Commande proposée dans une demande (référence et boutique ou cliente).
typedef SupportOrderChoice = ({String id, String label});

/// Demandes d'aide de l'utilisatrice (spec 016). Remplaçable en test.
abstract interface class SupportService {
  /// `client` ou `vendor`.
  String get app;

  Future<Result<List<SupportTicket>>> tickets();

  Future<Result<SupportTicket>> open({
    required TicketSubject subject,
    required String body,
    String? orderId,
  });

  Future<Result<SupportTicket>> reply(String ticketId, String body);

  /// Commandes récentes proposées (liste vide : aucune).
  Future<List<SupportOrderChoice>> recentOrders();
}

class NeonSupportService implements SupportService {
  new({
    required this._repository,
    required this.app,
    required this._recentOrders,
  });

  final SupportRepository _repository;
  final Future<List<SupportOrderChoice>> Function() _recentOrders;

  @override
  final String app;

  @override
  Future<Result<List<SupportTicket>>> tickets() => _repository.myTickets(app);

  @override
  Future<Result<SupportTicket>> open({
    required TicketSubject subject,
    required String body,
    String? orderId,
  }) => _repository.open(
    app: app,
    subject: subject,
    body: body,
    orderId: orderId,
  );

  @override
  Future<Result<SupportTicket>> reply(String ticketId, String body) =>
      _repository.reply(ticketId, body);

  @override
  Future<List<SupportOrderChoice>> recentOrders() => _recentOrders();
}

/// Demandes en mémoire (tests, galerie). Jamais en production.
class MemorySupportService implements SupportService {
  new({
    this.app = 'client',
    List<SupportTicket> tickets = const [],
    this.orders = const [],
    DateTime? now,
  }) : _tickets = [...tickets],
       _now = now ?? DateTime.utc(2026, 10, 5, 11);

  @override
  final String app;
  final List<SupportOrderChoice> orders;
  final List<SupportTicket> _tickets;
  final DateTime _now;
  Failure? failNext;

  Result<T>? _fail<T>() {
    final f = failNext;
    if (f == null) return null;
    failNext = null;
    return Err(f);
  }

  @override
  Future<Result<List<SupportTicket>>> tickets() async =>
      _fail<List<SupportTicket>>() ?? Ok(List.of(_tickets));

  @override
  Future<Result<SupportTicket>> open({
    required TicketSubject subject,
    required String body,
    String? orderId,
  }) async {
    final failed = _fail<SupportTicket>();
    if (failed != null) return failed;
    final t = SupportTicket(
      id: 't${_tickets.length + 1}',
      app: app,
      subject: subject,
      status: TicketStatus.open,
      orderId: orderId,
      createdAt: _now,
      lastActivityAt: _now,
      messages: [
        TicketMessage(
          id: 'm0',
          authorRole: 'user',
          body: body,
          createdAt: _now,
        ),
      ],
    );
    _tickets.insert(0, t);
    return Ok(t);
  }

  @override
  Future<Result<SupportTicket>> reply(String ticketId, String body) async {
    final failed = _fail<SupportTicket>();
    if (failed != null) return failed;
    final i = _tickets.indexWhere((t) => t.id == ticketId);
    final t = _tickets[i];
    return Ok(
      _tickets[i] = SupportTicket(
        id: t.id,
        app: t.app,
        subject: t.subject,
        status: TicketStatus.open,
        orderId: t.orderId,
        orderReference: t.orderReference,
        createdAt: t.createdAt,
        lastActivityAt: _now,
        messages: [
          ...t.messages,
          TicketMessage(
            id: 'm${t.messages.length}',
            authorRole: 'user',
            body: body,
            createdAt: _now,
          ),
        ],
      ),
    );
  }

  @override
  Future<List<SupportOrderChoice>> recentOrders() async => orders;
}

String ticketSubjectLabel(DymLocalizations l10n, TicketSubject s) =>
    switch (s) {
      TicketSubject.order => l10n.supportSubjectOrder,
      TicketSubject.payment => l10n.supportSubjectPayment,
      TicketSubject.account => l10n.supportSubjectAccount,
      TicketSubject.store => l10n.supportSubjectStore,
      _ => l10n.supportSubjectOther,
    };

/// Aide (écran 66) : nouvelle demande et suivi des demandes.
class SupportViewModel extends BaseViewModel {
  new({required this.service});

  final SupportService service;

  List<SupportTicket>? tickets;
  List<SupportOrderChoice> orders = const [];
  Failure? failure;
  Failure? sendFailure;
  TicketSubject subject = TicketSubject.order;
  String? orderId;
  String body = '';
  bool sending = false;
  bool sent = false;

  List<TicketSubject> get subjects => [
    TicketSubject.order,
    TicketSubject.payment,
    TicketSubject.account,
    if (service.app == 'vendor') TicketSubject.store,
    TicketSubject.other,
  ];

  bool get canSend => body.trim().length >= 3 && !sending;

  Future<void> load() async {
    failure = null;
    setBusy(true);
    orders = await service.recentOrders();
    switch (await service.tickets()) {
      case Ok(:final value):
        tickets = value;
      case Err(failure: final f):
        failure = f;
    }
    setBusy(false);
  }

  void setSubject(TicketSubject? value) {
    subject = value ?? subject;
    notifyListeners();
  }

  void setOrder(String? value) {
    orderId = value;
    notifyListeners();
  }

  void setBody(String value) {
    body = value;
    sent = false;
    notifyListeners();
  }

  /// `true` si envoyée (le formulaire peut être vidé).
  Future<bool> send() async {
    if (!canSend) return false;
    sending = true;
    sendFailure = null;
    notifyListeners();
    final result = await service.open(
      subject: subject,
      body: body.trim(),
      orderId: orderId,
    );
    sending = false;
    switch (result) {
      case Ok(:final value):
        tickets = [value, ...?tickets];
        body = '';
        orderId = null;
        sent = true;
      case Err(failure: final f):
        sendFailure = f;
    }
    notifyListeners();
    return result.isOk;
  }

  Future<bool> reply(String ticketId, String text) async {
    if (text.trim().isEmpty) return false;
    final result = await service.reply(ticketId, text.trim());
    if (result case Ok(:final value)) {
      tickets = [
        for (final t in tickets ?? const <SupportTicket>[])
          if (t.id == ticketId) value else t,
      ];
      notifyListeners();
    }
    return result.isOk;
  }
}

class SupportView extends StackedView<SupportViewModel> {
  const new({
    required this.service,
    required this.onBack,
    super.key,
    this.clock = DateTime.now,
  });

  final SupportService service;
  final VoidCallback onBack;
  final DateTime Function() clock;

  @override
  SupportViewModel viewModelBuilder(BuildContext context) =>
      SupportViewModel(service: service);

  @override
  void onViewModelReady(SupportViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    SupportViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final now = clock();
    final tickets = vm.tickets;
    final form = Container(
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.supportNew, style: t.title.copyWith(fontSize: 22)),
          const SizedBox(height: DymTokenSpace.s2),
          DropdownButtonFormField<TicketSubject>(
            initialValue: vm.subject,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.supportSubject),
            items: [
              for (final s in vm.subjects)
                DropdownMenuItem(
                  value: s,
                  child: Text(ticketSubjectLabel(l10n, s)),
                ),
            ],
            onChanged: vm.setSubject,
          ),
          if (vm.orders.isNotEmpty) ...[
            const SizedBox(height: DymTokenSpace.s2),
            DropdownButtonFormField<String?>(
              initialValue: vm.orderId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.supportOrder),
              items: [
                DropdownMenuItem<String?>(child: Text(l10n.supportNoOrder)),
                for (final o in vm.orders)
                  DropdownMenuItem(
                    value: o.id,
                    child: Text(o.label, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: vm.setOrder,
            ),
          ],
          const SizedBox(height: DymTokenSpace.s2),
          _BodyField(vm: vm),
          if (vm.sendFailure != null)
            Text(
              vm.sendFailure is NetworkFailure
                  ? l10n.errorOffline
                  : l10n.errorGeneric,
              style: t.label.copyWith(color: c.pimentStrong),
            ),
          if (vm.sent)
            Text(l10n.supportSent, style: t.label.copyWith(color: c.brandDeep)),
          const SizedBox(height: DymTokenSpace.s2),
          DymButton(
            label: l10n.supportSend,
            icon: Icons.send_rounded,
            loading: vm.sending,
            onPressed: vm.canSend ? vm.send : null,
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(DymLayout.gutter(context)),
          children: [
            for (final w in <Widget>[
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.authBack,
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      l10n.accountHelp,
                      style: t.display.copyWith(fontSize: 32),
                    ),
                  ),
                ],
              ),
              Text(
                l10n.supportPromise,
                style: t.body.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: DymTokenSpace.s3),
              form,
              const SizedBox(height: DymTokenSpace.s4),
              Text(l10n.supportMine, style: t.title.copyWith(fontSize: 22)),
              const SizedBox(height: DymTokenSpace.s2),
              if (tickets == null && vm.failure == null)
                Center(child: CircularProgressIndicator(color: c.brand))
              else if (tickets == null)
                DymStateView(
                  kind: vm.failure is NetworkFailure
                      ? DymStateKind.offline
                      : DymStateKind.error,
                  title: vm.failure is NetworkFailure
                      ? l10n.errorOffline
                      : l10n.errorGeneric,
                  message: '',
                  actionLabel: l10n.retry,
                  onAction: vm.load,
                )
              else if (tickets.isEmpty)
                Text(
                  l10n.supportNone,
                  style: t.body.copyWith(color: c.textSecondary),
                )
              else
                for (final ticket in tickets)
                  _TicketTile(vm: vm, ticket: ticket, now: now),
            ])
              DymContentWidth.form(child: w),
          ],
        ),
      ),
    );
  }
}

class _BodyField extends StatefulWidget {
  const new({required this.vm});

  final SupportViewModel vm;

  @override
  State<_BodyField> createState() => _BodyFieldState();
}

class _BodyFieldState extends State<_BodyField> {
  final _text = TextEditingController();

  @override
  void didUpdateWidget(covariant _BodyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vm.body.isEmpty && _text.text.isNotEmpty) _text.clear();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DymTextField(
    label: DymLocalizations.of(context).supportDescribe,
    controller: _text,
    minLines: 3,
    maxLines: 6,
    maxLength: 2000,
    textCapitalization: TextCapitalization.sentences,
    onChanged: widget.vm.setBody,
  );
}

class _TicketTile extends StatelessWidget {
  const new({required this.vm, required this.ticket, required this.now});

  final SupportViewModel vm;
  final SupportTicket ticket;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final closed = ticket.status == TicketStatus.closed;
    final first = ticket.messages.isEmpty ? '' : ticket.messages.first.body;
    final minutes = now.difference(ticket.lastActivityAt).inMinutes;
    return Padding(
      padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          side: BorderSide(color: c.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          shape: const Border(),
          title: Text(
            first,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.title.copyWith(fontSize: 16),
          ),
          subtitle: Text(
            [
              ticketSubjectLabel(l10n, ticket.subject),
              if (minutes < 60)
                l10n.timeMinutesAgo(minutes.clamp(1, 59))
              else
                MaterialLocalizations.of(context)
                    .formatShortMonthDay(ticket.lastActivityAt.toLocal()),
            ].join(' · '),
            style: t.label.copyWith(color: c.textSecondary),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DymTokenSpace.s2,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: closed ? c.background : c.tintVertTendre,
              borderRadius: BorderRadius.circular(DymTokenRadius.chip),
            ),
            child: Text(
              closed ? l10n.supportClosed : l10n.supportInProgress,
              style: t.label.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            for (final m in ticket.messages)
              Align(
                alignment: m.authorRole == 'team'
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: DymTokenSpace.s1),
                  padding: const EdgeInsets.all(DymTokenSpace.s2),
                  decoration: BoxDecoration(
                    color: m.authorRole == 'team'
                        ? c.tintPlantainClair
                        : c.tintVertTendre,
                    borderRadius: BorderRadius.circular(DymTokenRadius.chip),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (m.authorRole == 'team')
                        Text(
                          l10n.disputeTeam,
                          style: t.label.copyWith(fontWeight: FontWeight.w700),
                        ),
                      Text(m.body, style: t.body),
                    ],
                  ),
                ),
              ),
            _ReplyRow(vm: vm, ticketId: ticket.id),
          ],
        ),
      ),
    );
  }
}

class _ReplyRow extends StatefulWidget {
  const new({required this.vm, required this.ticketId});

  final SupportViewModel vm;
  final String ticketId;

  @override
  State<_ReplyRow> createState() => _ReplyRowState();
}

class _ReplyRowState extends State<_ReplyRow> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: DymTextField(
            label: l10n.chatWriteHint,
            controller: _text,
            maxLength: 2000,
          ),
        ),
        IconButton.filled(
          tooltip: l10n.chatSend,
          style: IconButton.styleFrom(
            backgroundColor: c.brand,
            minimumSize: const Size(48, 48),
          ),
          onPressed: () async {
            if (await widget.vm.reply(widget.ticketId, _text.text)) {
              _text.clear();
            }
          },
          icon: Icon(Icons.send_rounded, color: c.onBrand),
        ),
      ],
    );
  }
}
