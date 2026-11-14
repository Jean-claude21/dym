import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Couleurs de la console (spec 091) : coque grise, panneau blanc, filets fins,
/// une couleur par famille de chiffres (maquette validée « Admin 2026 »).
abstract final class AdminPalette {
  /// Fond derrière le menu et le panneau.
  static const shell = Color(0xFFF4F4F1);

  /// Panneau des pages et cartes.
  static const panel = Color(0xFFFFFFFF);

  /// Filet des cartes et séparateurs.
  static const line = Color(0xFFE9E9E4);

  /// Filet des champs et boutons secondaires.
  static const lineStrong = Color(0xFFDDDDD7);

  /// Fond des onglets segmentés et lignes survolées.
  static const muted = Color(0xFFF3F3F0);

  /// Texte secondaire.
  static const ink2 = Color(0xFF5E6663);

  /// Texte discret (libellés de chiffres, notes).
  static const ink3 = Color(0xFF858C88);

  /// Familles de chiffres : (couleur, fond teinté).
  static const green = (Color(0xFF2E7D5B), Color(0xFFE7F1EC));
  static const blue = (Color(0xFF2F6FD6), Color(0xFFE8F0FC));
  static const teal = (Color(0xFF1F9A8A), Color(0xFFE2F4F1));
  static const orange = (Color(0xFFD9622A), Color(0xFFFCEDE4));
  static const rose = (Color(0xFFD6456E), Color(0xFFFBE8EE));
  static const amber = (Color(0xFFB57C0F), Color(0xFFFBF2DC));
}

/// Thème de l'admin : celui de DYM, resserré pour le bureau (texte 14 px,
/// titres plus petits, cartes blanches à filet, fond de page blanc).
ThemeData adminTheme() {
  final base = DymTheme.light();
  const c = DymColors.light;
  final t = DymTextStyles.light;
  final colors = DymColors(
    brand: c.brand,
    brandDeep: c.brandDeep,
    plantain: c.plantain,
    piment: c.piment,
    pimentStrong: c.pimentStrong,
    huile: c.huile,
    indigo: c.indigo,
    background: AdminPalette.panel,
    card: AdminPalette.panel,
    textPrimary: c.textPrimary,
    textSecondary: AdminPalette.ink2,
    onBrand: c.onBrand,
    tintPeche: c.tintPeche,
    tintVertTendre: c.tintVertTendre,
    tintPlantainClair: c.tintPlantainClair,
    tintPimentClair: c.tintPimentClair,
    tintIndigoClair: c.tintIndigoClair,
    originMarcheBg: c.originMarcheBg,
    originMarcheFg: c.originMarcheFg,
    originMaisonBg: c.originMaisonBg,
    originMaisonFg: c.originMaisonFg,
    originBoutiqueBg: c.originBoutiqueBg,
    originBoutiqueFg: c.originBoutiqueFg,
    hairline: AdminPalette.line,
    lineStrong: AdminPalette.lineStrong,
    muted: AdminPalette.muted,
  );
  final text = DymTextStyles(
    display: t.display.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.2,
    ),
    title: t.title.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
    price: t.price.copyWith(fontSize: 15),
    body: t.body.copyWith(fontSize: 14),
    label: t.label.copyWith(fontSize: 13),
  );
  return base.copyWith(
    scaffoldBackgroundColor: AdminPalette.shell,
    canvasColor: AdminPalette.panel,
    dividerColor: AdminPalette.line,
    dividerTheme: const DividerThemeData(
      color: AdminPalette.line,
      space: 1,
      thickness: 1,
    ),
    cardTheme: base.cardTheme.copyWith(
      color: AdminPalette.panel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: AdminPalette.line),
      ),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: AdminPalette.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    extensions: [colors, text],
  );
}
