import 'dart:async';

import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Remplacement validé par photo et garantie fraîcheur, côté cliente
/// (spec 034).
abstract interface class AdjustmentsService {
  Future<Result<Map<String, String>>> photoUrls(String orderId);

  Future<Result<List<OrderAdjustment>>> answer(
    String adjustmentId, {
    required bool accept,
  });

  /// Photo prise ou choisie, envoyée, puis réclamation ; `Ok(null)` : photo
  /// annulée.
  Future<Result<List<OrderAdjustment>?>> claimFreshness({
    required String orderId,
    required String variantId,
    required PhotoSource source,
    String? note,
  });
}

class NeonAdjustmentsService implements AdjustmentsService {
  new({required this._repository, required this._photos});

  final OrderAdjustmentRepository _repository;
  final PhotoPicker _photos;

  @override
  Future<Result<Map<String, String>>> photoUrls(String orderId) =>
      _repository.photoUrls(orderId);

  @override
  Future<Result<List<OrderAdjustment>>> answer(
    String adjustmentId, {
    required bool accept,
  }) => _repository.answer(adjustmentId, accept: accept);

  @override
  Future<Result<List<OrderAdjustment>?>> claimFreshness({
    required String orderId,
    required String variantId,
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
            return await _repository.claimFreshness(
              orderId: orderId,
              variantId: variantId,
              photoKey: k,
              note: note,
            );
        }
    }
  }
}

/// Erreurs affichées.
enum AdjustmentError {
  windowClosed,
  limitReached,
  alreadyCredited,
  offline,
  generic,
}

AdjustmentError adjustmentErrorOf(Failure failure) => switch (failure) {
  NetworkFailure() => AdjustmentError.offline,
  ValidationFailure(message: 'claim_window_closed') =>
    AdjustmentError.windowClosed,
  ValidationFailure(message: 'claim_limit_reached') =>
    AdjustmentError.limitReached,
  ValidationFailure(message: 'already_credited' || 'already_answered') =>
    AdjustmentError.alreadyCredited,
  _ => AdjustmentError.generic,
};

String adjustmentErrorLabel(DymLocalizations l10n, AdjustmentError e) =>
    switch (e) {
      AdjustmentError.windowClosed => l10n.freshnessWindowClosed,
      AdjustmentError.limitReached => l10n.freshnessLimitReached,
      AdjustmentError.alreadyCredited => l10n.freshnessAlreadyCredited,
      AdjustmentError.offline => l10n.errorOffline,
      AdjustmentError.generic => l10n.errorGeneric,
    };

class AdjustmentsViewModel extends BaseViewModel {
  new({required this.service, required CustomerOrder order})
    : adjustments = order.adjustments,
      orderId = order.id;

  final AdjustmentsService service;
  final String orderId;
  List<OrderAdjustment> adjustments;
  Map<String, String> urls = const {};
  AdjustmentError? problem;
  bool acting = false;

  /// Montant rendu par le dernier geste (message).
  int? lastCredited;

  Future<void> loadPhotos() async {
    if (adjustments.isEmpty) return;
    if (await service.photoUrls(orderId) case Ok(:final value)) {
      urls = value;
      notifyListeners();
    }
  }

  Future<void> _run(
    Future<Result<List<OrderAdjustment>?>> Function() call,
  ) async {
    if (acting) return;
    acting = true;
    problem = null;
    lastCredited = null;
    notifyListeners();
    final before = {for (final a in adjustments) a.id: a.creditedMinor};
    final result = await call();
    acting = false;
    switch (result) {
      case Ok(value: final list?):
        adjustments = list;
        final credited = list
            .where((a) => a.creditedMinor > (before[a.id] ?? 0))
            .fold(0, (t, a) => t + a.creditedMinor - (before[a.id] ?? 0));
        if (credited > 0) lastCredited = credited;
        unawaited(loadPhotos());
      case Ok():
        break;
      case Err(:final failure):
        problem = adjustmentErrorOf(failure);
    }
    notifyListeners();
  }

  Future<void> answer(OrderAdjustment a, {required bool accept}) =>
      _run(() => service.answer(a.id, accept: accept));

  Future<void> claim(String variantId, PhotoSource source) => _run(
    () => service.claimFreshness(
      orderId: orderId,
      variantId: variantId,
      source: source,
    ),
  );

  bool credited(String variantId) =>
      adjustments.any((a) => a.variantId == variantId && a.creditedMinor > 0);
}

/// Panneau du suivi : propositions à valider, montants rendus, « Pas frais ? ».
class OrderAdjustmentsPanel extends StackedView<AdjustmentsViewModel> {
  const new({
    required this.service,
    required this.order,
    required this.money,
    super.key,
  });

  final AdjustmentsService service;
  final CustomerOrder order;
  final String? Function(int minor) money;

  @override
  AdjustmentsViewModel viewModelBuilder(BuildContext context) =>
      AdjustmentsViewModel(service: service, order: order);

  @override
  void onViewModelReady(AdjustmentsViewModel viewModel) =>
      unawaited(viewModel.loadPhotos());

  @override
  Widget builder(BuildContext context, AdjustmentsViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final delivered = order.status == OrderStatus.delivered;
    if (vm.adjustments.isEmpty && !delivered) return const SizedBox.shrink();
    final claimable = [
      for (final line in order.items)
        if (!vm.credited(line.variantId)) line,
    ];
    return Padding(
      padding: const EdgeInsets.only(top: DymTokenSpace.s3),
      child: CartCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.adjustTitle, style: t.title.copyWith(fontSize: 17)),
            for (final a in vm.adjustments)
              _AdjustmentRow(vm: vm, adjustment: a, money: money),
            if (vm.lastCredited case final amount?)
              Padding(
                padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                child: CartIssue(
                  label: l10n.adjustCreditedNow(money(amount) ?? ''),
                  blocking: false,
                ),
              ),
            if (vm.problem case final p?)
              Padding(
                padding: const EdgeInsets.only(top: DymTokenSpace.s2),
                child: CartIssue(label: adjustmentErrorLabel(l10n, p)),
              ),
            if (delivered && claimable.isNotEmpty) ...[
              const SizedBox(height: DymTokenSpace.s2),
              DymButton(
                label: l10n.freshnessClaim,
                icon: Icons.eco_rounded,
                variant: DymButtonVariant.secondary,
                loading: vm.acting,
                onPressed: vm.acting
                    ? null
                    : () => _claim(context, vm, claimable),
              ),
              Text(
                l10n.freshnessHint,
                style: t.label.copyWith(color: c.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<void> _claim(
    BuildContext context,
    AdjustmentsViewModel vm,
    List<OrderLine> lines,
  ) async {
    final l10n = DymLocalizations.of(context);
    final choice = await showModalBottomSheet<(String, PhotoSource)>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => _ClaimSheet(lines: lines, l10n: l10n),
    );
    if (choice case (final variant, final source)) {
      await vm.claim(variant, source);
    }
  }
}

class _ClaimSheet extends StatefulWidget {
  const new({required this.lines, required this.l10n});

  final List<OrderLine> lines;
  final DymLocalizations l10n;

  @override
  State<_ClaimSheet> createState() => _ClaimSheetState();
}

class _ClaimSheetState extends State<_ClaimSheet> {
  late String _variant = widget.lines.first.variantId;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.freshnessWhich, style: context.dym.text.title),
            RadioGroup<String>(
              groupValue: _variant,
              onChanged: (v) => setState(() => _variant = v ?? _variant),
              child: Column(
                children: [
                  for (final line in widget.lines)
                    RadioListTile<String>(
                      value: line.variantId,
                      title: Text('${line.name} × ${line.quantity}'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DymTokenSpace.s2),
            DymButton(
              label: l10n.photoTake,
              icon: Icons.photo_camera_rounded,
              onPressed: () =>
                  Navigator.of(context).pop((_variant, PhotoSource.camera)),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            DymButton(
              label: l10n.photoFromGallery,
              icon: Icons.photo_library_rounded,
              variant: DymButtonVariant.secondary,
              onPressed: () =>
                  Navigator.of(context).pop((_variant, PhotoSource.gallery)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustmentRow extends StatelessWidget {
  const new({required this.vm, required this.adjustment, required this.money});

  final AdjustmentsViewModel vm;
  final OrderAdjustment adjustment;
  final String? Function(int minor) money;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final a = adjustment;
    final url = vm.urls[a.photoKey];
    final text = switch ((a.kind, a.status)) {
      (AdjustmentKind.substitution, AdjustmentStatus.pending) =>
        l10n.adjustProposed(a.itemName, a.proposedName ?? ''),
      (AdjustmentKind.substitution, AdjustmentStatus.accepted) =>
        l10n.adjustAccepted(a.itemName, a.proposedName ?? ''),
      (AdjustmentKind.freshness, _) => l10n.adjustFreshness(
        a.itemName,
        money(a.creditedMinor) ?? '',
      ),
      _ => l10n.adjustRefused(a.itemName, money(a.creditedMinor) ?? ''),
    };
    return Padding(
      padding: const EdgeInsets.only(top: DymTokenSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DymTokenRadius.tile / 2),
                child: SizedBox.square(
                  dimension: 64,
                  child: url == null
                      ? ColoredBox(
                          color: c.tintVertTendre,
                          child: Icon(Icons.photo_rounded, color: c.brandDeep),
                        )
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          semanticLabel: a.itemName,
                          errorBuilder: (_, _, _) =>
                              ColoredBox(color: c.tintVertTendre),
                        ),
                ),
              ),
              const SizedBox(width: DymTokenSpace.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: t.body),
                    if (a.note case final note?)
                      Text(
                        '« $note »',
                        style: t.label.copyWith(color: c.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (a.awaitingAnswer) ...[
            const SizedBox(height: DymTokenSpace.s2),
            Row(
              children: [
                Expanded(
                  child: DymButton(
                    label: l10n.adjustAccept,
                    icon: Icons.check_rounded,
                    compact: true,
                    onPressed: vm.acting
                        ? null
                        : () => vm.answer(a, accept: true),
                  ),
                ),
                const SizedBox(width: DymTokenSpace.s2),
                Expanded(
                  child: DymButton(
                    label: l10n.adjustRefuse,
                    icon: Icons.close_rounded,
                    compact: true,
                    variant: DymButtonVariant.secondary,
                    onPressed: vm.acting
                        ? null
                        : () => vm.answer(a, accept: false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
