import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/store/store_format.dart';
import 'package:dym_vendor/features/store/store_summary.dart';
import 'package:flutter/material.dart';

/// Écran 22 : « Ta boutique est ouverte ! », résumé et suite du parcours.
class StoreOpenedView extends StatelessWidget {
  const new({
    required this.store,
    required this.config,
    required this.onSeeStore,
    required this.onAddProduct,
    super.key,
  });

  final MyStore store;
  final CountryConfig config;
  final VoidCallback onSeeStore;

  /// Catalogue (spec `catalog`).
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final summary = StoreSummary(
      store,
      config,
      Localizations.localeOf(context).languageCode,
    );
    final lines = [
      l10n.storeSummaryName,
      if (summary.originLabel != null)
        l10n.storeSummaryOrigin(summary.originLabel!),
      l10n.storeSummaryDelivery(summary.deliveryZoneCount),
      if (summary.paymentLabels.isNotEmpty) summary.paymentLabels,
      hoursSummary(context, store.hours),
    ];
    return Scaffold(
      backgroundColor: c.brand,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final inset = DymLayout.sideInset(
                    box.maxWidth,
                    gutter: DymLayout.gutter(context),
                    maxWidth: DymTokenLayout.formMax,
                  );
                  return ListView(
                    padding: EdgeInsets.fromLTRB(inset, 12, inset, 16),
                    children: [
                      Text(
                        l10n.appNameVendor,
                        textAlign: TextAlign.center,
                        style: t.title.copyWith(color: c.onBrand),
                      ),
                      const SizedBox(height: DymTokenSpace.s3),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: AspectRatio(
                            aspectRatio: 1.1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.plantain,
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: Image(
                                  image: DymIllustrations.storeOpened,
                                  fit: BoxFit.cover,
                                  semanticLabel: l10n.storeOpenedTitle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: DymTokenSpace.s4),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.storeOpenedTitle,
                          textAlign: TextAlign.center,
                          style: t.display.copyWith(
                            fontSize: 34,
                            color: c.onBrand,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: DymTokenSpace.s2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on_rounded, color: c.plantain),
                          const SizedBox(width: DymTokenSpace.s1),
                          Flexible(
                            child: Text(
                              summary.zoneName == null
                                  ? store.name
                                  : l10n.storeNamePlace(
                                      store.name,
                                      summary.zoneName!,
                                    ),
                              textAlign: TextAlign.center,
                              style: t.title.copyWith(color: c.onBrand),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DymTokenSpace.s4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DymTokenSpace.s4,
                          vertical: DymTokenSpace.s2,
                        ),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(
                            DymTokenRadius.card,
                          ),
                          border: Border.all(color: c.hairline),
                        ),
                        child: Column(
                          children: [
                            for (final (i, line) in lines.indexed) ...[
                              if (i > 0)
                                Divider(
                                  height: 1,
                                  color: c.textSecondary.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                              _CheckLine(text: line),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            DymContentWidth.form(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DymLayout.gutter(context),
                  4,
                  DymLayout.gutter(context),
                  12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DymButton(
                      label: l10n.storeAddFirstProduct,
                      icon: Icons.add_rounded,
                      variant: DymButtonVariant.plantain,
                      onPressed: onAddProduct,
                    ),
                    const SizedBox(height: DymTokenSpace.s3),
                    DymButton(
                      label: l10n.storeSeeMine,
                      icon: Icons.storefront_rounded,
                      variant: DymButtonVariant.onBrand,
                      onPressed: onSeeStore,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: c.tintVertTendre,
            child: Icon(Icons.check_rounded, color: c.brandDeep),
          ),
          const SizedBox(width: DymTokenSpace.s4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s2),
              child: Text(
                text,
                style: context.dym.text.title.copyWith(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
