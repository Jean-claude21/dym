import 'dart:async';

import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/content/report_sheet.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:video_player/video_player.dart';

/// Lecteur d'un média vidéo ; remplaçable (tests, galerie).
typedef VideoBuilder = Widget Function(
  BuildContext context,
  Uri url, {
  required bool active,
});

/// Fil de vidéos shoppables (écran 74) : « Pour toi » (quartier) ou
/// « Boutiques suivies » ; produits tagués ajoutés au panier en un tap.
class FeedViewModel extends BaseViewModel {
  new({required this.service, this.productId});

  final ContentService service;

  /// Vidéos d'un produit (depuis sa fiche, C-CAT-12).
  final String? productId;

  bool following = false;
  List<ContentItem>? items;
  Failure? failure;
  CountryConfig? config;
  int index = 0;

  /// Produit tout juste ajouté (message).
  String? added;
  bool _loadingMore = false;
  bool _ended = false;

  Future<void> load() async {
    failure = null;
    items = null;
    _ended = false;
    notifyListeners();
    config ??= (await service.countryConfig()).valueOrNull;
    switch (await service.feed(following: following, productId: productId)) {
      case Ok(:final value):
        items = value;
        index = 0;
        if (value.isNotEmpty) service.viewed(value.first);
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  Future<void> selectTab({required bool following}) async {
    if (this.following == following) return;
    this.following = following;
    await load();
  }

  Future<void> onPage(int i) async {
    final list = items;
    if (list == null || i >= list.length) return;
    index = i;
    service.viewed(list[i]);
    notifyListeners();
    if (i >= list.length - 2 && !_loadingMore && !_ended) {
      _loadingMore = true;
      final more = await service.feed(
        following: following,
        before: list.last.createdAt,
        productId: productId,
      );
      if (more case Ok(:final value)) {
        if (value.isEmpty) _ended = true;
        items = [...list, ...value];
      }
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(ContentItem content) async {
    final liked = !content.liked;
    _replace(
      content.copyWith(
        liked: liked,
        likeCount: content.likeCount + (liked ? 1 : -1),
      ),
    );
    if (await service.like(content, like: liked) case Ok(:final value)) {
      _replace(content.copyWith(liked: liked, likeCount: value));
    }
  }

  Future<bool> add(ContentItem content, CatalogItem product) async {
    final result = await service.addToCart(content, product);
    added = result.isOk ? product.name : null;
    notifyListeners();
    return result.isOk;
  }

  Future<void> report(ContentItem content, ReportReason reason) =>
      service.report(ReportTarget.content, content.id, reason);

  void _replace(ContentItem content) {
    items = [
      for (final c in items ?? const <ContentItem>[])
        if (c.id == content.id) content else c,
    ];
    notifyListeners();
  }
}

/// Écran 74.
class FeedView extends StackedView<FeedViewModel> {
  const new({
    required this.service,
    super.key,
    this.productId,
    this.onBack,
    this.onOpenStore,
    this.videoBuilder = networkVideo,
  });

  final ContentService service;
  final String? productId;

  /// Présent quand le fil est ouvert depuis une fiche produit.
  final VoidCallback? onBack;
  final ValueChanged<String>? onOpenStore;
  final VideoBuilder videoBuilder;

  @override
  FeedViewModel viewModelBuilder(BuildContext context) =>
      FeedViewModel(service: service, productId: productId);

  @override
  void onViewModelReady(FeedViewModel viewModel) => unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, FeedViewModel viewModel, Widget? child) {
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final items = vm.items;
    final Widget body;
    if (items == null) {
      body = DiscoveryState(failure: vm.failure, onRetry: vm.load);
    } else if (items.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s5),
          child: Text(
            vm.following ? l10n.feedEmptyFollowing : l10n.feedEmpty,
            textAlign: TextAlign.center,
            style: context.dym.text.body.copyWith(color: Colors.white),
          ),
        ),
      );
    } else {
      body = PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: items.length,
        onPageChanged: vm.onPage,
        itemBuilder: (context, i) => _ContentPage(
          vm: vm,
          content: items[i],
          active: i == vm.index,
          videoBuilder: videoBuilder,
          onOpenStore: onOpenStore,
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: body),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DymTokenSpace.s2,
                  vertical: DymTokenSpace.s1,
                ),
                child: Row(
                  children: [
                    if (onBack case final back?)
                      IconButton(
                        tooltip: l10n.authBack,
                        onPressed: back,
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    if (productId == null)
                      Expanded(
                        child: Wrap(
                          spacing: DymTokenSpace.s2,
                          children: [
                            for (final (following, label) in [
                              (false, l10n.feedForYou),
                              (true, l10n.feedFollowing),
                            ])
                              _Tab(
                                label: label,
                                selected: vm.following == following,
                                onTap: () => vm.selectTab(following: following),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (vm.added case final name?)
            Positioned(
              left: DymTokenSpace.s3,
              right: DymTokenSpace.s3,
              top: 96,
              child: Semantics(
                liveRegion: true,
                child: Material(
                  color: context.dym.colors.brandDeep,
                  borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                  child: Padding(
                    padding: const EdgeInsets.all(DymTokenSpace.s2),
                    child: Text(
                      l10n.feedAdded(name),
                      textAlign: TextAlign.center,
                      style: context.dym.text.body.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DymTokenRadius.button),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: DymTokenSpace.s2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? context.dym.colors.brand : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Align(
            widthFactor: 1,
            child: Text(
              label,
              style: t.title.copyWith(
                color: selected ? Colors.white : Colors.white70,
                shadows: const [Shadow(blurRadius: 6)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentPage extends StatelessWidget {
  const new({
    required this.vm,
    required this.content,
    required this.active,
    required this.videoBuilder,
    this.onOpenStore,
  });

  final FeedViewModel vm;
  final ContentItem content;
  final bool active;
  final VideoBuilder videoBuilder;
  final ValueChanged<String>? onOpenStore;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final service = vm.service;
    final product = content.products.firstOrNull;
    final price = moneyOf(vm.config, product?.minPriceMinor);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (content.isVideo)
          videoBuilder(
            context,
            service.mediaUrl(content.mediaKey!),
            active: active,
          )
        else
          Image(
            image: service.photo(content.mediaKey!),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(color: c.brandDeep),
          ),
        Positioned(
          left: DymTokenSpace.s2,
          right: DymTokenSpace.s2,
          bottom: DymTokenSpace.s2,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  children: [
                    _RoundAction(
                      icon: content.liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: '${content.likeCount}',
                      tooltip: l10n.feedLike,
                      onTap: () => vm.toggleLike(content),
                    ),
                    const SizedBox(height: DymTokenSpace.s3),
                    _RoundAction(
                      icon: Icons.flag_outlined,
                      tooltip: l10n.reportAction,
                      onTap: () async {
                        final reason = await showReportSheet(context);
                        if (reason != null) await vm.report(content, reason);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: DymTokenSpace.s2),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(DymTokenRadius.card),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(DymTokenSpace.s3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          onTap: onOpenStore == null
                              ? null
                              : () => onOpenStore!(content.store.id),
                          child: Wrap(
                            spacing: DymTokenSpace.s2,
                            runSpacing: DymTokenSpace.s1,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                content.store.name,
                                style: t.title.copyWith(color: Colors.white),
                              ),
                              if (originOf(content.store.origin) case final o?)
                                DymOriginBadge(
                                  origin: o,
                                  label: originLabel(
                                    vm.config,
                                    content.store.origin,
                                    locale,
                                  ),
                                  dense: true,
                                ),
                            ],
                          ),
                        ),
                        if (content.caption case final caption?)
                          Text(
                            caption,
                            style: t.body.copyWith(color: Colors.white),
                          ),
                        if (product != null) ...[
                          const SizedBox(height: DymTokenSpace.s2),
                          Material(
                            color: c.card,
                            borderRadius: BorderRadius.circular(
                              DymTokenRadius.tile,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(DymTokenSpace.s2),
                              child: Row(
                                children: [
                                  if (product.photoKey case final key?)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        DymTokenRadius.tile / 2,
                                      ),
                                      child: Image(
                                        image: service.photo(key),
                                        width: 64,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const SizedBox(width: 64),
                                      ),
                                    ),
                                  const SizedBox(width: DymTokenSpace.s2),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: t.title.copyWith(fontSize: 16),
                                        ),
                                        Text(
                                          [
                                            ?product.unitLabel?.resolve(locale),
                                            ?price?.format(),
                                          ].join(' · '),
                                          style: t.body.copyWith(
                                            color: c.brandDeep,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DymButton(
                                    label: l10n.feedAdd,
                                    compact: true,
                                    expanded: false,
                                    onPressed: product.available
                                        ? () => vm.add(content, product)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black.withValues(alpha: 0.45),
    shape: const StadiumBorder(),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
          padding: const EdgeInsets.all(DymTokenSpace.s2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              if (label case final l?)
                Text(
                  l,
                  style: context.dym.text.label.copyWith(color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Lecteur réseau (`video_player`) : en boucle, lecture quand la page est
/// visible, pause d'un tap.
Widget networkVideo(BuildContext context, Uri url, {required bool active}) =>
    _NetworkVideo(url: url, active: active);

class _NetworkVideo extends StatefulWidget {
  const new({required this.url, required this.active});

  final Uri url;
  final bool active;

  @override
  State<_NetworkVideo> createState() => _NetworkVideoState();
}

class _NetworkVideoState extends State<_NetworkVideo> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(widget.url);
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      _controller.initialize().then((_) async {
        if (!mounted) return;
        await _controller.setLooping(true);
        setState(() => _ready = true);
        if (widget.active) await _controller.play();
      }),
    );
  }

  @override
  void didUpdateWidget(_NetworkVideo old) {
    super.didUpdateWidget(old);
    if (!_ready) return;
    unawaited(widget.active ? _controller.play() : _controller.pause());
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      onTap: () => unawaited(
        _controller.value.isPlaying ? _controller.pause() : _controller.play(),
      ),
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
