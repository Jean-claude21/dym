import 'dart:ui' show PathMetric;

import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_gallery/demo/demo_catalog.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/screens/common.dart';
import 'package:dym_gallery/screens/s05_cart.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Écran 06 — Suivi : le zem avance sur l'itinéraire entre les deux boutiques
/// et la maison de la cliente.
class TrackingScreen extends StatefulWidget {
  const new({required this.country, super.key});

  final DemoCountry country;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  /// Position courante du zem sur l'itinéraire (0 = départ, 1 = arrivée).
  static const _current = 0.68;

  late final AnimationController _ride = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DymMotion.enabled(context)) {
      _ride.forward(from: 0);
    } else {
      _ride.value = 1;
    }
  }

  @override
  void dispose() {
    _ride.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final total = DemoCartScreenData.total(widget.country);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DymTokenRadius.card),
              child: SizedBox(
                height: 400,
                child: LayoutBuilder(
                  builder: (context, box) => _Map(
                    size: Size(box.maxWidth, box.maxHeight),
                    progress: CurvedAnimation(
                      parent: _ride,
                      curve: DymMotion.standard,
                    ),
                    current: _current,
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(8, -86),
              child: Align(
                alignment: Alignment.centerLeft,
                child: WhiteCard(
                  padding: const EdgeInsets.fromLTRB(16, 12, 24, 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded, color: c.brand, size: 36),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ton zem arrive dans',
                            style: t.title.copyWith(fontSize: 17),
                          ),
                          Text(
                            '9 min',
                            style: t.display.copyWith(
                              fontSize: 44,
                              height: 1,
                              color: c.brandDeep,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -70),
              child: Column(
                children: [
                  WhiteCard(
                    child: Row(
                      children: [
                        DymAvatar(
                          image: DemoImages.person('yao'),
                          size: 64,
                          ring: false,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Yao ',
                                  style: t.title.copyWith(fontSize: 22),
                                ),
                                TextSpan(
                                  text: 'arrive en zem',
                                  style: t.body.copyWith(
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _roundAction(Icons.call_rounded, 'Appeler Yao'),
                        const SizedBox(width: 8),
                        _roundAction(Icons.chat_rounded, 'Écrire à Yao'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const WhiteCard(
                    child: DymTimeline(
                      steps: [
                        DymStep('Confirmée', DymStepState.done),
                        DymStep('Préparée par 2 boutiques', DymStepState.done),
                        DymStep('En route', DymStepState.current),
                        DymStep('Livrée', DymStepState.todo),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Substitution(),
                  const SizedBox(height: 10),
                  WhiteCard(
                    child: Row(
                      children: [
                        Icon(Icons.payments_rounded, color: c.brand, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'À payer à la livraison',
                                style: t.label.copyWith(fontSize: 15),
                              ),
                              Text(
                                '${total.format()} en cash',
                                style: t.price.copyWith(
                                  fontSize: 24,
                                  color: c.brandDeep,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _roundAction(IconData icon, String label) {
    final c = context.dym.colors;
    return Material(
      color: c.tintVertTendre,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: label,
        onPressed: () {},
        icon: Icon(icon, color: c.brandDeep),
      ),
    );
  }
}

class _Substitution extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return WhiteCard(
      color: c.tintPlantainClair,
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image(image: DemoImages.product('tomates')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Étal d'Akossiwa a remplacé :",
                  style: t.label.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    style: t.label.copyWith(color: c.textSecondary),
                    children: [
                      const TextSpan(text: 'tomates grappe '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: c.textSecondary,
                        ),
                      ),
                      const TextSpan(text: ' tomates rondes, même prix'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DymButton(
                        label: 'Accepter',
                        compact: true,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DymButton(
                        label: 'Refuser',
                        variant: DymButtonVariant.secondary,
                        compact: true,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte stylisée + itinéraire + zem animé.
class _Map extends StatelessWidget {
  const new({
    required this.size,
    required this.progress,
    required this.current,
  });

  final Size size;
  final Animation<double> progress;
  final double current;

  Path _route() {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.12, h * 0.16)
      ..cubicTo(w * 0.22, h * 0.32, w * 0.36, h * 0.30, w * 0.50, h * 0.27)
      ..cubicTo(w * 0.66, h * 0.24, w * 0.62, h * 0.48, w * 0.72, h * 0.52)
      ..cubicTo(w * 0.82, h * 0.56, w * 0.80, h * 0.66, w * 0.88, h * 0.70);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final route = _route();
    final metric = route.computeMetrics().first;
    final akossiwa = DemoCatalog.stores['akossiwa']!;
    final esi = DemoCatalog.stores['esi']!;
    return Stack(
      children: [
        Positioned.fill(
          child: Image(image: DemoImages.map, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _RoutePainter(route, c.brand)),
        ),
        _pin(context, metric, 0, akossiwa.avatar, akossiwa.name),
        _pin(context, metric, 0.42, esi.avatar, esi.name),
        _homePin(context, metric),
        AnimatedBuilder(
          animation: progress,
          builder: (context, child) {
            final tangent = metric.getTangentForOffset(
              metric.length * current * progress.value,
            )!;
            return Positioned(
              left: tangent.position.dx - 30,
              top: tangent.position.dy - 30,
              child: child!,
            );
          },
          child: Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: c.plantain,
              shape: BoxShape.circle,
              border: Border.all(color: c.card, width: 3),
            ),
            child: Image(image: DemoImages.zem),
          ),
        ),
      ],
    );
  }

  Widget _pin(
    BuildContext context,
    PathMetric metric,
    double at,
    ImageProvider avatar,
    String label,
  ) {
    final p = metric.getTangentForOffset(metric.length * at)!.position;
    return Positioned(
      left: p.dx - 22,
      top: p.dy - 52,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.dym.colors.brand, width: 3),
            ),
            child: DymAvatar(image: avatar, size: 44, ring: false),
          ),
          const SizedBox(width: 4),
          _Label(label),
        ],
      ),
    );
  }

  Widget _homePin(BuildContext context, PathMetric metric) {
    final c = context.dym.colors;
    final p = metric.getTangentForOffset(metric.length)!.position;
    return Positioned(
      left: p.dx - 24,
      top: p.dy - 54,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.pimentStrong,
              shape: BoxShape.circle,
              border: Border.all(color: c.card, width: 3),
            ),
            child: Icon(Icons.home_rounded, color: c.onBrand),
          ),
          const _Label('Chez toi'),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.dym.colors.card,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [DymTokenShadows.card],
      ),
      child: Text(
        text,
        style: context.dym.text.label.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  new(this.route, this.color);

  final Path route;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawPath(
        route,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      )
      ..drawPath(
        route,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) => oldDelegate.route != route;
}
