import 'dart:async';

import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// IA et paiements (écran 77) : requêtes comprises, latence, passages à la
/// recherche classique, paiements de la dernière heure (alerte sous 90 %).
class AdminAiHealthViewModel extends AdminViewModel {
  new({required this.service});

  final AdminService service;

  AiHealth? data;

  bool get ready => data != null && !failed;

  Future<void> load() => run(service.currencies, () async {
    final result = await service.aiHealth();
    if (result case Ok(:final value)) data = value;
    return result.failureOrNull;
  });
}

class AdminAiHealthView extends StackedView<AdminAiHealthViewModel> {
  const new({required this.service, super.key, this.clock = DateTime.now});

  final AdminService service;
  final DateTime Function() clock;

  @override
  AdminAiHealthViewModel viewModelBuilder(BuildContext context) =>
      AdminAiHealthViewModel(service: service);

  @override
  void onViewModelReady(AdminAiHealthViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(
    BuildContext context,
    AdminAiHealthViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final d = vm.data;
    if (!vm.ready || d == null) {
      return AdminState(
        failure: vm.isBusy ? null : vm.failure,
        onRetry: vm.load,
      );
    }
    final dates = MaterialLocalizations.of(context);
    String percent(int? p) => p == null ? '—' : l10n.adminPercent(p);
    Widget tile(
      IconData icon,
      String label,
      String value, {
      String? note,
      AdminTone tone = AdminTone.neutral,
    }) {
      final (bg, fg) = switch (tone) {
        AdminTone.danger => (c.tintPimentClair, c.pimentStrong),
        AdminTone.warning => (c.tintPeche, c.originMaisonFg),
        AdminTone.success => (c.tintVertTendre, c.brandDeep),
        AdminTone.neutral => (c.card, c.textPrimary),
      };
      return Container(
        width: 240,
        padding: const EdgeInsets.all(DymTokenSpace.s3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: t.label.copyWith(color: fg)),
                  Text(value, style: t.title.copyWith(fontSize: 26, color: fg)),
                  if (note != null)
                    Text(note, style: t.label.copyWith(color: fg)),
                ],
              ),
            ),
            Icon(icon, color: fg),
          ],
        ),
      );
    }

    final understood = d.understoodPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (d.paymentsAlert)
          AdminAlert(l10n.aiPaymentsAlert(percent(d.paymentsPercent))),
        Wrap(
          spacing: DymTokenSpace.s3,
          runSpacing: DymTokenSpace.s3,
          children: [
            tile(
              Icons.chat_rounded,
              l10n.aiUnderstood,
              percent(understood),
              note: l10n.ai24h,
              tone: understood == null || understood >= 80
                  ? AdminTone.success
                  : AdminTone.warning,
            ),
            tile(
              Icons.schedule_rounded,
              l10n.aiLatency,
              d.latencyMs == null ? '—' : l10n.aiSeconds(d.latencyMs! / 1000),
              tone: (d.latencyMs ?? 0) > 3000
                  ? AdminTone.warning
                  : AdminTone.neutral,
            ),
            tile(
              Icons.search_rounded,
              l10n.aiFallback,
              percent(d.fallbackPercent),
              tone: (d.fallbackPercent ?? 0) > 20
                  ? AdminTone.warning
                  : AdminTone.neutral,
            ),
            tile(
              Icons.credit_card_rounded,
              l10n.adminPaymentsSucceeded1h,
              percent(d.paymentsPercent),
              note: l10n.ai1h,
              tone: d.paymentsAlert ? AdminTone.danger : AdminTone.success,
            ),
          ],
        ),
        const SizedBox(height: DymTokenSpace.s3),
        AdminCard(
          title: l10n.aiSeries,
          child: SizedBox(
            height: 140,
            child: Semantics(
              label: l10n.aiSeries,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in d.series)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              percent(day.percent),
                              style: t.label,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: FractionallySizedBox(
                                heightFactor: ((day.percent ?? 0) / 100).clamp(
                                  0.02,
                                  1,
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: c.brand.withValues(alpha: 0.6),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              dates.formatShortMonthDay(day.day),
                              style: t.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: DymTokenSpace.s3),
        AdminCard(
          title: l10n.aiMisses,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (d.misses.isEmpty) AdminEmpty(l10n.adminNoData),
              for (final m in d.misses)
                AdminField(
                  [
                    dates.formatTimeOfDay(
                      TimeOfDay.fromDateTime(m.at.toLocal()),
                    ),
                    aiUsageLabel(l10n, m.usage),
                  ].join(' · '),
                  [
                    m.query ?? '—',
                    if (m.outcome == 'failure')
                      l10n.aiOutcomeFailure
                    else
                      l10n.aiOutcomeNoResult,
                  ].join(' · '),
                ),
              const SizedBox(height: DymTokenSpace.s2),
              Text(
                l10n.aiNoPersonalData,
                style: t.label.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String aiUsageLabel(DymLocalizations l10n, String usage) => switch (usage) {
  'search_transcription' => l10n.aiUsageVoice,
  'search_from_photo' => l10n.aiUsagePhoto,
  _ => l10n.aiUsageText,
};
