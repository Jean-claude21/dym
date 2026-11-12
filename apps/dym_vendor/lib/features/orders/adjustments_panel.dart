import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Remplacement validé par photo, côté vendeuse (spec 034).
abstract interface class VendorAdjustmentsService {
  Future<Result<Map<String, String>>> photoUrls(String orderId);

  /// Produits publiés de la boutique (choix du remplacement).
  Future<Result<List<Product>>> products();

  /// Photo prise ou choisie, envoyée, puis proposition ; `Ok(null)` : annulé.
  Future<Result<List<OrderAdjustment>?>> propose({
    required String orderId,
    required String variantId,
    required String proposedVariantId,
    required PhotoSource source,
    String? note,
  });
}

class NeonVendorAdjustmentsService implements VendorAdjustmentsService {
  new({
    required this._repository,
    required this._photos,
    required this._products,
  });

  final OrderAdjustmentRepository _repository;
  final PhotoPicker _photos;
  final Future<Result<List<Product>>> Function() _products;

  @override
  Future<Result<Map<String, String>>> photoUrls(String orderId) =>
      _repository.photoUrls(orderId);

  @override
  Future<Result<List<Product>>> products() => _products();

  @override
  Future<Result<List<OrderAdjustment>?>> propose({
    required String orderId,
    required String variantId,
    required String proposedVariantId,
    required PhotoSource source,
    String? note,
  }) async {
    final picked = await _photos.pick(source);
    switch (picked) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: null):
        return const Ok(null);
      case Ok(value: final photo?):
        final key = await _repository.uploadPhoto(
          orderId,
          photo.bytes,
          contentType: photo.contentType,
        );
        switch (key) {
          case Err(:final failure):
            return Err(failure);
          case Ok(value: final k):
            return await _repository.propose(
              orderId: orderId,
              variantId: variantId,
              proposedVariantId: proposedVariantId,
              photoKey: k,
              note: note,
            );
        }
    }
  }
}

class VendorAdjustmentsViewModel extends BaseViewModel {
  new({required this.service, required VendorOrder order})
    : orderId = order.id,
      adjustments = order.adjustments;

  final VendorAdjustmentsService service;
  final String orderId;
  List<OrderAdjustment> adjustments;
  Map<String, String> urls = const {};
  bool acting = false;
  Failure? failure;

  Future<void> loadPhotos() async {
    if (adjustments.isEmpty) return;
    if (await service.photoUrls(orderId) case Ok(:final value)) {
      urls = value;
      notifyListeners();
    }
  }

  bool pending(String variantId) =>
      adjustments.any((a) => a.variantId == variantId && a.awaitingAnswer);

  Future<void> propose(
    String variantId,
    String proposedVariantId,
    PhotoSource source,
    String? note,
  ) async {
    if (acting) return;
    acting = true;
    failure = null;
    notifyListeners();
    final result = await service.propose(
      orderId: orderId,
      variantId: variantId,
      proposedVariantId: proposedVariantId,
      source: source,
      note: note,
    );
    acting = false;
    switch (result) {
      case Ok(value: final list?):
        adjustments = list;
        unawaited(loadPhotos());
      case Ok():
        break;
      case Err(failure: final f):
        failure = f;
    }
    notifyListeners();
  }
}

/// Lignes de la commande : « Remplacer » et réponses de la cliente.
class VendorAdjustmentsPanel extends StackedView<VendorAdjustmentsViewModel> {
  const new({required this.service, required this.order, super.key});

  final VendorAdjustmentsService service;
  final VendorOrder order;

  @override
  VendorAdjustmentsViewModel viewModelBuilder(BuildContext context) =>
      VendorAdjustmentsViewModel(service: service, order: order);

  @override
  void onViewModelReady(VendorAdjustmentsViewModel viewModel) =>
      unawaited(viewModel.loadPhotos());

  @override
  Widget builder(
    BuildContext context,
    VendorAdjustmentsViewModel vm,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final open =
        order.status == OrderStatus.accepted ||
        order.status == OrderStatus.preparing;
    if (vm.adjustments.isEmpty && !open) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: DymTokenSpace.s3),
      padding: const EdgeInsets.all(DymTokenSpace.s4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.vendorSubstituteTitle,
            style: t.title.copyWith(fontSize: 17),
          ),
          Text(
            l10n.vendorSubstituteHint,
            style: t.label.copyWith(color: c.textSecondary),
          ),
          for (final a in vm.adjustments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox.square(
                  dimension: 48,
                  child: switch (vm.urls[a.photoKey]) {
                    final url? => Image.network(url, fit: BoxFit.cover),
                    null => ColoredBox(color: c.tintVertTendre),
                  },
                ),
              ),
              title: Text(
                a.kind == AdjustmentKind.freshness
                    ? l10n.vendorFreshnessClaimed(a.itemName)
                    : l10n.vendorSubstituteLine(
                        a.itemName,
                        a.proposedName ?? '',
                      ),
                style: t.body,
              ),
              subtitle: Text(switch (a.status) {
                AdjustmentStatus.pending => l10n.vendorSubstituteWaiting,
                AdjustmentStatus.accepted => l10n.vendorSubstituteAccepted,
                _ => l10n.vendorSubstituteRefunded,
              }, style: t.label.copyWith(color: c.brandDeep)),
            ),
          if (open)
            for (final line in order.items)
              if (!vm.pending(line.variantId))
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: vm.acting
                        ? null
                        : () => _substitute(context, vm, line),
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(l10n.vendorSubstitute(line.name)),
                  ),
                ),
          if (vm.failure case final f?)
            Text(
              f is NetworkFailure ? l10n.errorOffline : l10n.errorGeneric,
              style: t.label.copyWith(color: c.pimentStrong),
            ),
        ],
      ),
    );
  }

  Future<void> _substitute(
    BuildContext context,
    VendorAdjustmentsViewModel vm,
    OrderLine line,
  ) async {
    final products = (await vm.service.products()).valueOrNull ?? const [];
    if (!context.mounted) return;
    final candidates = [
      for (final p in products)
        if (p.status == ProductStatus.published && p.isAvailable)
          for (final v in p.variants)
            if (v.id != line.variantId)
              (variant: v.id, label: [p.name, ?v.label].join(' · ')),
    ];
    final choice = await showModalBottomSheet<(String, PhotoSource, String)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _SubstituteSheet(line: line, candidates: candidates),
    );
    if (choice case (final variant, final source, final note)) {
      await vm.propose(
        line.variantId,
        variant,
        source,
        note.trim().isEmpty ? null : note,
      );
    }
  }
}

class _SubstituteSheet extends StatefulWidget {
  const new({required this.line, required this.candidates});

  final OrderLine line;
  final List<({String variant, String label})> candidates;

  @override
  State<_SubstituteSheet> createState() => _SubstituteSheetState();
}

class _SubstituteSheetState extends State<_SubstituteSheet> {
  String? _variant;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _done(PhotoSource source) {
    final v = _variant;
    if (v != null) Navigator.of(context).pop((v, source, _note.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.vendorSubstitute(widget.line.name),
                style: context.dym.text.title,
              ),
              if (widget.candidates.isEmpty)
                Text(l10n.vendorSubstituteNone)
              else
                RadioGroup<String>(
                  groupValue: _variant,
                  onChanged: (v) => setState(() => _variant = v),
                  child: Column(
                    children: [
                      for (final c in widget.candidates)
                        RadioListTile<String>(
                          value: c.variant,
                          title: Text(c.label),
                        ),
                    ],
                  ),
                ),
              TextField(
                controller: _note,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: l10n.vendorSubstituteNote,
                ),
              ),
              DymButton(
                label: l10n.photoTake,
                icon: Icons.photo_camera_rounded,
                onPressed: _variant == null
                    ? null
                    : () => _done(PhotoSource.camera),
              ),
              const SizedBox(height: DymTokenSpace.s3),
              DymButton(
                label: l10n.photoFromGallery,
                icon: Icons.photo_library_rounded,
                variant: DymButtonVariant.secondary,
                onPressed: _variant == null
                    ? null
                    : () => _done(PhotoSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
