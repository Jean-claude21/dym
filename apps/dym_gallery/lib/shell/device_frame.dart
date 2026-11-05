import 'package:flutter/material.dart';

/// Format de prévisualisation d'un écran (spec 002, US4).
enum DeviceFormat {
  phone('Téléphone', Icons.smartphone_rounded, Size(412, 915)),
  phoneLandscape(
    'Paysage',
    Icons.stay_current_landscape_rounded,
    Size(915, 412),
  ),
  tablet('Tablette', Icons.tablet_android_rounded, Size(800, 1280)),
  tabletLandscape('Tablette paysage', Icons.tablet_rounded, Size(1280, 800)),
  desktop('Bureau', Icons.desktop_windows_rounded, Size(1440, 900)),
  free('Libre', Icons.open_in_full_rounded, null);

  new(this.label, this.icon, this.size);

  final String label;
  final IconData icon;

  /// Taille logique simulée ; `null` : toute la place disponible.
  final Size? size;
}

/// Rend [child] comme sur un appareil de taille [DeviceFormat.size] : même
/// `MediaQuery`, mêmes contraintes, puis réduit pour tenir dans la fenêtre.
class DeviceFrame extends StatelessWidget {
  const new({required this.format, required this.child, super.key});

  final DeviceFormat format;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = format.size;
    final media = MediaQuery.of(context);
    if (size == null) {
      // Libre : l'écran prend la zone d'aperçu, redimensionnable sur web.
      return LayoutBuilder(
        builder: (context, box) => MediaQuery(
          data: media
              .removePadding(
                removeTop: true,
                removeBottom: true,
                removeLeft: true,
                removeRight: true,
              )
              .copyWith(size: box.biggest),
          child: child,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: FittedBox(
          child: SizedBox.fromSize(
            size: size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                size.shortestSide < 600 ? 28 : 16,
              ),
              child: MediaQuery(
                data: media
                    .removePadding(
                      removeTop: true,
                      removeBottom: true,
                      removeLeft: true,
                      removeRight: true,
                    )
                    .removeViewPadding(
                      removeTop: true,
                      removeBottom: true,
                      removeLeft: true,
                      removeRight: true,
                    )
                    .copyWith(size: size),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
