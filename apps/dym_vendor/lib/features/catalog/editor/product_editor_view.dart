import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/catalog/catalog_service.dart';
import 'package:dym_vendor/features/catalog/editor/product_editor_viewmodel.dart';
import 'package:dym_vendor/features/store/widgets/store_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

/// Écrans 25 et 26 : nouveau produit (photo puis prix et stock), ou
/// modification d'un produit.
class ProductEditorView extends StackedView<ProductEditorViewModel> {
  const new({
    required this.service,
    required this.onDone,
    required this.onCancel,
    super.key,
    this.product,
    this.initialSource,
    this.initialStep = 1,
  });

  final CatalogService service;
  final void Function(Product product) onDone;
  final VoidCallback onCancel;
  final Product? product;

  /// Nouveau produit : source de la première photo, ouverte d'emblée.
  final PhotoSource? initialSource;

  /// Produit existant : étape ouverte (2 : prix et stock).
  final int initialStep;

  @override
  ProductEditorViewModel viewModelBuilder(BuildContext context) =>
      ProductEditorViewModel(
        service: service,
        onDone: onDone,
        product: product,
        initialSource: initialSource,
        initialStep: initialStep,
        onClosed: onCancel,
      );

  @override
  void onViewModelReady(ProductEditorViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    ProductEditorViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    if (!viewModel.ready) {
      return Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: viewModel.loadFailure == null
              ? Center(
                  child: Semantics(
                    label: l10n.startupPreparing,
                    child: CircularProgressIndicator(color: c.brand),
                  ),
                )
              : DymStateView(
                  kind: viewModel.offline
                      ? DymStateKind.offline
                      : DymStateKind.error,
                  title: viewModel.offline
                      ? l10n.errorOffline
                      : l10n.errorGeneric,
                  message: l10n.errorLoadMessage,
                  actionLabel: l10n.retry,
                  onAction: viewModel.load,
                ),
        ),
      );
    }
    final first = viewModel.step == 1;
    final published = viewModel.product?.isPublished ?? false;
    return DymFormScaffold(
      // Une étape = un écran : le défilement repart du haut.
      key: ValueKey('editor-step-${viewModel.step}'),
      title: first
          ? (viewModel.isNew ? l10n.productNewTitle : l10n.productEditTitle)
          : l10n.productPriceTitle,
      subtitle: first && viewModel.isNew
          ? Text(l10n.productPhotoSubtitle)
          : null,
      backLabel: l10n.authBack,
      onBack: viewModel.canGoBack ? viewModel.back : onCancel,
      progress: DymStepProgress(
        current: viewModel.step,
        total: 2,
        label: l10n.storeStepLabel(viewModel.step, 2),
      ),
      action: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StoreErrorBanner(failure: viewModel.saveFailure),
          if (first)
            DymButton(
              label: l10n.storeContinue,
              loading: viewModel.isBusy,
              onPressed: viewModel.canContinue ? viewModel.next : null,
            )
          else
            DymButton(
              label: published ? l10n.storeSave : l10n.productPublish,
              icon: published ? null : Icons.storefront_rounded,
              loading: viewModel.isBusy,
              onPressed: viewModel.canPublish ? viewModel.publish : null,
            ),
        ],
      ),
      children: [
        KeyedSubtree(
          key: ValueKey('step-${viewModel.step}'),
          child: first
              ? _PhotoStep(viewModel: viewModel)
              : _PriceStep(viewModel: viewModel),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ étape 1

class _PhotoStep extends StatelessWidget {
  const new({required this.viewModel});

  final ProductEditorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final vm = viewModel;
    final showInvalid = vm.name.isNotEmpty && !vm.nameValid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Photos(viewModel: vm),
        const SizedBox(height: DymTokenSpace.s4),
        StoreSection(
          children: [
            _SuggestionHeader(state: vm.suggestion),
            // Recréés quand la proposition arrive : les champs repartent des
            // valeurs du viewmodel (ce qui était saisi est conservé).
            KeyedSubtree(
              key: ValueKey(vm.suggestion),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Le libellé flottant du champ suffit.
                  StoreTextField(
                    label: l10n.productNameLabel,
                    hint: l10n.productNameHint,
                    initialValue: vm.name,
                    onChanged: vm.setName,
                    maxLength: ProductEditorViewModel.nameMax,
                    status: showInvalid
                        ? DymFieldStatus.error
                        : DymFieldStatus.none,
                    message: showInvalid ? l10n.productNameInvalid : null,
                  ),
                  const SizedBox(height: DymTokenSpace.s4),
                  StoreFieldLabel(l10n.productAisleLabel),
                  Wrap(
                    runSpacing: DymTokenSpace.s2,
                    spacing: DymTokenSpace.s2,
                    children: [
                      for (final category in vm.topCategories)
                        DymFilterChip(
                          label: category.label.resolve(locale),
                          selected: vm.topCategoryId == category.id,
                          onTap: () => vm.selectCategory(category.id),
                        ),
                    ],
                  ),
                  if (vm.subCategories.isNotEmpty) ...[
                    const SizedBox(height: DymTokenSpace.s2),
                    Wrap(
                      runSpacing: DymTokenSpace.s2,
                      spacing: DymTokenSpace.s2,
                      children: [
                        for (final sub in vm.subCategories)
                          DymFilterChip(
                            label: sub.label.resolve(locale),
                            multiple: true,
                            selected: vm.categoryId == sub.id,
                            onTap: () => vm.selectCategory(sub.id),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: DymTokenSpace.s4),
                  StoreFieldLabel(l10n.productDescriptionLabel),
                  StoreTextField(
                    label: l10n.productDescriptionLabel,
                    initialValue: vm.description,
                    onChanged: vm.setDescription,
                    maxLength: ProductEditorViewModel.descriptionMax,
                    minLines: 2,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (vm.suggestion == SuggestionState.received) ...[
          const SizedBox(height: DymTokenSpace.s2),
          Text(
            l10n.productSuggestionCheck,
            style: t.label.copyWith(color: c.textSecondary, fontSize: 14),
          ),
        ],
        if (!vm.isNew && !(vm.product?.isArchived ?? false)) ...[
          const SizedBox(height: DymTokenSpace.s4),
          Center(
            child: TextButton.icon(
              onPressed: vm.isBusy
                  ? null
                  : vm.isDraft
                  ? vm.deleteDraft
                  : vm.archive,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: c.pimentStrong,
              ),
              icon: Icon(
                vm.isDraft
                    ? Icons.delete_outline_rounded
                    : Icons.archive_outlined,
              ),
              label: Text(
                vm.isDraft ? l10n.productDeleteDraft : l10n.productArchive,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SuggestionHeader extends StatelessWidget {
  const new({required this.state});

  final SuggestionState state;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final (Widget? icon, String? text) = switch (state) {
      SuggestionState.idle => (null, null),
      SuggestionState.loading => (
        SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: c.brand),
        ),
        l10n.productSuggesting,
      ),
      SuggestionState.received => (
        Icon(Icons.auto_awesome_rounded, color: c.brandDeep),
        l10n.productSuggestedBy,
      ),
      SuggestionState.unavailable => (
        Icon(Icons.edit_note_rounded, color: c.textSecondary),
        l10n.productSuggestionUnavailable,
      ),
    };
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: DymTokenSpace.s3),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            ?icon,
            const SizedBox(width: DymTokenSpace.s2),
            Expanded(
              child: Text(
                text,
                style: t.title.copyWith(
                  fontSize: 18,
                  color: state == SuggestionState.received
                      ? c.brandDeep
                      : c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photos extends StatelessWidget {
  const new({required this.viewModel});

  final ProductEditorViewModel viewModel;

  Future<void> _choose(BuildContext context) async {
    final l10n = DymLocalizations.of(context);
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(l10n.productTakePhoto),
              onTap: () => Navigator.pop(context, PhotoSource.camera),
            ),
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(l10n.productChoosePhoto),
              onTap: () => Navigator.pop(context, PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await viewModel.addPhoto(source);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final keys = vm.photoKeys;
    final status = <Widget>[
      if (vm.uploading) ...[
        const SizedBox(height: DymTokenSpace.s2),
        Semantics(
          liveRegion: true,
          label: l10n.productPhotoUploading,
          child: LinearProgressIndicator(color: c.brand),
        ),
      ],
      if (vm.uploadFailed) ...[
        const SizedBox(height: DymTokenSpace.s2),
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Icon(Icons.error_rounded, color: c.pimentStrong),
              const SizedBox(width: DymTokenSpace.s2),
              Expanded(
                child: Text(
                  l10n.productPhotoFailed,
                  style: t.label.copyWith(color: c.pimentStrong, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    ];
    if (keys.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: c.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DymTokenRadius.card),
              side: BorderSide(color: c.hairline),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(DymTokenRadius.card),
              onTap: vm.uploading
                  ? null
                  : () => vm.addPhoto(PhotoSource.camera),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DymTokenRadius.card),
                    border: Border.all(color: c.brand, width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_camera_rounded,
                        size: 48,
                        color: c.brandDeep,
                      ),
                      const SizedBox(height: DymTokenSpace.s2),
                      Text(
                        l10n.productTakePhoto,
                        style: t.title.copyWith(color: c.brandDeep),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: DymTokenSpace.s2),
          DymButton(
            label: l10n.productChoosePhoto,
            icon: Icons.photo_library_rounded,
            variant: DymButtonVariant.secondary,
            onPressed: vm.uploading
                ? null
                : () => vm.addPhoto(PhotoSource.gallery),
          ),
          ...status,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(DymTokenRadius.card),
          child: ColoredBox(
            color: context.dym.colors.tintVertTendre,
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image(
                image: vm.service.photo(keys.first),
                fit: BoxFit.cover,
                semanticLabel: vm.name,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(
                    Icons.photo_outlined,
                    size: 48,
                    color: context.dym.colors.brandDeep,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: DymTokenSpace.s3),
        Wrap(
          spacing: DymTokenSpace.s2,
          runSpacing: DymTokenSpace.s2,
          children: [
            for (final (i, key) in keys.indexed)
              _Thumb(
                image: vm.service.photo(key),
                selected: i == 0,
                removeLabel: l10n.productRemovePhoto,
                onRemove: () => vm.removePhoto(key),
              ),
            if (keys.length < ProductEditorViewModel.maxPhotos)
              Semantics(
                button: true,
                label: l10n.productAddPhoto,
                excludeSemantics: true,
                child: InkWell(
                  onTap: vm.uploading ? null : () => _choose(context),
                  borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                      border: Border.all(color: c.brand, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: c.brandDeep,
                        ),
                        Text(
                          l10n.productAddPhoto,
                          style: t.label.copyWith(
                            color: c.brandDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: DymTokenSpace.s1),
        Text(
          l10n.productPhotoCount(keys.length, ProductEditorViewModel.maxPhotos),
          style: t.label.copyWith(color: c.textSecondary, fontSize: 13),
        ),
        ...status,
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const new({
    required this.image,
    required this.selected,
    required this.removeLabel,
    required this.onRemove,
  });

  final ImageProvider image;
  final bool selected;
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                border: Border.all(
                  color: selected ? c.brand : Colors.transparent,
                  width: 2.5,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DymTokenRadius.tile - 2),
                child: Image(
                  image: image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      ColoredBox(color: context.dym.colors.tintVertTendre),
                ),
              ),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: IconButton(
              tooltip: removeLabel,
              onPressed: onRemove,
              icon: CircleAvatar(
                radius: 13,
                backgroundColor: c.card,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ étape 2

class _PriceStep extends StatelessWidget {
  const new({required this.viewModel});

  final ProductEditorViewModel viewModel;

  Future<void> _newCategory(BuildContext context) async {
    final l10n = DymLocalizations.of(context);
    var name = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.categoriesNewHint),
        content: TextField(
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (value) => name = value,
          onSubmitted: (_) => Navigator.pop(context, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.categoriesAdd),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await viewModel.createStoreCategory(name);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final vm = viewModel;
    final currency = vm.currency;
    final digits = currency?.minorUnits ?? 0;
    final amountFormat = FilteringTextInputFormatter.allow(
      RegExp(digits == 0 ? r'[\d\s]' : r'[\d\s.,]'),
    );
    final showPriceError = vm.priceText.isNotEmpty && !vm.priceValid;
    final units = vm.config?.units ?? const <MarketUnit>[];
    final several = vm.variants.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StoreSection(
          title: l10n.productPriceLabel,
          children: [
            _AmountField(
              label: l10n.productPriceLabel,
              initialValue: vm.priceText,
              suffix: currency?.symbol,
              formatter: amountFormat,
              decimal: digits > 0,
              onChanged: vm.setPrice,
              error: showPriceError ? l10n.productPriceInvalid : null,
            ),
            if (units.isNotEmpty) ...[
              const SizedBox(height: DymTokenSpace.s3),
              Wrap(
                runSpacing: DymTokenSpace.s2,
                spacing: DymTokenSpace.s2,
                children: [
                  for (final unit in units)
                    DymFilterChip(
                      label: unit.label.resolve(locale),
                      selected: vm.unitId == unit.id,
                      onTap: () => vm.selectUnit(unit.id),
                    ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: DymTokenSpace.s4),
        StoreSection(
          title: l10n.productVariantsTitle,
          children: [
            DymSwitchTile(
              title: l10n.productTrackStock,
              subtitle: vm.trackStock ? null : l10n.productTrackStockHint,
              value: vm.trackStock,
              onChanged: (value) => vm.setTrackStock(value: value),
            ),
            for (final variant in vm.variants) ...[
              const SizedBox(height: DymTokenSpace.s3),
              _VariantRow(
                key: ValueKey(variant.id),
                viewModel: vm,
                variant: variant,
                editable: several || variant.label.isNotEmpty,
                amountFormat: amountFormat,
                decimal: digits > 0,
                suffix: currency?.symbol,
              ),
            ],
            if (several && !vm.variantLabelsValid) ...[
              const SizedBox(height: DymTokenSpace.s2),
              Text(
                l10n.productVariantLabelsRequired,
                style: t.label.copyWith(color: c.pimentStrong, fontSize: 14),
              ),
            ],
            if (vm.variants.length < ProductEditorViewModel.maxVariants)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: vm.addVariant,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.productVariantAdd),
                ),
              ),
          ],
        ),
        const SizedBox(height: DymTokenSpace.s4),
        StoreSection(
          title: l10n.productStoreCategoryTitle,
          children: [
            Wrap(
              runSpacing: DymTokenSpace.s2,
              spacing: DymTokenSpace.s2,
              children: [
                for (final category in vm.storeCategories)
                  DymFilterChip(
                    label: category.name,
                    multiple: true,
                    selected: vm.storeCategoryIds.contains(category.id),
                    onTap: () => vm.toggleStoreCategory(category.id),
                  ),
                DymFilterChip(
                  label: '+ ${l10n.productStoreCategoryNew}',
                  selected: false,
                  onTap: () => _newCategory(context),
                ),
              ],
            ),
          ],
        ),
        if (vm.photoKeys.isEmpty) ...[
          const SizedBox(height: DymTokenSpace.s3),
          Row(
            children: [
              Icon(Icons.photo_camera_rounded, color: c.pimentStrong),
              const SizedBox(width: DymTokenSpace.s2),
              Expanded(
                child: Text(
                  l10n.productMissingPhoto,
                  style: t.label.copyWith(color: c.pimentStrong, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  const new({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    required this.formatter,
    required this.decimal,
    this.suffix,
    this.error,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextInputFormatter formatter;
  final bool decimal;
  final String? suffix;
  final String? error;

  @override
  Widget build(BuildContext context) => _ControlledField(
    initialValue: initialValue,
    builder: (controller) => DymTextField(
      label: label,
      hint: label,
      controller: controller,
      onChanged: onChanged,
      suffixText: suffix,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [formatter],
      status: error == null ? DymFieldStatus.none : DymFieldStatus.error,
      message: error,
    ),
  );
}

class _VariantRow extends StatelessWidget {
  const new({
    required this.viewModel,
    required this.variant,
    required this.editable,
    required this.amountFormat,
    required this.decimal,
    super.key,
    this.suffix,
  });

  final ProductEditorViewModel viewModel;
  final VariantDraft variant;
  final bool editable;
  final TextInputFormatter amountFormat;
  final bool decimal;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final stepper = vm.trackStock
        ? Row(
            children: [
              Expanded(
                child: Text(
                  l10n.productStockLabel,
                  style: t.title.copyWith(fontSize: 17),
                ),
              ),
              DymQuantityStepper(
                quantity: variant.stock,
                max: ProductEditorViewModel.maxStock,
                decreaseLabel: l10n.productStockDecrease,
                increaseLabel: l10n.productStockIncrease,
                onChanged: (value) => vm.setStock(variant.id, value),
              ),
            ],
          )
        : null;
    if (!editable) return stepper ?? const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        border: Border.all(color: c.textSecondary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: StoreTextField(
                  label: l10n.productVariantLabel,
                  initialValue: variant.label,
                  onChanged: (value) => vm.setVariantLabel(variant.id, value),
                  maxLength: 30,
                ),
              ),
              if (vm.variants.length > 1)
                IconButton(
                  tooltip: l10n.productVariantRemove,
                  onPressed: () => vm.removeVariant(variant.id),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: c.pimentStrong,
                  ),
                ),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s2),
          _AmountField(
            label: l10n.productVariantPrice,
            initialValue: variant.priceText,
            suffix: suffix,
            formatter: amountFormat,
            decimal: decimal,
            onChanged: (value) => vm.setVariantPrice(variant.id, value),
          ),
          if (stepper != null) ...[
            const SizedBox(height: DymTokenSpace.s2),
            stepper,
          ],
        ],
      ),
    );
  }
}

/// Garde un contrôleur de texte créé à partir d'une valeur initiale.
class _ControlledField extends StatefulWidget {
  const new({required this.initialValue, required this.builder});

  final String initialValue;
  final Widget Function(TextEditingController controller) builder;

  @override
  State<_ControlledField> createState() => _ControlledFieldState();
}

class _ControlledFieldState extends State<_ControlledField> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}
