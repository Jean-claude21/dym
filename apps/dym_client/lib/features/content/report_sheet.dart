import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/material.dart';

/// Libellé d'un motif de signalement.
String reportReasonLabel(DymLocalizations l10n, ReportReason r) => switch (r) {
  ReportReason.misleading => l10n.reportMisleading,
  ReportReason.offensive => l10n.reportOffensive,
  ReportReason.forbidden => l10n.reportForbidden,
  ReportReason.spam => l10n.reportSpam,
  ReportReason.other => l10n.reportOther,
};

/// Choix du motif d'un signalement (A-MOD-01) ; `null` : annulé.
Future<ReportReason?> showReportSheet(BuildContext context) {
  final l10n = DymLocalizations.of(context);
  return showModalBottomSheet<ReportReason>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                l10n.reportTitle,
                style: Theme.of(sheet).textTheme.titleLarge,
              ),
            ),
            for (final r in ReportReason.values)
              ListTile(
                minTileHeight: 56,
                leading: const Icon(Icons.flag_outlined),
                title: Text(reportReasonLabel(l10n, r)),
                onTap: () => Navigator.of(sheet).pop(r),
              ),
          ],
        ),
      ),
    ),
  );
}
