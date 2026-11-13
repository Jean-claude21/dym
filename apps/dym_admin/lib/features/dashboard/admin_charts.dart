import 'dart:math' as math;

import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Graphiques du pilotage (spec 073), dessinés sans bibliothèque externe :
/// courbe avec axes et info-bulle, mini-courbe, anneau, entonnoir, barres.

/// Ligne de cartes : côte à côte sur un écran large (même hauteur, largeur
/// proportionnelle à `span`), empilées sur un écran étroit.
class AdminRow extends StatelessWidget {
  const new({required this.items, super.key, this.breakpoint = 1000});

  /// (part sur 12, carte).
  final List<(int, Widget)> items;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, (_, child)) in items.indexed) ...[
            if (i > 0) const SizedBox(height: DymTokenSpace.s3),
            child,
          ],
        ],
      );
    }
    if (width < breakpoint) {
      // Tablette : deux cartes par ligne ; une carte large reste seule.
      final rows = <List<Widget>>[];
      var open = false;
      for (final (span, child) in items) {
        if (span < 7 && open) {
          rows.last.add(child);
          open = false;
        } else {
          rows.add([child]);
          open = span < 7;
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const SizedBox(height: DymTokenSpace.s3),
            if (row.length == 1)
              row.first
            else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: row[0]),
                    const SizedBox(width: DymTokenSpace.s3),
                    Expanded(child: row[1]),
                  ],
                ),
              ),
          ],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, (span, child)) in items.indexed) ...[
            if (i > 0) const SizedBox(width: DymTokenSpace.s3),
            Expanded(flex: span, child: child),
          ],
        ],
      ),
    );
  }
}

/// Mini-courbe d'une carte de chiffre.
class AdminSparkline extends StatelessWidget {
  const new({required this.values, required this.color, super.key});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 36,
      width: double.infinity,
      child: CustomPaint(painter: _SparkPainter(values, color)),
    ),
  );
}

class _SparkPainter extends CustomPainter {
  new(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final top = values.reduce(math.max);
    final max = top <= 0 ? 1.0 : top;
    final dx = size.width / (values.length - 1);
    final path = Path();
    for (final (i, v) in values.indexed) {
      final p = Offset(i * dx, size.height - 2 - (v / max) * (size.height - 4));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas
      ..drawPath(area, Paint()..color = color.withValues(alpha: 0.12))
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.color != color;
}

/// Courbe d'une série : axes, quadrillage, info-bulle au survol ou au
/// toucher. Les libellés (axe, info-bulle) sont fournis par l'appelant.
class AdminTrendChart extends StatefulWidget {
  const new({
    required this.values,
    required this.xLabel,
    required this.yLabel,
    required this.tooltip,
    required this.semanticLabel,
    super.key,
    this.height = 260,
  });

  final List<double> values;

  /// Libellé de l'axe horizontal pour le point `i` (nul : aucun).
  final String? Function(int i) xLabel;

  /// Libellé d'une graduation verticale.
  final String Function(double value) yLabel;

  /// Texte de l'info-bulle du point `i`.
  final String Function(int i) tooltip;
  final String semanticLabel;
  final double height;

  @override
  State<AdminTrendChart> createState() => _AdminTrendChartState();
}

class _AdminTrendChartState extends State<AdminTrendChart> {
  int? _hover;
  double _width = 0;

  static const _left = 64.0;
  static const _bottom = 28.0;

  void _track(Offset local) {
    final box = context.findRenderObject() as RenderBox?;
    final n = widget.values.length;
    if (box == null || n == 0) return;
    _width = box.size.width;
    final plot = box.size.width - _left - 24;
    final step = n == 1 ? plot : plot / (n - 1);
    final i = ((local.dx - _left) / step).round().clamp(0, n - 1);
    if (i != _hover) setState(() => _hover = i);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final values = widget.values;
    final top = values.isEmpty ? 0.0 : values.reduce(math.max);
    final max = _niceMax(top);
    final hover = _hover;
    return Semantics(
      label: widget.semanticLabel,
      child: MouseRegion(
        onHover: (e) => _track(e.localPosition),
        onExit: (_) => setState(() => _hover = null),
        child: GestureDetector(
          onPanDown: (d) => _track(d.localPosition),
          onPanUpdate: (d) => _track(d.localPosition),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrendPainter(
                values: values,
                max: max,
                hover: hover,
                line: c.brand,
                grid: c.hairline,
                labelStyle: t.label.copyWith(
                  fontSize: 12,
                  color: c.textSecondary,
                ),
                xLabel: widget.xLabel,
                yLabel: widget.yLabel,
                left: _left,
                bottom: _bottom,
              ),
              child: hover == null || values.isEmpty
                  ? null
                  : _Tooltip(
                      text: widget.tooltip(hover),
                      fraction: values.length == 1
                          ? 0
                          : hover / (values.length - 1),
                      left: _left,
                      width: _width,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Graduation « ronde » au-dessus du maximum (1, 2, 5 × 10ⁿ).
double _niceMax(double top) {
  if (top <= 0) return 4;
  final magnitude = math
      .pow(10, (math.log(top) / math.ln10).floor())
      .toDouble();
  for (final m in const [1, 2, 2.5, 5, 10]) {
    if (top <= m * magnitude) return m * magnitude;
  }
  return 10 * magnitude;
}

class _Tooltip extends StatelessWidget {
  const new({
    required this.text,
    required this.fraction,
    required this.left,
    required this.width,
  });

  final String text;
  final double fraction;
  final double left;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final px = left + fraction * (width - left - 24);
    // L'info-bulle reste dans le cadre : à gauche du point en fin de courbe.
    final onRight = fraction < 0.6;
    return Padding(
      padding: EdgeInsets.only(
        left: onRight ? px + 10 : 0,
        right: onRight ? 0 : math.max(0, width - px + 10),
      ),
      child: Align(
        alignment: onRight ? Alignment.topLeft : Alignment.topRight,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DymTokenSpace.s2,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: c.textPrimary,
            borderRadius: BorderRadius.circular(DymTokenRadius.chip),
          ),
          child: Text(
            text,
            style: context.dym.text.label.copyWith(
              color: c.background,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  new({
    required this.values,
    required this.max,
    required this.hover,
    required this.line,
    required this.grid,
    required this.labelStyle,
    required this.xLabel,
    required this.yLabel,
    required this.left,
    required this.bottom,
  });

  final List<double> values;
  final double max;
  final int? hover;
  final Color line;
  final Color grid;
  final TextStyle labelStyle;
  final String? Function(int i) xLabel;
  final String Function(double value) yLabel;
  final double left;
  final double bottom;

  void _text(
    Canvas canvas,
    String s,
    Offset at, {
    TextAlign align = TextAlign.left,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: labelStyle),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: 120);
    final dx = switch (align) {
      TextAlign.right => at.dx - tp.width,
      TextAlign.center => at.dx - tp.width / 2,
      _ => at.dx,
    };
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Marge à droite : le dernier libellé de l'axe reste entier.
    final plotW = size.width - left - 24;
    final plotH = size.height - bottom - 8;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    // Quadrillage et graduations (0, ¼, ½, ¾, max).
    for (var k = 0; k <= 4; k++) {
      final y = 8 + plotH - plotH * k / 4;
      canvas.drawLine(Offset(left, y), Offset(left + plotW, y), gridPaint);
      _text(
        canvas,
        yLabel(max * k / 4),
        Offset(left - 8, y),
        align: TextAlign.right,
      );
    }
    final n = values.length;
    if (n == 0) return;
    Offset at(int i) => Offset(
      left + (n == 1 ? plotW / 2 : plotW * i / (n - 1)),
      8 + plotH - (values[i] / max).clamp(0, 1) * plotH,
    );
    // Libellés de l'axe horizontal, espacés pour rester lisibles.
    final every = math.max(1, (n / math.max(1, plotW / 64)).ceil());
    for (var i = 0; i < n; i += every) {
      if (xLabel(i) case final s?) {
        _text(
          canvas,
          s,
          Offset(at(i).dx, size.height - bottom / 2),
          align: TextAlign.center,
        );
      }
    }
    final path = Path();
    for (var i = 0; i < n; i++) {
      final p = at(i);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    final area = Path.from(path)
      ..lineTo(at(n - 1).dx, 8 + plotH)
      ..lineTo(at(0).dx, 8 + plotH)
      ..close();
    canvas
      ..drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              line.withValues(alpha: 0.22),
              line.withValues(alpha: 0.02),
            ],
          ).createShader(Rect.fromLTWH(left, 8, plotW, plotH)),
      )
      ..drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    if (hover case final h? when h < n) {
      final p = at(h);
      canvas
        ..drawLine(
          Offset(p.dx, 8),
          Offset(p.dx, 8 + plotH),
          Paint()
            ..color = line.withValues(alpha: 0.35)
            ..strokeWidth = 1,
        )
        ..drawCircle(p, 6, Paint()..color = line)
        ..drawCircle(p, 3, Paint()..color = const Color(0xFFFFFFFF));
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values || old.hover != hover || old.max != max;
}

/// Part d'un anneau.
typedef DonutPart = ({String label, int value, Color color});

/// Anneau avec total au centre et légende (valeur et part).
class AdminDonut extends StatelessWidget {
  const new({
    required this.parts,
    required this.centerLabel,
    required this.percent,
    super.key,
  });

  final List<DonutPart> parts;
  final String centerLabel;

  /// Formate un pourcentage (localisé par l'appelant).
  final String Function(int p) percent;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final total = parts.fold(0, (s, p) => s + p.value);
    final ring = SizedBox(
      width: 132,
      height: 132,
      child: CustomPaint(
        painter: _DonutPainter(parts, total, c.muted),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$total', style: t.title.copyWith(fontSize: 26)),
              Text(
                centerLabel,
                style: t.label.copyWith(color: c.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in parts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: p.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: DymTokenSpace.s2),
                Expanded(child: Text(p.label, style: t.body)),
                Text(
                  '${p.value}',
                  style: t.body.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    total == 0 ? '—' : percent((p.value * 100 / total).round()),
                    textAlign: TextAlign.end,
                    style: t.label.copyWith(color: c.textSecondary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    return Semantics(
      label: [
        centerLabel,
        for (final p in parts) '${p.label} ${p.value}',
      ].join(', '),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: ring),
            const SizedBox(height: DymTokenSpace.s3),
            legend,
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  new(this.parts, this.total, this.empty);

  final List<DonutPart> parts;
  final int total;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - stroke / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    if (total == 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = empty);
      return;
    }
    var start = -math.pi / 2;
    for (final p in parts) {
      if (p.value == 0) continue;
      final sweep = math.pi * 2 * p.value / total;
      // Petit blanc entre les parts pour les distinguer.
      canvas.drawArc(
        rect,
        start,
        math.max(0, sweep - 0.03),
        false,
        paint..color = p.color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.parts != parts || old.total != total;
}

/// Étape d'un entonnoir.
typedef FunnelStep = ({String label, int value});

/// Entonnoir : barres proportionnelles à la première étape et passage
/// d'une étape à la suivante.
class AdminFunnelChart extends StatelessWidget {
  const new({required this.steps, required this.percent, super.key});

  final List<FunnelStep> steps;
  final String Function(int p) percent;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final first = steps.isEmpty ? 0 : steps.first.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, s) in steps.indexed) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  s.label,
                  style: t.label.copyWith(color: c.textSecondary),
                ),
              ),
              Text(
                '${s.value}',
                style: t.body.copyWith(fontWeight: FontWeight.w700),
              ),
              if (i > 0)
                SizedBox(
                  width: 56,
                  child: Text(
                    steps[i - 1].value == 0
                        ? '—'
                        : percent((s.value * 100 / steps[i - 1].value).round()),
                    textAlign: TextAlign.end,
                    style: t.label.copyWith(
                      color: c.brandDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                const SizedBox(width: 56),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: first == 0 ? 0 : s.value / first,
              minHeight: 12,
              color: Color.lerp(
                c.brand,
                c.brandDeep,
                i / math.max(1, steps.length - 1),
              ),
              backgroundColor: c.muted,
            ),
          ),
          if (i < steps.length - 1) const SizedBox(height: DymTokenSpace.s2),
        ],
      ],
    );
  }
}

/// Classement en barres horizontales (rayons, boutiques).
class AdminBarList extends StatelessWidget {
  const new({required this.rows, super.key});

  /// (libellé, valeur affichée, part 0–1).
  final List<(String, String, double)> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (label, value, share) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
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
                        style: t.body,
                      ),
                    ),
                    const SizedBox(width: DymTokenSpace.s2),
                    Text(
                      value,
                      style: t.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share.clamp(0, 1),
                    minHeight: 8,
                    color: c.brand,
                    backgroundColor: c.muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
