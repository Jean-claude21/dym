// GÉNÉRÉ — ne pas modifier.
// Source : docs/design/tokens/dym.tokens.json
// Commande : melos run tokens
// ignore_for_file: public_member_api_docs

import 'dart:ui' show Color, FontFeature, FontWeight, Offset;

import 'package:flutter/painting.dart' show BoxShadow, TextStyle;

abstract final class DymTokenColors {
  /// Vert DYM : action principale unique, onglet actif, une carte forte au plus par écran. Blanc dessus : 7.69:1 ; sur fond : 7.36:1.
  static const brandPrimary = Color(0xFF145C43);

  /// Vert très profond : texte vert sur fonds clairs et menthe. Blanc dessus : 10.6:1 ; sur menthe : 9.5:1.
  static const brandPrimaryDeep = Color(0xFF0E4632);

  /// Soleil : cash à encaisser, notes, mises en avant ponctuelles. Texte encre dessus : 11.2:1.
  static const accentPlantain = Color(0xFFF6C343);

  /// Tomate : promo, rupture, erreur ; aplats et grands textes (blanc dessus : 4.5:1).
  static const accentPiment = Color(0xFFD93F33);

  /// Tomate foncée : petit texte blanc sur badge, texte d'erreur. Blanc dessus : 6.0:1.
  static const accentPimentStrong = Color(0xFFB83229);

  /// Touche décorative. Pas de texte dessus.
  static const accentHuile = Color(0xFFE8892B);

  /// Liens et badge « Boutique ».
  static const accentIndigo = Color(0xFF2E3A8C);

  /// Fond blanc cassé, lisible en plein soleil.
  static const surfaceBackground = Color(0xFFFAFAF7);

  /// Carte et champ ; réservés aux éléments qui doivent ressortir.
  static const surfaceCard = Color(0xFFFFFFFF);

  /// Fond discret : squelettes de chargement, champs désactivés, étiquettes neutres.
  static const surfaceMuted = Color(0xFFF1F2EE);

  /// Filet de séparation et bordure de carte (1 px).
  static const lineHairline = Color(0xFFE6E7E2);

  /// Bordure des contrôles (champs, boutons secondaires, puces non choisies).
  static const lineStrong = Color(0xFFC9CCC4);

  /// Encre. Sur fond : 16.3:1.
  static const textPrimary = Color(0xFF16201B);

  /// Texte secondaire, jamais plus clair. Sur fond : 7.0:1 ; sur blanc : 7.3:1.
  static const textSecondary = Color(0xFF4E5852);
  static const textOnBrand = Color(0xFFFFFFFF);

  /// Pastille « Fait maison ».
  static const tintPeche = Color(0xFFF8E3D3);

  /// Menthe : fond des photos produits, cercles des rayons, pastille « Au marché ».
  static const tintVertTendre = Color(0xFFE8F2EC);

  /// Fond du cash à encaisser.
  static const tintPlantainClair = Color(0xFFFBF1D3);

  /// Fond des alertes et erreurs.
  static const tintPimentClair = Color(0xFFF8DEDA);

  /// Pastille « Boutique ».
  static const tintIndigoClair = Color(0xFFE3E6F4);
  static const originMarcheBg = Color(0xFFE8F2EC);

  /// 9.5:1
  static const originMarcheFg = Color(0xFF0E4632);
  static const originMaisonBg = Color(0xFFF8E3D3);

  /// 5.69:1
  static const originMaisonFg = Color(0xFF8C4513);
  static const originBoutiqueBg = Color(0xFFE3E6F4);

  /// 8.1:1
  static const originBoutiqueFg = Color(0xFF2E3A8C);
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
  /// Puces et filtres : même rayon que les boutons.
  static const double chip = 12.0;

  /// Tuiles et photos produits dans une grille.
  static const double tile = 12.0;

  /// Cartes et feuilles du bas.
  static const double card = 12.0;

  /// Boutons, mini-panier, stepper.
  static const double button = 12.0;

  /// Champs de saisie et recherche.
  static const double field = 10.0;

  /// Images dans une liste.
  static const double image = 10.0;
}

abstract final class DymTokenSize {
  /// Cible tactile minimale, même quand le visuel est plus petit.
  static const double touchMin = 48.0;

  /// Petit bouton rond « + » (zone de toucher 48 px).
  static const double addButton = 36.0;
  static const double avatarBoutique = 48.0;

  /// Hauteur des boutons principaux.
  static const double buttonHeight = 52.0;

  /// Hauteur des champs.
  static const double fieldHeight = 52.0;
}

abstract final class DymTokenBreakpoints {
  /// Compacte → moyenne (tablette portrait).
  static const double medium = 600.0;

  /// Moyenne → étendue (tablette paysage, téléphone paysage).
  static const double expanded = 840.0;

  /// Étendue → large (bureau).
  static const double large = 1200.0;
}

abstract final class DymTokenLayout {
  /// Marge latérale en classe compacte.
  static const double gutterCompact = 16.0;

  /// Marge latérale en classe moyenne.
  static const double gutterMedium = 24.0;

  /// Marge latérale en classe étendue.
  static const double gutterExpanded = 32.0;

  /// Marge latérale en classe large.
  static const double gutterLarge = 32.0;

  /// Largeur maximale d'un contenu (grilles, accueil).
  static const double contentMax = 1200.0;

  /// Largeur maximale d'un formulaire ou d'une page de lecture.
  static const double formMax = 600.0;

  /// Largeur maximale d'un élément flottant (mini-panier).
  static const double floatingMax = 560.0;

  /// Largeur du rail de navigation.
  static const double railWidth = 88.0;

  /// Largeur du rail de navigation étendu.
  static const double railExtendedWidth = 220.0;
}

abstract final class DymTokenFonts {
  static const package = 'dym_ui';

  /// Titres et prix : Inter SemiBold, chiffres tabulaires.
  static const display = 'Inter';

  /// Texte courant : Inter Regular.
  static const body = 'Inter';
}

abstract final class DymTokenTypography {
  /// Titre d'écran.
  static const display = TextStyle(
    fontFamily: 'Inter',
    package: 'dym_ui',
    fontWeight: FontWeight.w700,
    fontSize: 28.0,
    height: 1.18,
    letterSpacing: -0.6,
  );

  /// Titre de section et de carte.
  static const title = TextStyle(
    fontFamily: 'Inter',
    package: 'dym_ui',
    fontWeight: FontWeight.w600,
    fontSize: 19.0,
    height: 1.25,
    letterSpacing: -0.3,
  );

  /// Prix, chiffres tabulaires.
  static const price = TextStyle(
    fontFamily: 'Inter',
    package: 'dym_ui',
    fontWeight: FontWeight.w600,
    fontSize: 17.0,
    height: 1.2,
    letterSpacing: -0.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const body = TextStyle(
    fontFamily: 'Inter',
    package: 'dym_ui',
    fontWeight: FontWeight.w400,
    fontSize: 15.0,
    height: 1.45,
  );

  /// Pastilles, unités, boutique d'origine, libellés de navigation. 14 px minimum (12 px toléré sous une icône de navigation).
  static const label = TextStyle(
    fontFamily: 'Inter',
    package: 'dym_ui',
    fontWeight: FontWeight.w500,
    fontSize: 14.0,
    height: 1.3,
  );
}

abstract final class DymTokenShadows {
  /// Aucune ombre (design épuré) : les cartes se distinguent par un filet.
  static const card = BoxShadow(
    color: Color(0x0016201B),
    offset: Offset(0.0, 0.0),
    blurRadius: 0.0,
    spreadRadius: 0.0,
  );

  /// Seule ombre permise : éléments flottants au-dessus du contenu (mini-panier, feuille du bas).
  static const floating = BoxShadow(
    color: Color(0x1F16201B),
    offset: Offset(0.0, 6.0),
    blurRadius: 20.0,
    spreadRadius: -6.0,
  );
}
