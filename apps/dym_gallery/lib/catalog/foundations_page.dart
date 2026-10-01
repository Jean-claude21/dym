import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Typographie, espacements, rayons et ombre des tokens.
class FoundationsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final styles = <(String, TextStyle, String)>[
      ('display · Nunito 800 · 28', t.display, 'Ton panier'),
      ('title · Nunito 800 · 20', t.title, 'Boutiques ouvertes près de toi'),
      ('price · Nunito 800 · 18 · tabulaires', t.price, '1 500 F CFA'),
      ('body · Nunito Sans 400 · 15', t.body, "Les jus d'Esi, fait maison."),
      ('label · Nunito Sans 600 · 13', t.label, 'le tas · Au marché'),
    ];
    const spaces = <(String, double)>[
      ('s1', DymTokenSpace.s1),
      ('s2', DymTokenSpace.s2),
      ('s3', DymTokenSpace.s3),
      ('s4', DymTokenSpace.s4),
      ('s5', DymTokenSpace.s5),
      ('s6', DymTokenSpace.s6),
    ];
    const radii = <(String, double)>[
      ('button 16', DymTokenRadius.button),
      ('tile 20', DymTokenRadius.tile),
      ('card 24', DymTokenRadius.card),
      ('chip', DymTokenRadius.chip),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const DymSectionHeader(title: 'Typographie'),
        for (final (name, style, sample) in styles) ...[
          const SizedBox(height: 10),
          Text(name, style: t.label.copyWith(color: c.textSecondary)),
          Text(sample, style: style),
        ],
        const SizedBox(height: 20),
        const DymSectionHeader(title: 'Espacements'),
        const SizedBox(height: 8),
        for (final (name, value) in spaces)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(width: 72, child: Text('$name · ${value.toInt()}')),
                Container(width: value * 4, height: 14, color: c.plantain),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const DymSectionHeader(title: 'Rayons et ombre'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (name, value) in radii)
              Container(
                width: 104,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(value),
                  boxShadow: const [DymTokenShadows.card],
                ),
                child: Text(name, style: t.label),
              ),
          ],
        ),
      ],
    );
  }
}
