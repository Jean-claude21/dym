// GÉNÉRÉ — ne pas modifier.
// Source : docs/design/tokens/dym.tokens.json
// Commande : melos run tokens
// ignore_for_file: public_member_api_docs

import 'dart:ui' show Color, FontFeature, FontWeight, Offset;

import 'package:flutter/painting.dart' show BoxShadow, TextStyle;

abstract final class DymTokenColors {
  /// Vert profond : marque et action principale unique (boutons, navigation active, logo). Blanc dessus : 7.92:1 ; sur crème : 7.35:1.
  static const brandPrimary = Color(0xFF0B5D3F);

  /// Vert très profond : fond de l'app vendeuse, texte vert sur fonds clairs. Blanc dessus : 11.04:1.
  static const brandPrimaryDeep = Color(0xFF08452F);

  /// Mises en avant : pastille de délai, jauges, bouton sur fond vert (4.72:1 sur primary). Texte encre dessus : 10.29:1.
  static const accentPlantain = Color(0xFFF2C14E);

  /// Aplats et grands textes uniquement (blanc dessus : 4.36:1, insuffisant pour le petit texte).
  static const accentPiment = Color(0xFFD9442B);

  /// Badges promo et pastilles de compteur avec texte blanc : 5.92:1.
  static const accentPimentStrong = Color(0xFFB8341E);

  /// Touche secondaire décorative (motifs, illustrations). Pas de texte dessus.
  static const accentHuile = Color(0xFFE8892B);

  /// Touche secondaire, liens, badge « Boutique ».
  static const accentIndigo = Color(0xFF2B3A8F);

  /// Fond crème chaud, lisible en plein soleil.
  static const surfaceBackground = Color(0xFFFBF6EC);
  static const surfaceCard = Color(0xFFFFFFFF);

  /// Encre chaude. Sur crème : 16.03:1.
  static const textPrimary = Color(0xFF1F1A14);

  /// Sur crème : 5.38:1 ; sur blanc : 5.79:1.
  static const textSecondary = Color(0xFF6E6458);
  static const textOnBrand = Color(0xFFFFFFFF);
  static const tintPeche = Color(0xFFF8E3D3);
  static const tintVertTendre = Color(0xFFE9F1DC);
  static const tintPlantainClair = Color(0xFFFBEFC9);
  static const tintPimentClair = Color(0xFFF6DAD3);
  static const tintIndigoClair = Color(0xFFE1E5F3);
  static const originMarcheBg = Color(0xFFE9F1DC);

  /// 9.5:1
  static const originMarcheFg = Color(0xFF08452F);
  static const originMaisonBg = Color(0xFFF8E3D3);

  /// 5.69:1
  static const originMaisonFg = Color(0xFF8C4513);
  static const originBoutiqueBg = Color(0xFFE1E5F3);

  /// 7.94:1
  static const originBoutiqueFg = Color(0xFF2B3A8F);
}

abstract final class DymTokenSpace {
  static const double s1 = 4.0;
  static const double s2 = 8.0;
  static const double s3 = 12.0;

  /// Marge latérale d'écran.
  static const double s4 = 16.0;
  static const double s5 = 24.0;
  static const double s6 = 32.0;
}

abstract final class DymTokenRadius {
  static const double chip = 999.0;
  static const double tile = 20.0;
  static const double card = 24.0;
  static const double button = 16.0;
}

abstract final class DymTokenSize {
  /// Cible tactile minimale.
  static const double touchMin = 48.0;
  static const double addButton = 40.0;
  static const double avatarBoutique = 56.0;
}

abstract final class DymTokenFonts {
  static const package = 'dym_ui';

  /// Titres et prix : grotesque arrondie chaleureuse. À valider sur appareil.
  static const display = 'Nunito';

  /// Texte courant. À valider sur appareil.
  static const body = 'NunitoSans';
}

abstract final class DymTokenTypography {
  /// Titre d'écran.
  static const display = TextStyle(
    fontFamily: 'Nunito',
    package: 'dym_ui',
    fontWeight: FontWeight.w800,
    fontSize: 28.0,
    height: 1.15,
  );

  /// Titre de section.
  static const title = TextStyle(
    fontFamily: 'Nunito',
    package: 'dym_ui',
    fontWeight: FontWeight.w800,
    fontSize: 20.0,
    height: 1.2,
  );

  /// Prix, chiffres tabulaires.
  static const price = TextStyle(
    fontFamily: 'Nunito',
    package: 'dym_ui',
    fontWeight: FontWeight.w800,
    fontSize: 18.0,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const body = TextStyle(
    fontFamily: 'NunitoSans',
    package: 'dym_ui',
    fontWeight: FontWeight.w400,
    fontSize: 15.0,
    height: 1.4,
  );

  /// Badges, unités, boutique d'origine. Jamais en dessous de 12px.
  static const label = TextStyle(
    fontFamily: 'NunitoSans',
    package: 'dym_ui',
    fontWeight: FontWeight.w600,
    fontSize: 13.0,
    height: 1.3,
  );
}

abstract final class DymTokenShadows {
  /// Ombre très douce.
  static const card = BoxShadow(
    color: Color(0x141F1A14),
    offset: Offset(0.0, 4.0),
    blurRadius: 16.0,
    spreadRadius: 0.0,
  );
}
