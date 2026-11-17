part of 'chat_views.dart';

/// Émojis proposés (sélection maison, sans paquet) : visages, gestes,
/// cœurs, puis fruits, légumes et cuisine.
const chatEmojis = [
  '😀', '😁', '😂', '🤣', '😊', '😍', '😘', '😉', '🙂', '😅', //
  '😎', '🤩', '🤔', '😮', '😢', '😭', '😡', '😴', '🥳', '🤗',
  '👍', '👎', '👌', '🙏', '👏', '🙌', '💪', '🤝', '👋', '✌️',
  '❤️', '🧡', '💛', '💚', '💙', '💜', '🔥', '⭐', '✅', '❌',
  '🍅', '🧅', '🧄', '🌶️', '🥕', '🥔', '🍠', '🥬', '🥦', '🌽',
  '🍆', '🫑', '🥒', '🍌', '🍍', '🥭', '🍊', '🍋', '🍉', '🥥',
  '🍎', '🍐', '🍇', '🍓', '🥑', '🥜', '🍚', '🍞', '🥚', '🐟',
  '🍗', '🥩', '🦐', '🧂', '🫖', '🍳', '🥘', '🔪', '🛒', '🛍️',
  '🚚', '🛵', '📦', '💰', '💳', '📍', '⏰', '📞', '🎉', '🙈',
];

/// Champ de saisie (spec 111) : émojis, menu « + », réponse citée, vocal
/// tenu (glisser pour annuler, vers le haut pour verrouiller) ou d'un tap.
class _Composer extends StatefulWidget {
  const new({required this.vm, this.pickProducts});

  final ChatViewModel vm;
  final Future<List<String>?> Function(BuildContext context)? pickProducts;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _emojis = false;

  /// Décalage du doigt pendant un vocal tenu.
  Offset _drag = Offset.zero;
  bool _held = false;

  static const _cancelAt = -110.0;
  static const _lockAt = -80.0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus && _emojis) setState(() => _emojis = false);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toggleEmojis() {
    if (_emojis) {
      setState(() => _emojis = false);
      _focus.requestFocus();
    } else {
      _focus.unfocus();
      setState(() => _emojis = true);
    }
  }

  void _insert(String emoji) {
    final value = _text.value;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : value.text.length;
    final end = sel.isValid ? sel.end : value.text.length;
    final text = value.text.replaceRange(start, end, emoji);
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    widget.vm.textChanged(text);
  }

  Future<void> _attach() async {
    final l10n = DymLocalizations.of(context);
    final c = context.dym.colors;
    final t = context.dym.text;
    final vm = widget.vm;
    final options = <(Object, IconData, String, Color)>[
      if (vm.canSendDocuments)
        ('document', Icons.description_rounded, l10n.chatDocument, c.indigo),
      ('camera', Icons.photo_camera_rounded, l10n.chatCamera, c.pimentStrong),
      ('gallery', Icons.photo_library_rounded, l10n.chatGallery, c.brandDeep),
      if (widget.pickProducts != null)
        ('products', Icons.sell_rounded, l10n.chatShareProduct, c.huile),
      for (final (action, icon, label) in commerceOptions(l10n, vm))
        (action, icon, label, c.brandDeep),
    ];
    final choice = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      backgroundColor: c.card,
      constraints: const BoxConstraints(maxWidth: DymTokenLayout.formMax),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DymTokenSpace.s2,
            0,
            DymTokenSpace.s2,
            DymTokenSpace.s3,
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth / 4;
              return Wrap(
                runSpacing: DymTokenSpace.s2,
                children: [
                  for (final (value, icon, label, color) in options)
                    SizedBox(
                      width: width,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          DymTokenRadius.tile,
                        ),
                        onTap: () => Navigator.pop(sheet, value),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: color,
                                child: Icon(icon, color: c.onBrand, size: 26),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                label,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: t.label,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case final CommerceAction action:
        await runCommerceAction(context, vm, action);
      case 'document':
        await vm.sendDocument();
      case 'camera':
        await vm.sendPhoto(PhotoSource.camera);
      case 'gallery':
        await vm.sendPhoto(PhotoSource.gallery);
      case 'products':
        final ids = await widget.pickProducts!(context);
        if (ids != null && ids.isNotEmpty) await vm.sendProducts(ids);
    }
  }

  Future<void> _send() async {
    final text = _text.text;
    if (text.trim().isEmpty) return;
    _text.clear();
    await widget.vm.sendText(text);
  }

  // ------------------------------------------------------------- vocal tenu

  Future<void> _holdStart() async {
    _drag = Offset.zero;
    _held = true;
    await widget.vm.startRecording();
    if (mounted) setState(() {});
  }

  void _holdMove(LongPressMoveUpdateDetails d) {
    final vm = widget.vm;
    if (!_held || !vm.recording) return;
    setState(() => _drag = d.offsetFromOrigin);
    if (d.offsetFromOrigin.dx < _cancelAt) {
      _held = false;
      unawaited(vm.cancelRecording());
    } else if (d.offsetFromOrigin.dy < _lockAt) {
      _held = false;
      vm.lockRecording();
    }
  }

  Future<void> _holdEnd() async {
    final vm = widget.vm;
    final wasHeld = _held;
    _held = false;
    setState(() => _drag = Offset.zero);
    if (wasHeld && vm.recording && !vm.recordLocked) {
      await vm.stopAndSendRecording();
    }
  }

  /// Tap simple : enregistrement verrouillé (gants, accessibilité).
  Future<void> _tapRecord() async {
    await widget.vm.startRecording();
    widget.vm.lockRecording();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final vm = widget.vm;
    final reply = vm.replyingTo;
    return Material(
      color: c.card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reply != null && !vm.recording)
            _ReplyBanner(message: reply, vm: vm),
          Padding(
            padding: const EdgeInsets.all(DymTokenSpace.s2),
            child: vm.recording
                ? _RecordingBar(
                    vm: vm,
                    held: _held,
                    drag: _drag,
                    onHoldMove: _holdMove,
                    onHoldEnd: _holdEnd,
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.background,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                tooltip: _emojis
                                    ? l10n.chatKeyboard
                                    : l10n.chatEmoji,
                                onPressed: _toggleEmojis,
                                icon: Icon(
                                  _emojis
                                      ? Icons.keyboard_rounded
                                      : Icons.emoji_emotions_outlined,
                                  color: c.textSecondary,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _text,
                                  focusNode: _focus,
                                  minLines: 1,
                                  maxLines: 5,
                                  maxLength: 1000,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  onChanged: vm.textChanged,
                                  onSubmitted: (_) => _send(),
                                  decoration: InputDecoration(
                                    hintText: l10n.chatWriteHint,
                                    counterText: '',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.chatAttach,
                                onPressed: _attach,
                                icon: Icon(
                                  Icons.attach_file_rounded,
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: DymTokenSpace.s1),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _text,
                        builder: (context, value, _) {
                          final empty = value.text.trim().isEmpty;
                          if (empty && vm.canRecord) {
                            return GestureDetector(
                              onLongPressStart: (_) => _holdStart(),
                              onLongPressMoveUpdate: _holdMove,
                              onLongPressEnd: (_) => _holdEnd(),
                              child: IconButton.filled(
                                tooltip: l10n.chatVoiceRecord,
                                style: IconButton.styleFrom(
                                  backgroundColor: c.brand,
                                  minimumSize: const Size(52, 52),
                                ),
                                onPressed: _tapRecord,
                                icon: Icon(Icons.mic_rounded, color: c.onBrand),
                              ),
                            );
                          }
                          return IconButton.filled(
                            tooltip: l10n.chatSend,
                            style: IconButton.styleFrom(
                              backgroundColor: c.brand,
                              minimumSize: const Size(52, 52),
                            ),
                            onPressed: empty ? null : _send,
                            icon: Icon(Icons.send_rounded, color: c.onBrand),
                          );
                        },
                      ),
                    ],
                  ),
          ),
          if (_emojis && !vm.recording)
            _EmojiGrid(onPick: _insert, height: 240),
        ],
      ),
    );
  }
}

/// Grille d'émojis (champ de saisie et « Autres réactions »).
class _EmojiGrid extends StatelessWidget {
  const new({required this.onPick, required this.height});

  final ValueChanged<String> onPick;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: DymTokenSpace.s2),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 52,
      ),
      itemCount: chatEmojis.length,
      itemBuilder: (context, i) => InkWell(
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
        onTap: () => onPick(chatEmojis[i]),
        child: Center(
          child: Text(chatEmojis[i], style: const TextStyle(fontSize: 28)),
        ),
      ),
    ),
  );
}

/// « Réponse à … » au-dessus du champ, avec l'extrait cité.
class _ReplyBanner extends StatelessWidget {
  const new({required this.message, required this.vm});

  final ChatMessage message;
  final ChatViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final name = _authorLabel(l10n, vm, message.authorRole);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        DymTokenSpace.s2,
        DymTokenSpace.s2,
        DymTokenSpace.s2,
        0,
      ),
      padding: const EdgeInsets.only(left: DymTokenSpace.s2),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        border: Border(left: BorderSide(color: c.brand, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.chatReplyingTo(name),
                  style: t.label.copyWith(
                    color: c.brandDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _excerpt(l10n, message.kind, message.body, message.fileName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.body.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.chatCancelReply,
            onPressed: vm.cancelReply,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

String _clockOf(Duration d) {
  final s = d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Vocal en cours : point rouge, secondes qui défilent, onde du micro.
/// Tenu : « glisse pour annuler » et cadenas ; verrouillé : corbeille et
/// envoi.
class _RecordingBar extends StatelessWidget {
  const new({
    required this.vm,
    required this.held,
    required this.drag,
    required this.onHoldMove,
    required this.onHoldEnd,
  });

  final ChatViewModel vm;
  final bool held;
  final Offset drag;
  final GestureLongPressMoveUpdateCallback onHoldMove;
  final VoidCallback onHoldEnd;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final elapsed = Semantics(
      liveRegion: true,
      label: l10n.chatVoiceRecording,
      child: Text(
        _clockOf(vm.recordElapsed),
        style: t.title.copyWith(
          fontSize: 18,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
    final dot = _Blink(
      child: Icon(
        Icons.fiber_manual_record_rounded,
        color: c.pimentStrong,
        size: 18,
      ),
    );
    if (!vm.recordLocked) {
      // Doigt sur le micro : le bouton reste sous le doigt.
      final cancelProgress = (drag.dx / -110).clamp(0.0, 1.0);
      return Row(
        children: [
          dot,
          const SizedBox(width: DymTokenSpace.s1),
          elapsed,
          const SizedBox(width: DymTokenSpace.s2),
          Expanded(
            child: Opacity(
              opacity: 1 - cancelProgress * 0.7,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chevron_left_rounded, color: c.textSecondary),
                  Flexible(
                    child: Text(
                      l10n.chatVoiceSlideCancel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.label.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: c.textSecondary,
                semanticLabel: l10n.chatVoiceLock,
              ),
              Icon(Icons.keyboard_arrow_up_rounded, color: c.textSecondary),
            ],
          ),
          const SizedBox(width: DymTokenSpace.s1),
          GestureDetector(
            onLongPressMoveUpdate: onHoldMove,
            onLongPressEnd: (_) => onHoldEnd(),
            child: Transform.translate(
              offset: Offset(drag.dx.clamp(-110, 0), drag.dy.clamp(-80, 0)),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: c.brand,
                child: Icon(Icons.mic_rounded, color: c.onBrand, size: 30),
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        IconButton(
          tooltip: l10n.chatVoiceCancel,
          onPressed: vm.cancelRecording,
          icon: Icon(Icons.delete_rounded, color: c.pimentStrong),
        ),
        dot,
        const SizedBox(width: DymTokenSpace.s1),
        elapsed,
        const SizedBox(width: DymTokenSpace.s2),
        Expanded(
          child: _Wave(levels: vm.recordLevels, color: c.brandDeep),
        ),
        const SizedBox(width: DymTokenSpace.s2),
        IconButton.filled(
          tooltip: l10n.chatVoiceSend,
          style: IconButton.styleFrom(
            backgroundColor: c.brand,
            minimumSize: const Size(52, 52),
          ),
          onPressed: vm.stopAndSendRecording,
          icon: Icon(Icons.send_rounded, color: c.onBrand),
        ),
      ],
    );
  }
}

/// Onde : barres verticales à partir des niveaux (0 à 1).
class _Wave extends StatelessWidget {
  const new({required this.levels, required this.color, this.progress});

  final List<double> levels;
  final Color color;

  /// Partie déjà lue (vocal reçu), nulle pendant l'enregistrement.
  final double? progress;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 32,
    child: CustomPaint(
      painter: _WavePainter(
        levels: levels.isEmpty ? const [0.1] : levels,
        color: color,
        progress: progress,
      ),
    ),
  );
}

class _WavePainter extends CustomPainter {
  new({required this.levels, required this.color, this.progress});

  final List<double> levels;
  final Color color;
  final double? progress;

  @override
  void paint(Canvas canvas, Size size) {
    const bar = 3.0;
    const gap = 2.0;
    final count = (size.width / (bar + gap)).floor();
    if (count <= 0) return;
    final played = Paint()..color = color;
    final rest = Paint()..color = color.withValues(alpha: 0.35);
    for (var i = 0; i < count; i++) {
      // Barres réparties sur les niveaux connus (les plus récents à droite).
      final index = (i * levels.length / count).floor().clamp(
        0,
        levels.length - 1,
      );
      final h = (0.15 + levels[index] * 0.85) * size.height;
      final x = i * (bar + gap);
      final p = progress;
      final paint = p == null || i / count <= p ? played : rest;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - h) / 2, bar, h),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.levels != levels || old.progress != progress || old.color != color;
}

/// Clignotement doux (désactivé si l'appareil réduit les animations).
class _Blink extends StatefulWidget {
  const new({required this.child});

  final Widget child;

  @override
  State<_Blink> createState() => _BlinkState();
}

class _BlinkState extends State<_Blink> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 1, end: 0.25).animate(_c),
    child: widget.child,
  );
}
