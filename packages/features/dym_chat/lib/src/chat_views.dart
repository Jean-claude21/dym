import 'dart:typed_data';

import 'package:dym_chat/src/call_service.dart';
import 'package:dym_chat/src/call_views.dart';
import 'package:dym_chat/src/chat_service.dart';
import 'package:dym_chat/src/chat_viewmodels.dart';
import 'package:dym_chat/src/commerce_views.dart';
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

/// Heure d'un message dans le fil (le jour est dans le séparateur).
String chatClock(BuildContext context, DateTime at) =>
    TimeOfDay.fromDateTime(at.toLocal()).format(context);

String _capitalized(String s) =>
    s.isEmpty ? s : s.characters.first.toUpperCase() + s.substring(1);

/// Séparateur de jour : « Aujourd'hui », « Hier », sinon la date.
String chatDayLabel(BuildContext context, DateTime day, DateTime now) {
  final l10n = DymLocalizations.of(context);
  final today = DateUtils.dateOnly(now.toLocal());
  final days = today.difference(day).inDays;
  if (days == 0) return _capitalized(l10n.chatToday);
  if (days == 1) return _capitalized(l10n.timeYesterday);
  return MaterialLocalizations.of(context).formatMediumDate(day);
}

/// Aperçu d'un dernier message (« Toi : » quand il vient de moi).
String chatPreview(DymLocalizations l10n, ChatMessage? m, [ChatRole? me]) {
  final text = switch (m) {
    null => '',
    ChatMessage(kind: MessageKind.image) => l10n.chatPhoto,
    ChatMessage(kind: MessageKind.audio) => l10n.chatVoicePreview,
    ChatMessage(kind: MessageKind.call) => l10n.chatCallPreview,
    ChatMessage(kind: MessageKind.video) => l10n.chatVideo,
    ChatMessage(kind: MessageKind.location) => l10n.chatLocation,
    ChatMessage(kind: MessageKind.quote) => l10n.chatQuote,
    ChatMessage(kind: MessageKind.paymentRequest) => l10n.chatPaymentRequest,
    ChatMessage(kind: MessageKind.coupon) => l10n.chatCouponSend,
    ChatMessage(kind: MessageKind.product, :final product) =>
      l10n.chatProductPreview(product?.name ?? ''),
    ChatMessage(:final body) => body ?? '',
  };
  if (m == null || me == null || !m.fromMe(me) || text.isEmpty) return text;
  return l10n.chatYou(text);
}

/// Texte d'une réponse rapide.
String quickReplyText(DymLocalizations l10n, QuickReply reply) =>
    switch (reply) {
      QuickReply.isAvailable => l10n.chatQuickIsAvailable,
      QuickReply.price => l10n.chatQuickPrice,
      QuickReply.deliveryToday => l10n.chatQuickDeliveryToday,
      QuickReply.thanks => l10n.chatQuickThanks,
      QuickReply.yesAvailable => l10n.chatQuickYesAvailable,
      QuickReply.soldOut => l10n.chatQuickSoldOut,
      QuickReply.preparing => l10n.chatQuickPreparing,
      QuickReply.thanksOrder => l10n.chatQuickThanksOrder,
    };

String _orderStatus(DymLocalizations l10n, OrderStatus status) =>
    switch (status) {
      OrderStatus.pending => l10n.orderStatusPending,
      OrderStatus.accepted => l10n.orderStatusAccepted,
      OrderStatus.preparing => l10n.orderStatusPreparing,
      OrderStatus.ready => l10n.orderStatusReady,
      OrderStatus.outForDelivery => l10n.orderStatusOutForDelivery,
      OrderStatus.delivered => l10n.orderStatusDelivered,
      OrderStatus.refused => l10n.orderStatusRefused,
      OrderStatus.cancelled => l10n.orderStatusCancelled,
      OrderStatus.unknown => l10n.chatActiveOrder,
    };

IconData? _previewIcon(MessageKind? kind) => switch (kind) {
  MessageKind.image => Icons.photo_camera_rounded,
  MessageKind.audio => Icons.mic_rounded,
  MessageKind.call => Icons.call_rounded,
  MessageKind.product => Icons.sell_rounded,
  MessageKind.video => Icons.videocam_rounded,
  MessageKind.location => Icons.place_rounded,
  MessageKind.quote => Icons.request_quote_outlined,
  MessageKind.paymentRequest => Icons.payments_outlined,
  MessageKind.coupon => Icons.local_offer_outlined,
  _ => null,
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

/// Bandeau discret « hors ligne ».
class _OfflineNote extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: c.textSecondary),
          const SizedBox(width: DymTokenSpace.s1),
          Flexible(
            child: Text(
              DymLocalizations.of(context).chatOffline,
              style: t.label.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const new({required this.name, required this.radius});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return CircleAvatar(
      radius: radius,
      backgroundColor: c.tintVertTendre,
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: context.dym.text.title.copyWith(
          fontSize: radius * 0.8,
          color: c.brandDeep,
        ),
      ),
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
        Expanded(child: Text(l10n.chatMessagesTitle, style: t.display)),
        if (vm.ready && vm.unread > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DymTokenSpace.s2,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: c.brand,
              borderRadius: BorderRadius.circular(DymTokenRadius.chip),
            ),
            child: Text(
              l10n.chatUnread(vm.unread),
              style: t.label.copyWith(
                fontWeight: FontWeight.w600,
                color: c.onBrand,
              ),
            ),
          ),
      ],
    );
    final shown = vm.shown;
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
          if (vm.ready && vm.offline) const _OfflineNote(),
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
                      padding: EdgeInsets.fromLTRB(
                        DymLayout.gutter(context),
                        0,
                        DymLayout.gutter(context),
                        DymLayout.gutter(context),
                      ),
                      children: [
                        if (vm.searchable)
                          DymContentWidth.form(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: DymTokenSpace.s2,
                              ),
                              child: DymTextField(
                                label: l10n.chatSearchConversations,
                                icon: Icons.search_rounded,
                                onChanged: vm.setQuery,
                              ),
                            ),
                          ),
                        if (vm.conversations.isEmpty)
                          DymStateView(
                            kind: DymStateKind.empty,
                            icon: Icons.chat_bubble_outline_rounded,
                            title: l10n.chatEmptyList,
                            message: '',
                          ),
                        for (final conv in shown)
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
    final unread = conversation.unread > 0;
    final icon = _previewIcon(last?.kind);
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
                _Avatar(name: name, radius: 26),
                const SizedBox(width: DymTokenSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.title.copyWith(
                          fontSize: 18,
                          fontWeight: unread ? FontWeight.w700 : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: c.textSecondary),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              chatPreview(l10n, last, role),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.body.copyWith(
                                color: unread ? c.textPrimary : c.textSecondary,
                                fontWeight: unread ? FontWeight.w600 : null,
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
                        style: t.label.copyWith(
                          color: unread ? c.brandDeep : c.textSecondary,
                          fontWeight: unread ? FontWeight.w700 : null,
                        ),
                      ),
                    if (unread)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        constraints: const BoxConstraints(minWidth: 26),
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
    this.onOpenOrder,
    this.onOpenStore,
    this.pickProducts,
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

  /// Ouvrir la commande en cours (bandeau en tête du fil).
  final ValueChanged<String>? onOpenOrder;

  /// Cliente : ouvrir la boutique depuis l'en-tête.
  final ValueChanged<String>? onOpenStore;

  /// Choisir des produits à partager (vendeuse : les siens ; cliente : ceux
  /// de la boutique `storeId`). Nul ou vide : annulé.
  final Future<List<String>?> Function(BuildContext context, String storeId)?
  pickProducts;

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
    clock: clock,
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
    final vendor = service.role == ChatRole.vendor;
    final name = conv == null
        ? ''
        : (vendor ? (conv.clientFirstName ?? '') : conv.storeName);
    final openStore = vendor || conv == null ? null : onOpenStore;
    final identity = Row(
      children: [
        _Avatar(name: name, radius: 20),
        const SizedBox(width: DymTokenSpace.s2),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.title.copyWith(fontSize: 18),
              ),
              if (openStore != null)
                Text(
                  l10n.chatSeeStore,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.label.copyWith(
                    color: c.brandDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    final header = Material(
      color: c.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, DymTokenSpace.s2, 4),
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.authBack,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: openStore == null
                  ? identity
                  : InkWell(
                      borderRadius: BorderRadius.circular(DymTokenRadius.chip),
                      onTap: () => openStore(conv!.storeId),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: DymTokenSize.touchMin,
                        ),
                        child: identity,
                      ),
                    ),
            ),
            if (service.calls case final calls?) ...[
              IconButton(
                tooltip: l10n.callAudio,
                onPressed: () => _call(context, calls, CallKind.audio, name),
                icon: Icon(Icons.call_rounded, color: c.brandDeep),
              ),
              // Vidéo ouverte par le flag `calls_video` (spec 089).
              if (vm.videoCalls)
                IconButton(
                  tooltip: l10n.callVideo,
                  onPressed: () => _call(context, calls, CallKind.video, name),
                  icon: Icon(Icons.videocam_rounded, color: c.brandDeep),
                ),
            ],
          ],
        ),
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
    final entries = vm.entries.reversed.toList();
    final order = vm.activeOrder;
    final openOrder = onOpenOrder;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            header,
            Divider(height: 1, color: c.hairline),
            if (order != null)
              _OrderBanner(
                order: order,
                total: vm.activeOrderTotal,
                onOpen: openOrder == null ? null : () => openOrder(order.id),
              ),
            if (vm.offline) const _OfflineNote(),
            Expanded(
              child: entries.isEmpty
                  ? _EmptyThread(name: name, vendor: vendor)
                  : ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.symmetric(
                        horizontal: DymLayout.gutter(context),
                        vertical: DymTokenSpace.s2,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, i) => DymContentWidth.form(
                        child: switch (entries[i]) {
                          ChatDayEntry(:final day) => _DaySeparator(
                            label: chatDayLabel(context, day, now),
                          ),
                          final ChatMessageEntry e => _Bubble(
                            entry: e,
                            vm: vm,
                            onAddToCart: onAddToCart,
                            onOpenProduct: onOpenProduct,
                          ),
                          final ChatOutgoingEntry e => _OutgoingBubble(
                            entry: e,
                            vm: vm,
                          ),
                        },
                      ),
                    ),
            ),
            if (vm.sendFailure != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DymTokenSpace.s3,
                  vertical: DymTokenSpace.s1,
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
                          onPressed: vm.sendPendingProduct,
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
            if (vm.quickReplies.isNotEmpty) _QuickReplies(vm: vm),
            DymContentWidth.form(
              child: _Composer(
                vm: vm,
                pickProducts: switch ((pickProducts, conv)) {
                  (final pick?, final conv?) => (context) => pick(
                    context,
                    conv.storeId,
                  ),
                  _ => null,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Commande en cours entre la cliente et la boutique, rappelée en tête.
class _OrderBanner extends StatelessWidget {
  const new({required this.order, required this.total, this.onOpen});

  final ChatOrder order;
  final Money? total;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final amount = total;
    return Material(
      color: c.tintVertTendre,
      child: InkWell(
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: DymTokenSize.touchMin),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DymTokenSpace.s3,
              vertical: DymTokenSpace.s2,
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: c.brandDeep),
                const SizedBox(width: DymTokenSpace.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.chatActiveOrder,
                        style: t.label.copyWith(color: c.brandDeep),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: _orderStatus(l10n, order.status)),
                            if (amount != null)
                              TextSpan(text: ' · ${amount.format()}'),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.body.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                if (onOpen != null)
                  Semantics(
                    label: l10n.chatSeeOrder,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: c.brandDeep,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const new({required this.name, required this.vendor});

  final String name;
  final bool vendor;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DymTokenSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: c.tintVertTendre,
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 30,
                color: c.brandDeep,
              ),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            Text(
              name.isEmpty
                  ? l10n.chatEmptyThread
                  : (vendor
                        ? l10n.chatEmptyThreadClient(name)
                        : l10n.chatEmptyThreadStore(name)),
              textAlign: TextAlign.center,
              style: t.body.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DymTokenSpace.s3,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: c.muted,
            borderRadius: BorderRadius.circular(DymTokenRadius.chip),
          ),
          child: Text(
            label,
            style: context.dym.text.label.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Coins d'une bulle : le coin du côté de l'auteur est pincé en tête de
/// groupe.
BorderRadius _bubbleRadius({required bool mine, required bool continued}) {
  const r = Radius.circular(18);
  const pinched = Radius.circular(6);
  return BorderRadius.only(
    topLeft: !mine && !continued ? pinched : r,
    topRight: mine && !continued ? pinched : r,
    bottomLeft: r,
    bottomRight: r,
  );
}

/// Heure et état (« envoyé », « vu ») sous un message.
class _Meta extends StatelessWidget {
  const new({
    required this.time,
    required this.onBrand,
    this.mine = false,
    this.seen = false,
    this.pending = false,
  });

  final String time;
  final bool onBrand;
  final bool mine;
  final bool seen;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final color = onBrand ? c.onBrand : c.textSecondary;
    final status = pending
        ? l10n.chatSending
        : (seen ? l10n.chatSeen : l10n.chatSent);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: context.dym.text.label.copyWith(fontSize: 12, color: color),
        ),
        if (mine) ...[
          const SizedBox(width: 4),
          Icon(
            pending
                ? Icons.schedule_rounded
                : (seen ? Icons.done_all_rounded : Icons.done_rounded),
            size: 16,
            color: color,
            semanticLabel: status,
          ),
        ],
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const new({
    required this.entry,
    required this.vm,
    this.onAddToCart,
    this.onOpenProduct,
  });

  final ChatMessageEntry entry;
  final ChatViewModel vm;
  final Future<void> Function(CatalogItem item)? onAddToCart;
  final ValueChanged<String>? onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final message = entry.message;
    final mine = message.fromMe(vm.role);
    final clock = chatClock(context, message.createdAt);
    Widget meta({bool onBrand = false}) =>
        _Meta(time: clock, onBrand: onBrand, mine: mine, seen: entry.seen);
    final content = switch (message.kind) {
      MessageKind.image => _Photo(
        url: vm.mediaUrl(message.id),
        vm: vm,
        meta: meta(),
        mine: mine,
      ),
      MessageKind.audio => Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _AudioBubble(message: message, vm: vm, mine: mine, meta: meta()),
          TranscriptLine(message: message, vm: vm),
        ],
      ),
      MessageKind.call => _CallBubble(message: message, meta: meta()),
      // Chat de commerce (spec 099).
      MessageKind.video ||
      MessageKind.location ||
      MessageKind.quote ||
      MessageKind.paymentRequest ||
      MessageKind.coupon => CommerceBubble(
        message: message,
        vm: vm,
        mine: mine,
        meta: meta(),
      ),
      MessageKind.product => _ProductCard(
        message: message,
        vm: vm,
        meta: meta(),
        onAddToCart: mine ? null : onAddToCart,
        onOpenProduct: onOpenProduct,
      ),
      _ => _TextBubble(
        text: message.body ?? l10n.errorGeneric,
        mine: mine,
        continued: entry.continued,
        meta: meta(onBrand: mine),
      ),
    };
    return _Placed(mine: mine, continued: entry.continued, child: content);
  }
}

/// Place une bulle à gauche ou à droite, plus serrée dans un groupe.
class _Placed extends StatelessWidget {
  const new({required this.mine, required this.continued, required this.child});

  final bool mine;
  final bool continued;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: continued ? 2 : DymTokenSpace.s2),
    child: Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: child,
      ),
    ),
  );
}

class _TextBubble extends StatelessWidget {
  const new({
    required this.text,
    required this.mine,
    required this.continued,
    required this.meta,
    this.faded = false,
  });

  final String text;
  final bool mine;
  final bool continued;
  final Widget meta;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Opacity(
      opacity: faded ? 0.75 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          DymTokenSpace.s3,
          DymTokenSpace.s2,
          DymTokenSpace.s2,
          6,
        ),
        decoration: BoxDecoration(
          color: mine ? c.brand : c.card,
          borderRadius: _bubbleRadius(mine: mine, continued: continued),
          border: mine ? null : Border.all(color: c.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                text,
                style: t.body.copyWith(color: mine ? c.onBrand : c.textPrimary),
              ),
            ),
            meta,
          ],
        ),
      ),
    );
  }
}

/// Message parti de cet appareil : en cours d'envoi, ou en échec avec
/// « Réessayer » et « Supprimer ».
class _OutgoingBubble extends StatelessWidget {
  const new({required this.entry, required this.vm});

  final ChatOutgoingEntry entry;
  final ChatViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final o = entry.message;
    final failed = o.state == OutgoingState.failed;
    final meta = _Meta(
      time: chatClock(context, o.createdAt),
      onBrand: o.kind == MessageKind.text,
      mine: true,
      pending: !failed,
    );
    final Widget content = switch (o.kind) {
      MessageKind.text => _TextBubble(
        text: o.body ?? '',
        mine: true,
        continued: entry.continued,
        meta: meta,
        faded: !failed,
      ),
      MessageKind.image when o.photo != null => _Photo(
        bytes: o.photo!.bytes,
        vm: vm,
        meta: meta,
      ),
      _ => Container(
        padding: const EdgeInsets.all(DymTokenSpace.s2),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          border: Border.all(color: c.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              o.kind == MessageKind.audio
                  ? Icons.mic_rounded
                  : Icons.sell_rounded,
              color: c.brandDeep,
            ),
            const SizedBox(width: DymTokenSpace.s2),
            Flexible(
              child: Text(
                o.kind == MessageKind.audio
                    ? l10n.chatVoicePreview
                    : l10n.chatShareProduct,
                style: t.body,
              ),
            ),
            const SizedBox(width: DymTokenSpace.s2),
            meta,
          ],
        ),
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Placed(mine: true, continued: entry.continued, child: content),
        if (failed)
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: c.pimentStrong,
              ),
              const SizedBox(width: 4),
              Text(
                o.failure is NetworkFailure
                    ? '${l10n.chatNotSent} · ${l10n.errorOffline}'
                    : l10n.chatNotSent,
                style: t.label.copyWith(
                  color: c.pimentStrong,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () => vm.retry(o),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, DymTokenSize.touchMin),
                  foregroundColor: c.brandDeep,
                ),
                child: Text(l10n.retry),
              ),
              TextButton(
                onPressed: () => vm.discard(o),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, DymTokenSize.touchMin),
                  foregroundColor: c.textSecondary,
                ),
                child: Text(l10n.chatDiscard),
              ),
            ],
          ),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const new({
    required this.vm,
    required this.meta,
    this.url,
    this.bytes,
    this.mine = true,
  });

  final bool mine;
  final String? url;
  final Uint8List? bytes;
  final ChatViewModel vm;
  final Widget meta;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    Widget frame(Widget icon) => ColoredBox(
      color: c.tintVertTendre,
      child: Center(child: icon),
    );
    final placeholder = frame(
      Icon(
        Icons.photo_rounded,
        size: 32,
        color: c.brandDeep,
        semanticLabel: l10n.chatPhoto,
      ),
    );
    final local = bytes;
    final remote = url;
    final image = local != null
        ? Image.memory(local, fit: BoxFit.cover, semanticLabel: l10n.chatPhoto)
        : remote == null
        ? placeholder
        : Image(
            image: vm.service.mediaImage(remote),
            fit: BoxFit.cover,
            semanticLabel: l10n.chatPhoto,
            // Photo illisible : un cadre menthe, jamais une icône flottante.
            errorBuilder: (_, _, _) => placeholder,
          );
    return Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          child: SizedBox(width: 220, height: 165, child: image),
        ),
        const SizedBox(height: 2),
        meta,
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
    required this.meta,
    this.onAddToCart,
    this.onOpenProduct,
  });

  final ChatMessage message;
  final ChatViewModel vm;
  final Widget meta;
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
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DymTokenRadius.chip),
                child: SizedBox(
                  width: 80,
                  height: 80,
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
                    Text(item.name, style: t.title.copyWith(fontSize: 17)),
                    Wrap(
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
                    const SizedBox(height: 2),
                    meta,
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
    required this.meta,
  });

  final ChatMessage message;
  final ChatViewModel vm;
  final bool mine;
  final Widget meta;

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
        border: mine ? null : Border.all(color: c.hairline),
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
          meta,
        ],
      ),
    );
  }
}

/// Résumé d'un appel dans le fil.
class _CallBubble extends StatelessWidget {
  const new({required this.message, required this.meta});

  final ChatMessage message;
  final Widget meta;

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
          meta,
        ],
      ),
    );
  }
}

/// Réponses rapides, au-dessus du champ (défilement horizontal).
class _QuickReplies extends StatelessWidget {
  const new({required this.vm});

  final ChatViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return SizedBox(
      height: DymTokenSize.touchMin + DymTokenSpace.s2,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: DymTokenSpace.s2,
          vertical: 4,
        ),
        children: [
          for (final reply in vm.quickReplies)
            Padding(
              padding: const EdgeInsets.only(right: DymTokenSpace.s1),
              child: OutlinedButton(
                onPressed: () => vm.sendText(quickReplyText(l10n, reply)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, DymTokenSize.touchMin),
                  padding: const EdgeInsets.symmetric(
                    horizontal: DymTokenSpace.s3,
                  ),
                  foregroundColor: c.brandDeep,
                  backgroundColor: c.card,
                  side: BorderSide(color: c.hairline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DymTokenRadius.chip),
                  ),
                  textStyle: t.label.copyWith(fontWeight: FontWeight.w600),
                ),
                child: Text(quickReplyText(l10n, reply)),
              ),
            ),
        ],
      ),
    );
  }
}

enum _Attach { camera, gallery, products }

class _Composer extends StatefulWidget {
  const new({required this.vm, this.pickProducts});

  final ChatViewModel vm;
  final Future<List<String>?> Function(BuildContext context)? pickProducts;

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

  Future<void> _attach() async {
    final l10n = DymLocalizations.of(context);
    final c = context.dym.colors;
    Widget option(_Attach value, IconData icon, String label) => ListTile(
      minTileHeight: DymTokenSize.touchMin + 8,
      leading: CircleAvatar(
        backgroundColor: c.tintVertTendre,
        child: Icon(icon, color: c.brandDeep),
      ),
      title: Text(label),
      onTap: () => Navigator.pop(context, value),
    );
    final extra = commerceOptions(l10n, widget.vm);
    CommerceAction? commerce;
    final choice = await showModalBottomSheet<_Attach>(
      context: context,
      showDragHandle: true,
      backgroundColor: c.card,
      constraints: const BoxConstraints(maxWidth: DymTokenLayout.formMax),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.pickProducts != null)
              option(
                _Attach.products,
                Icons.sell_rounded,
                l10n.chatShareProduct,
              ),
            option(_Attach.camera, Icons.photo_camera_rounded, l10n.chatCamera),
            option(
              _Attach.gallery,
              Icons.photo_library_rounded,
              l10n.chatGallery,
            ),
            for (final (action, icon, label) in extra)
              ListTile(
                minTileHeight: DymTokenSize.touchMin + 8,
                leading: CircleAvatar(
                  backgroundColor: c.tintPlantainClair,
                  child: Icon(icon, color: c.brandDeep),
                ),
                title: Text(label),
                onTap: () {
                  commerce = action;
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
    if (commerce case final action? when mounted) {
      await runCommerceAction(context, widget.vm, action);
      return;
    }
    if (!mounted) return;
    switch (choice) {
      case _Attach.camera:
        await widget.vm.sendPhoto(PhotoSource.camera);
      case _Attach.gallery:
        await widget.vm.sendPhoto(PhotoSource.gallery);
      case _Attach.products:
        final ids = await widget.pickProducts!(context);
        if (ids != null && ids.isNotEmpty) await widget.vm.sendProducts(ids);
      case null:
        break;
    }
  }

  Future<void> _send() async {
    final text = _text.text;
    if (text.trim().isEmpty) return;
    _text.clear();
    await widget.vm.sendText(text);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final vm = widget.vm;
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
      padding: const EdgeInsets.all(DymTokenSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            tooltip: l10n.chatAttach,
            style: IconButton.styleFrom(minimumSize: const Size(48, 52)),
            onPressed: _attach,
            icon: Icon(Icons.add_circle_outline_rounded, color: c.brandDeep),
          ),
          Expanded(
            child: TextField(
              controller: _text,
              minLines: 1,
              maxLines: 4,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              onChanged: vm.textChanged,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: l10n.chatWriteHint,
                counterText: '',
                filled: true,
                fillColor: c.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DymTokenSpace.s3,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: DymTokenSpace.s1),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _text,
            builder: (context, value, _) {
              final empty = value.text.trim().isEmpty;
              final voice = empty && vm.canRecord;
              return IconButton.filled(
                tooltip: voice ? l10n.chatVoiceRecord : l10n.chatSend,
                style: IconButton.styleFrom(
                  backgroundColor: c.brand,
                  minimumSize: const Size(52, 52),
                ),
                onPressed: voice ? vm.startRecording : _send,
                icon: Icon(
                  voice ? Icons.mic_rounded : Icons.send_rounded,
                  color: c.onBrand,
                ),
              );
            },
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

/// Feuille « Partager un produit » : un ou plusieurs produits cochés
/// (« panier proposé »). Renvoie les identifiants choisis.
Future<List<String>?> showProductShareSheet(
  BuildContext context,
  List<ShareableProduct> products, {
  String? searchLabel,
}) => showModalBottomSheet<List<String>>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: context.dym.colors.card,
  constraints: const BoxConstraints(maxWidth: DymTokenLayout.formMax),
  builder: (_) =>
      ProductShareSheet(products: products, searchLabel: searchLabel),
);

/// Contenu de la feuille de partage (recherche, sélection multiple).
class ProductShareSheet extends StatefulWidget {
  const new({required this.products, super.key, this.searchLabel});

  final List<ShareableProduct> products;

  /// Libellé du champ de recherche (par défaut : « mes produits »).
  final String? searchLabel;

  @override
  State<ProductShareSheet> createState() => _ProductShareSheetState();
}

class _ProductShareSheetState extends State<ProductShareSheet> {
  String _query = '';
  final _picked = <String>[];

  void _toggle(String id) => setState(() {
    if (!_picked.remove(id)) _picked.add(id);
  });

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
        height: MediaQuery.sizeOf(context).height * 0.75,
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
                label: widget.searchLabel ?? l10n.chatSearchProducts,
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
                        horizontal: DymTokenSpace.s2,
                      ),
                      children: [
                        for (final p in shown)
                          _ShareRow(
                            product: p,
                            picked: _picked.contains(p.id),
                            onTap: () => _toggle(p.id),
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(DymTokenSpace.s3),
              child: DymButton(
                label: _picked.isEmpty
                    ? l10n.chatShare
                    : l10n.chatShareSelected(_picked.length),
                icon: Icons.send_rounded,
                onPressed: _picked.isEmpty
                    ? null
                    : () => Navigator.pop(context, List.of(_picked)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const new({required this.product, required this.picked, required this.onTap});

  final ShareableProduct product;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final p = product;
    return Padding(
      padding: const EdgeInsets.only(bottom: DymTokenSpace.s1),
      child: Material(
        color: picked ? c.tintVertTendre : Colors.transparent,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        child: InkWell(
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(DymTokenSpace.s1),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DymTokenRadius.chip),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: p.photo == null
                        ? _leaf(c)
                        : Image(
                            image: p.photo!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _leaf(c),
                          ),
                  ),
                ),
                const SizedBox(width: DymTokenSpace.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: t.title.copyWith(fontSize: 17)),
                      if (p.detail case final d?)
                        Text(d, style: t.body.copyWith(color: c.brandDeep)),
                    ],
                  ),
                ),
                Checkbox(
                  value: picked,
                  onChanged: (_) => onTap(),
                  activeColor: c.brand,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
