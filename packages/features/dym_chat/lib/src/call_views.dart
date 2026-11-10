import 'dart:async';

import 'package:dym_chat/src/call_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Appel en cours (spec 035) : sonnerie, décroché, fin. L'état vient de la
/// base (sondage court) ; le média passe par le fournisseur.
class CallViewModel extends BaseViewModel {
  new({
    required this.service,
    this.conversationId,
    this.kind = CallKind.audio,
    CallSession? session,
    this.pollEvery = const Duration(seconds: 2),
  }) : call = session;

  final CallService service;
  final String? conversationId;
  final CallKind kind;
  final Duration pollEvery;
  CallSession? call;
  Failure? failure;
  bool joined = false;
  Timer? _timer;
  int elapsed = 0;

  bool get simulated => service.provider.simulated;
  bool get finished => call != null && !call!.active;

  Future<void> init() async {
    if (call == null) {
      switch (await service.start(conversationId!, kind)) {
        case Ok(:final value):
          call = value;
        case Err(failure: final f):
          failure = f;
          notifyListeners();
          return;
      }
    }
    notifyListeners();
    await _onState();
    _timer = Timer.periodic(pollEvery, (_) => unawaited(_tick()));
  }

  Future<void> _tick() async {
    final current = call;
    if (current == null) return;
    if (current.status == CallStatus.ongoing) elapsed++;
    if (await service.state(current.id) case Ok(:final value)) {
      call = value;
      await _onState();
    }
    notifyListeners();
  }

  Future<void> _onState() async {
    final current = call;
    if (current == null) return;
    if (current.status == CallStatus.ongoing && !joined) {
      joined = true;
      await service.provider.join(
        current.id,
        video: current.kind == CallKind.video,
      );
    }
    if (!current.active) {
      _timer?.cancel();
      if (joined) await service.provider.leave();
    }
  }

  Future<void> answer({required bool accept}) async {
    final current = call;
    if (current == null) return;
    if (await service.answer(current.id, accept: accept) case Ok(
      :final value,
    )) {
      call = value;
      await _onState();
    }
    notifyListeners();
  }

  Future<void> hangUp() async {
    final current = call;
    if (current == null) return;
    if (await service.end(current.id) case Ok(:final value)) call = value;
    await _onState();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (joined) unawaited(service.provider.leave());
    super.dispose();
  }
}

String callStatusLabel(DymLocalizations l10n, CallSession call) =>
    switch (call.status) {
      CallStatus.ringing =>
        call.outgoing ? l10n.callRinging : l10n.callIncoming,
      CallStatus.ongoing => l10n.callOngoing,
      CallStatus.declined => l10n.callDeclined,
      CallStatus.missed => l10n.callMissed,
      CallStatus.ended || CallStatus.unknown => l10n.callEnded,
    };

class CallView extends StackedView<CallViewModel> {
  const new({
    required this.service,
    required this.onClose,
    required this.peerName,
    super.key,
    this.conversationId,
    this.kind = CallKind.audio,
    this.session,
  });

  final CallService service;
  final VoidCallback onClose;
  final String peerName;

  /// Appel sortant : conversation et type.
  final String? conversationId;
  final CallKind kind;

  /// Appel entrant déjà connu.
  final CallSession? session;

  @override
  CallViewModel viewModelBuilder(BuildContext context) => CallViewModel(
    service: service,
    conversationId: conversationId,
    kind: kind,
    session: session,
  );

  @override
  void onViewModelReady(CallViewModel viewModel) => unawaited(viewModel.init());

  @override
  Widget builder(BuildContext context, CallViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final call = vm.call;
    final video = (call?.kind ?? kind) == CallKind.video;
    final minutes = (vm.elapsed * 2 ~/ 60).toString().padLeft(2, '0');
    final seconds = (vm.elapsed * 2 % 60).toString().padLeft(2, '0');
    return Scaffold(
      backgroundColor: c.brandDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s4),
          child: Column(
            children: [
              if (vm.simulated)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(DymTokenSpace.s2),
                  decoration: BoxDecoration(
                    color: c.plantain,
                    borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                  ),
                  child: Text(
                    l10n.callSimulated,
                    textAlign: TextAlign.center,
                    style: t.label.copyWith(color: c.textPrimary),
                  ),
                ),
              const Spacer(),
              CircleAvatar(
                radius: 56,
                backgroundColor: c.tintVertTendre,
                child: Icon(
                  video ? Icons.videocam_rounded : Icons.call_rounded,
                  size: 48,
                  color: c.brandDeep,
                ),
              ),
              const SizedBox(height: DymTokenSpace.s3),
              Text(
                peerName,
                textAlign: TextAlign.center,
                style: t.display.copyWith(color: c.onBrand, fontSize: 28),
              ),
              const SizedBox(height: DymTokenSpace.s1),
              Semantics(
                liveRegion: true,
                child: Text(switch (call) {
                  null when vm.failure != null => l10n.callUnavailable,
                  null => l10n.callRinging,
                  final current when current.status == CallStatus.ongoing =>
                    '${l10n.callOngoing} · $minutes:$seconds',
                  final current => callStatusLabel(l10n, current),
                }, style: t.title.copyWith(color: c.onBrand)),
              ),
              const Spacer(),
              if (call != null &&
                  call.status == CallStatus.ringing &&
                  !call.outgoing)
                Row(
                  children: [
                    Expanded(
                      child: DymButton(
                        label: l10n.callDecline,
                        icon: Icons.call_end_rounded,
                        variant: DymButtonVariant.destructive,
                        onPressed: () => vm.answer(accept: false),
                      ),
                    ),
                    const SizedBox(width: DymTokenSpace.s3),
                    Expanded(
                      child: DymButton(
                        label: l10n.callAnswer,
                        icon: Icons.call_rounded,
                        onPressed: () => vm.answer(accept: true),
                      ),
                    ),
                  ],
                )
              else if (call == null || vm.finished)
                DymButton(
                  label: l10n.callClose,
                  icon: Icons.close_rounded,
                  variant: DymButtonVariant.secondary,
                  onPressed: onClose,
                )
              else
                DymButton(
                  label: l10n.callHangUp,
                  icon: Icons.call_end_rounded,
                  variant: DymButtonVariant.destructive,
                  onPressed: vm.hangUp,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Surveille les appels entrants (sondage) et propose de décrocher.
class IncomingCallWatcher extends StatefulWidget {
  const new({
    required this.service,
    required this.child,
    super.key,
    this.pollEvery = const Duration(seconds: 10),
    this.navigatorKey,
  });

  final CallService service;
  final Widget child;
  final Duration pollEvery;

  /// Navigateur de l'app, quand le surveillant est monté au-dessus de lui.
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<IncomingCallWatcher> createState() => _IncomingCallWatcherState();
}

class _IncomingCallWatcherState extends State<IncomingCallWatcher> {
  Timer? _timer;
  CallSession? _incoming;
  final _seen = <String>{};

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.pollEvery, (_) => unawaited(_check()));
  }

  Future<void> _check() async {
    if (await widget.service.incoming() case Ok(:final value)) {
      if (!mounted) return;
      setState(() {
        _incoming = value != null && !_seen.contains(value.id) ? value : null;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _open(CallSession call) async {
    _seen.add(call.id);
    setState(() => _incoming = null);
    final navigator =
        widget.navigatorKey?.currentState ?? Navigator.of(context);
    await navigator.push<void>(
      MaterialPageRoute(
        builder: (route) => CallView(
          service: widget.service,
          session: call,
          peerName: call.callerName ?? '',
          onClose: () => Navigator.of(route).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final call = _incoming;
    return Stack(
      children: [
        widget.child,
        if (call != null)
          Positioned(
            left: 12,
            right: 12,
            top: MediaQuery.paddingOf(context).top + 8,
            child: Material(
              color: c.brandDeep,
              elevation: 6,
              borderRadius: BorderRadius.circular(DymTokenRadius.tile),
              child: ListTile(
                minTileHeight: 64,
                leading: Icon(
                  call.kind == CallKind.video
                      ? Icons.videocam_rounded
                      : Icons.call_rounded,
                  color: c.onBrand,
                ),
                title: Text(
                  l10n.callIncomingFrom(call.callerName ?? ''),
                  style: t.title.copyWith(color: c.onBrand, fontSize: 17),
                ),
                trailing: FilledButton(
                  onPressed: () => _open(call),
                  child: Text(l10n.callOpen),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
