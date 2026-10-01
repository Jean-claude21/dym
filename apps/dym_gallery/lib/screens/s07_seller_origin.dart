import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/screens/common.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Écran 07 — App vendeuse, inscription : « Où vends-tu ? ».
class SellerOriginScreen extends StatefulWidget {
  const new({required this.country, super.key});

  final DemoCountry country;

  @override
  State<SellerOriginScreen> createState() => _SellerOriginScreenState();
}

class _SellerOriginScreenState extends State<SellerOriginScreen> {
  StoreOrigin _selected = StoreOrigin.maison;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final choices = [
      (
        StoreOrigin.marche,
        DemoImages.store('etal-akossiwa'),
        'Au marché',
        'Tu as un étal ou une place au marché.',
      ),
      (
        StoreOrigin.maison,
        DemoImages.store('cour-esi'),
        'Depuis chez moi',
        'Tu prépares ou vends depuis ta maison.',
      ),
      (
        StoreOrigin.magasin,
        DemoImages.store('epicerie-kodjo'),
        'Dans ma boutique',
        'Tu as un magasin ou un kiosque.',
      ),
    ];
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            DymContentWidth.form(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Retour',
                      onPressed: () => Navigator.maybePop(context),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: c.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Étape 2 sur 7',
                            style: t.label.copyWith(
                              fontSize: 15,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              for (var i = 0; i < 7; i++)
                                Expanded(
                                  child: Container(
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: i < 2
                                          ? c.brand
                                          : c.textSecondary.withValues(
                                              alpha: 0.18,
                                            ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                  ],
                ),
              ),
            ),
            Expanded(
              child: BoundedListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                children: [
                  Text(
                    'Où vends-tu ?',
                    textAlign: TextAlign.center,
                    style: t.display.copyWith(fontSize: 36),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chaque boutique a sa place sur DYM.\n'
                    'Tu pourras changer plus tard.',
                    textAlign: TextAlign.center,
                    style: t.body.copyWith(
                      fontSize: 17,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final (origin, image, title, description)
                      in choices) ...[
                    DymSelectableCard(
                      image: image,
                      title: title,
                      description: description,
                      selected: _selected == origin,
                      onTap: () => setState(() => _selected = origin),
                      footer: origin == StoreOrigin.maison
                          ? _PrivacyNote(zone: widget.country.zone)
                          : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
            DymContentWidth.form(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: DymButton(label: 'Continuer', onPressed: () {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const new({required this.zone});

  final String zone;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.tintPeche,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: c.originMaisonFg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ton adresse reste privée : les clientes voient seulement ton '
              'quartier.',
              style: context.dym.text.label.copyWith(
                color: c.originMaisonFg,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
