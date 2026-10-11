import 'dart:async';

import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/content/feed_view.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Rangée des stories du quartier (C-HOME-07), en tête de l'accueil.
class StoriesRow extends StatefulWidget {
  const new({required this.service, required this.onOpen, super.key});

  final ContentService service;

  /// Groupes et index du groupe touché.
  final void Function(List<StoryGroup> groups, int index) onOpen;

  @override
  State<StoriesRow> createState() => _StoriesRowState();
}

class _StoriesRowState extends State<StoriesRow> {
  List<StoryGroup> _groups = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!await widget.service.enabled()) return;
    final groups = (await widget.service.stories()).valueOrNull;
    if (mounted && groups != null) setState(() => _groups = groups);
  }

  @override
  Widget build(BuildContext context) {
    if (_groups.isEmpty) return const SizedBox.shrink();
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.storiesTitle,
      child: SizedBox(
        height: 104,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _groups.length,
          separatorBuilder: (_, _) => const SizedBox(width: DymTokenSpace.s3),
          itemBuilder: (context, i) {
            final g = _groups[i];
            final cover = g.stories.firstOrNull;
            return InkWell(
              onTap: () => widget.onOpen(_groups, i),
              borderRadius: BorderRadius.circular(DymTokenRadius.tile),
              child: SizedBox(
                width: 76,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: c.plantain, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: c.tintVertTendre,
                        backgroundImage: cover == null || cover.isVideo
                            ? null
                            : widget.service.photo(cover.mediaKey),
                        child: cover == null || cover.isVideo
                            ? Icon(Icons.play_arrow_rounded, color: c.brandDeep)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      g.store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.label,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Lecture des stories : une page par story, glisser pour passer à la
/// boutique suivante ; produit tagué ajouté au panier.
class StoryViewer extends StatefulWidget {
  const new({
    required this.service,
    required this.groups,
    required this.onClose,
    super.key,
    this.initial = 0,
    this.videoBuilder = networkVideo,
  });

  final ContentService service;
  final List<StoryGroup> groups;
  final int initial;
  final VoidCallback onClose;
  final VideoBuilder videoBuilder;

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late final List<ContentItem> _stories = [
    for (final g in widget.groups) ...g.stories,
  ];
  late final _controller = PageController(
    initialPage: [
      for (final g in widget.groups.take(widget.initial)) g.stories.length,
    ].fold(0, (a, b) => a + b),
  );
  late int _index = _controller.initialPage;
  String? _added;

  @override
  void initState() {
    super.initState();
    if (_stories.isNotEmpty) widget.service.viewed(_stories[_index]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _stories.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              widget.service.viewed(_stories[i]);
            },
            itemBuilder: (context, i) {
              final s = _stories[i];
              final product = s.products.firstOrNull;
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (s.isVideo)
                    widget.videoBuilder(
                      context,
                      widget.service.mediaUrl(s.mediaKey),
                      active: i == _index,
                    )
                  else
                    Image(
                      image: widget.service.photo(s.mediaKey),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(color: c.brandDeep),
                    ),
                  Positioned(
                    left: DymTokenSpace.s3,
                    right: DymTokenSpace.s3,
                    bottom: DymTokenSpace.s3,
                    child: SafeArea(
                      top: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            s.store.name,
                            style: t.title.copyWith(
                              color: Colors.white,
                              shadows: const [Shadow(blurRadius: 6)],
                            ),
                          ),
                          if (s.caption case final caption?)
                            Text(
                              caption,
                              style: t.body.copyWith(
                                color: Colors.white,
                                shadows: const [Shadow(blurRadius: 6)],
                              ),
                            ),
                          if (product != null) ...[
                            const SizedBox(height: DymTokenSpace.s2),
                            DymButton(
                              label: l10n.storyAddProduct(product.name),
                              icon: Icons.add_shopping_cart_rounded,
                              onPressed: product.available
                                  ? () async {
                                      final r = await widget.service.addToCart(
                                        s,
                                        product,
                                      );
                                      if (mounted && r.isOk) {
                                        setState(() => _added = product.name);
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(DymTokenSpace.s2),
                  child: LinearProgressIndicator(
                    value: _stories.isEmpty
                        ? 0
                        : (_index + 1) / _stories.length,
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: l10n.actionClose,
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
                if (_added case final name?)
                  Padding(
                    padding: const EdgeInsets.all(DymTokenSpace.s3),
                    child: Text(
                      l10n.feedAdded(name),
                      textAlign: TextAlign.center,
                      style: t.body.copyWith(
                        color: Colors.white,
                        shadows: const [Shadow(blurRadius: 6)],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
