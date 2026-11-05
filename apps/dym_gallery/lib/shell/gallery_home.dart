import 'package:dym_gallery/catalog/catalog_page.dart';
import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_gallery/shell/demo_banner.dart';
import 'package:dym_gallery/shell/reference_screens.dart';
import 'package:dym_gallery/shell/screen_viewer.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Accueil de la galerie : écrans validés, catalogue, pays de démonstration.
class GalleryHome extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text('Galerie DYM · dym_ui', style: t.title),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(28),
          child: DemoBanner(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Compare chaque écran à son image validée avec « Comparer ».',
            style: t.body.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          const Center(child: CountrySwitch()),
          const SizedBox(height: 16),
          const DymSectionHeader(title: 'Écrans validés'),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, box) {
              final columns = (box.maxWidth / 180).floor().clamp(2, 6);
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.48,
                children: [
                  for (final s in referenceScreens) _ScreenTile(screen: s),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const DymSectionHeader(title: 'Design system'),
          const SizedBox(height: 8),
          DymButton(
            label: 'Ouvrir le catalogue',
            icon: Icons.palette_outlined,
            variant: DymButtonVariant.secondary,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const CatalogPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenTile extends StatelessWidget {
  const new({required this.screen});

  final ReferenceScreen screen;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(DymTokenRadius.tile),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => ScreenViewer(screen: screen)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image(
                image: ReferenceImages.of(screen.referenceFile),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${screen.id} · ${screen.surface}',
                    style: context.dym.text.label.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                  Text(
                    screen.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.dym.text.title.copyWith(fontSize: 15),
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
