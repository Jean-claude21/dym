import 'dart:math' as math;

import 'package:dym_admin/ui/admin_theme.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Famille de couleur d'une carte (couleur, fond teinté).
typedef AdminHue = (Color, Color);

/// Chiffre clé d'une carte : valeur, unité discrète, libellé.
typedef AdminMetric = ({String value, String? unit, String label});

/// Icône sur fond teinté (titres de carte, menu).
class AdminIconTile extends StatelessWidget {
  const new({required this.icon, required this.hue, super.key, this.size = 26});

  final IconData icon;
  final AdminHue hue;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: hue.$2,
      borderRadius: BorderRadius.circular(size * 0.28),
    ),
    child: Icon(icon, size: size * 0.6, color: hue.$1),
  );
}

/// Carte de la console (maquette « Admin 2026 ») : titre avec icône teintée,
/// trois chiffres clés séparés par des filets, contenu, note de provenance.
class AdminMetricCard extends StatelessWidget {
  const new({
    required this.icon,
    required this.hue,
    required this.title,
    required this.metrics,
    required this.child,
    super.key,
    this.note,
    this.caption,
    this.action,
  });

  final IconData icon;
  final AdminHue hue;
  final String title;
  final List<AdminMetric> metrics;
  final Widget child;

  /// Intitulé discret au-dessus du contenu.
  final String? caption;

  /// Note de provenance en bas de carte.
  final String? note;

  /// Lien à droite du titre (« Voir tout »).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    return Container(
      decoration: BoxDecoration(
        color: AdminPalette.panel,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AdminPalette.line),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(
              children: [
                AdminIconTile(icon: icon, hue: hue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ?action,
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, m) in metrics.indexed)
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 12, right: 8),
                    decoration: i == 0
                        ? null
                        : const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: AdminPalette.line),
                            ),
                          ),
                    child: _MetricValue(metric: m),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (caption case final text?)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                text,
                style: t.label.copyWith(fontSize: 12, color: AdminPalette.ink3),
              ),
            ),
          child,
          if (note case final text?) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              text,
              style: t.label.copyWith(fontSize: 12, color: AdminPalette.ink3),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricValue extends StatelessWidget {
  const new({required this.metric});

  final AdminMetric metric;

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              text: metric.value,
              style: t.display.copyWith(fontSize: 22, height: 1.15),
              children: [
                if (metric.unit case final u?)
                  TextSpan(
                    text: ' $u',
                    style: t.label.copyWith(
                      fontSize: 12,
                      color: AdminPalette.ink2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          metric.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: t.label.copyWith(fontSize: 12, color: AdminPalette.ink3),
        ),
      ],
    );
  }
}

/// Ligne avec barre de proportion : libellé, valeur, complément.
class AdminBarRow extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.fraction,
    required this.hue,
    super.key,
    this.extra,
    this.extraWidth = 58,
    this.onTap,
  });

  final String label;
  final String value;
  final String? extra;

  /// Largeur réservée au complément (pourcentage, nombre de commandes).
  final double extraWidth;

  /// Part de la barre (0 à 1).
  final double fraction;
  final AdminHue hue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.label.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Text(value, style: t.label.copyWith(fontWeight: FontWeight.w600)),
              if (extra case final e?)
                SizedBox(
                  width: extraWidth,
                  child: Text(
                    e,
                    textAlign: TextAlign.end,
                    style: t.label.copyWith(
                      fontSize: 12,
                      color: AdminPalette.ink3,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 6,
              child: ColoredBox(
                color: hue.$2,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: fraction.clamp(0, 1).toDouble(),
                    heightFactor: 1,
                    child: ColoredBox(color: hue.$1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: row,
    );
  }
}

/// Histogramme en colonnes : une barre par valeur, quelques repères sous
/// l'axe, valeur écrite au-dessus des plus hautes.
class AdminColumnChart extends StatelessWidget {
  const new({
    required this.values,
    required this.hue,
    required this.label,
    required this.semanticLabel,
    super.key,
    this.height = 170,
  });

  final List<int> values;
  final AdminHue hue;

  /// Repère sous la barre i (null : rien).
  final String? Function(int i) label;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    final top = values.fold(0, math.max);
    final small = t.label.copyWith(fontSize: 11, color: AdminPalette.ink3);
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        height: height + 40,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  // Place réservée à la valeur écrite au-dessus des barres.
                  final room = math.max(
                    0,
                    box.maxHeight -
                        (small.fontSize ?? 11) *
                            1.6 *
                            MediaQuery.textScalerOf(context).scale(1) -
                        6,
                  );
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final v in values)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: values.length > 20 ? 1.5 : 4,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (top > 0 && v >= top * 0.6)
                                  Text(
                                    '$v',
                                    maxLines: 1,
                                    style: small.copyWith(
                                      color: AdminPalette.ink2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                const SizedBox(height: 3),
                                Container(
                                  height: top == 0
                                      ? 2
                                      : math.max(2, v / top * room).toDouble(),
                                  decoration: BoxDecoration(
                                    color: v == 0 ? AdminPalette.muted : hue.$1,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 6),
            SizedBox(
              height: 16 * MediaQuery.textScalerOf(context).scale(1),
              child: Row(
                children: [
                  for (var i = 0; i < values.length; i++)
                    Expanded(
                      child: OverflowBox(
                        maxWidth: 80,
                        maxHeight: 16,
                        child: Text(
                          label(i) ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: small,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grille de cartes à hauteur égale par ligne : 3 colonnes sur bureau, 2 sur
/// tablette, 1 sur téléphone.
class AdminCardGrid extends StatelessWidget {
  const new({required this.children, super.key, this.gap = 14});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth;
      final cols = w >= 1050
          ? 3
          : w >= 680
          ? 2
          : 1;
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += cols) {
        final line = children.sublist(i, math.min(i + cols, children.length));
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (j, card) in line.indexed) ...[
                  if (j > 0) SizedBox(width: gap),
                  Expanded(child: card),
                ],
                for (var k = line.length; k < cols; k++) ...[
                  SizedBox(width: gap),
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) SizedBox(height: gap),
            r,
          ],
        ],
      );
    },
  );
}

/// Choix exclusif compact (période, section), façon onglets segmentés.
class AdminSegmented<T> extends StatelessWidget {
  const new({
    required this.options,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AdminPalette.muted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminPalette.line),
      ),
      child: Wrap(
        children: [
          for (final (value, label) in options)
            Semantics(
              selected: value == selected,
              button: true,
              child: Material(
                color: value == selected
                    ? AdminPalette.panel
                    : Colors.transparent,
                elevation: value == selected ? 1 : 0,
                shadowColor: const Color(0x22000000),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onSelect(value),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 36),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        label,
                        style: t.label.copyWith(
                          fontWeight: value == selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: value == selected
                              ? context.dym.colors.textPrimary
                              : AdminPalette.ink2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
