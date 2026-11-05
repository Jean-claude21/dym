import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/content/report_sheet.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_client/features/orders/order_texts.dart';
import 'package:dym_client/features/orders/orders_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Libellé d'une étiquette d'avis.
String reviewTagLabel(DymLocalizations l10n, ReviewTag tag) => switch (tag) {
  ReviewTag.fresh => l10n.reviewTagFresh,
  ReviewTag.wellPacked => l10n.reviewTagWellPacked,
  ReviewTag.fast => l10n.reviewTagFast,
  ReviewTag.friendly => l10n.reviewTagFriendly,
  ReviewTag.unknown => '',
};

const List<ReviewTag> reviewTags = [
  ReviewTag.fresh,
  ReviewTag.wellPacked,
  ReviewTag.fast,
  ReviewTag.friendly,
];

/// Étoiles (lecture seule, ou tactiles avec [onChanged]).
class ReviewStars extends StatelessWidget {
  const new({required this.rating, super.key, this.size = 20, this.onChanged});

  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return Semantics(
      label: l10n.reviewStarsLabel(rating),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            if (onChanged == null)
              Icon(
                i <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                size: size,
                color: i <= rating ? c.plantain : c.textSecondary,
              )
            else
              IconButton(
                tooltip: l10n.reviewStarsLabel(i),
                iconSize: size,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => onChanged!(i),
                icon: Icon(
                  i <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: i <= rating ? c.plantain : c.textSecondary,
                ),
              ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ 63

/// Laisser un avis (écran 63).
class ReviewFormViewModel extends BaseViewModel {
  new({required this.service, required this.orderId, required this.onSent});

  final OrdersService service;
  final String orderId;
  final void Function(Review review) onSent;

  int rating = 0;
  final tags = <ReviewTag>{};
  String comment = '';
  Failure? failure;

  bool get canSend => rating > 0 && !isBusy;

  void setRating(int value) {
    rating = value;
    notifyListeners();
  }

  void toggle(ReviewTag tag) {
    if (!tags.remove(tag)) tags.add(tag);
    notifyListeners();
  }

  Future<void> send() async {
    if (!canSend) return;
    failure = null;
    final result = await runBusyFuture(
      service.leaveReview(
        orderId,
        rating: rating,
        tags: tags.toList(),
        comment: comment.trim().isEmpty ? null : comment.trim(),
      ),
    );
    switch (result) {
      case Ok(:final value):
        onSent(value);
      case Err(failure: final f):
        failure = f;
        notifyListeners();
    }
  }
}

class ReviewFormView extends StackedView<ReviewFormViewModel> {
  const new({
    required this.service,
    required this.orderId,
    required this.storeName,
    required this.onBack,
    required this.onSent,
    super.key,
  });

  final OrdersService service;
  final String orderId;
  final String storeName;
  final VoidCallback onBack;
  final void Function(Review review) onSent;

  @override
  ReviewFormViewModel viewModelBuilder(BuildContext context) =>
      ReviewFormViewModel(service: service, orderId: orderId, onSent: onSent);

  @override
  Widget builder(
    BuildContext context,
    ReviewFormViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final error = switch (vm.failure) {
      null => null,
      ValidationFailure(message: 'review_exists') => l10n.reviewExists,
      ValidationFailure(message: 'review_not_allowed') => l10n.reviewNotAllowed,
      NetworkFailure() => l10n.errorOffline,
      _ => l10n.errorGeneric,
    };
    final children = <Widget>[
      const SizedBox(height: DymTokenSpace.s3),
      Text(
        l10n.reviewQuestion,
        textAlign: TextAlign.center,
        style: t.display.copyWith(fontSize: 26),
      ),
      const SizedBox(height: DymTokenSpace.s3),
      Center(
        child: ReviewStars(
          rating: vm.rating,
          size: 40,
          onChanged: vm.setRating,
        ),
      ),
      const SizedBox(height: DymTokenSpace.s3),
      Wrap(
        spacing: DymTokenSpace.s2,
        runSpacing: DymTokenSpace.s2,
        alignment: WrapAlignment.center,
        children: [
          for (final tag in reviewTags)
            DymFilterChip(
              label: reviewTagLabel(l10n, tag),
              icon: vm.tags.contains(tag) ? Icons.check_circle_rounded : null,
              selected: vm.tags.contains(tag),
              multiple: true,
              onTap: () => vm.toggle(tag),
            ),
        ],
      ),
      const SizedBox(height: DymTokenSpace.s3),
      DymTextField(
        label: l10n.reviewCommentLabel,
        minLines: 2,
        maxLines: 5,
        maxLength: 500,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (v) => vm.comment = v,
      ),
      if (error != null) CartIssue(label: error),
    ];
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(
              title: l10n.reviewTitle,
              subtitle: storeName,
              onBack: onBack,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  for (final w in children) DymContentWidth.form(child: w),
                ],
              ),
            ),
            DymContentWidth.form(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: DymButton(
                  label: l10n.reviewPublish,
                  icon: Icons.check_rounded,
                  loading: vm.isBusy,
                  onPressed: vm.canSend ? vm.send : null,
                ),
              ),
            ),
            TextButton(onPressed: onBack, child: Text(l10n.reviewLater)),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ 64

/// Avis d'une boutique (écran 64).
class StoreReviewsViewModel extends BaseViewModel {
  new({required this.service, required this.storeId});

  final DiscoveryService service;
  final String storeId;

  StoreReviews? reviews;
  Failure? failure;

  Future<void> load() async {
    failure = null;
    setBusy(true);
    switch (await service.storeReviews(storeId)) {
      case Ok(:final value):
        reviews = value;
      case Err(failure: final f):
        failure = f;
    }
    setBusy(false);
  }
}

class StoreReviewsView extends StackedView<StoreReviewsViewModel> {
  const new({
    required this.service,
    required this.storeId,
    required this.storeName,
    required this.onBack,
    super.key,
    this.onMessage,
    this.clock = DateTime.now,
    this.onReport,
  });

  final DiscoveryService service;
  final String storeId;
  final String storeName;
  final VoidCallback onBack;
  final VoidCallback? onMessage;

  /// Signaler un avis abusif (spec 020) ; nul : non proposé.
  final Future<void> Function(Review review, ReportReason reason)? onReport;
  final DateTime Function() clock;

  @override
  StoreReviewsViewModel viewModelBuilder(BuildContext context) =>
      StoreReviewsViewModel(service: service, storeId: storeId);

  @override
  void onViewModelReady(StoreReviewsViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    StoreReviewsViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final data = viewModel.reviews;
    final now = clock();
    Widget body;
    if (data == null) {
      body = DiscoveryState(
        failure: viewModel.isBusy ? null : viewModel.failure,
        onRetry: viewModel.load,
      );
    } else {
      final total = data.reviewCount;
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          for (final w in <Widget>[
            CartCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: DymTokenSpace.s3,
                    runSpacing: DymTokenSpace.s1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        data.rating == null
                            ? '—'
                            : l10n.reviewAverage(
                                data.rating!.toStringAsFixed(1),
                              ),
                        style: t.display.copyWith(fontSize: 40),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ReviewStars(rating: (data.rating ?? 0).round()),
                          Text(
                            l10n.reviewCount(total),
                            style: t.label.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: DymTokenSpace.s2),
                  for (var s = 5; s >= 1; s--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text('$s', style: t.label),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: total == 0
                                  ? 0
                                  : (data.distribution['$s'] ?? 0) / total,
                              color: c.plantain,
                              backgroundColor: c.background,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            if (data.reviews.isEmpty)
              Text(
                l10n.reviewNone,
                textAlign: TextAlign.center,
                style: t.body.copyWith(color: c.textSecondary),
              ),
            for (final r in data.reviews)
              Padding(
                padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
                child: ReviewCard(
                  review: r,
                  now: now,
                  storeName: storeName,
                  footer: switch (onReport) {
                    final report? => Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          final reason = await showReportSheet(context);
                          if (reason != null) await report(r, reason);
                        },
                        icon: const Icon(Icons.flag_outlined),
                        label: Text(l10n.reportAction),
                      ),
                    ),
                    null => null,
                  },
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
            CartHeader(
              title: l10n.reviewStoreTitle,
              subtitle: storeName,
              onBack: onBack,
            ),
            Expanded(child: body),
            if (onMessage case final message?)
              DymContentWidth.form(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: DymButton(
                    label: l10n.chatWriteToStore,
                    icon: Icons.chat_bubble_rounded,
                    onPressed: message,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Avis et réponse de la boutique.
class ReviewCard extends StatelessWidget {
  const new({
    required this.review,
    required this.now,
    required this.storeName,
    super.key,
    this.footer,
  });

  final Review review;
  final DateTime now;
  final String storeName;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final r = review;
    return CartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: DymTokenSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                r.authorFirstName ?? l10n.disputeCustomer,
                style: t.title.copyWith(fontSize: 16),
              ),
              ReviewStars(rating: r.rating, size: 16),
              Text(
                timeAgo(l10n, r.createdAt, now),
                style: t.label.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          if (r.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  for (final tag in r.tags)
                    if (tag != ReviewTag.unknown) reviewTagLabel(l10n, tag),
                ].join(' · '),
                style: t.label.copyWith(color: c.brandDeep),
              ),
            ),
          if (r.comment case final comment?)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(comment, style: t.body),
            ),
          if (r.reply case final reply?)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: DymTokenSpace.s2),
              padding: const EdgeInsets.all(DymTokenSpace.s2),
              decoration: BoxDecoration(
                color: c.tintVertTendre,
                borderRadius: BorderRadius.circular(DymTokenRadius.chip),
              ),
              child: Text(
                l10n.reviewStoreReply(storeName, reply),
                style: t.label.copyWith(fontSize: 15),
              ),
            ),
          ?footer,
        ],
      ),
    );
  }
}

/// Ligne de note d'une boutique (page boutique).
class StoreRatingRow extends StatelessWidget {
  const new({required this.store, required this.onTap, super.key});

  final PublicStore store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final rating = store.rating;
    return InkWell(
      borderRadius: BorderRadius.circular(DymTokenRadius.chip),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, color: c.plantain),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                rating == null
                    ? l10n.reviewNoneYet
                    : '${l10n.reviewAverage(rating.toStringAsFixed(1))} · '
                          '${l10n.reviewCount(store.reviewCount)}',
                style: t.title.copyWith(fontSize: 15),
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
