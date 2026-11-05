import 'dart:async';

import 'package:flutter/widgets.dart';

/// Déconnecte après [timeout] sans interaction (pointeur, molette, clavier) :
/// A-AUTH-05, 30 minutes pour l'admin.
class InactivityGuard extends StatefulWidget {
  const new({
    required this.child,
    required this.onTimeout,
    super.key,
    this.timeout = const Duration(minutes: 30),
  });

  final Widget child;
  final VoidCallback onTimeout;
  final Duration timeout;

  @override
  State<InactivityGuard> createState() => _InactivityGuardState();
}

class _InactivityGuardState extends State<InactivityGuard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset([Object? _]) {
    _timer?.cancel();
    _timer = Timer(widget.timeout, widget.onTimeout);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: (_, _) {
      _reset();
      return KeyEventResult.ignored;
    },
    child: Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _reset,
      onPointerMove: _reset,
      onPointerHover: _reset,
      onPointerSignal: _reset,
      child: widget.child,
    ),
  );
}
