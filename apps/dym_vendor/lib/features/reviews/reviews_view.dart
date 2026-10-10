import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Avis de ma boutique (spec 016). Remplaçable en test.
abstract interface class VendorReviewsService {
  Future<Result<StoreReviews>> reviews();

  Future<Result<Review>> reply(String reviewId, String text);
}

class NeonVendorReviewsService implements VendorReviewsService {
  new(this._repository);

  final ReviewRepository _repository;

  @override
  Future<Result<StoreReviews>> reviews() => _repository.myStoreReviews();

  @override
  Future<Result<Review>> reply(String reviewId, String text) =>
      _repository.reply(reviewId, text);
}

/// Avis en mémoire (tests, galerie). Jamais en production.
class MemoryVendorReviewsService implements VendorReviewsService {
  new(this.data);

  StoreReviews data;
  Failure? failNext;
  final replies = <String>[];

  @override
  Future<Result<StoreReviews>> reviews() async {
    final f = failNext;
    failNext = null;
    return f == null ? Ok(data) : Err(f);
  }

  @override
  Future<Result<Review>> reply(String reviewId, String text) async {
    replies.add('$reviewId:$text');
    final updated = [
      for (final r in data.reviews)
        if (r.id == reviewId)
          Review(
            id: r.id,
            orderId: r.orderId,
            storeId: r.storeId,
            rating: r.rating,
            tags: r.tags,
            comment: r.comment,
            reply: text,
            repliedAt: DateTime.utc(2026, 10, 5, 11),
            createdAt: r.createdAt,
            authorFirstName: r.authorFirstName,
          )
        else
          r,
    ];
    data = StoreReviews(
      rating: data.rating,
      reviewCount: data.reviewCount,
      distribution: data.distribution,
      reviews: updated,
    );
    return Ok(updated.firstWhere((r) => r.id == reviewId));
  }
}

class VendorReviewsViewModel extends BaseViewModel {
  new({required this.service});

  final VendorReviewsService service;

  StoreReviews? reviews;
  Failure? failure;
  Failure? replyFailure;

  Future<void> load() async {
    failure = null;
    setBusy(true);
    switch (await service.reviews()) {
      case Ok(:final value):
        reviews = value;
      case Err(failure: final f):
        failure = f;
    }
    setBusy(false);
  }

  Future<bool> reply(String reviewId, String text) async {
    if (text.trim().isEmpty) return false;
    replyFailure = null;
    final result = await service.reply(reviewId, text.trim());
    switch (result) {
      case Ok():
        await load();
      case Err(failure: final f):
        replyFailure = f;
        notifyListeners();
    }
    return result.isOk;
  }
}

/// Écran 65 : mes avis et réponses.
class VendorReviewsView extends StackedView<VendorReviewsViewModel> {
  const new({
    required this.service,
    required this.onBack,
    super.key,
    this.clock = DateTime.now,
  });

  final VendorReviewsService service;
  final VoidCallback onBack;
  final DateTime Function() clock;

  @override
  VendorReviewsViewModel viewModelBuilder(BuildContext context) =>
      VendorReviewsViewModel(service: service);

  @override
  void onViewModelReady(VendorReviewsViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    VendorReviewsViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final data = vm.reviews;
    final now = clock();
    Future<void> reply(Review r) async {
      final text = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: c.card,
        constraints: const BoxConstraints(maxWidth: DymTokenLayout.formMax),
        builder: (_) => _ReplySheet(
          title: l10n.reviewReplyTo(r.authorFirstName ?? l10n.disputeCustomer),
          initial: r.reply,
        ),
      );
      if (text != null) await vm.reply(r.id, text);
    }

    String ago(DateTime at) {
      final d = now.difference(at);
      if (d.inHours < 1) return l10n.timeMinutesAgo(d.inMinutes.clamp(1, 59));
      if (d.inDays < 1) return l10n.timeHoursAgo(d.inHours);
      return l10n.timeDaysAgo(d.inDays);
    }

    final Widget body;
    if (data == null) {
      body = vm.failure == null
          ? Center(child: CircularProgressIndicator(color: c.brand))
          : DymStateView(
              kind: vm.failure is NetworkFailure
                  ? DymStateKind.offline
                  : DymStateKind.error,
              title: vm.failure is NetworkFailure
                  ? l10n.errorOffline
                  : l10n.errorGeneric,
              message: '',
              actionLabel: l10n.retry,
              onAction: vm.load,
            );
    } else {
      body = ListView(
        padding: EdgeInsets.all(DymLayout.gutter(context)),
        children: [
          for (final w in <Widget>[
            Container(
              padding: const EdgeInsets.all(DymTokenSpace.s3),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(DymTokenRadius.card),
              ),
              child: Row(
                children: [
                  Icon(Icons.star_rounded, color: c.plantain, size: 40),
                  const SizedBox(width: DymTokenSpace.s2),
                  Expanded(
                    child: Text(
                      data.rating == null
                          ? l10n.reviewNoneYet
                          : l10n.reviewSummary(
                              data.rating!.toStringAsFixed(1),
                              data.reviewCount,
                            ),
                      style: t.title.copyWith(fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            if (vm.replyFailure != null)
              Text(
                vm.replyFailure is NetworkFailure
                    ? l10n.errorOffline
                    : l10n.errorGeneric,
                style: t.label.copyWith(color: c.pimentStrong),
              ),
            if (data.reviews.isEmpty)
              Text(
                l10n.reviewNone,
                style: t.body.copyWith(color: c.textSecondary),
              ),
            for (final r in data.reviews)
              Container(
                margin: const EdgeInsets.only(bottom: DymTokenSpace.s2),
                padding: const EdgeInsets.all(DymTokenSpace.s3),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: DymTokenSpace.s2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          r.authorFirstName ?? l10n.disputeCustomer,
                          style: t.title.copyWith(fontSize: 16),
                        ),
                        Semantics(
                          label: l10n.reviewStarsLabel(r.rating),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 1; i <= 5; i++)
                                Icon(
                                  i <= r.rating
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 16,
                                  color: i <= r.rating
                                      ? c.plantain
                                      : c.textSecondary,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          ago(r.createdAt),
                          style: t.label.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                    if (r.comment case final comment?)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(comment, style: t.body),
                      ),
                    if (r.reply case final text?)
                      Container(
                        margin: const EdgeInsets.only(top: DymTokenSpace.s2),
                        padding: const EdgeInsets.all(DymTokenSpace.s2),
                        decoration: BoxDecoration(
                          color: c.tintVertTendre,
                          borderRadius: BorderRadius.circular(
                            DymTokenRadius.chip,
                          ),
                        ),
                        child: Text(l10n.reviewMyReply(text), style: t.label),
                      ),
                    const SizedBox(height: DymTokenSpace.s2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: DymButton(
                        label: r.reply == null
                            ? l10n.disputeReply
                            : l10n.reviewEditReply,
                        icon: Icons.chat_bubble_outline_rounded,
                        variant: DymButtonVariant.secondary,
                        expanded: false,
                        onPressed: () => reply(r),
                      ),
                    ),
                  ],
                ),
              ),
          ])
            DymContentWidth.form(child: w),
        ],
      );
    }
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            DymContentWidth(
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.authBack,
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      l10n.reviewMine,
                      style: t.display.copyWith(fontSize: 26),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _ReplySheet extends StatefulWidget {
  const new({required this.title, this.initial});

  final String title;
  final String? initial;

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
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
                widget.title,
                style: context.dym.text.title.copyWith(fontSize: 18),
              ),
              const SizedBox(height: DymTokenSpace.s2),
              DymTextField(
                label: l10n.reviewReplyHint,
                controller: _text,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: DymTokenSpace.s2),
              ListenableBuilder(
                listenable: _text,
                builder: (context, _) => DymButton(
                  label: l10n.reviewPublishReply,
                  icon: Icons.send_rounded,
                  onPressed: _text.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(context, _text.text.trim()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
