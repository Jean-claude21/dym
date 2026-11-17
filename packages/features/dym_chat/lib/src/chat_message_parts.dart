part of 'chat_views.dart';

/// Nom de l'auteur d'un message cité : « Toi » pour moi.
String _authorLabel(DymLocalizations l10n, ChatViewModel vm, String role) {
  if (role == vm.role.code) return l10n.chatYouName;
  return vm.thread?.conversation.authorName(role) ?? '';
}

/// Extrait d'un message cité (texte, sinon sa nature).
String _excerpt(
  DymLocalizations l10n,
  MessageKind kind,
  String? body,
  String? fileName,
) => switch (kind) {
  MessageKind.image => l10n.chatPhoto,
  MessageKind.audio => l10n.chatVoicePreview,
  MessageKind.video => l10n.chatVideo,
  MessageKind.location => l10n.chatLocation,
  MessageKind.file => fileName ?? l10n.chatDocument,
  MessageKind.product => body ?? l10n.chatShareProduct,
  MessageKind.quote => l10n.chatQuote,
  MessageKind.paymentRequest => l10n.chatPaymentRequest,
  MessageKind.coupon => l10n.chatCouponSend,
  MessageKind.call => l10n.chatCallPreview,
  _ => body ?? '',
};

IconData? _kindIcon(MessageKind kind) => switch (kind) {
  MessageKind.image => Icons.photo_camera_rounded,
  MessageKind.audio => Icons.mic_rounded,
  MessageKind.video => Icons.videocam_rounded,
  MessageKind.location => Icons.place_rounded,
  MessageKind.file => Icons.description_rounded,
  MessageKind.product => Icons.sell_rounded,
  _ => null,
};

/// Taille lisible d'un document (« 52 Ko », « 1,4 Mo »).
String _fileSize(BuildContext context, int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  final locale = Localizations.localeOf(context).languageCode;
  final fr = locale == 'fr';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).ceil()} ${fr ? 'Ko' : 'KB'}';
  }
  final mb = (bytes / (1024 * 1024) * 10).round() / 10;
  final text = fr ? '$mb'.replaceAll('.', ',') : '$mb';
  return '$text ${fr ? 'Mo' : 'MB'}';
}

/// Citation dans une bulle : barre de couleur, auteur, extrait. Toucher
/// remonte au message (s'il est chargé).
class _QuoteBlock extends StatelessWidget {
  const new({required this.quote, required this.vm, required this.onBrand});

  final MessageQuote quote;
  final ChatViewModel vm;
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final fg = onBrand ? c.onBrand : c.textPrimary;
    final icon = _kindIcon(quote.kind);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(
        DymTokenSpace.s2,
        4,
        DymTokenSpace.s2,
        4,
      ),
      decoration: BoxDecoration(
        color: onBrand
            ? c.onBrand.withValues(alpha: 0.18)
            : c.tintVertTendre.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(DymTokenRadius.chip),
        border: Border(
          left: BorderSide(color: onBrand ? c.onBrand : c.brand, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _authorLabel(l10n, vm, quote.authorRole),
            style: t.label.copyWith(
              color: onBrand ? c.onBrand : c.brandDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null && !quote.deleted) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  quote.deleted
                      ? l10n.chatDeletedMessage
                      : _excerpt(l10n, quote.kind, quote.body, null),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.label.copyWith(
                    color: fg,
                    fontStyle: quote.deleted ? FontStyle.italic : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// « ↪ Transféré » au-dessus du contenu.
class _ForwardedLabel extends StatelessWidget {
  const new({required this.onBrand});

  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final color = onBrand ? c.onBrand : c.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shortcut_rounded, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            DymLocalizations.of(context).chatForwarded,
            style: context.dym.text.label.copyWith(
              color: color,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Message supprimé pour tout le monde.
class _DeletedBubble extends StatelessWidget {
  const new({required this.mine, required this.meta});

  final bool mine;
  final Widget meta;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DymTokenSpace.s3,
        DymTokenSpace.s2,
        DymTokenSpace.s2,
        6,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.hairline),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: DymTokenSpace.s2,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_rounded, size: 18, color: c.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  DymLocalizations.of(context).chatDeletedMessage,
                  style: context.dym.text.body.copyWith(
                    color: c.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          meta,
        ],
      ),
    );
  }
}

/// Réactions sous une bulle : emoji et nombre ; la mienne est entourée.
class _ReactionsRow extends StatelessWidget {
  const new({required this.message, required this.vm});

  final ChatMessage message;
  final ChatViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final mine = message.reactionOf(vm.role);
    return Semantics(
      label: DymLocalizations.of(context).chatReactions,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Wrap(
          spacing: 4,
          children: [
            for (final r in message.reactions)
              Material(
                color: r.emoji == mine ? c.tintVertTendre : c.card,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: r.emoji == mine ? c.brand : c.hairline,
                  ),
                ),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => unawaited(vm.react(message, r.emoji)),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 32),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(r.emoji, style: const TextStyle(fontSize: 16)),
                          if (r.count > 1) ...[
                            const SizedBox(width: 2),
                            Text('${r.count}', style: t.label),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Glisser une bulle vers la droite pour y répondre.
class _SwipeToReply extends StatefulWidget {
  const new({required this.onReply, required this.child, this.enabled = true});

  final VoidCallback onReply;
  final Widget child;
  final bool enabled;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
  double _dx = 0;
  bool _fired = false;
  static const _trigger = 64.0;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final c = context.dym.colors;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (d) {
        setState(() => _dx = (_dx + d.delta.dx).clamp(0, _trigger + 16));
        if (!_fired && _dx >= _trigger) {
          _fired = true;
          unawaited(HapticFeedback.selectionClick());
        }
      },
      onHorizontalDragEnd: (_) {
        if (_fired) widget.onReply();
        setState(() {
          _dx = 0;
          _fired = false;
        });
      },
      onHorizontalDragCancel: () => setState(() {
        _dx = 0;
        _fired = false;
      }),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (_dx > 8)
            Opacity(
              opacity: (_dx / _trigger).clamp(0, 1),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: c.tintVertTendre,
                child: Icon(Icons.reply_rounded, size: 18, color: c.brandDeep),
              ),
            ),
          Transform.translate(offset: Offset(_dx, 0), child: widget.child),
        ],
      ),
    );
  }
}

/// Appui long : réactions rapides, puis répondre, copier, transférer,
/// supprimer.
Future<void> _messageActions(
  BuildContext context,
  ChatViewModel vm,
  ChatMessage m,
) async {
  final c = context.dym.colors;
  final l10n = DymLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final current = m.reactionOf(vm.role);
  unawaited(HapticFeedback.mediumImpact());
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    backgroundColor: c.card,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: DymTokenLayout.formMax),
    builder: (sheet) => _ActionsSheet(
      vm: vm,
      message: m,
      current: current,
      onPick: (value) => Navigator.pop(sheet, value),
    ),
  );
  if (choice == null || !context.mounted) return;
  if (choice.startsWith('emoji:')) {
    await vm.react(m, choice.substring(6));
    return;
  }
  switch (choice) {
    case 'reply':
      vm.startReply(m);
    case 'copy':
      await Clipboard.setData(ClipboardData(text: m.body ?? ''));
      messenger.showSnackBar(SnackBar(content: Text(l10n.chatCopied)));
    case 'forward':
      final targets = await vm.forwardTargets();
      if (!context.mounted) return;
      if (targets.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.chatForwardNone)));
        return;
      }
      final target = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        backgroundColor: c.card,
        isScrollControlled: true,
        constraints: const BoxConstraints(maxWidth: DymTokenLayout.formMax),
        builder: (sheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheet).height * 0.7,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DymTokenSpace.s3,
                  ),
                  child: Text(
                    l10n.chatForwardTo,
                    style: sheet.dym.text.title.copyWith(fontSize: 22),
                  ),
                ),
                for (final conv in targets)
                  ListTile(
                    minTileHeight: DymTokenSize.touchMin + 8,
                    leading: _Avatar(name: conv.title(vm.role), radius: 20),
                    title: Text(conv.title(vm.role)),
                    onTap: () => Navigator.pop(sheet, conv.id),
                  ),
              ],
            ),
          ),
        ),
      );
      if (target != null && await vm.forward(m, target)) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.chatForwardDone)));
      }
    case 'delete':
      final forAll = vm.canDeleteForAll(m);
      final mode = await showDialog<String>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(l10n.chatDeleteTitle),
          content: m.fromMe(vm.role) && !forAll
              ? Text(l10n.chatDeleteTooLate)
              : null,
          actions: [
            if (forAll)
              TextButton(
                onPressed: () => Navigator.pop(dialog, 'all'),
                style: TextButton.styleFrom(foregroundColor: c.pimentStrong),
                child: Text(l10n.chatDeleteForAll),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialog, 'me'),
              child: Text(l10n.chatDeleteForMe),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );
      if (mode != null) await vm.deleteMessage(m, forAll: mode == 'all');
  }
}

class _ActionsSheet extends StatefulWidget {
  const new({
    required this.vm,
    required this.message,
    required this.current,
    required this.onPick,
  });

  final ChatViewModel vm;
  final ChatMessage message;
  final String? current;
  final ValueChanged<String> onPick;

  @override
  State<_ActionsSheet> createState() => _ActionsSheetState();
}

class _ActionsSheetState extends State<_ActionsSheet> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final m = widget.message;
    Widget action(String value, IconData icon, String label, {Color? color}) =>
        ListTile(
          minTileHeight: DymTokenSize.touchMin + 4,
          leading: Icon(icon, color: color ?? c.brandDeep),
          title: Text(label, style: TextStyle(color: color)),
          onTap: () => widget.onPick(value),
        );
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!m.deleted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DymTokenSpace.s2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final e in quickReactions)
                    _ReactionChoice(
                      emoji: e,
                      selected: e == widget.current,
                      onTap: () => widget.onPick('emoji:$e'),
                    ),
                  IconButton(
                    tooltip: l10n.chatMoreReactions,
                    onPressed: () => setState(() => _all = !_all),
                    icon: Icon(
                      _all ? Icons.expand_less_rounded : Icons.add_rounded,
                    ),
                  ),
                ],
              ),
            ),
          if (_all)
            _EmojiGrid(onPick: (e) => widget.onPick('emoji:$e'), height: 200),
          const Divider(),
          if (!m.deleted) action('reply', Icons.reply_rounded, l10n.chatReply),
          if (!m.deleted && (m.body ?? '').isNotEmpty)
            action('copy', Icons.copy_rounded, l10n.chatCopy),
          if (m.forwardable)
            action('forward', Icons.shortcut_rounded, l10n.chatForward),
          action(
            'delete',
            Icons.delete_outline_rounded,
            l10n.chatDeleteForMe.split(' ').first,
            color: c.pimentStrong,
          ),
        ],
      ),
    );
  }
}

class _ReactionChoice extends StatelessWidget {
  const new({required this.emoji, required this.selected, required this.onTap});

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Material(
      color: selected ? c.tintVertTendre : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: DymTokenSize.touchMin,
          height: DymTokenSize.touchMin,
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
        ),
      ),
    );
  }
}

/// Document : icône du type, nom, taille ; toucher l'ouvre.
class _FileBubble extends StatelessWidget {
  const new({
    required this.name,
    required this.size,
    required this.mine,
    required this.meta,
    this.onOpen,
    this.faded = false,
  });

  final String name;
  final int? size;
  final bool mine;
  final Widget meta;
  final VoidCallback? onOpen;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final ext = name.contains('.') ? name.split('.').last.toUpperCase() : '';
    return Opacity(
      opacity: faded ? 0.75 : 1,
      child: Material(
        color: mine ? c.tintVertTendre : c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DymTokenRadius.card),
          side: BorderSide(color: c.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(DymTokenSpace.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 52,
                      decoration: BoxDecoration(
                        color: ext == 'PDF' ? c.pimentStrong : c.indigo,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        ext.length > 4 ? ext.substring(0, 4) : ext,
                        style: t.label.copyWith(
                          color: c.onBrand,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: DymTokenSpace.s2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.body.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            [
                              _fileSize(context, size),
                              ext,
                            ].where((s) => s.isNotEmpty).join(' · '),
                            style: t.label.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (onOpen != null)
                      Icon(
                        Icons.download_rounded,
                        color: c.brandDeep,
                        semanticLabel: l10n.chatDocumentOpen,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                meta,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vidéo lue dans la bulle ; plein écran au besoin.
class _VideoBubble extends StatelessWidget {
  const new({
    required this.message,
    required this.vm,
    required this.mine,
    required this.meta,
  });

  final ChatMessage message;
  final ChatViewModel vm;
  final bool mine;
  final Widget meta;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final url = vm.mediaUrl(message.id);
    final seconds = ((message.durationMs ?? 0) / 1000).round();
    return Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          child: InlineVideo(
            url: url,
            playLabel: l10n.chatVideoPlay,
            pauseLabel: l10n.chatVideoPause,
            muteLabel: l10n.chatVideoMute,
            unmuteLabel: l10n.chatVideoUnmute,
            fullScreenLabel: l10n.chatFullScreen,
            durationLabel: seconds > 0
                ? _clockOf(Duration(seconds: seconds))
                : null,
            onFullScreen: url == null
                ? null
                : () => unawaited(_openVideo(context, url)),
          ),
        ),
        if (message.body case final caption? when caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(caption, style: context.dym.text.body),
          ),
        const SizedBox(height: 2),
        meta,
      ],
    );
  }
}

Future<void> _openVideo(BuildContext context, String url) {
  final l10n = DymLocalizations.of(context);
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (page) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            tooltip: l10n.chatClose,
            onPressed: () => Navigator.pop(page),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: Center(
          child: LayoutBuilder(
            builder: (context, box) => InlineVideo(
              url: url,
              width: box.maxWidth,
              height: box.maxHeight,
              playLabel: l10n.chatVideoPlay,
              pauseLabel: l10n.chatVideoPause,
              muteLabel: l10n.chatVideoMute,
              unmuteLabel: l10n.chatVideoUnmute,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Photo en plein écran : pincer pour zoomer.
Future<void> _openPhoto(BuildContext context, ImageProvider image) {
  final l10n = DymLocalizations.of(context);
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (page) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            tooltip: l10n.chatClose,
            onPressed: () => Navigator.pop(page),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: Image(
              image: image,
              fit: BoxFit.contain,
              semanticLabel: l10n.chatPhoto,
            ),
          ),
        ),
      ),
    ),
  );
}

/// « 3 nouveaux messages ».
class _NewMessagesSeparator extends StatelessWidget {
  const new({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s2),
      child: Row(
        children: [
          Expanded(child: Divider(color: c.brand)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: DymTokenSpace.s2),
            padding: const EdgeInsets.symmetric(
              horizontal: DymTokenSpace.s3,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: c.tintVertTendre,
              borderRadius: BorderRadius.circular(DymTokenRadius.chip),
            ),
            child: Text(
              DymLocalizations.of(context).chatNewMessages(count),
              style: context.dym.text.label.copyWith(
                color: c.brandDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Divider(color: c.brand)),
        ],
      ),
    );
  }
}

/// Résultats de la recherche dans la conversation.
class _SearchResults extends StatelessWidget {
  const new({required this.vm});

  final ChatViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final q = vm.searchQuery.trim();
    final results = vm.searchResults;
    if (q.length < 2 || results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s4),
          child: Text(
            q.length < 2 ? l10n.chatSearchHint : l10n.chatSearchEmpty,
            textAlign: TextAlign.center,
            style: t.body.copyWith(color: c.textSecondary),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: DymLayout.gutter(context)),
      itemCount: results.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: c.hairline),
      itemBuilder: (context, i) {
        final m = results[i];
        final day = MaterialLocalizations.of(
          context,
        ).formatShortMonthDay(m.createdAt.toLocal());
        final text = m.kind == MessageKind.file
            ? (m.fileName ?? '')
            : m.kind == MessageKind.product
            ? (m.product?.name ?? '')
            : (m.body ?? '');
        return DymContentWidth.form(
          child: ListTile(
            minTileHeight: DymTokenSize.touchMin + 8,
            leading: Icon(
              _kindIcon(m.kind) ?? Icons.chat_bubble_outline_rounded,
              color: c.brandDeep,
            ),
            title: _Highlighted(text: text, query: q),
            subtitle: Text(
              '${_authorLabel(l10n, vm, m.authorRole)} · '
              '$day ${chatClock(context, m.createdAt)}',
              style: t.label.copyWith(color: c.textSecondary),
            ),
          ),
        );
      },
    );
  }
}

/// Texte avec la recherche surlignée.
class _Highlighted extends StatelessWidget {
  const new({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final i = text.toLowerCase().indexOf(query.toLowerCase());
    if (i < 0 || query.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: t.body,
      );
    }
    return Text.rich(
      TextSpan(
        style: t.body,
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(
            text: text.substring(i, i + query.length),
            style: TextStyle(
              backgroundColor: c.tintPlantainClair,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: text.substring(i + query.length)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Médias et documents d'une conversation (onglets).
class ChatMediaPage extends StatelessWidget {
  const new({required this.vm, super.key});

  final ChatViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final media = vm.mediaMessages;
    final docs = vm.documentMessages;
    Widget empty(String text) => Center(
      child: Padding(
        padding: const EdgeInsets.all(DymTokenSpace.s4),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: t.body.copyWith(color: c.textSecondary),
        ),
      ),
    );
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.card,
          title: Text(l10n.chatMediaTitle),
          bottom: TabBar(
            labelColor: c.brandDeep,
            indicatorColor: c.brand,
            tabs: [
              Tab(text: l10n.chatMediaTab),
              Tab(text: l10n.chatDocumentsTab),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            if (media.isEmpty)
              empty(l10n.chatMediaEmpty)
            else
              GridView.builder(
                padding: const EdgeInsets.all(2),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: media.length,
                itemBuilder: (context, i) {
                  final m = media[i];
                  final url = vm.mediaUrl(m.id);
                  final video = m.kind == MessageKind.video;
                  return InkWell(
                    onTap: url == null
                        ? null
                        : () => unawaited(
                            video
                                ? _openVideo(context, url)
                                : _openPhoto(
                                    context,
                                    vm.service.mediaImage(url),
                                  ),
                          ),
                    child: video || url == null
                        ? ColoredBox(
                            color: video ? c.textPrimary : c.tintVertTendre,
                            child: Icon(
                              video
                                  ? Icons.play_circle_fill_rounded
                                  : Icons.photo_rounded,
                              color: video ? c.card : c.brandDeep,
                              size: 36,
                              semanticLabel: video
                                  ? l10n.chatVideo
                                  : l10n.chatPhoto,
                            ),
                          )
                        : Image(
                            image: vm.service.mediaImage(url),
                            fit: BoxFit.cover,
                            semanticLabel: l10n.chatPhoto,
                            errorBuilder: (_, _, _) =>
                                ColoredBox(color: c.tintVertTendre),
                          ),
                  );
                },
              ),
            if (docs.isEmpty)
              empty(l10n.chatDocumentsEmpty)
            else
              ListView(
                padding: const EdgeInsets.all(DymTokenSpace.s3),
                children: [
                  for (final m in docs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
                      child: _FileBubble(
                        name: m.fileName ?? l10n.chatDocument,
                        size: m.fileSize,
                        mine: m.fromMe(vm.role),
                        meta: Text(
                          chatClock(context, m.createdAt),
                          style: t.label.copyWith(color: c.textSecondary),
                        ),
                        onOpen: vm.service.opener == null
                            ? null
                            : () => unawaited(vm.openDocument(m)),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
