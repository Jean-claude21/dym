import 'package:dym_gallery/catalog/colors_page.dart';
import 'package:dym_gallery/catalog/components_page.dart';
import 'package:dym_gallery/catalog/foundations_page.dart';
import 'package:dym_gallery/shell/demo_banner.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Catalogue du design system : couleurs, fondations, composants.
class CatalogPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.card,
          title: Text('Catalogue dym_ui', style: context.dym.text.title),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(76),
            child: Column(
              children: [
                const DemoBanner(),
                TabBar(
                  labelColor: c.brandDeep,
                  indicatorColor: c.brand,
                  tabs: const [
                    Tab(text: 'Couleurs'),
                    Tab(text: 'Fondations'),
                    Tab(text: 'Composants'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [ColorsPage(), FoundationsPage(), ComponentsPage()],
        ),
      ),
    );
  }
}
