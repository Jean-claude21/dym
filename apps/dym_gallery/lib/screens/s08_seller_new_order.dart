import 'package:dym_core/dym_core.dart';
import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_gallery/demo/demo_catalog.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/screens/common.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Écran 08 — App vendeuse : nouvelle commande reçue, avec sonnerie visuelle.
class SellerNewOrderScreen extends StatefulWidget {
  const new({required this.country, super.key});

  final DemoCountry country;

  @override
  State<SellerNewOrderScreen> createState() => _SellerNewOrderScreenState();
}

class _SellerNewOrderScreenState extends State<SellerNewOrderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  static const _lines = <String, int>{'tomates': 2, 'gombo': 1, 'piment': 1};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DymMotion.enabled(context)) {
      _ring.repeat();
    } else {
      _ring.value = 0;
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final country = widget.country;
    final total = _lines.entries.fold(
      Money.zero(country.currency),
      (sum, e) =>
          sum + country.price(DemoCatalog.products[e.key]!.priceXof) * e.value,
    );
    final white = c.onBrand;
    return Scaffold(
      backgroundColor: c.brandDeep,
      body: SafeArea(
        child: BoundedListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Text(
              'DYM Vendeuse',
              textAlign: TextAlign.center,
              style: t.title.copyWith(color: white, fontSize: 18),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: AnimatedBuilder(
                animation: _ring,
                builder: (context, child) => CustomPaint(
                  painter: _RingPainter(_ring.value, c.plantain),
                  child: child,
                ),
                child: Center(
                  child: Container(
                    width: 196,
                    height: 196,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: c.plantain,
                      shape: BoxShape.circle,
                    ),
                    child: Image(image: DemoImages.product('tomates')),
                  ),
                ),
              ),
            ),
            Text(
              'Nouvelle commande !',
              textAlign: TextAlign.center,
              style: t.display.copyWith(color: white, fontSize: 30),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded, color: c.plantain),
                const SizedBox(width: 4),
                Text(
                  'Awa · Bè Kpota · à 1,2 km',
                  style: t.title.copyWith(color: white, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(DymTokenRadius.card),
              ),
              child: Column(
                children: [
                  for (final e in _lines.entries) ...[
                    _line(e.key, e.value, country),
                    const SizedBox(height: 10),
                  ],
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tu encaisses',
                          style: t.title.copyWith(fontSize: 20),
                        ),
                      ),
                      MoneyText(total, size: 24, color: c.brandDeep),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.tintVertTendre,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.payments_rounded, color: c.brandDeep),
                        const SizedBox(width: 10),
                        Text(
                          'Cash à la livraison',
                          style: t.title.copyWith(
                            fontSize: 17,
                            color: c.brandDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Image(image: DemoImages.zem, width: 64, height: 56),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Le zem passe récupérer à 10 h 20',
                          style: t.label.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Réponds dans les 10 minutes',
              textAlign: TextAlign.center,
              style: t.title.copyWith(color: white, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DymButton(
                    label: 'Refuser',
                    variant: DymButtonVariant.onBrand,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DymButton(
                    label: 'Accepter',
                    variant: DymButtonVariant.plantain,
                    onPressed: () => _ring.stop(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String id, int quantity, DemoCountry country) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final p = DemoCatalog.products[id]!;
    return Row(
      children: [
        Container(
          width: 72,
          height: 60,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.tintPeche,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image(image: p.image),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                style: t.label.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${p.unit} × $quantity',
                style: t.label.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
        MoneyText(
          country.price(p.priceXof) * quantity,
          size: 16,
          color: c.brandDeep,
        ),
      ],
    );
  }
}

/// Ondes concentriques de sonnerie autour du disque central.
class _RingPainter extends CustomPainter {
  new(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < 2; i++) {
      final phase = (t + i * 0.5) % 1;
      final radius = 104 + phase * 40;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = color.withValues(alpha: (1 - phase) * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.t != t;
}
