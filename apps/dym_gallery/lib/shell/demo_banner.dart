import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Bandeau « Données de démonstration » (spec FR-015).
class DemoBanner extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return ValueListenableBuilder<DemoCountry>(
      valueListenable: demoCountry,
      builder: (context, country, _) => Container(
        height: 28,
        width: double.infinity,
        color: c.plantain,
        alignment: Alignment.center,
        child: Text(
          'Données de démonstration · ${country.name} '
          '(${country.currency.code}) · images générées par IA',
          style: context.dym.text.label.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Sélecteur de pays de démonstration Togo / Ghana (spec FR-013).
class CountrySwitch extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DemoCountry>(
      valueListenable: demoCountry,
      builder: (context, country, _) => SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'TG', label: Text('Togo · XOF')),
          ButtonSegment(value: 'GH', label: Text('Ghana · GHS')),
        ],
        selected: {country.code},
        onSelectionChanged: (s) => demoCountry.value = s.first == 'GH'
            ? DemoCountry.ghana
            : DemoCountry.togo,
      ),
    );
  }
}
