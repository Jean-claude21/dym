import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo DYM (sac sur fond vert, `docs/design/marque/icone-dym.svg`), coins
/// arrondis comme une icône d'app.
class DymLogoMark extends StatelessWidget {
  const new({super.key, this.size = 32, this.semanticLabel});

  final double size;

  /// Nom lu par le lecteur d'écran ; `null` : décoratif.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final mark = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: SvgPicture.asset(
        'assets/brand/icone.svg',
        package: 'dym_ui',
        width: size,
        height: size,
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: mark)
        : Semantics(image: true, label: semanticLabel, child: mark);
  }
}
