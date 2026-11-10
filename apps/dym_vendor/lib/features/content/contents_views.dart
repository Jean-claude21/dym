import 'dart:async';
import 'dart:typed_data';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Média choisi avant publication.
typedef ContentMedia = ({Uint8List bytes, String contentType, bool isVideo});

/// Contenus de la vendeuse (spec 020) : publier une story 24 h ou une vidéo
/// avec produits tagués (75), suivre ses statistiques, archiver, supprimer.
abstract interface class VendorContentService {
  /// Flag `shoppable_content` du pays de la boutique.
  Future<bool> enabled();

  Future<Result<ContentMedia?>> pick({
    required bool video,
    required PhotoSource source,
  });

  /// Produits publiés, à taguer.
  Future<Result<List<Product>>> products();

  Future<Result<ContentItem>> publish({
    required ContentKind kind,
    required ContentMedia media,
    String? caption,
    List<String> productIds = const [],
  });

  /// Statut texte (story écrite, sans média).
  Future<Result<ContentItem>> publishText({
    required String text,
    required String background,
    List<String> productIds = const [],
  });

  Future<Result<List<ContentItem>>> mine();

  Future<Result<void>> archive(String contentId);

  Future<Result<void>> delete(String contentId);

  /// Taux versé aux créatrices qui font vendre (spec 039), de la boutique ou
  /// d'un de ses produits.
  Future<Result<AffiliateRate>> affiliateRate({String? productId});

  /// Nouveau taux en points de base ; null : niveau au-dessus (pays pour la
  /// boutique, boutique pour un produit).
  Future<Result<AffiliateRate>> setAffiliateRate(
    int? rateBps, {
    String? productId,
  });

  ImageProvider photo(String objectKey);

  /// Aperçu d'une photo choisie, avant envoi.
  ImageProvider mediaPreview(ContentMedia media);
}

/// Implémentation Neon.
class NeonVendorContentService implements VendorContentService {
  new({
    required this._repository,
    required this._photos,
    required this._videos,
    required this._products,
    required this._config,
    required this._photo,
  });

  final ContentRepository _repository;
  final PhotoPicker _photos;
  final VideoPicker _videos;
  final Future<Result<List<Product>>> Function() _products;
  final Future<Result<CountryConfig>> Function() _config;
  final ImageProvider Function(String key) _photo;

  @override
  Future<bool> enabled() async =>
      (await _config()).valueOrNull?.isEnabled('shoppable_content') ?? false;

  @override
  Future<Result<ContentMedia?>> pick({
    required bool video,
    required PhotoSource source,
  }) async {
    if (video) {
      return (await _videos.pick(source)).map(
        (v) => v == null
            ? null
            : (bytes: v.bytes, contentType: v.contentType, isVideo: true),
      );
    }
    return (await _photos.pick(source)).map(
      (p) => p == null
          ? null
          : (bytes: p.bytes, contentType: p.contentType, isVideo: false),
    );
  }

  @override
  Future<Result<List<Product>>> products() async => (await _products()).map(
    (all) => [
      for (final p in all)
        if (p.status == ProductStatus.published) p,
    ],
  );

  @override
  Future<Result<ContentItem>> publish({
    required ContentKind kind,
    required ContentMedia media,
    String? caption,
    List<String> productIds = const [],
  }) async {
    final upload = await _repository.upload(
      media.bytes,
      contentType: media.contentType,
    );
    switch (upload) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final u):
        return await _repository.publish(
          upload: u,
          kind: kind,
          caption: caption,
          productIds: productIds,
        );
    }
  }

  @override
  Future<Result<ContentItem>> publishText({
    required String text,
    required String background,
    List<String> productIds = const [],
  }) => _repository.publishText(
    id: Uuid.v4(),
    text: text,
    background: background,
    productIds: productIds,
  );

  @override
  Future<Result<List<ContentItem>>> mine() => _repository.mine();

  @override
  Future<Result<void>> archive(String contentId) =>
      _repository.archive(contentId);

  @override
  Future<Result<void>> delete(String contentId) =>
      _repository.delete(contentId);

  @override
  Future<Result<AffiliateRate>> affiliateRate({String? productId}) =>
      _repository.affiliateRate(productId: productId);

  @override
  Future<Result<AffiliateRate>> setAffiliateRate(
    int? rateBps, {
    String? productId,
  }) => _repository.setAffiliateRate(rateBps, productId: productId);

  @override
  ImageProvider photo(String objectKey) => _photo(objectKey);

  @override
  ImageProvider mediaPreview(ContentMedia media) => MemoryImage(media.bytes);
}

// ------------------------------------------------------------------ publier

class PublishContentViewModel extends BaseViewModel {
  new({required this.service, this.media});

  final VendorContentService service;

  ContentKind kind = ContentKind.story;
  ContentMedia? media;
  List<Product> products = const [];
  final tagged = <String>{};
  String caption = '';
  bool publishing = false;
  Failure? failure;

  /// Statut écrit (story seulement) : texte sur un fond de couleur.
  bool textMode = false;
  String text = '';
  String background = storyColors.first;

  bool get canPublish =>
      !publishing &&
      (textMode
          ? kind == ContentKind.story && text.trim().isNotEmpty
          : media != null &&
                (kind == ContentKind.story || (media?.isVideo ?? false)));

  void setTextMode({required bool value}) {
    textMode = value && kind == ContentKind.story;
    notifyListeners();
  }

  void setText(String value) {
    text = value;
    notifyListeners();
  }

  void setBackground(String value) {
    background = value;
    notifyListeners();
  }

  Future<void> init() async {
    products = (await service.products()).valueOrNull ?? const [];
    notifyListeners();
  }

  void selectKind(ContentKind value) {
    kind = value;
    if (value == ContentKind.video) textMode = false;
    if (value == ContentKind.video && !(media?.isVideo ?? true)) media = null;
    notifyListeners();
  }

  Future<void> pick({required bool video, required PhotoSource source}) async {
    failure = null;
    switch (await service.pick(video: video, source: source)) {
      case Ok(value: final m?):
        media = m;
      case Ok(value: null):
        break;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  void toggleTag(String productId) {
    if (!tagged.remove(productId) && tagged.length < 5) tagged.add(productId);
    notifyListeners();
  }

  Future<bool> publish() async {
    final m = media;
    if (!canPublish || (!textMode && m == null)) return false;
    publishing = true;
    failure = null;
    notifyListeners();
    final result = textMode
        ? await service.publishText(
            text: text.trim(),
            background: background,
            productIds: tagged.toList(),
          )
        : await service.publish(
            kind: kind,
            media: m!,
            caption: caption.trim().isEmpty ? null : caption.trim(),
            productIds: tagged.toList(),
          );
    publishing = false;
    failure = result.failureOrNull;
    notifyListeners();
    return result.isOk;
  }
}

/// Fonds proposés pour un statut écrit.
const storyColors = [
  '#0b5d3b',
  '#c0392b',
  '#d35400',
  '#8e44ad',
  '#2c3e50',
  '#16a085',
];

Color _hex(String hex) =>
    Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));

/// Écran 75.
class PublishContentView extends StackedView<PublishContentViewModel> {
  const new({
    required this.service,
    required this.onBack,
    required this.onPublished,
    super.key,
    this.initialMedia,
  });

  final VendorContentService service;
  final VoidCallback onBack;
  final VoidCallback onPublished;

  /// Média déjà choisi (partage depuis la galerie du téléphone, galerie DYM).
  final ContentMedia? initialMedia;

  @override
  PublishContentViewModel viewModelBuilder(BuildContext context) =>
      PublishContentViewModel(service: service, media: initialMedia);

  @override
  void onViewModelReady(PublishContentViewModel viewModel) =>
      unawaited(viewModel.init());

  @override
  Widget builder(
    BuildContext context,
    PublishContentViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final media = vm.media;
    final story = vm.kind == ContentKind.story;
    final taggedProducts = [
      for (final p in vm.products)
        if (vm.tagged.contains(p.id)) p,
    ];
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(l10n.contentPublishTitle),
        leading: IconButton(
          tooltip: l10n.authBack,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: DymContentWidth(
          child: ListView(
            padding: EdgeInsets.all(DymLayout.gutter(context)),
            children: [
              SegmentedButton<ContentKind>(
                segments: [
                  ButtonSegment(
                    value: ContentKind.story,
                    label: Text(l10n.contentStory),
                  ),
                  ButtonSegment(
                    value: ContentKind.video,
                    label: Text(l10n.contentVideo),
                  ),
                ],
                selected: {vm.kind},
                onSelectionChanged: (s) => vm.selectKind(s.first),
              ),
              if (story) ...[
                const SizedBox(height: DymTokenSpace.s3),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.photo_rounded),
                      label: Text(l10n.contentMediaMode),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.text_fields_rounded),
                      label: Text(l10n.contentTextMode),
                    ),
                  ],
                  selected: {vm.textMode},
                  onSelectionChanged: (s) => vm.setTextMode(value: s.first),
                ),
              ],
              const SizedBox(height: DymTokenSpace.s3),
              if (vm.textMode) ...[
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DymTokenRadius.card),
                    child: ColoredBox(
                      color: _hex(vm.background),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(DymTokenSpace.s4),
                          child: Text(
                            vm.text.trim().isEmpty
                                ? l10n.contentTextHint
                                : vm.text,
                            textAlign: TextAlign.center,
                            style: t.title.copyWith(
                              color: Colors.white,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DymTokenSpace.s3),
                Wrap(
                  spacing: DymTokenSpace.s2,
                  children: [
                    for (final color in storyColors)
                      Semantics(
                        button: true,
                        selected: vm.background == color,
                        label: color,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => vm.setBackground(color),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: _hex(color),
                            child: vm.background == color
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: DymTokenSpace.s3),
                DymTextField(
                  label: l10n.contentTextLabel,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: vm.setText,
                ),
              ] else
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DymTokenRadius.card),
                    child: ColoredBox(
                      color: c.tintVertTendre,
                      child: media == null
                          ? Center(
                              child: Text(
                                story
                                    ? l10n.contentPickStory
                                    : l10n.contentPickVideo,
                                textAlign: TextAlign.center,
                                style: t.body.copyWith(color: c.brandDeep),
                              ),
                            )
                          : media.isVideo
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.movie_rounded,
                                    size: 56,
                                    color: c.brandDeep,
                                  ),
                                  Text(
                                    l10n.contentVideoReady,
                                    style: t.body.copyWith(color: c.brandDeep),
                                  ),
                                ],
                              ),
                            )
                          : Image(
                              image: service.mediaPreview(media),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const SizedBox(),
                            ),
                    ),
                  ),
                ),
              const SizedBox(height: DymTokenSpace.s3),
              if (!vm.textMode)
                Wrap(
                  spacing: DymTokenSpace.s2,
                  runSpacing: DymTokenSpace.s2,
                  children: [
                    DymButton(
                      label: l10n.contentFilm,
                      icon: Icons.videocam_rounded,
                      variant: DymButtonVariant.secondary,
                      expanded: false,
                      onPressed: () =>
                          vm.pick(video: true, source: PhotoSource.camera),
                    ),
                    if (story)
                      DymButton(
                        label: l10n.photoTake,
                        icon: Icons.photo_camera_rounded,
                        variant: DymButtonVariant.secondary,
                        expanded: false,
                        onPressed: () =>
                            vm.pick(video: false, source: PhotoSource.camera),
                      ),
                    DymButton(
                      label: l10n.contentGallery,
                      icon: Icons.photo_library_rounded,
                      variant: DymButtonVariant.secondary,
                      expanded: false,
                      onPressed: () =>
                          vm.pick(video: !story, source: PhotoSource.gallery),
                    ),
                  ],
                ),
              const SizedBox(height: DymTokenSpace.s3),
              Text(l10n.contentTagged, style: t.title),
              const SizedBox(height: DymTokenSpace.s2),
              if (vm.products.isEmpty)
                Text(
                  l10n.contentNoProducts,
                  style: t.body.copyWith(color: c.textSecondary),
                ),
              Wrap(
                spacing: DymTokenSpace.s2,
                runSpacing: DymTokenSpace.s2,
                children: [
                  for (final p in vm.products)
                    FilterChip(
                      label: Text(p.name),
                      selected: vm.tagged.contains(p.id),
                      onSelected: (_) => vm.toggleTag(p.id),
                    ),
                ],
              ),
              if (taggedProducts.length >= 5)
                Text(
                  l10n.contentTagLimit,
                  style: t.label.copyWith(color: c.textSecondary),
                ),
              const SizedBox(height: DymTokenSpace.s3),
              if (!vm.textMode)
                DymTextField(
                  label: l10n.contentCaption,
                  maxLength: 200,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (v) => vm.caption = v,
                ),
              if (vm.failure != null)
                Padding(
                  padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                  child: Text(
                    vm.failure is NetworkFailure
                        ? l10n.errorOffline
                        : l10n.errorGeneric,
                    style: t.body.copyWith(color: c.pimentStrong),
                  ),
                ),
              const SizedBox(height: DymTokenSpace.s3),
              DymButton(
                label: story
                    ? l10n.contentPublishStory
                    : l10n.contentPublishVideo,
                icon: Icons.send_rounded,
                loading: vm.publishing,
                onPressed: vm.canPublish
                    ? () async {
                        if (await vm.publish()) onPublished();
                      }
                    : null,
              ),
              const SizedBox(height: DymTokenSpace.s2),
              Text(
                story ? l10n.contentStoryHint : l10n.contentVideoHint,
                textAlign: TextAlign.center,
                style: t.label.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- mes contenus

class MyContentsViewModel extends BaseViewModel {
  new({required this.service});

  final VendorContentService service;

  List<ContentItem>? items;
  Failure? failure;

  /// Taux d'affiliation ; null : non chargé (réglage masqué).
  AffiliateRate? rate;
  bool savingRate = false;

  /// Choix proposés : minimum du pays, puis paliers jusqu'à 30 %.
  List<int> get rateChoices {
    final min = rate?.minRateBps;
    if (min == null) return const [];
    return {
      for (final step in const [0, 200, 500, 1000])
        if (min + step <= 3000) min + step,
    }.toList();
  }

  Future<void> chooseRate(int bps) async {
    final current = rate;
    if (current == null || savingRate || bps == current.effectiveBps) return;
    savingRate = true;
    notifyListeners();
    final result = await service.setAffiliateRate(
      bps == current.minRateBps ? null : bps,
    );
    if (result case Ok(:final value)) rate = value;
    savingRate = false;
    notifyListeners();
  }

  /// Produit au taux propre, en cours de réglage.
  Product? rateProduct;
  AffiliateRate? productRate;
  List<Product> catalog = const [];

  Future<void> pickRateProduct(Product product) async {
    rateProduct = product;
    productRate = null;
    notifyListeners();
    productRate = (await service.affiliateRate(productId: product.id))
        .valueOrNull;
    notifyListeners();
  }

  /// Taux du produit ; null : comme la boutique.
  Future<void> chooseProductRate(int? bps) async {
    final product = rateProduct;
    final current = productRate;
    if (product == null || current == null || savingRate) return;
    if (bps == current.rateBps) return;
    savingRate = true;
    notifyListeners();
    final result = await service.setAffiliateRate(bps, productId: product.id);
    if (result case Ok(:final value)) productRate = value;
    savingRate = false;
    notifyListeners();
  }

  Future<void> load() async {
    failure = null;
    rate ??= (await service.affiliateRate()).valueOrNull;
    if (rate != null && catalog.isEmpty) {
      catalog = (await service.products()).valueOrNull ?? const [];
    }
    switch (await service.mine()) {
      case Ok(:final value):
        items = value;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }

  Future<void> archive(ContentItem content) async {
    if ((await service.archive(content.id)).isOk) await load();
  }

  Future<void> delete(ContentItem content) async {
    if ((await service.delete(content.id)).isOk) await load();
  }
}

/// Mes contenus : statistiques (V-CONT-05), archiver, supprimer (V-CONT-06).
class MyContentsView extends StackedView<MyContentsViewModel> {
  const new({
    required this.service,
    required this.onBack,
    required this.onPublish,
    super.key,
  });

  final VendorContentService service;
  final VoidCallback onBack;

  /// Ouvre la publication ; la liste est relue au retour.
  final Future<void> Function() onPublish;

  @override
  MyContentsViewModel viewModelBuilder(BuildContext context) =>
      MyContentsViewModel(service: service);

  @override
  void onViewModelReady(MyContentsViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(
    BuildContext context,
    MyContentsViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final items = vm.items;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text(l10n.contentMine),
        leading: IconButton(
          tooltip: l10n.authBack,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await onPublish();
          await vm.load();
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.contentPublishTitle),
      ),
      body: SafeArea(
        child: DymContentWidth(
          child: items == null
              ? Center(
                  child: vm.failure == null
                      ? const CircularProgressIndicator()
                      : TextButton(onPressed: vm.load, child: Text(l10n.retry)),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    DymLayout.gutter(context),
                    DymTokenSpace.s2,
                    DymLayout.gutter(context),
                    96,
                  ),
                  children: [
                    if (vm.rate case final rate?)
                      Card(
                        margin: const EdgeInsets.only(bottom: DymTokenSpace.s3),
                        child: Padding(
                          padding: const EdgeInsets.all(DymTokenSpace.s3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.affiliateRateTitle, style: t.title),
                              const SizedBox(height: DymTokenSpace.s1),
                              Text(
                                l10n.affiliateRateHint(
                                  _percent(l10n, rate.minRateBps),
                                ),
                                style: t.label.copyWith(color: c.textSecondary),
                              ),
                              const SizedBox(height: DymTokenSpace.s2),
                              Wrap(
                                spacing: DymTokenSpace.s2,
                                runSpacing: DymTokenSpace.s2,
                                children: [
                                  for (final bps in vm.rateChoices)
                                    ChoiceChip(
                                      label: Text(_percent(l10n, bps)),
                                      selected: bps == rate.effectiveBps,
                                      onSelected: vm.savingRate
                                          ? null
                                          : (_) => vm.chooseRate(bps),
                                    ),
                                ],
                              ),
                              if (vm.catalog.isNotEmpty) ...[
                                const SizedBox(height: DymTokenSpace.s2),
                                PopupMenuButton<Product>(
                                  tooltip: l10n.affiliateProductRate,
                                  onSelected: vm.pickRateProduct,
                                  itemBuilder: (_) => [
                                    for (final p in vm.catalog)
                                      PopupMenuItem(
                                        value: p,
                                        child: Text(p.name),
                                      ),
                                  ],
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 48,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.sell_rounded,
                                          color: c.brandDeep,
                                        ),
                                        const SizedBox(width: DymTokenSpace.s2),
                                        Expanded(
                                          child: Text(
                                            vm.rateProduct?.name ??
                                                l10n.affiliateProductRate,
                                            style: t.body,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_drop_down_rounded,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (vm.productRate case final pr?)
                                  Wrap(
                                    spacing: DymTokenSpace.s2,
                                    runSpacing: DymTokenSpace.s2,
                                    children: [
                                      ChoiceChip(
                                        label: Text(l10n.affiliateLikeStore),
                                        selected: pr.rateBps == null,
                                        onSelected: vm.savingRate
                                            ? null
                                            : (_) => vm.chooseProductRate(null),
                                      ),
                                      for (final bps in vm.rateChoices)
                                        ChoiceChip(
                                          label: Text(_percent(l10n, bps)),
                                          selected: bps == pr.rateBps,
                                          onSelected: vm.savingRate
                                              ? null
                                              : (_) =>
                                                    vm.chooseProductRate(bps),
                                        ),
                                    ],
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(DymTokenSpace.s5),
                        child: Text(
                          l10n.contentNone,
                          textAlign: TextAlign.center,
                          style: t.body.copyWith(color: c.textSecondary),
                        ),
                      ),
                    for (final item in items)
                      Card(
                        margin: const EdgeInsets.only(bottom: DymTokenSpace.s2),
                        child: ListTile(
                          minTileHeight: 72,
                          leading: CircleAvatar(
                            backgroundColor: c.tintVertTendre,
                            backgroundImage:
                                item.mediaKey == null || item.isVideo
                                ? null
                                : service.photo(item.mediaKey!),
                            child: item.isText
                                ? const Text('Aa')
                                : item.isVideo
                                ? Icon(
                                    Icons.play_arrow_rounded,
                                    color: c.brandDeep,
                                  )
                                : null,
                          ),
                          title: Text(
                            [
                              if (item.kind == ContentKind.story)
                                l10n.contentStory
                              else
                                l10n.contentVideo,
                              if (item.status == 'archived')
                                l10n.contentArchived,
                            ].join(' · '),
                          ),
                          subtitle: Text(
                            l10n.contentStats(
                              item.viewCount,
                              item.clickCount,
                              item.likeCount,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            tooltip: l10n.contentActions,
                            onSelected: (action) => action == 'archive'
                                ? vm.archive(item)
                                : vm.delete(item),
                            itemBuilder: (_) => [
                              if (item.status == 'published')
                                PopupMenuItem(
                                  value: 'archive',
                                  child: Text(l10n.contentArchive),
                                ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(l10n.contentDelete),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Contenus en mémoire (tests, galerie).
/// Points de base en pourcentage lisible (250 → « 2,5 % »), affichage seul.
String _percent(DymLocalizations l10n, int bps) =>
    l10n.affiliatePercent(bps / 100);

class MemoryVendorContentService implements VendorContentService {
  new({
    this.isEnabled = true,
    this.catalog = const [],
    List<ContentItem>? contents,
    this.media,
    this.photoResolver,
  }) : _contents = contents ?? [];

  final bool isEnabled;
  final List<Product> catalog;
  final List<ContentItem> _contents;
  final ContentMedia? media;
  final ImageProvider Function(String key)? photoResolver;
  final gestures = <String>[];

  @override
  Future<bool> enabled() async => isEnabled;

  @override
  Future<Result<ContentMedia?>> pick({
    required bool video,
    required PhotoSource source,
  }) async => Ok(
    media ??
        (
          bytes: Uint8List(0),
          contentType: video ? 'video/mp4' : 'image/jpeg',
          isVideo: video,
        ),
  );

  @override
  Future<Result<List<Product>>> products() async => Ok(catalog);

  @override
  Future<Result<ContentItem>> publish({
    required ContentKind kind,
    required ContentMedia media,
    String? caption,
    List<String> productIds = const [],
  }) async {
    gestures.add('publish:${kind.name}:${productIds.join(',')}');
    final item = ContentItem(
      id: 'c${_contents.length + 1}',
      kind: kind,
      mediaKey: 'stores/s/contents/c.jpg',
      isVideo: media.isVideo,
      caption: caption,
      createdAt: DateTime.utc(2026, 10, 5, 9),
      store: const ContentStore(id: 's', name: "Étal d'Akossiwa"),
    );
    _contents.insert(0, item);
    return Ok(item);
  }

  @override
  Future<Result<ContentItem>> publishText({
    required String text,
    required String background,
    List<String> productIds = const [],
  }) async {
    gestures.add('publish:text:$background:${productIds.join(',')}');
    final item = ContentItem(
      id: 'c${_contents.length + 1}',
      kind: ContentKind.story,
      mediaKey: null,
      isVideo: false,
      isText: true,
      background: background,
      caption: text,
      createdAt: DateTime.utc(2026, 10, 5, 9),
      store: const ContentStore(id: 's', name: "Étal d'Akossiwa"),
    );
    _contents.insert(0, item);
    return Ok(item);
  }

  @override
  Future<Result<List<ContentItem>>> mine() async => Ok(List.of(_contents));

  @override
  Future<Result<void>> archive(String contentId) async {
    gestures.add('archive:$contentId');
    final i = _contents.indexWhere((c) => c.id == contentId);
    if (i >= 0) _contents[i] = _contents[i].copyWith(status: 'archived');
    return const Ok(null);
  }

  @override
  Future<Result<void>> delete(String contentId) async {
    gestures.add('delete:$contentId');
    _contents.removeWhere((c) => c.id == contentId);
    return const Ok(null);
  }

  AffiliateRate rate = const AffiliateRate(minRateBps: 300);
  final productRates = <String, int?>{};

  @override
  Future<Result<AffiliateRate>> affiliateRate({String? productId}) async =>
      Ok(_rateOf(productId));

  @override
  Future<Result<AffiliateRate>> setAffiliateRate(
    int? rateBps, {
    String? productId,
  }) async {
    gestures.add('rate:${productId ?? 'store'}:$rateBps');
    if (productId == null) {
      rate = AffiliateRate(minRateBps: rate.minRateBps, rateBps: rateBps);
    } else {
      productRates[productId] = rateBps;
    }
    return Ok(_rateOf(productId));
  }

  AffiliateRate _rateOf(String? productId) => productId == null
      ? rate
      : AffiliateRate(
          minRateBps: rate.minRateBps,
          storeRateBps: rate.rateBps,
          rateBps: productRates[productId],
        );

  @override
  ImageProvider photo(String objectKey) =>
      photoResolver?.call(objectKey) ?? MemoryImage(_pixel);

  @override
  ImageProvider mediaPreview(ContentMedia media) =>
      photoResolver?.call('preview') ??
      MemoryImage(media.bytes.isEmpty ? _pixel : media.bytes);
}

final _pixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);
