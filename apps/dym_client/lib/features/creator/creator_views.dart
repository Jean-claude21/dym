import 'dart:async';

import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/creator/creator_service.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Erreurs du studio.
enum CreatorError { name, media, offline, generic }

CreatorError creatorErrorOf(Failure f) => switch (f) {
  NetworkFailure() => CreatorError.offline,
  ValidationFailure(message: 'invalid_name') => CreatorError.name,
  ValidationFailure(message: 'invalid_media') => CreatorError.media,
  _ => CreatorError.generic,
};

String creatorErrorLabel(DymLocalizations l10n, CreatorError e) => switch (e) {
  CreatorError.name => l10n.creatorErrorName,
  CreatorError.media => l10n.creatorErrorMedia,
  CreatorError.offline => l10n.errorOffline,
  CreatorError.generic => l10n.errorGeneric,
};

class CreatorStudioViewModel extends BaseViewModel {
  new({required this.service});

  final CreatorService service;
  CreatorProfile? profile;
  List<ContentItem> posts = const [];
  bool ready = false;
  Failure? failure;
  CreatorError? problem;
  bool acting = false;

  Future<void> load() async {
    failure = null;
    setBusy(true);
    switch (await service.profile()) {
      case Ok(:final value):
        profile = value;
        if (value != null) {
          posts = (await service.mine()).valueOrNull ?? const [];
        }
        ready = true;
      case Err(failure: final f):
        failure = f;
    }
    setBusy(false);
  }

  Future<bool> become(String name, String bio) async {
    if (acting) return false;
    acting = true;
    problem = null;
    notifyListeners();
    final result = await service.become(
      name,
      bio: bio.trim().isEmpty ? null : bio,
    );
    acting = false;
    switch (result) {
      case Ok(:final value):
        profile = value;
      case Err(failure: final f):
        problem = creatorErrorOf(f);
    }
    notifyListeners();
    return result.isOk;
  }

  Future<void> archive(ContentItem post) async {
    if (await service.archive(post.id) case Ok()) {
      posts = [
        for (final p in posts)
          if (p.id != post.id) p,
      ];
      notifyListeners();
    }
  }
}

/// « Créer et partager » : devenir créatrice, publier, ses posts.
class CreatorStudioView extends StackedView<CreatorStudioViewModel> {
  const new({
    required this.service,
    required this.onBack,
    required this.onCompose,
    super.key,
  });

  final CreatorService service;
  final VoidCallback onBack;

  /// Nouveau post ; `true` s'il est publié.
  final Future<bool> Function() onCompose;

  @override
  CreatorStudioViewModel viewModelBuilder(BuildContext context) =>
      CreatorStudioViewModel(service: service);

  @override
  void onViewModelReady(CreatorStudioViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(
    BuildContext context,
    CreatorStudioViewModel vm,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final Widget body;
    if (!vm.ready) {
      body = DiscoveryState(
        failure: vm.isBusy ? null : vm.failure,
        onRetry: vm.load,
      );
    } else if (vm.profile == null) {
      body = _Become(vm: vm);
    } else {
      final profile = vm.profile!;
      body = RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            DymContentWidth.form(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: c.tintVertTendre,
                  child: Icon(Icons.person_pin_rounded, color: c.brandDeep),
                ),
                title: Text(profile.displayName, style: t.title),
                subtitle: profile.bio == null ? null : Text(profile.bio!),
              ),
            ),
            DymContentWidth.form(
              child: DymButton(
                label: l10n.creatorNewPost,
                icon: Icons.add_a_photo_rounded,
                onPressed: () async {
                  if (await onCompose()) await vm.load();
                },
              ),
            ),
            const SizedBox(height: DymTokenSpace.s4),
            DymContentWidth.form(
              child: DymSectionHeader(title: l10n.creatorMyPosts),
            ),
            if (vm.posts.isEmpty)
              DymContentWidth.form(
                child: Text(
                  l10n.creatorNoPost,
                  style: t.body.copyWith(color: c.textSecondary),
                ),
              ),
            for (final p in vm.posts)
              DymContentWidth.form(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox.square(
                      dimension: 56,
                      child: p.isVideo || p.mediaKey == null
                          ? ColoredBox(
                              color: c.tintVertTendre,
                              child: Icon(
                                Icons.play_circle_rounded,
                                color: c.brandDeep,
                              ),
                            )
                          : Image(
                              image: service.photo(p.mediaKey!),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  title: Text(
                    p.caption ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    l10n.creatorPostStats(
                      p.viewCount,
                      p.clickCount,
                      p.products.length,
                    ),
                    style: t.label.copyWith(color: c.textSecondary),
                  ),
                  trailing: IconButton(
                    tooltip: l10n.creatorArchive,
                    onPressed: () => vm.archive(p),
                    icon: const Icon(Icons.archive_rounded),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(title: l10n.creatorTitle, onBack: onBack),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _Become extends StatefulWidget {
  const new({required this.vm});

  final CreatorStudioViewModel vm;

  @override
  State<_Become> createState() => _BecomeState();
}

class _BecomeState extends State<_Become> {
  final _name = TextEditingController();
  final _bio = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final t = context.dym.text;
    final vm = widget.vm;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        DymContentWidth.form(child: Text(l10n.creatorIntro, style: t.body)),
        const SizedBox(height: DymTokenSpace.s3),
        DymContentWidth.form(
          child: DymTextField(
            label: l10n.creatorName,
            hint: l10n.creatorNameHint,
            controller: _name,
            maxLength: 40,
          ),
        ),
        DymContentWidth.form(
          child: DymTextField(
            label: l10n.creatorBio,
            controller: _bio,
            maxLength: 200,
            maxLines: 3,
          ),
        ),
        if (vm.problem case final p?)
          DymContentWidth.form(
            child: CartIssue(label: creatorErrorLabel(l10n, p)),
          ),
        const SizedBox(height: DymTokenSpace.s3),
        DymContentWidth.form(
          child: DymButton(
            label: l10n.creatorBecome,
            icon: Icons.auto_awesome_rounded,
            loading: vm.acting,
            onPressed: vm.acting
                ? null
                : () => vm.become(_name.text, _bio.text),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- nouveau post

class ComposeViewModel extends BaseViewModel {
  new({required this.service});

  final CreatorService service;
  CreatorMedia? media;

  /// Légende saisie (suivie sans reconstruire l'écran).
  String caption = '';
  List<ContentCategory> categories = const [];
  String? categoryId;

  /// Catégorie proposée par l'IA (affichée, choisie si la créatrice valide).
  String? suggestedSlug;
  bool suggesting = false;
  final tagged = <CatalogItem>[];

  /// Ingrédients génériques de la recette (spec 038).
  List<ShoppingItem> ingredients = const [];
  bool findingIngredients = false;
  List<CatalogItem> results = const [];
  bool publishing = false;
  CreatorError? problem;

  static const maxTags = 5;

  Future<void> load() async {
    categories = (await service.categories()).valueOrNull ?? const [];
    notifyListeners();
  }

  Future<void> pick({required bool video, required PhotoSource source}) async {
    switch (await service.pick(video: video, source: source)) {
      case Ok(value: final m?):
        media = m;
        problem = null;
      case Ok():
        break;
      case Err(failure: final f):
        problem = creatorErrorOf(f);
    }
    notifyListeners();
  }

  void choose(String? id) {
    categoryId = id;
    notifyListeners();
  }

  /// L'IA propose une catégorie à partir de la légende.
  Future<void> suggest() async {
    if (suggesting) return;
    suggesting = true;
    notifyListeners();
    suggestedSlug = await service.suggestCategory(caption);
    suggesting = false;
    final match = categories.where((c) => c.slug == suggestedSlug).firstOrNull;
    if (match != null && categoryId == null) categoryId = match.id;
    notifyListeners();
  }

  void addIngredient(String label) {
    final value = label.trim();
    if (value.isEmpty || ingredients.length >= 15) return;
    ingredients = [...ingredients, ShoppingItem(label: value)];
    notifyListeners();
  }

  void removeIngredient(int index) {
    ingredients = [...ingredients]..removeAt(index);
    notifyListeners();
  }

  /// L'IA repère les ingrédients dans la légende ; ils s'ajoutent à la liste.
  Future<void> findIngredients() async {
    if (findingIngredients) return;
    findingIngredients = true;
    notifyListeners();
    final found = await service.suggestIngredients(caption);
    final known = {for (final i in ingredients) i.label.toLowerCase()};
    ingredients = [
      ...ingredients,
      for (final i in found)
        if (!known.contains(i.label.toLowerCase())) i,
    ].take(15).toList();
    findingIngredients = false;
    notifyListeners();
  }

  Future<void> search(String text) async {
    if (text.trim().length < 2) return;
    results = (await service.searchProducts(text)).valueOrNull ?? const [];
    notifyListeners();
  }

  void toggleTag(CatalogItem item) {
    if (tagged.any((p) => p.id == item.id)) {
      tagged.removeWhere((p) => p.id == item.id);
    } else if (tagged.length < maxTags) {
      tagged.add(item);
    }
    notifyListeners();
  }

  /// `true` : publié.
  Future<bool> publish() async {
    final m = media;
    if (m == null || publishing) return false;
    publishing = true;
    problem = null;
    notifyListeners();
    final chosen = categories.where((c) => c.id == categoryId).firstOrNull;
    final source = chosen == null
        ? 'default'
        : (chosen.slug == suggestedSlug ? 'ai' : 'chosen');
    final result = await service.publish(
      media: m,
      caption: caption.trim().isEmpty ? null : caption.trim(),
      categoryId: chosen?.id,
      categorySource: source,
      productIds: [for (final p in tagged) p.id],
      ingredients: ingredients,
    );
    publishing = false;
    if (result case Err(:final failure)) problem = creatorErrorOf(failure);
    notifyListeners();
    return result.isOk;
  }
}

/// Nouveau post : média, légende, catégorie, produits tagués.
class ComposePostView extends StackedView<ComposeViewModel> {
  const new({
    required this.service,
    required this.onBack,
    required this.onPublished,
    super.key,
  });

  final CreatorService service;
  final VoidCallback onBack;
  final VoidCallback onPublished;

  @override
  ComposeViewModel viewModelBuilder(BuildContext context) =>
      ComposeViewModel(service: service);

  @override
  void onViewModelReady(ComposeViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, ComposeViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final media = vm.media;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(title: l10n.creatorNewPost, onBack: onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  DymContentWidth.form(
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          DymTokenRadius.card,
                        ),
                        child: media == null
                            ? ColoredBox(
                                color: c.tintVertTendre,
                                child: Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 56,
                                  color: c.brandDeep,
                                ),
                              )
                            : media.isVideo
                            ? ColoredBox(
                                color: c.brandDeep,
                                child: Icon(
                                  Icons.movie_rounded,
                                  size: 56,
                                  color: c.onBrand,
                                ),
                              )
                            : Image(
                                image: service.preview(media),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s2),
                  DymContentWidth.form(
                    child: Wrap(
                      spacing: DymTokenSpace.s2,
                      runSpacing: DymTokenSpace.s2,
                      children: [
                        for (final (video, source, icon, label) in [
                          (
                            false,
                            PhotoSource.camera,
                            Icons.photo_camera_rounded,
                            l10n.photoTake,
                          ),
                          (
                            false,
                            PhotoSource.gallery,
                            Icons.photo_library_rounded,
                            l10n.photoFromGallery,
                          ),
                          (
                            true,
                            PhotoSource.gallery,
                            Icons.video_library_rounded,
                            l10n.creatorPickVideo,
                          ),
                        ])
                          ActionChip(
                            avatar: Icon(icon, color: c.brandDeep),
                            label: Text(label),
                            onPressed: () =>
                                vm.pick(video: video, source: source),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  DymContentWidth.form(
                    child: DymTextField(
                      label: l10n.creatorCaption,
                      hint: l10n.creatorCaptionHint,
                      maxLength: 200,
                      maxLines: 3,
                      onChanged: (value) => vm.caption = value,
                    ),
                  ),
                  DymContentWidth.form(
                    child: DymSectionHeader(
                      title: l10n.creatorCategory,
                      actionLabel: vm.suggesting
                          ? null
                          : l10n.creatorSuggestCategory,
                      onAction: vm.suggesting ? null : vm.suggest,
                    ),
                  ),
                  DymContentWidth.form(
                    child: Wrap(
                      spacing: DymTokenSpace.s2,
                      runSpacing: DymTokenSpace.s2,
                      children: [
                        for (final cat in vm.categories)
                          ChoiceChip(
                            label: Text(cat.label.resolve(locale)),
                            avatar: cat.slug == vm.suggestedSlug
                                ? const Icon(Icons.auto_awesome_rounded)
                                : null,
                            selected: vm.categoryId == cat.id,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            onSelected: (on) => vm.choose(on ? cat.id : null),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.creatorCategoryHint,
                    style: t.label.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  DymContentWidth.form(
                    child: DymSectionHeader(
                      title: l10n.recipeIngredients,
                      actionLabel: vm.findingIngredients
                          ? null
                          : l10n.recipeFindIngredients,
                      onAction: vm.findingIngredients
                          ? null
                          : vm.findIngredients,
                    ),
                  ),
                  DymContentWidth.form(
                    child: Wrap(
                      spacing: DymTokenSpace.s2,
                      runSpacing: DymTokenSpace.s2,
                      children: [
                        for (final (i, item) in vm.ingredients.indexed)
                          InputChip(
                            label: Text('${item.label} × ${item.quantity}'),
                            onDeleted: () => vm.removeIngredient(i),
                            deleteButtonTooltipMessage: l10n.shoppingRemoveItem(
                              item.label,
                            ),
                          ),
                      ],
                    ),
                  ),
                  DymContentWidth.form(
                    child: DymTextField(
                      label: l10n.recipeAddIngredient,
                      textInputAction: TextInputAction.done,
                      onSubmitted: vm.addIngredient,
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  DymContentWidth.form(
                    child: DymSectionHeader(
                      title: l10n.creatorTagProducts(
                        vm.tagged.length,
                        ComposeViewModel.maxTags,
                      ),
                    ),
                  ),
                  DymContentWidth.form(
                    child: DymTextField(
                      label: l10n.creatorSearchProducts,
                      icon: Icons.search_rounded,
                      textInputAction: TextInputAction.search,
                      onSubmitted: vm.search,
                    ),
                  ),
                  for (final p in [
                    ...vm.tagged,
                    for (final r in vm.results)
                      if (!vm.tagged.any((t) => t.id == r.id)) r,
                  ])
                    DymContentWidth.form(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: vm.tagged.any((t) => t.id == p.id),
                        onChanged: (_) => vm.toggleTag(p),
                        title: Text(p.name),
                        subtitle: Text(p.store.name),
                      ),
                    ),
                  if (vm.problem case final pr?)
                    DymContentWidth.form(
                      child: CartIssue(label: creatorErrorLabel(l10n, pr)),
                    ),
                  const SizedBox(height: DymTokenSpace.s3),
                  DymContentWidth.form(
                    child: DymButton(
                      label: l10n.creatorPublish,
                      icon: Icons.send_rounded,
                      loading: vm.publishing,
                      onPressed: media == null || vm.publishing
                          ? null
                          : () async {
                              if (await vm.publish()) onPublished();
                            },
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
