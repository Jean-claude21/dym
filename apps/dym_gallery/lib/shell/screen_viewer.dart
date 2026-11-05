import 'package:dym_gallery/demo/demo_assets.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_gallery/shell/demo_banner.dart';
import 'package:dym_gallery/shell/device_frame.dart';
import 'package:dym_gallery/shell/reference_screens.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Affiche un écran reproduit dans un cadre de téléphone, avec le mode
/// « Comparer » : l'image validée se superpose, curseur d'opacité.
///
/// Le sélecteur de format rend l'écran en téléphone, paysage, tablette ou
/// bureau (spec 002) ; « Comparer » n'existe qu'en téléphone.
class ScreenViewer extends StatefulWidget {
  const new({required this.screen, super.key});

  final ReferenceScreen screen;

  @override
  State<ScreenViewer> createState() => _ScreenViewerState();
}

class _ScreenViewerState extends State<ScreenViewer> {
  bool _compare = false;
  DeviceFormat _format = DeviceFormat.phone;
  double _opacity = 0.5;
  int _restart = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final s = widget.screen;
    return Scaffold(
      backgroundColor: const Color(0xFF26231F),
      appBar: AppBar(
        backgroundColor: c.card,
        title: Text('${s.id} · ${s.title}', style: context.dym.text.title),
        actions: [
          IconButton(
            tooltip: 'Rejouer les animations',
            onPressed: () => setState(() => _restart++),
            icon: const Icon(Icons.replay_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Comparer'),
              tooltip: _format == DeviceFormat.phone
                  ? null
                  : 'Références disponibles en téléphone uniquement',
              selected: _compare && _format == DeviceFormat.phone,
              onSelected: _format == DeviceFormat.phone
                  ? (v) => setState(() => _compare = v)
                  : null,
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(28),
          child: DemoBanner(),
        ),
      ),
      body: Column(
        children: [
          ColoredBox(
            color: c.card,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  for (final f in DeviceFormat.values) ...[
                    ChoiceChip(
                      avatar: Icon(f.icon, size: 18),
                      label: Text(f.label),
                      selected: f == _format,
                      onSelected: (_) => setState(() => _format = f),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          if (_compare && _format == DeviceFormat.phone)
            ColoredBox(
              color: c.card,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Text('Référence', style: context.dym.text.label),
                  Expanded(
                    child: Slider(
                      value: _opacity,
                      onChanged: (v) => setState(() => _opacity = v),
                    ),
                  ),
                  Text(
                    '${(_opacity * 100).round()} %',
                    style: context.dym.text.label,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, box) {
                  // Cadre téléphone 390 de large au maximum (écrans validés).
                  final width = box.maxWidth.clamp(0, 412).toDouble();
                  final framed = box.maxWidth > 500;
                  final phone = ValueListenableBuilder<DemoCountry>(
                    valueListenable: demoCountry,
                    builder: (context, country, _) => Stack(
                      fit: StackFit.expand,
                      children: [
                        KeyedSubtree(
                          key: ValueKey('${country.code}-$_restart'),
                          child: s.builder(country),
                        ),
                        if (_compare && _format == DeviceFormat.phone)
                          IgnorePointer(
                            child: Opacity(
                              opacity: _opacity,
                              child: Image(
                                image: ReferenceImages.of(s.referenceFile),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                  if (_format != DeviceFormat.phone) {
                    return DeviceFrame(format: _format, child: phone);
                  }
                  if (!framed) return phone;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: AspectRatio(
                      aspectRatio: 941 / 1672,
                      child: SizedBox(
                        width: width,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          // L'écran voit la taille du cadre, pas celle de
                          // la fenêtre (classe de fenêtre compacte).
                          child: LayoutBuilder(
                            builder: (context, frame) => MediaQuery(
                              data: MediaQuery.of(context)
                                  .removePadding(
                                    removeTop: true,
                                    removeBottom: true,
                                  )
                                  .copyWith(size: frame.biggest),
                              child: phone,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
