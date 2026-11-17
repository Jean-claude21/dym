import 'dart:async';

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
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

part 'chat_composer.dart';
part 'chat_groups.dart';
part 'chat_message_parts.dart';

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
    ChatMessage(deleted: true) => l10n.chatDeletedMessage,
    ChatMessage(kind: MessageKind.file, :final fileName) =>
      fileName ?? l10n.chatDocument,
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
      QuickReply.onMyWay => l10n.chatQuickOnMyWay,
      QuickReply.atTheDoor => l10n.chatQuickAtTheDoor,
      QuickReply.cantFind => l10n.chatQuickCantFind,
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
  MessageKind.file => Icons.description_rounded,
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
  const new({required this.name, required this.radius, this.icon});

  final String name;
  final double radius;

  /// Groupe (spec 112) : une icône au lieu de l'initiale.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final glyph = icon;
    return CircleAvatar(
      radius: radius,
      backgroundColor: c.tintVertTendre,
      child: glyph != null
          ? Icon(glyph, color: c.brandDeep, size: radius)
          : Text(
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
        if (vm.ready && vm.canCreateGroups)
          IconButton(
            tooltip: l10n.chatNewGroup,
            onPressed: () async {
              final title = await askGroupName(context);
              if (title == null) return;
              final id = await vm.createFamilyGroup(title);
              if (id != null) onOpen(id);
            },
            icon: Icon(Icons.group_add_rounded, color: c.brandDeep),
          ),
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
                        if (vm.conversations.isNotEmpty)
                          DymContentWidth.form(child: _FilterChips(vm: vm)),
                        if (vm.conversations.isEmpty)
                          DymStateView(
                            kind: DymStateKind.empty,
                            icon: Icons.chat_bubble_outline_rounded,
                            title: l10n.chatEmptyList,
                            message: '',
                          )
                        else if (shown.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(DymTokenSpace.s4),
                            child: Text(
                              l10n.chatFilterEmpty,
                              textAlign: TextAlign.center,
                              style: t.body.copyWith(color: c.textSecondary),
                            ),
                          ),
                        for (final conv in shown)
                          DymContentWidth.form(
                            child: _ConversationTile(
                              conversation: conv,
                              role: service.role,
                              now: now,
                              pinned: vm.pinned(conv),
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

/// Toutes · Non lues · Commandes.
class _FilterChips extends StatelessWidget {
  const new({required this.vm});

  final ConversationsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final filters = [
      (ConversationFilter.all, l10n.chatFilterAll),
      (ConversationFilter.unread, l10n.chatFilterUnread),
      if (vm.hasOrderThreads)
        (ConversationFilter.orders, l10n.chatFilterOrders),
      if (vm.hasGroups) (ConversationFilter.groups, l10n.chatFilterGroups),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
      child: Wrap(
        spacing: DymTokenSpace.s1,
        children: [
          for (final (filter, label) in filters)
            ChoiceChip(
              label: Text(label),
              selected: vm.filter == filter,
              showCheckmark: false,
              selectedColor: c.tintVertTendre,
              labelStyle: context.dym.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: vm.filter == filter ? c.brandDeep : c.textPrimary,
              ),
              onSelected: (_) => vm.setFilter(filter),
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
    this.pinned = false,
  });

  final Conversation conversation;
  final ChatRole role;
  final DateTime now;
  final VoidCallback onTap;

  /// Fil d'une commande en cours, en tête.
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final name = conversation.title(role);
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
                _Avatar(
                  name: name,
                  radius: 26,
                  icon: switch (conversation.kind) {
                    'family' => Icons.family_restroom_rounded,
                    'group_buy' => Icons.shopping_basket_rounded,
                    _ => null,
                  },
                ),
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
                      if (pinned)
                        Row(
                          children: [
                            Icon(
                              Icons.push_pin_rounded,
                              size: 14,
                              color: c.brandDeep,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              l10n.chatPinnedOrder,
                              style: t.label.copyWith(
                                color: c.brandDeep,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
                              // Groupe : « Awa : … » pour les autres.
                              switch ((conversation.isGroup, last)) {
                                (true, final m?)
                                    when !m.fromMe(role) &&
                                        (m.authorName ?? '').isNotEmpty =>
                                  '${m.authorName} : '
                                      '${chatPreview(l10n, m, role)}',
                                _ => chatPreview(l10n, last, role),
                              },
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
    final name = conv == null ? '' : conv.title(service.role);
    final openStore = vendor || conv == null || conv.isGroup
        ? null
        : onOpenStore;
    void openGroup() => Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => GroupInfoPage(vm: viewModel, onLeft: onBack),
      ),
    );
    final group = conv?.isGroup ?? false;
    final identity = Row(
      children: [
        _Avatar(
          name: name,
          radius: 20,
          icon: switch (conv?.kind) {
            'family' => Icons.family_restroom_rounded,
            'group_buy' => Icons.shopping_basket_rounded,
            _ => null,
          },
        ),
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
              // « Awa écrit… » remplace le sous-titre (spec 111).
              if (vm.typingRole != null)
                Text(
                  vm.typingName.isEmpty
                      ? l10n.chatTypingSomeone
                      : l10n.chatTyping(vm.typingName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.label.copyWith(
                    color: c.brandDeep,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else if (group)
                Text(
                  l10n.chatMembers(conv?.membersCount ?? 0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.label.copyWith(color: c.textSecondary),
                )
              else if (openStore != null)
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
              child: (conv?.isGroup ?? false)
                  ? InkWell(
                      borderRadius: BorderRadius.circular(DymTokenRadius.chip),
                      onTap: openGroup,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: DymTokenSize.touchMin,
                        ),
                        child: identity,
                      ),
                    )
                  : openStore == null
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
            // Appels : à deux seulement.
            if (service.calls case final calls?
                when !(conv?.isGroup ?? false)) ...[
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
            if (vm.ready)
              PopupMenuButton<String>(
                tooltip: l10n.chatMoreOptions,
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'group') openGroup();
                  if (value == 'search') vm.openSearch();
                  if (value == 'media') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(builder: (_) => ChatMediaPage(vm: vm)),
                    );
                  }
                },
                itemBuilder: (_) => [
                  if (conv?.isGroup ?? false)
                    PopupMenuItem(
                      value: 'group',
                      child: ListTile(
                        leading: const Icon(Icons.groups_rounded),
                        title: Text(l10n.chatGroupInfo),
                      ),
                    ),
                  PopupMenuItem(
                    value: 'search',
                    child: ListTile(
                      leading: const Icon(Icons.search_rounded),
                      title: Text(l10n.chatSearchInThread),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'media',
                    child: ListTile(
                      leading: const Icon(Icons.perm_media_outlined),
                      title: Text(l10n.chatMediaTitle),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
    final searchHeader = Material(
      color: c.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, DymTokenSpace.s2, 4),
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.chatClose,
              onPressed: vm.closeSearch,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: TextField(
                autofocus: true,
                onChanged: vm.setSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.chatSearchInThread,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
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
        child: vm.searching
            ? Column(
                children: [
                  searchHeader,
                  Divider(height: 1, color: c.hairline),
                  Expanded(child: _SearchResults(vm: vm)),
                ],
              )
            : Column(
                children: [
                  header,
                  Divider(height: 1, color: c.hairline),
                  if (order != null)
                    _OrderBanner(
                      order: order,
                      total: vm.activeOrderTotal,
                      onOpen: openOrder == null
                          ? null
                          : () => openOrder(order.id),
                    ),
                  if (vm.offline) const _OfflineNote(),
                  Expanded(
                    child: entries.isEmpty
                        ? _EmptyThread(
                            name: name,
                            vendor: vendor,
                            orderThread: conv?.isOrderThread ?? false,
                            group: conv?.isGroup ?? false,
                          )
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
                                ChatNewEntry(:final count) =>
                                  _NewMessagesSeparator(count: count),
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
                        switch (vm.sendFailure) {
                          NetworkFailure() => l10n.errorOffline,
                          ValidationFailure(message: 'too_large') =>
                            l10n.chatDocumentTooLarge,
                          ValidationFailure(message: 'unsupported') =>
                            l10n.chatDocumentUnsupported,
                          ServerFailure(message: final m)
                              when m.contains('too_late') =>
                            l10n.chatDeleteTooLate,
                          _ => l10n.chatSendFailed,
                        },
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
                  // Fil d'une commande terminée (spec 109) : lecture seule.
                  if (conv?.closed ?? false)
                    Padding(
                      padding: const EdgeInsets.all(DymTokenSpace.s3),
                      child: Text(
                        l10n.chatThreadClosed,
                        textAlign: TextAlign.center,
                        style: t.label.copyWith(color: c.textSecondary),
                      ),
                    )
                  else ...[
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
  const new({
    required this.name,
    required this.vendor,
    this.orderThread = false,
    this.group = false,
  });

  final String name;
  final bool vendor;

  /// Groupe (spec 112).
  final bool group;

  /// Fil d'une commande (spec 109).
  final bool orderThread;

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
              group
                  ? l10n.chatEmptyGroup
                  : orderThread
                  ? l10n.chatEmptyOrderThread
                  : name.isEmpty
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
    this.delivered = false,
    this.pending = false,
  });

  final String time;
  final bool onBrand;
  final bool mine;
  final bool seen;

  /// Reçu par l'app de l'autre personne (✓✓ sans couleur).
  final bool delivered;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final color = onBrand ? c.onBrand : c.textSecondary;
    final status = pending
        ? l10n.chatSending
        : seen
        ? l10n.chatSeen
        : delivered
        ? l10n.chatDelivered
        : l10n.chatSent;
    // Lu : ✓✓ en couleur (plantain sur la bulle verte, indigo ailleurs).
    final tick = seen ? (onBrand ? c.plantain : c.indigo) : color;
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
                : (seen || delivered
                      ? Icons.done_all_rounded
                      : Icons.done_rounded),
            size: 16,
            color: tick,
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
    final conv = vm.thread?.conversation;
    final mine = message.fromMe(vm.role);
    final clock = chatClock(context, message.createdAt);
    Widget meta({bool onBrand = false}) => _Meta(
      time: clock,
      onBrand: onBrand,
      mine: mine,
      seen: entry.seen,
      delivered: entry.delivered,
    );
    // Citation et « Transféré » : dans la bulle de texte, au-dessus sinon.
    final textKind =
        message.kind == MessageKind.text || message.kind == MessageKind.unknown;
    final top = <Widget>[
      if (message.forwarded) _ForwardedLabel(onBrand: mine && textKind),
      if (message.replyTo case final quote?)
        _QuoteBlock(quote: quote, vm: vm, onBrand: mine && textKind),
    ];
    final content = message.deleted
        ? _DeletedBubble(mine: mine, meta: meta())
        : switch (message.kind) {
            MessageKind.image => _Photo(
              url: vm.mediaUrl(message.id),
              vm: vm,
              meta: meta(),
              mine: mine,
            ),
            MessageKind.video => _VideoBubble(
              message: message,
              vm: vm,
              mine: mine,
              meta: meta(),
            ),
            MessageKind.file => _FileBubble(
              name: message.fileName ?? l10n.chatDocument,
              size: message.fileSize,
              mine: mine,
              meta: meta(),
              onOpen:
                  vm.service.opener == null || vm.mediaUrl(message.id) == null
                  ? null
                  : () => unawaited(vm.openDocument(message)),
            ),
            MessageKind.audio => Column(
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _AudioBubble(
                  message: message,
                  vm: vm,
                  mine: mine,
                  meta: meta(),
                ),
                TranscriptLine(message: message, vm: vm),
              ],
            ),
            MessageKind.call => _CallBubble(message: message, meta: meta()),
            // Chat de commerce (spec 099).
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
              top: top,
            ),
          };
    final framed = !message.deleted && !textKind && top.isNotEmpty
        ? Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: top,
                ),
              ),
              content,
            ],
          )
        : content;
    final withReactions = message.reactions.isEmpty
        ? framed
        : Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              framed,
              _ReactionsRow(message: message, vm: vm),
            ],
          );
    // Glisser pour répondre, appui long pour réagir et agir (spec 111).
    final interactive = _SwipeToReply(
      enabled: !message.deleted && !(conv?.closed ?? false),
      onReply: () => vm.startReply(message),
      child: GestureDetector(
        onLongPress: conv?.closed ?? false
            ? null
            : () => unawaited(_messageActions(context, vm, message)),
        child: withReactions,
      ),
    );
    // Fil à plusieurs (spec 109) : le nom de l'auteur au-dessus de sa bulle.
    final many = (conv?.isOrderThread ?? false) || (conv?.isGroup ?? false);
    final named = !mine && !entry.continued && many;
    return _Placed(
      mine: mine,
      continued: entry.continued,
      child: named
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: DymTokenSpace.s1,
                    bottom: 2,
                  ),
                  child: Text(
                    message.authorName ?? conv!.authorName(message.authorRole),
                    style: context.dym.text.label.copyWith(
                      color: context.dym.colors.brandDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                interactive,
              ],
            )
          : interactive,
    );
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
    this.top = const [],
  });

  final String text;
  final bool mine;
  final bool continued;
  final Widget meta;
  final bool faded;

  /// « Transféré » et citation, dans la bulle.
  final List<Widget> top;

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
            if (top.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: top,
              ),
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
        top: [
          if (o.replyTo case final r?)
            _QuoteBlock(
              quote: MessageQuote(
                id: r.id,
                authorRole: r.authorRole,
                kind: r.kind,
                body: r.body,
              ),
              vm: vm,
              onBrand: true,
            ),
        ],
      ),
      MessageKind.file when o.document != null => _FileBubble(
        name: o.document!.name,
        size: o.document!.size,
        mine: true,
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
    final full = local != null
        ? MemoryImage(local)
        : remote == null
        ? null
        : vm.service.mediaImage(remote);
    return Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          child: SizedBox(
            width: 220,
            height: 165,
            child: full == null
                ? image
                : Semantics(
                    button: true,
                    label: l10n.chatFullScreen,
                    child: InkWell(
                      onTap: () => unawaited(_openPhoto(context, full)),
                      child: image,
                    ),
                  ),
          ),
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

/// Vocal : lecture et pause, onde qui avance, temps écoulé, vitesse.
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

  /// Onde stable propre à chaque vocal (dérivée de son identifiant).
  static List<double> _shape(String id) {
    var seed = id.hashCode;
    return [
      for (var i = 0; i < 32; i++)
        () {
          seed = (seed * 1103515245 + 12345) & 0x7fffffff;
          return 0.2 + (seed % 80) / 100;
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final current = vm.playingId == message.id;
    final playing = current && !vm.playPaused;
    final total = Duration(milliseconds: message.durationMs ?? 0);
    final shown = current ? vm.playPosition : total;
    return Container(
      width: 270,
      padding: const EdgeInsets.fromLTRB(4, 4, DymTokenSpace.s2, 6),
      decoration: BoxDecoration(
        color: mine ? c.tintVertTendre : c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        border: mine ? null : Border.all(color: c.hairline),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: playing ? l10n.chatVoicePause : l10n.chatVoicePlay,
            onPressed: vm.mediaUrl(message.id) == null
                ? null
                : () => vm.togglePlay(message),
            icon: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: c.brandDeep,
              size: 32,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Wave(
                  levels: _shape(message.id),
                  color: c.brandDeep,
                  progress: vm.progressOf(message),
                ),
                Row(
                  children: [
                    Text(
                      _clockOf(shown),
                      style: t.label.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Spacer(),
                    meta,
                  ],
                ),
              ],
            ),
          ),
          if (current)
            TextButton(
              onPressed: vm.cycleSpeed,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, DymTokenSize.touchMin),
                foregroundColor: c.brandDeep,
              ),
              child: Semantics(
                label: l10n.chatVoiceSpeed,
                child: Text(
                  '${vm.playSpeed == 1.5 ? '1,5' : vm.playSpeed.toInt()}×',
                  style: t.label.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
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
