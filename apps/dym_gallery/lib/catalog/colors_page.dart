import 'package:dym_gallery/catalog/contrast.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Couleurs des tokens et contrastes mesurés des couples texte/fond.
class ColorsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final swatches = <(String, Color)>[
      ('brand.primary', c.brand),
      ('brand.primary-deep', c.brandDeep),
      ('accent.plantain', c.plantain),
      ('accent.piment', c.piment),
      ('accent.piment-strong', c.pimentStrong),
      ('accent.huile', c.huile),
      ('accent.indigo', c.indigo),
      ('surface.background', c.background),
      ('surface.card', c.card),
      ('text.primary', c.textPrimary),
      ('text.secondary', c.textSecondary),
      ('tint.peche', c.tintPeche),
      ('tint.vert-tendre', c.tintVertTendre),
      ('tint.plantain-clair', c.tintPlantainClair),
      ('tint.piment-clair', c.tintPimentClair),
      ('tint.indigo-clair', c.tintIndigoClair),
    ];
    final pairs = <(String, Color, Color)>[
      ('Texte blanc / vert profond', c.onBrand, c.brand),
      ('Texte blanc / vert profond', c.onBrand, c.brandDeep),
      ('Encre / plantain', c.textPrimary, c.plantain),
      ('Texte blanc / piment foncé', c.onBrand, c.pimentStrong),
      ('Encre / crème', c.textPrimary, c.background),
      ('Secondaire / crème', c.textSecondary, c.background),
      ('Secondaire / blanc', c.textSecondary, c.card),
      ('Vert profond / crème', c.brand, c.background),
      ('Badge « Au marché »', c.originMarcheFg, c.originMarcheBg),
      ('Badge « Fait maison »', c.originMaisonFg, c.originMaisonBg),
      ('Badge « Boutique »', c.originBoutiqueFg, c.originBoutiqueBg),
    ];
    final t = context.dym.text;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const DymSectionHeader(title: 'Palette'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (name, color) in swatches)
              SizedBox(
                width: 104,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: c.textSecondary.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(name, style: t.label.copyWith(fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const DymSectionHeader(title: 'Contrastes texte / fond (AA ≥ 4,5)'),
        const SizedBox(height: 8),
        for (final (name, fg, bg) in pairs)
          _ContrastRow(name: name, fg: fg, bg: bg),
      ],
    );
  }
}

class _ContrastRow extends StatelessWidget {
  const new({required this.name, required this.fg, required this.bg});

  final String name;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final ratio = contrastRatio(fg, bg);
    final ok = ratio >= 4.5;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.textSecondary.withValues(alpha: 0.2)),
            ),
            child: Text(
              'Aa 1 500 F',
              style: context.dym.text.label.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: context.dym.text.body)),
          Text(
            '${ratio.toStringAsFixed(2)}:1',
            style: context.dym.text.price.copyWith(
              fontSize: 15,
              color: ok ? c.brandDeep : c.pimentStrong,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: ok ? c.brand : c.pimentStrong,
          ),
        ],
      ),
    );
  }
}
