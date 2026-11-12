import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/credit/credit_service.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

String creditProblem(DymLocalizations l10n, String code) => switch (code) {
  'credit_limit' => l10n.creditLimitReached,
  'payment_too_high' => l10n.creditPaymentTooHigh,
  'invalid_phone' => l10n.courierInvalidPhone,
  'invalid_amount' || 'invalid_name' => l10n.walletErrorAmount,
  'already_reminded' => l10n.creditAlreadyReminded,
  'offline' => l10n.errorOffline,
  _ => l10n.errorGeneric,
};

/// Ardoise et une cliente (spec 047).
class CreditViewModel extends BaseViewModel {
  new({required this.service});

  final CreditService service;
  CountryConfig? config;
  StoreCredits? credits;
  StoreCredit? open;
  Failure? failure;
  String? problem;

  Future<void> load() async {
    failure = null;
    config ??= (await service.countryConfig()).valueOrNull;
    switch (await service.credits()) {
      case Ok(:final value):
        credits = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  String money(int minor) => config?.money(minor).format() ?? '';

  int? parse(String text) {
    final currency = config?.currency;
    if (currency == null || text.trim().isEmpty) return null;
    final minor = Money.parseMajor(text, currency);
    return minor == null || minor <= 0 ? null : minor;
  }

  String _code(Failure f) => f is NetworkFailure ? 'offline' : f.message;

  Future<void> select(StoreCredit credit) async {
    problem = null;
    switch (await service.detail(credit.id)) {
      case Ok(:final value):
        open = value;
      case Err(failure: final f):
        problem = _code(f);
    }
    notifyListeners();
  }

  void close() {
    open = null;
    notifyListeners();
    unawaited(load());
  }

  Future<bool> create(String name, String phone, String limitText) async {
    problem = null;
    final limit = limitText.trim().isEmpty ? null : parse(limitText);
    if (limitText.trim().isNotEmpty && limit == null) {
      problem = 'invalid_amount';
      notifyListeners();
      return false;
    }
    final result = await service.save(
      name: name.trim(),
      phone: phone.trim().isEmpty ? null : phone.trim(),
      limitMinor: limit,
    );
    switch (result) {
      case Ok(:final value):
        open = value;
      case Err(failure: final f):
        problem = _code(f);
    }
    notifyListeners();
    return result.isOk;
  }

  Future<bool> add({
    required bool debt,
    required String amountText,
    String? note,
  }) async {
    final credit = open;
    final amount = parse(amountText);
    if (credit == null || amount == null) {
      problem = 'invalid_amount';
      notifyListeners();
      return false;
    }
    problem = null;
    final result = await service.addEntry(
      credit,
      debt: debt,
      amountMinor: amount,
      note: note,
    );
    switch (result) {
      case Ok(:final value):
        open = value;
      case Err(failure: final f):
        problem = _code(f);
    }
    notifyListeners();
    return result.isOk;
  }

  Future<void> remind(String Function(StoreCredit reminded) message) async {
    final credit = open;
    if (credit == null) return;
    switch (await service.remind(credit, message)) {
      case Ok(:final value):
        open = value;
      case Err(failure: final f):
        problem = _code(f);
    }
    notifyListeners();
  }

  Future<void> archive() async {
    final credit = open;
    if (credit == null) return;
    switch (await service.archive(credit)) {
      case Ok(:final value):
        credits = value;
        open = null;
      case Err(failure: final f):
        problem = _code(f);
    }
    notifyListeners();
  }
}

class CreditView extends StackedView<CreditViewModel> {
  const new({required this.service, required this.onBack, super.key});

  final CreditService service;
  final VoidCallback onBack;

  @override
  CreditViewModel viewModelBuilder(BuildContext context) =>
      CreditViewModel(service: service);

  @override
  void onViewModelReady(CreditViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, CreditViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final open = vm.open;
    final credits = vm.credits;
    return PopScope(
      canPop: open == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) vm.close();
      },
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          title: Text(open?.customerName ?? l10n.creditTitle),
          leading: IconButton(
            tooltip: l10n.authBack,
            onPressed: open == null ? onBack : vm.close,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: SafeArea(
          child: credits == null
              ? Center(
                  child: vm.failure == null
                      ? const CircularProgressIndicator()
                      : DymStateView(
                          kind: vm.failure is NetworkFailure
                              ? DymStateKind.offline
                              : DymStateKind.error,
                          title: vm.failure is NetworkFailure
                              ? l10n.errorOffline
                              : l10n.errorGeneric,
                          message: l10n.creditLoadError,
                          actionLabel: l10n.retry,
                          onAction: vm.load,
                        ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    DymLayout.gutter(context),
                    DymTokenSpace.s2,
                    DymLayout.gutter(context),
                    96,
                  ),
                  children: [
                    if (open == null) ...[
                      // Total dû en grand, puis une ligne par cliente.
                      DymContentWidth(
                        child: Text(
                          l10n.creditOwedLabel,
                          style: t.body.copyWith(color: c.textSecondary),
                        ),
                      ),
                      DymContentWidth(
                        child: Text(
                          vm.money(credits.totalMinor),
                          style: t.display.copyWith(
                            fontSize: 40,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: DymTokenSpace.s3),
                      DymContentWidth(
                        child: DymButton(
                          label: l10n.creditNew,
                          icon: Icons.person_add_alt_1_outlined,
                          variant: DymButtonVariant.secondary,
                          onPressed: () => _sheet(context, _NewCredit(vm: vm)),
                        ),
                      ),
                      const SizedBox(height: DymTokenSpace.s3),
                      if (credits.credits.isEmpty)
                        DymStateView(
                          kind: DymStateKind.empty,
                          icon: Icons.menu_book_outlined,
                          title: l10n.creditNone,
                          message: l10n.creditNoneHint,
                        ),
                      for (final (i, cr) in credits.credits.indexed)
                        DymContentWidth(
                          child: Column(
                            children: [
                              if (i > 0) Divider(height: 1, color: c.hairline),
                              InkWell(
                                onTap: () => vm.select(cr),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 68,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: c.tintVertTendre,
                                        child: Text(
                                          cr.customerName.characters.first
                                              .toUpperCase(),
                                          style: t.body.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: c.brandDeep,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: DymTokenSpace.s3),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              cr.customerName,
                                              style: t.body,
                                            ),
                                            if (cr.limitMinor case final l?)
                                              Text(
                                                l10n.creditLimit(vm.money(l)),
                                                style: t.label.copyWith(
                                                  color: c.textSecondary,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        vm.money(cr.balanceMinor),
                                        style: t.body.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: cr.balanceMinor > 0
                                              ? c.pimentStrong
                                              : c.textSecondary,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: c.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ] else ...[
                      DymContentWidth(
                        child: Text(
                          l10n.creditOwes(vm.money(open.balanceMinor)),
                          style: t.display.copyWith(fontSize: 30),
                        ),
                      ),
                      const SizedBox(height: DymTokenSpace.s3),
                      DymContentWidth(
                        child: Row(
                          children: [
                            Expanded(
                              child: DymButton(
                                label: l10n.creditAddDebt,
                                icon: Icons.add_rounded,
                                onPressed: () =>
                                    _sheet(context, _Entry(vm: vm, debt: true)),
                              ),
                            ),
                            const SizedBox(width: DymTokenSpace.s3),
                            Expanded(
                              child: DymButton(
                                label: l10n.creditAddPayment,
                                icon: Icons.payments_rounded,
                                variant: DymButtonVariant.secondary,
                                onPressed: open.balanceMinor <= 0
                                    ? null
                                    : () => _sheet(
                                        context,
                                        _Entry(vm: vm, debt: false),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DymTokenSpace.s3),
                      DymContentWidth(
                        child: DymButton(
                          label: l10n.creditRemind,
                          icon: Icons.chat_outlined,
                          variant: DymButtonVariant.secondary,
                          onPressed: open.canRemind
                              ? () => vm.remind(
                                  (r) => l10n.creditReminderText(
                                    r.customerName,
                                    vm.money(r.balanceMinor),
                                    r.storeName ?? '',
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (open.balanceMinor == 0)
                        DymContentWidth(
                          child: TextButton(
                            onPressed: vm.archive,
                            child: Text(l10n.creditArchive),
                          ),
                        ),
                      if (vm.problem case final p?)
                        DymContentWidth(
                          child: Text(
                            creditProblem(l10n, p),
                            style: t.body.copyWith(color: c.pimentStrong),
                          ),
                        ),
                      const SizedBox(height: DymTokenSpace.s3),
                      for (final e in open.entries)
                        DymContentWidth(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              e.isDebt
                                  ? Icons.north_east_rounded
                                  : Icons.south_west_rounded,
                              color: e.isDebt ? c.pimentStrong : c.brand,
                            ),
                            title: Text(
                              e.isDebt ? l10n.creditDebt : l10n.creditPayment,
                            ),
                            subtitle: Text(
                              [
                                MaterialLocalizations.of(context)
                                    .formatShortDate(e.at.toLocal()),
                                ?e.note,
                              ].join(' · '),
                            ),
                            trailing: Text(vm.money(e.amountMinor)),
                          ),
                        ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

Future<void> _sheet(BuildContext context, Widget child) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => child,
    );

class _NewCredit extends StatefulWidget {
  const new({required this.vm});

  final CreditViewModel vm;

  @override
  State<_NewCredit> createState() => _NewCreditState();
}

class _NewCreditState extends State<_NewCredit> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _limit = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return _SheetBody(
      title: l10n.creditNew,
      fields: [
        DymTextField(
          label: l10n.creditName,
          controller: _name,
          autofocus: true,
        ),
        const SizedBox(height: DymTokenSpace.s4),
        DymTextField(
          label: l10n.courierPhone,
          controller: _phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: DymTokenSpace.s4),
        DymTextField(
          label: l10n.creditLimitField,
          controller: _limit,
          keyboardType: TextInputType.number,
        ),
      ],
      action: l10n.creditCreate,
      problem: widget.vm.problem == null
          ? null
          : creditProblem(l10n, widget.vm.problem!),
      onConfirm: () => widget.vm.create(_name.text, _phone.text, _limit.text),
    );
  }
}

class _Entry extends StatefulWidget {
  const new({required this.vm, required this.debt});

  final CreditViewModel vm;
  final bool debt;

  @override
  State<_Entry> createState() => _EntryState();
}

class _EntryState extends State<_Entry> {
  final _amount = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return _SheetBody(
      title: widget.debt ? l10n.creditAddDebt : l10n.creditAddPayment,
      fields: [
        DymTextField(
          label: l10n.tillAmount,
          controller: _amount,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        const SizedBox(height: DymTokenSpace.s4),
        DymTextField(label: l10n.creditNote, controller: _note),
      ],
      action: l10n.tillSave,
      problem: widget.vm.problem == null
          ? null
          : creditProblem(l10n, widget.vm.problem!),
      onConfirm: () => widget.vm.add(
        debt: widget.debt,
        amountText: _amount.text,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      ),
    );
  }
}

class _SheetBody extends StatefulWidget {
  const new({
    required this.title,
    required this.fields,
    required this.action,
    required this.onConfirm,
    this.problem,
  });

  final String title;
  final List<Widget> fields;
  final String action;
  final Future<bool> Function() onConfirm;
  final String? problem;

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  bool _busy = false;
  bool _failed = false;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        DymTokenSpace.s4,
        0,
        DymTokenSpace.s4,
        DymTokenSpace.s4 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: context.dym.text.title),
          for (final f in widget.fields) ...[
            const SizedBox(height: DymTokenSpace.s3),
            f,
          ],
          const SizedBox(height: DymTokenSpace.s3),
          DymButton(
            label: widget.action,
            loading: _busy,
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    final ok = await widget.onConfirm();
                    if (!context.mounted) return;
                    setState(() {
                      _busy = false;
                      _failed = !ok;
                    });
                    if (ok) Navigator.pop(context);
                  },
          ),
          if (_failed && widget.problem != null)
            Padding(
              padding: const EdgeInsets.only(top: DymTokenSpace.s2),
              child: Text(widget.problem!),
            ),
        ],
      ),
    ),
  );
}
