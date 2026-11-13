import 'dart:async';

import 'package:dym_chat/src/call_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
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

  /// Média impossible à joindre (réseau) : l'appel reste ouvert, signalé.
  bool mediaFailed = false;
  Timer? _timer;
  int elapsed = 0;
  CallProvider? _media;

  /// Fournisseur de l'appel (choisi par la base), `null` avant sa création.
  CallProvider? get media =>
      _media ?? (call == null ? null : service.providerFor(call!));

  bool get simulated => media?.simulated ?? false;
  bool get finished => call != null && !call!.active;
  bool get microphoneOn => media?.microphoneOn ?? true;
  bool get speakerOn => media?.speakerOn ?? false;

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

  void _onMedia() => notifyListeners();

  Future<void> _onState() async {
    final current = call;
    if (current == null) return;
    if (current.status == CallStatus.ongoing && !joined) {
      joined = true;
      final provider = service.providerFor(current);
      _media = provider..changes.addListener(_onMedia);
      final result = await provider.join(
        current.id,
        video: current.kind == CallKind.video,
      );
      mediaFailed = result is Err;
    }
    if (!current.active) {
      _timer?.cancel();
      if (joined) await _media?.leave();
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

  Future<void> toggleMicrophone() async {
    await media?.setMicrophone(on: !microphoneOn);
  }

  Future<void> toggleSpeaker() async {
    await media?.setSpeaker(on: !speakerOn);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _media?.changes.removeListener(_onMedia);
    if (joined) unawaited(_media?.leave());
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
    final ongoing = call != null && call.status == CallStatus.ongoing;
    final remote = ongoing && video ? vm.media?.remoteVideo() : null;
    final local = ongoing && video ? vm.media?.localVideo() : null;
    return Scaffold(
      backgroundColor: c.brandDeep,
      body: Stack(
        children: [
          // Vidéo de l'autre personne en plein écran, la sienne en vignette.
          if (remote != null) Positioned.fill(child: remote),
          if (local != null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + DymTokenSpace.s4,
              right: DymTokenSpace.s4,
              width: 96,
              height: 128,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                child: local,
              ),
            ),
          SafeArea(
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
                        borderRadius: BorderRadius.circular(
                          DymTokenRadius.tile,
                        ),
                      ),
                      child: Text(
                        l10n.callSimulated,
                        textAlign: TextAlign.center,
                        style: t.label.copyWith(color: c.textPrimary),
                      ),
                    ),
                  const Spacer(),
                  if (remote == null) ...[
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
                  ],
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
                  if (vm.mediaFailed) ...[
                    const SizedBox(height: DymTokenSpace.s2),
                    Text(
                      l10n.callMediaFailed,
                      textAlign: TextAlign.center,
                      style: t.label.copyWith(color: c.plantain),
                    ),
                  ],
                  const Spacer(),
                  if (ongoing && !vm.finished) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _CallToggle(
                            icon: vm.microphoneOn
                                ? Icons.mic_rounded
                                : Icons.mic_off_rounded,
                            label: vm.microphoneOn
                                ? l10n.callMicrophoneOn
                                : l10n.callMicrophoneOff,
                            active: !vm.microphoneOn,
                            onTap: vm.toggleMicrophone,
                          ),
                        ),
                        const SizedBox(width: DymTokenSpace.s3),
                        Expanded(
                          child: _CallToggle(
                            icon: vm.speakerOn
                                ? Icons.volume_up_rounded
                                : Icons.hearing_rounded,
                            label: vm.speakerOn
                                ? l10n.callSpeakerOn
                                : l10n.callSpeakerOff,
                            active: vm.speakerOn,
                            onTap: vm.toggleSpeaker,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DymTokenSpace.s3),
                  ],
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
        ],
      ),
    );
  }
}

/// Bascule de l'écran d'appel (micro, haut-parleur) : icône et libellé,
/// cible de 56 dp.
class _CallToggle extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final fg = active ? c.brandDeep : c.onBrand;
    return Semantics(
      button: true,
      toggled: active,
      child: Material(
        color: active ? c.onBrand : c.onBrand.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.all(DymTokenSpace.s2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: fg, size: 22),
                  const SizedBox(width: DymTokenSpace.s2),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: t.label.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
