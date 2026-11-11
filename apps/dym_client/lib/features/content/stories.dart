import 'dart:async';

import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/content/feed_view.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
            // Photo de la story ; sinon photo de la boutique (vidéo, texte).
            final key = cover != null && !cover.isVideo && !cover.isText
                ? cover.mediaKey
                : g.store.coverKey;
            final text = cover != null && cover.isText && key == null;
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
                        border: Border.all(color: c.brand, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: text
                            ? storyBackground(cover.background)
                            : c.tintVertTendre,
                        backgroundImage: key == null
                            ? null
                            : widget.service.photo(key),
                        child: switch ((cover, key)) {
                          (_, null) when text => const Text(
                            'Aa',
                            style: TextStyle(color: Colors.white),
                          ),
                          (_, null) => Icon(
                            Icons.play_arrow_rounded,
                            color: c.brandDeep,
                          ),
                          _ => null,
                        },
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

/// Couleur d'un statut texte (#rrggbb), vert DYM par défaut.
Color storyBackground(String? hex) {
  final value = int.tryParse((hex ?? '').replaceFirst('#', ''), radix: 16);
  return value == null ? const Color(0xFF0B5D3B) : Color(0xFF000000 | value);
}

/// Durée d'affichage : photo 6 s ; texte selon sa longueur (5 à 12 s) ;
/// vidéo : sa durée réelle (au plus 60 s), 15 s tant qu'elle est inconnue.
Duration storyDuration(ContentItem story, {Duration? video}) {
  if (story.isVideo) {
    final d = video ?? const Duration(seconds: 15);
    return d > const Duration(seconds: 60) ? const Duration(seconds: 60) : d;
  }
  if (story.isText) {
    final ms = 4000 + 60 * (story.caption?.length ?? 0);
    return Duration(milliseconds: ms.clamp(5000, 12000));
  }
  return const Duration(seconds: 6);
}

/// Lecture des stories façon statuts : une barre par story de la boutique,
/// défilement automatique au temps imparti puis boutique suivante, fermeture
/// après la dernière ; toucher à droite / à gauche pour avancer / reculer,
/// appui long pour mettre en pause ; produit tagué ajouté au panier.
class StoryViewer extends StatefulWidget {
  const new({
    required this.service,
    required this.groups,
    required this.onClose,
    super.key,
    this.initial = 0,
    this.videoBuilder,
  });

  final ContentService service;
  final List<StoryGroup> groups;
  final int initial;
  final VoidCallback onClose;

  /// Lecteur vidéo de remplacement (tests) ; nul : lecteur réseau qui
  /// donne la durée réelle de la vidéo.
  final VideoBuilder? videoBuilder;

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late final List<ContentItem> _stories = [
    for (final g in widget.groups) ...g.stories,
  ];
  late final List<int> _groupOf = [
    for (final (i, g) in widget.groups.indexed) ...[
      for (var k = 0; k < g.stories.length; k++) i,
    ],
  ];
  late final _pages = PageController(
    initialPage: [
      for (final g in widget.groups.take(widget.initial)) g.stories.length,
    ].fold(0, (a, b) => a + b),
  );
  late final _progress = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _next();
    });
  late int _index = _pages.initialPage;
  bool _paused = false;
  bool _closed = false;
  String? _added;

  @override
  void initState() {
    super.initState();
    if (_stories.isNotEmpty) _start(_index);
  }

  @override
  void dispose() {
    _progress.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _start(int i, {Duration? video}) {
    final story = _stories[i];
    if (video == null) widget.service.viewed(story);
    // Vidéo du lecteur réseau : la barre attend sa durée réelle.
    final waitsForVideo =
        story.isVideo && widget.videoBuilder == null && video == null;
    _progress
      ..stop()
      ..value = 0
      ..duration = storyDuration(story, video: video);
    if (!waitsForVideo && !_paused) _progress.forward();
  }

  void _onVideoDuration(int i, Duration d) {
    if (!mounted || i != _index || d == Duration.zero) return;
    _start(i, video: d);
  }

  void _go(int i) {
    if (i < 0) {
      _start(_index); // première story : on la reprend
      return;
    }
    if (i >= _stories.length) {
      _close();
      return;
    }
    _pages.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _next() => _go(_index + 1);

  void _close() {
    if (_closed) return;
    _closed = true;
    _progress.stop();
    widget.onClose();
  }

  void _pause({required bool paused}) {
    setState(() => _paused = paused);
    if (paused) {
      _progress.stop();
    } else if (!_progress.isCompleted) {
      _progress.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final group = _stories.isEmpty ? null : widget.groups[_groupOf[_index]];
    final first = _stories.isEmpty ? 0 : _groupOf.indexOf(_groupOf[_index]);
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, box) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) =>
              d.localPosition.dx < box.maxWidth / 3 ? _go(_index - 1) : _next(),
          onLongPressStart: (_) => _pause(paused: true),
          onLongPressEnd: (_) => _pause(paused: false),
          child: Stack(
            children: [
              if (_stories.isEmpty)
                ColoredBox(color: c.brandDeep)
              else
                PageView.builder(
                  controller: _pages,
                  itemCount: _stories.length,
                  onPageChanged: (i) {
                    setState(() {
                      _index = i;
                      _added = null;
                    });
                    _start(i);
                  },
                  itemBuilder: _page,
                ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (group != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: AnimatedBuilder(
                          animation: _progress,
                          builder: (context, _) => Row(
                            children: [
                              for (var k = 0; k < group.stories.length; k++)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: LinearProgressIndicator(
                                      minHeight: 3,
                                      borderRadius: BorderRadius.circular(2),
                                      value: switch (first + k - _index) {
                                        < 0 => 1,
                                        0 => _progress.value,
                                        _ => 0,
                                      },
                                      color: Colors.white,
                                      backgroundColor: Colors.white30,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        const SizedBox(width: DymTokenSpace.s3),
                        Expanded(
                          child: Text(
                            group?.store.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.label.copyWith(
                              color: Colors.white,
                              shadows: const [Shadow(blurRadius: 6)],
                            ),
                          ),
                        ),
                        if (_paused)
                          const Icon(Icons.pause_rounded, color: Colors.white),
                        IconButton(
                          tooltip: l10n.actionClose,
                          onPressed: _close,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
        ),
      ),
    );
  }

  Widget _page(BuildContext context, int i) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final s = _stories[i];
    final product = s.products.firstOrNull;
    final key = s.mediaKey;
    final Widget media;
    if (s.isText || key == null) {
      final long = (s.caption?.length ?? 0) > 120;
      media = ColoredBox(
        color: storyBackground(s.background),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DymTokenSpace.s6),
            child: Text(
              s.caption ?? '',
              textAlign: TextAlign.center,
              style: t.display.copyWith(
                color: Colors.white,
                fontSize: long ? 24 : 32,
                height: 1.25,
              ),
            ),
          ),
        ),
      );
    } else if (s.isVideo) {
      final url = widget.service.mediaUrl(key);
      media = switch (widget.videoBuilder) {
        final builder? => builder(context, url, active: i == _index),
        null => _StoryVideo(
          url: url,
          active: i == _index,
          paused: _paused,
          onDuration: (d) => _onVideoDuration(i, d),
        ),
      };
    } else {
      media = Image(
        image: widget.service.photo(key),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => ColoredBox(color: c.brandDeep),
      );
    }
    final caption = s.caption;
    return Stack(
      fit: StackFit.expand,
      children: [
        media,
        Positioned(
          left: DymTokenSpace.s3,
          right: DymTokenSpace.s3,
          bottom: DymTokenSpace.s3,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!s.isText && caption != null)
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
                            _pause(paused: true);
                            final r = await widget.service.addToCart(
                              s,
                              product,
                            );
                            if (!mounted) return;
                            if (r.isOk) setState(() => _added = product.name);
                            _pause(paused: false);
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
  }
}

/// Vidéo d'une story : lue une fois (pas en boucle), en pause avec la story,
/// durée réelle remontée pour la barre de progression.
class _StoryVideo extends StatefulWidget {
  const new({
    required this.url,
    required this.active,
    required this.paused,
    required this.onDuration,
  });

  final Uri url;
  final bool active;
  final bool paused;
  final ValueChanged<Duration> onDuration;

  @override
  State<_StoryVideo> createState() => _StoryVideoState();
}

class _StoryVideoState extends State<_StoryVideo> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(widget.url);
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      _controller.initialize().then((_) async {
        if (!mounted) return;
        setState(() => _ready = true);
        if (widget.active) {
          widget.onDuration(_controller.value.duration);
          if (!widget.paused) await _controller.play();
        }
      }),
    );
  }

  @override
  void didUpdateWidget(_StoryVideo old) {
    super.didUpdateWidget(old);
    if (!_ready) return;
    if (widget.active && !old.active) {
      unawaited(_controller.seekTo(Duration.zero));
      widget.onDuration(_controller.value.duration);
    }
    final play = widget.active && !widget.paused;
    unawaited(play ? _controller.play() : _controller.pause());
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}
