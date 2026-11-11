import 'package:flutter/widgets.dart';

/// Image décodée à sa taille d'affichage (PARCOURS §8) : jamais plus grande
/// qu'affichée, pour tenir sur un téléphone de 2 Go.
class DymSizedImage extends StatelessWidget {
  /// Crée l'image ; [fit] et [errorBuilder] comme `Image`.
  const new({
    required this.image,
    super.key,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  /// Source, décodée à la largeur occupée × densité de l'écran.
  final ImageProvider image;

  /// Ajustement dans la place donnée.
  final BoxFit fit;

  /// Repli si l'image ne charge pas.
  final ImageErrorWidgetBuilder? errorBuilder;

  /// Fournisseur réduit à [logicalWidth] points pour l'écran de [context].
  static ImageProvider sized(
    BuildContext context,
    ImageProvider image,
    double logicalWidth,
  ) {
    if (!logicalWidth.isFinite || logicalWidth <= 0) return image;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2;
    return ResizeImage.resizeIfNeeded(
      (logicalWidth * dpr).round(),
      null,
      image,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Image(
      image: sized(context, image, box.maxWidth),
      fit: fit,
      errorBuilder: errorBuilder,
    ),
  );
}
