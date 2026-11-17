import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Statistiques d'une vidéo pour sa propriétaire (spec 103) : temps moyen,
/// fin de lecture, ventes générées. [money] formate un montant (unités
/// mineures) dans la devise du pays.
class ContentStatsLine extends StatelessWidget {
  const new({required this.item, required this.money, super.key});

  final ContentItem item;
  final String Function(int minor) money;

  @override
  Widget build(BuildContext context) {
    final stats = item.stats;
    if (stats == null || !item.isVideo) return const SizedBox.shrink();
    final l10n = DymLocalizations.of(context);
    final t = context.dym.text;
    final c = context.dym.colors;
    final parts = [
      l10n.contentStatsAvgWatch((stats.avgWatchMs / 1000).round()),
      l10n.contentStatsCompletion((stats.completionRate * 100).round()),
      l10n.contentStatsSales(stats.salesOrders, money(stats.salesMinor)),
    ];
    return Text(
      parts.join(' · '),
      style: t.label.copyWith(color: c.textSecondary),
    );
  }
}

/// Choix de la miniature parmi les images de la vidéo convertie. Rend
/// l'image choisie (1..n), 0 pour l'image par défaut, null si annulé.
Future<int?> showCoverPicker(BuildContext context, ContentItem item) =>
    showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final l10n = DymLocalizations.of(context);
        final t = context.dym.text;
        final c = context.dym.colors;
        final frames = item.frameUrls;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DymTokenSpace.s4,
              0,
              DymTokenSpace.s4,
              DymTokenSpace.s4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.contentCoverChoose, style: t.title),
                const SizedBox(height: DymTokenSpace.s3),
                if (frames.isEmpty)
                  Text(l10n.contentCoverPending, style: t.body)
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.6,
                    ),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 4,
                      mainAxisSpacing: DymTokenSpace.s1,
                      crossAxisSpacing: DymTokenSpace.s1,
                      childAspectRatio: 9 / 16,
                      children: [
                        for (var i = 0; i < frames.length; i++)
                          InkWell(
                            onTap: () => Navigator.pop(context, i + 1),
                            child: DecoratedBox(
                              position: DecorationPosition.foreground,
                              decoration: BoxDecoration(
                                border: item.coverFrame == i + 1
                                    ? Border.all(color: c.brandDeep, width: 3)
                                    : null,
                              ),
                              child: Image.network(
                                frames[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    ColoredBox(color: c.tintVertTendre),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: DymTokenSpace.s2),
                if (frames.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.pop(context, 0),
                    child: Text(l10n.contentCoverDefault),
                  ),
              ],
            ),
          ),
        );
      },
    );
