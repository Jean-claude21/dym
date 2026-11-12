import 'package:dym_chat/src/call_service.dart';
import 'package:dym_chat/src/call_views.dart';
import 'package:dym_chat/src/chat_service.dart';
import 'package:dym_chat/src/chat_viewmodels.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Heure courte (aujourd'hui), « hier », sinon la date.
String chatTime(BuildContext context, DateTime at, DateTime now) {
  final local = at.toLocal();
  final today = DateUtils.dateOnly(now.toLocal());
  final day = DateUtils.dateOnly(local);
  if (day == today) return TimeOfDay.fromDateTime(local).format(context);
  if (today.difference(day).inDays == 1) {
    return DymLocalizations.of(context).timeYesterday;
  }
  return MaterialLocalizations.of(context).formatShortMonthDay(local);
}

/// Aperçu d'un dernier message.
String chatPreview(DymLocalizations l10n, ChatMessage? m) => switch (m) {
  null => '',
  ChatMessage(kind: MessageKind.image) => l10n.chatPhoto,
  ChatMessage(kind: MessageKind.product, :final product) =>
    l10n.chatProductPreview(product?.name ?? ''),
  ChatMessage(:final body) => body ?? '',
};

class _State extends StatelessWidget {
  const new({required this.failure, required this.onRetry});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final current = failure;
    if (current == null) {
      return Center(
        child: CircularProgressIndicator(color: context.dym.colors.brand),
      );
    }
    final offline = current is NetworkFailure;
    return DymStateView(
      kind: offline ? DymStateKind.offline : DymStateKind.error,
      title: offline ? l10n.errorOffline : l10n.errorGeneric,
      message: '',
      actionLabel: l10n.retry,
      onAction: onRetry,
    );
  }
}

// ------------------------------------------------------------------ 61

/// Conversations (écran 61 ; « Mes messages » côté cliente).
class ConversationsView extends StackedView<ConversationsViewModel> {
  const new({
    required this.service,
    required this.onOpen,
    super.key,
    this.onBack,
    this.clock = DateTime.now,
    this.refreshEvery = const Duration(seconds: 60),
  });

  final ChatService service;
  final ValueChanged<String> onOpen;
  final VoidCallback? onBack;
  final DateTime Function() clock;
  final Duration? refreshEvery;

  @override
  ConversationsViewModel viewModelBuilder(BuildContext context) =>
      ConversationsViewModel(service: service, refreshEvery: refreshEvery);

  @override
  void onViewModelReady(ConversationsViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    ConversationsViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final now = clock();
    final back = onBack;
    final header = Row(
      children: [
        if (back != null)
          IconButton(
            tooltip: l10n.authBack,
            onPressed: back,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        Expanded(
          child: Text(
            l10n.chatMessagesTitle,
            style: t.display,
          ),
        ),
        if (vm.ready)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DymTokenSpace.s2,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: vm.unread > 0 ? c.brand : c.tintVertTendre,
              borderRadius: BorderRadius.circular(DymTokenRadius.chip),
            ),
            child: Text(
              l10n.chatUnread(vm.unread),
              style: t.label.copyWith(
                fontWeight: FontWeight.w600,
                color: vm.unread > 0 ? c.onBrand : c.brandDeep,
              ),
            ),
          ),
      ],
    );
    return SafeArea(
      child: Column(
        children: [
          DymContentWidth.form(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                DymLayout.gutter(context),
                DymTokenSpace.s3,
                DymLayout.gutter(context),
                DymTokenSpace.s2,
              ),
              child: header,
            ),
          ),
          if (vm.ready && vm.offline)
            Text(
              l10n.chatOffline,
              style: t.label.copyWith(color: c.textSecondary),
            ),
          Expanded(
            child: !vm.ready
                ? _State(
                    failure: vm.isBusy ? null : vm.failure,
                    onRetry: vm.load,
                  )
                : RefreshIndicator(
                    onRefresh: vm.load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(DymLayout.gutter(context)),
                      children: [
                        if (vm.conversations.isEmpty)
                          DymStateView(
                            kind: DymStateKind.empty,
                            icon: Icons.chat_bubble_outline_rounded,
                            title: l10n.chatEmptyList,
                            message: '',
                          ),
                        for (final conv in vm.conversations)
                          DymContentWidth.form(
                            child: _ConversationTile(
                              conversation: conv,
                              role: service.role,
                              now: now,
                              onTap: () => onOpen(conv.id),
                            ),
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

class _ConversationTile extends StatelessWidget {
  const new({
    required this.conversation,
    required this.role,
    required this.now,
    required this.onTap,
  });

  final Conversation conversation;
  final ChatRole role;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final name = role == ChatRole.vendor
        ? (conversation.clientFirstName ?? '')
        : conversation.storeName;
    final last = conversation.lastMessage;
    final at = conversation.lastMessageAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DymTokenRadius.card),
          side: BorderSide(color: c.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(DymTokenSpace.s3),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: c.tintVertTendre,
                  child: Text(
                    name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                    style: t.title.copyWith(fontSize: 22, color: c.brandDeep),
                  ),
                ),
                const SizedBox(width: DymTokenSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: t.title.copyWith(fontSize: 18)),
                      Row(
                        children: [
                          if (last?.kind == MessageKind.image) ...[
                            Icon(
                              Icons.photo_camera_rounded,
                              size: 18,
                              color: c.textSecondary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              chatPreview(l10n, last),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.body.copyWith(
                                color: c.textSecondary,
                                fontWeight: conversation.unread > 0
                                    ? FontWeight.w700
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DymTokenSpace.s2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (at != null)
                      Text(
                        chatTime(context, at, now),
                        style: t.label.copyWith(color: c.textSecondary),
                      ),
                    if (conversation.unread > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        constraints: const BoxConstraints(minWidth: 28),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.brand,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${conversation.unread}',
                          textAlign: TextAlign.center,
                          style: t.label.copyWith(
                            fontWeight: FontWeight.w600,
                            color: c.onBrand,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ 60 · 62

/// Conversation (écran 60 côté cliente, 62 côté vendeuse).
class ChatView extends StackedView<ChatViewModel> {
  const new({
    required this.service,
    required this.conversationId,
    required this.onBack,
    super.key,
    this.onAddToCart,
    this.onOpenProduct,
    this.pickProduct,
    this.initialProductId,
    this.clock = DateTime.now,
    this.refreshEvery = const Duration(seconds: 30),
  });

  final ChatService service;
  final String conversationId;
  final VoidCallback onBack;

  /// Cliente : ajouter au panier un produit partagé.
  final Future<void> Function(CatalogItem item)? onAddToCart;
  final ValueChanged<String>? onOpenProduct;

  /// Vendeuse : choisir un de ses produits à partager (nul : annulé).
  final Future<String?> Function(BuildContext context)? pickProduct;

  /// Produit à joindre (ouverte depuis une fiche produit).
  final String? initialProductId;
  final DateTime Function() clock;
  final Duration? refreshEvery;

  @override
  ChatViewModel viewModelBuilder(BuildContext context) => ChatViewModel(
    service: service,
    conversationId: conversationId,
    refreshEvery: refreshEvery,
    initialProductId: initialProductId,
  );

  @override
  void onViewModelReady(ChatViewModel viewModel) => viewModel.load();

  Future<void> _call(
    BuildContext context,
    CallService calls,
    CallKind kind,
    String name,
  ) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (route) => CallView(
        service: calls,
        conversationId: conversationId,
        kind: kind,
        peerName: name,
        onClose: () => Navigator.of(route).pop(),
      ),
    ),
  );

  @override
  Widget builder(BuildContext context, ChatViewModel viewModel, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final conv = vm.thread?.conversation;
    final name = conv == null
        ? ''
        : (service.role == ChatRole.vendor
              ? (conv.clientFirstName ?? '')
              : conv.storeName);
    final header = Container(
      color: c.card,
      padding: const EdgeInsets.fromLTRB(4, 4, DymTokenSpace.s3, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.authBack,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: c.tintVertTendre,
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: t.title.copyWith(color: c.brandDeep),
            ),
          ),
          const SizedBox(width: DymTokenSpace.s2),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.title.copyWith(fontSize: 20),
            ),
          ),
          if (service.calls case final calls?) ...[
            IconButton(
              tooltip: l10n.callAudio,
              onPressed: () => _call(context, calls, CallKind.audio, name),
              icon: Icon(Icons.call_rounded, color: c.brandDeep),
            ),
            IconButton(
              tooltip: l10n.callVideo,
              onPressed: () => _call(context, calls, CallKind.video, name),
              icon: Icon(Icons.videocam_rounded, color: c.brandDeep),
            ),
          ],
        ],
      ),
    );
    if (!vm.ready) {
      return Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Column(
            children: [
              header,
              Expanded(
                child: _State(
                  failure: vm.isBusy ? null : vm.failure,
                  onRetry: vm.load,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final now = clock();
    final messages = vm.messages.reversed.toList();
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            header,
            if (vm.offline)
              Padding(
                padding: const EdgeInsets.all(DymTokenSpace.s1),
                child: Text(
                  l10n.chatOffline,
                  style: t.label.copyWith(color: c.textSecondary),
                ),
              ),
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(DymTokenSpace.s4),
                        child: Text(
                          l10n.chatEmptyThread,
                          textAlign: TextAlign.center,
                          style: t.body.copyWith(color: c.textSecondary),
                        ),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.all(DymLayout.gutter(context)),
                      itemCount: messages.length,
                      itemBuilder: (context, i) => DymContentWidth.form(
                        child: _Bubble(
                          message: messages[i],
                          vm: vm,
                          now: now,
                          onAddToCart: onAddToCart,
                          onOpenProduct: onOpenProduct,
                        ),
                      ),
                    ),
            ),
            if (vm.sendFailure != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DymTokenSpace.s3,
                ),
                child: Text(
                  vm.sendFailure is NetworkFailure
                      ? l10n.errorOffline
                      : l10n.chatSendFailed,
                  style: t.label.copyWith(
                    color: c.pimentStrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (vm.pendingProductId != null)
              DymContentWidth.form(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DymTokenSpace.s3,
                    DymTokenSpace.s1,
                    DymTokenSpace.s3,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DymButton(
                          label: l10n.chatAttachProduct,
                          icon: Icons.sell_rounded,
                          variant: DymButtonVariant.secondary,
                          onPressed: vm.sending ? null : vm.sendPendingProduct,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.chatDismiss,
                        onPressed: vm.dismissPendingProduct,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            DymContentWidth.form(
              child: _Composer(vm: vm, pickProduct: pickProduct),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const new({
    required this.message,
    required this.vm,
    required this.now,
    this.onAddToCart,
    this.onOpenProduct,
  });

  final ChatMessage message;
  final ChatViewModel vm;
  final DateTime now;
  final Future<void> Function(CatalogItem item)? onAddToCart;
  final ValueChanged<String>? onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final mine = message.fromMe(vm.role);
    final time = Text(
      chatTime(context, message.createdAt, now),
      style: t.label.copyWith(
        color: mine && message.kind == MessageKind.text
            ? c.onBrand
            : c.textSecondary,
      ),
    );
    final Widget content = switch (message.kind) {
      MessageKind.image => _Photo(message: message, vm: vm, time: time),
      MessageKind.audio => _AudioBubble(
        message: message,
        vm: vm,
        mine: mine,
        time: time,
      ),
      MessageKind.call => _CallBubble(message: message, time: time),
      MessageKind.product => _ProductCard(
        message: message,
        vm: vm,
        onAddToCart: mine ? null : onAddToCart,
        onOpenProduct: onOpenProduct,
      ),
      _ => Container(
        padding: const EdgeInsets.fromLTRB(
          DymTokenSpace.s3,
          DymTokenSpace.s2,
          DymTokenSpace.s3,
          DymTokenSpace.s2,
        ),
        decoration: BoxDecoration(
          color: mine ? c.brand : c.card,
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.body ?? l10n.errorGeneric,
              style: t.body.copyWith(color: mine ? c.onBrand : c.textPrimary),
            ),
            const SizedBox(height: 2),
            time,
          ],
        ),
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.8,
          ),
          child: content,
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const new({required this.message, required this.vm, required this.time});

  final ChatMessage message;
  final ChatViewModel vm;
  final Widget time;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final url = vm.mediaUrl(message.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          child: SizedBox(
            width: 240,
            height: 240,
            child: url == null
                ? ColoredBox(
                    color: c.card,
                    child: Icon(
                      Icons.photo_rounded,
                      size: 48,
                      color: c.textSecondary,
                      semanticLabel: l10n.chatPhoto,
                    ),
                  )
                : Image(
                    image: vm.service.mediaImage(url),
                    fit: BoxFit.cover,
                    semanticLabel: l10n.chatPhoto,
                    // Photo illisible : un cadre menthe, jamais une icône
                    // flottante.
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: c.tintVertTendre,
                      child: Icon(
                        Icons.photo_rounded,
                        size: 48,
                        color: c.brandDeep,
                      ),
                    ),
                  ),
          ),
        ),
        time,
      ],
    );
  }
}

/// Vignette produit sans photo : la feuille sur menthe, comme partout.
Widget _leaf(DymColors c) => ColoredBox(
  color: c.tintVertTendre,
  child: Icon(Icons.eco_outlined, color: c.brandDeep, size: 40),
);

class _ProductCard extends StatelessWidget {
  const new({
    required this.message,
    required this.vm,
    this.onAddToCart,
    this.onOpenProduct,
  });

  final ChatMessage message;
  final ChatViewModel vm;
  final Future<void> Function(CatalogItem item)? onAddToCart;
  final ValueChanged<String>? onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final item = message.product;
    if (item == null) {
      return Container(
        padding: const EdgeInsets.all(DymTokenSpace.s3),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          border: Border.all(color: c.hairline),
        ),
        child: Text(
          l10n.chatProductUnavailable,
          style: t.body.copyWith(color: c.textSecondary),
        ),
      );
    }
    final price = vm.price(item);
    final add = onAddToCart;
    final open = onOpenProduct;
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        side: BorderSide(color: c.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open == null ? null : () => open(item.id),
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DymTokenRadius.chip),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: item.photoKey == null
                      ? _leaf(c)
                      : Image(
                          image: vm.service.productPhoto(item.photoKey!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _leaf(c),
                        ),
                ),
              ),
              const SizedBox(width: DymTokenSpace.s2),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.name, style: t.title.copyWith(fontSize: 18)),
                    Wrap(
                      runSpacing: DymTokenSpace.s2,
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (item.unitLabel case final unit?)
                          Text(unit.resolve(locale), style: t.body),
                        if (price != null)
                          MoneyText(price, size: 17, color: c.brandDeep),
                      ],
                    ),
                    if (add != null && item.available) ...[
                      const SizedBox(height: DymTokenSpace.s1),
                      DymButton(
                        label: l10n.chatAddToCart,
                        icon: Icons.add_shopping_cart_rounded,
                        variant: DymButtonVariant.secondary,
                        compact: true,
                        expanded: false,
                        onPressed: () => add(item),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vocal : lecture, durée.
class _AudioBubble extends StatelessWidget {
  const new({
    required this.message,
    required this.vm,
    required this.mine,
    required this.time,
  });

  final ChatMessage message;
  final ChatViewModel vm;
  final bool mine;
  final Widget time;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final playing = vm.playingId == message.id;
    final seconds = ((message.durationMs ?? 0) / 1000).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, DymTokenSpace.s3, 4),
      decoration: BoxDecoration(
        color: mine ? c.tintVertTendre : c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: playing ? l10n.chatVoiceStop : l10n.chatVoicePlay,
            onPressed: vm.mediaUrl(message.id) == null
                ? null
                : () => vm.togglePlay(message),
            icon: Icon(
              playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: c.brandDeep,
            ),
          ),
          Icon(Icons.graphic_eq_rounded, color: c.brandDeep),
          const SizedBox(width: DymTokenSpace.s1),
          Text(l10n.chatVoiceDuration(seconds), style: t.label),
          const SizedBox(width: DymTokenSpace.s2),
          time,
        ],
      ),
    );
  }
}

/// Résumé d'un appel dans le fil.
class _CallBubble extends StatelessWidget {
  const new({required this.message, required this.time});

  final ChatMessage message;
  final Widget time;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final call = message.call;
    final video = call?.kind == CallKind.video;
    final label = switch (call?.status) {
      CallStatus.ended => l10n.callSummaryEnded(
        ((call?.durationS ?? 0) / 60).ceil(),
      ),
      CallStatus.declined => l10n.callDeclined,
      _ => l10n.callMissed,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DymTokenSpace.s3,
        vertical: DymTokenSpace.s2,
      ),
      decoration: BoxDecoration(
        color: c.muted,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            video ? Icons.videocam_rounded : Icons.call_rounded,
            color: c.brandDeep,
          ),
          const SizedBox(width: DymTokenSpace.s2),
          Flexible(child: Text(label, style: t.label)),
          const SizedBox(width: DymTokenSpace.s2),
          time,
        ],
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const new({required this.vm, this.pickProduct});

  final ChatViewModel vm;
  final Future<String?> Function(BuildContext context)? pickProduct;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _photo() async {
    final l10n = DymLocalizations.of(context);
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.dym.colors.card,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(l10n.chatCamera),
              onTap: () => Navigator.pop(context, PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(l10n.chatGallery),
              onTap: () => Navigator.pop(context, PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await widget.vm.sendPhoto(source);
  }

  Future<void> _product() async {
    final id = await widget.pickProduct!(context);
    if (id != null) await widget.vm.sendProduct(id);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final vm = widget.vm;
    Widget round(IconData icon, String tooltip, VoidCallback? onPressed) =>
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton.filledTonal(
            tooltip: tooltip,
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: c.tintVertTendre,
            ),
            onPressed: onPressed,
            icon: Icon(icon, color: c.brandDeep),
          ),
        );
    if (vm.recording) {
      return Container(
        color: c.card,
        padding: const EdgeInsets.all(DymTokenSpace.s2),
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.chatVoiceCancel,
              onPressed: vm.cancelRecording,
              icon: Icon(Icons.delete_rounded, color: c.pimentStrong),
            ),
            Icon(Icons.fiber_manual_record_rounded, color: c.pimentStrong),
            const SizedBox(width: DymTokenSpace.s2),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l10n.chatVoiceRecording,
                  style: context.dym.text.body,
                ),
              ),
            ),
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
        ),
      );
    }
    return Container(
      color: c.card,
      padding: const EdgeInsets.fromLTRB(
        DymTokenSpace.s2,
        DymTokenSpace.s2,
        DymTokenSpace.s2,
        DymTokenSpace.s2,
      ),
      child: Row(
        children: [
          if (vm.canRecord)
            round(
              Icons.mic_rounded,
              l10n.chatVoiceRecord,
              vm.sending ? null : vm.startRecording,
            ),
          if (widget.pickProduct != null)
            round(
              Icons.add_rounded,
              l10n.chatShareProduct,
              vm.sending ? null : _product,
            ),
          round(
            Icons.photo_camera_rounded,
            l10n.chatSendPhoto,
            vm.sending ? null : _photo,
          ),
          Expanded(
            child: TextField(
              controller: _text,
              minLines: 1,
              maxLines: 4,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => vm.textChanged(),
              decoration: InputDecoration(
                hintText: l10n.chatWriteHint,
                counterText: '',
                filled: true,
                fillColor: c.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DymTokenSpace.s3,
                  vertical: DymTokenSpace.s2,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DymTokenRadius.card),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton.filled(
            tooltip: l10n.chatSend,
            style: IconButton.styleFrom(
              backgroundColor: c.brand,
              minimumSize: const Size(52, 52),
            ),
            onPressed: vm.sending
                ? null
                : () async {
                    if (await vm.sendText(_text.text)) _text.clear();
                  },
            icon: Icon(Icons.send_rounded, color: c.onBrand),
          ),
        ],
      ),
    );
  }
}

/// Produit proposé au partage (écran 62).
class ShareableProduct {
  const new({required this.id, required this.name, this.detail, this.photo});

  final String id;
  final String name;

  /// Unité et prix, déjà formatés.
  final String? detail;
  final ImageProvider? photo;
}

/// Feuille « Partager un produit » ; renvoie l'identifiant choisi.
Future<String?> showProductShareSheet(
  BuildContext context,
  List<ShareableProduct> products,
) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: context.dym.colors.card,
  constraints: const BoxConstraints(maxWidth: DymTokenLayout.formMax),
  builder: (_) => ProductShareSheet(products: products),
);

/// Contenu de la feuille de partage (recherche dans mes produits).
class ProductShareSheet extends StatefulWidget {
  const new({required this.products, super.key});

  final List<ShareableProduct> products;

  @override
  State<ProductShareSheet> createState() => _ProductShareSheetState();
}

class _ProductShareSheetState extends State<ProductShareSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final p in widget.products)
        if (q.isEmpty || p.name.toLowerCase().contains(q)) p,
    ];
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DymTokenSpace.s3),
              child: Text(
                l10n.chatShareProduct,
                style: t.title.copyWith(fontSize: 24),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DymTokenSpace.s3),
              child: DymTextField(
                label: l10n.chatSearchProducts,
                icon: Icons.search_rounded,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Text(
                        l10n.chatNoProducts,
                        style: t.body.copyWith(color: c.textSecondary),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DymTokenSpace.s3,
                      ),
                      children: [
                        for (final p in shown)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: DymTokenSpace.s2,
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    DymTokenRadius.chip,
                                  ),
                                  child: SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: p.photo == null
                                        ? ColoredBox(color: c.tintVertTendre)
                                        : Image(
                                            image: p.photo!,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: DymTokenSpace.s2),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: t.title.copyWith(fontSize: 17),
                                      ),
                                      if (p.detail case final d?)
                                        Text(
                                          d,
                                          style: t.body.copyWith(
                                            color: c.brandDeep,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                DymButton(
                                  label: l10n.chatShare,
                                  compact: true,
                                  expanded: false,
                                  onPressed: () => Navigator.pop(context, p.id),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
