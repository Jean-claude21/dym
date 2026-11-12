import 'dart:async';

import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/creator/creator_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Refus de l'import affichés à l'écran.
enum TikTokImportError {
  handleRequired,
  notOwner,
  notFound,
  invalidUrl,
  offline,
  generic,
}

TikTokImportError tiktokErrorOf(Failure failure) => switch (failure) {
  NetworkFailure() => TikTokImportError.offline,
  ValidationFailure(message: 'tiktok_handle_required') =>
    TikTokImportError.handleRequired,
  ValidationFailure(message: 'not_owner') => TikTokImportError.notOwner,
  ValidationFailure(message: 'tiktok_not_found') => TikTokImportError.notFound,
  ValidationFailure() => TikTokImportError.invalidUrl,
  _ => TikTokImportError.generic,
};

/// Import d'une vidéo TikTok de la créatrice (spec 040) : lien, couverture et
/// légende proposées, ingrédients, publication.
class TikTokImportViewModel extends BaseViewModel {
  new({required this.service});

  final CreatorService service;

  String url = '';
  String caption = '';
  final captionController = TextEditingController();
  TikTokImport? imported;

  /// Photo choisie quand TikTok n'a pas donné de couverture.
  CreatorMedia? cover;
  List<ShoppingItem> ingredients = const [];

  bool get needsCover => imported != null && imported!.upload == null;

  Future<void> pickCover() async {
    if (await service.pick(video: false, source: PhotoSource.gallery) case Ok(
      value: final media?,
    )) {
      cover = media;
      notifyListeners();
    }
  }

  TikTokImportError? problem;
  bool working = false;
  bool findingIngredients = false;

  Future<void> import() async {
    if (working || url.trim().isEmpty) return;
    working = true;
    problem = null;
    notifyListeners();
    switch (await service.importTikTok(url.trim())) {
      case Ok(:final value):
        imported = value;
        caption = value.caption ?? '';
        captionController.text = caption;
      case Err(failure: final f):
        problem = tiktokErrorOf(f);
    }
    working = false;
    notifyListeners();
  }

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

  void removeIngredient(int index) {
    ingredients = [...ingredients]..removeAt(index);
    notifyListeners();
  }

  @override
  void dispose() {
    captionController.dispose();
    super.dispose();
  }

  Future<bool> publish() async {
    final video = imported;
    if (video == null || working || (needsCover && cover == null)) {
      return false;
    }
    working = true;
    problem = null;
    notifyListeners();
    final result = await service.publishImport(
      video,
      caption: caption.trim().isEmpty ? null : caption.trim(),
      ingredients: ingredients,
      cover: cover,
    );
    working = false;
    if (result case Err(failure: final f)) problem = tiktokErrorOf(f);
    notifyListeners();
    return result.isOk;
  }
}

class TikTokImportView extends StackedView<TikTokImportViewModel> {
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
  TikTokImportViewModel viewModelBuilder(BuildContext context) =>
      TikTokImportViewModel(service: service);

  @override
  Widget builder(
    BuildContext context,
    TikTokImportViewModel vm,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final video = vm.imported;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(title: l10n.tiktokImportTitle, onBack: onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // Compte déclaré, pas encore prouvé (décision 0015).
                  DymContentWidth.form(
                    child: Container(
                      padding: const EdgeInsets.all(DymTokenSpace.s3),
                      decoration: BoxDecoration(
                        color: c.tintVertTendre,
                        borderRadius: BorderRadius.circular(
                          DymTokenRadius.tile,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: c.brandDeep,
                          ),
                          const SizedBox(width: DymTokenSpace.s2),
                          Expanded(
                            child: Text(
                              l10n.tiktokUnverified,
                              style: t.label.copyWith(
                                color: c.brandDeep,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                  if (video == null) ...[
                    DymContentWidth.form(
                      child: DymTextField(
                        label: l10n.tiktokLink,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                        onChanged: (v) => vm.url = v,
                        onSubmitted: (_) => vm.import(),
                      ),
                    ),
                    const SizedBox(height: DymTokenSpace.s4),
                    DymContentWidth.form(
                      child: DymButton(
                        label: l10n.tiktokImport,
                        icon: Icons.download_rounded,
                        loading: vm.working,
                        onPressed: vm.working ? null : vm.import,
                      ),
                    ),
                  ] else ...[
                    if (video.upload case final upload?)
                      DymContentWidth.form(
                        child: _Cover(image: service.photo(upload.objectKey)),
                      )
                    else if (vm.cover case final cover?)
                      DymContentWidth.form(
                        child: _Cover(image: service.preview(cover)),
                      )
                    else
                      DymContentWidth.form(
                        child: Text(
                          l10n.tiktokNoCover,
                          style: t.body.copyWith(color: c.textSecondary),
                        ),
                      ),
                    if (vm.needsCover) ...[
                      const SizedBox(height: DymTokenSpace.s3),
                      DymContentWidth.form(
                        child: DymButton(
                          label: l10n.tiktokPickCover,
                          icon: Icons.photo_library_rounded,
                          variant: DymButtonVariant.secondary,
                          onPressed: vm.pickCover,
                        ),
                      ),
                    ],
                    const SizedBox(height: DymTokenSpace.s3),
                    DymContentWidth.form(
                      child: DymTextField(
                        label: l10n.creatorCaption,
                        controller: vm.captionController,
                        maxLines: 4,
                        onChanged: (v) => vm.caption = v,
                      ),
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
                              deleteButtonTooltipMessage: l10n
                                  .shoppingRemoveItem(item.label),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DymTokenSpace.s4),
                    DymContentWidth.form(
                      child: DymButton(
                        label: l10n.creatorPublish,
                        icon: Icons.send_rounded,
                        loading: vm.working,
                        onPressed:
                            vm.working || (vm.needsCover && vm.cover == null)
                            ? null
                            : () async {
                                if (await vm.publish()) onPublished();
                              },
                      ),
                    ),
                  ],
                  if (vm.problem case final problem?) ...[
                    const SizedBox(height: DymTokenSpace.s3),
                    DymContentWidth.form(
                      child: Text(switch (problem) {
                        TikTokImportError.handleRequired =>
                          l10n.tiktokHandleRequired,
                        TikTokImportError.notOwner => l10n.tiktokNotOwner,
                        TikTokImportError.notFound => l10n.tiktokNotFound,
                        TikTokImportError.invalidUrl => l10n.tiktokInvalidUrl,
                        TikTokImportError.offline => l10n.errorOffline,
                        TikTokImportError.generic => l10n.errorGeneric,
                      }, style: t.body.copyWith(color: c.pimentStrong)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const new({required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(DymTokenRadius.card),
    child: AspectRatio(
      aspectRatio: 3 / 4,
      child: Image(image: image, fit: BoxFit.cover),
    ),
  );
}
