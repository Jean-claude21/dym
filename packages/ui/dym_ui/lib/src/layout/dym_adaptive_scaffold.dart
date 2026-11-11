import 'dart:async';

import 'package:dym_ui/src/components/dym_bottom_nav.dart';
import 'package:dym_ui/src/components/dym_nav_rail.dart';
import 'package:dym_ui/src/layout/dym_window_class.dart';
import 'package:dym_ui/src/theme/dym_theme.dart';
import 'package:dym_ui/src/tokens/dym_tokens.g.dart';
import 'package:flutter/material.dart';

/// Structure d'écran à navigation principale adaptative.
///
/// - compacte : [DymBottomNav] (rendu validé de la spec 001) ;
/// - moyenne et étendue : [DymNavRail] à gauche ;
/// - large : [DymNavRail] étendu, libellés à côté des icônes.
///
/// Le corps garde son état quand la classe de fenêtre change (rotation,
/// redimensionnement).
class DymAdaptiveScaffold extends StatefulWidget {
  /// Crée la structure.
  const new({
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.body,
    super.key,
    this.backgroundColor,
    this.darkBottomNav = false,
    this.railLeading,
    this.maxBottomItems,
    this.moreItem,
  });

  /// Destinations principales.
  final List<DymNavItem> destinations;

  /// Destination active.
  final int currentIndex;

  /// Sélection d'une destination.
  final ValueChanged<int> onDestinationSelected;

  /// Contenu de l'écran.
  final Widget body;

  /// Fond de l'écran.
  final Color? backgroundColor;

  /// Barre basse sombre (lecture vidéo plein écran).
  final bool darkBottomNav;

  /// Élément en tête du rail (moyenne et au-delà).
  final Widget? railLeading;

  /// Fenêtre compacte : au-delà de ce nombre, les dernières destinations
  /// passent dans une feuille ouverte par [moreItem].
  final int? maxBottomItems;

  /// Entrée « Plus » de la barre basse (avec [maxBottomItems]).
  final DymNavItem? moreItem;

  @override
  State<DymAdaptiveScaffold> createState() => _DymAdaptiveScaffoldState();
}

class _DymAdaptiveScaffoldState extends State<DymAdaptiveScaffold> {
  Future<void> _openMore(BuildContext context, int from) async {
    final c = context.dym.colors;
    final chosen = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: c.card,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var i = from; i < widget.destinations.length; i++)
              ListTile(
                minTileHeight: DymTokenSize.touchMin,
                selected: i == widget.currentIndex,
                selectedColor: c.brandDeep,
                leading: Icon(widget.destinations[i].icon),
                title: Text(widget.destinations[i].label),
                onTap: () => Navigator.pop(sheet, i),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) widget.onDestinationSelected(chosen);
  }

  // Conserve l'état du corps quand il change de place dans l'arbre.
  final GlobalKey _bodyKey = GlobalKey(debugLabel: 'DymAdaptiveScaffold.body');

  @override
  Widget build(BuildContext context) {
    final windowClass = DymWindowClass.of(context);
    final body = KeyedSubtree(key: _bodyKey, child: widget.body);
    if (windowClass == DymWindowClass.compact) {
      final max = widget.maxBottomItems;
      final more = widget.moreItem;
      final all = widget.destinations;
      final folded = max != null && more != null && all.length > max;
      final shown = folded ? [...all.take(max - 1), more] : all;
      final current = folded && widget.currentIndex >= max - 1
          ? max - 1
          : widget.currentIndex;
      return Scaffold(
        backgroundColor: widget.backgroundColor,
        bottomNavigationBar: DymBottomNav(
          dark: widget.darkBottomNav,
          items: shown,
          currentIndex: current,
          onTap: (i) {
            if (folded && i == max - 1) {
              unawaited(_openMore(context, max - 1));
            } else {
              widget.onDestinationSelected(i);
            }
          },
        ),
        body: body,
      );
    }
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DymNavRail(
            items: widget.destinations,
            currentIndex: widget.currentIndex,
            onTap: widget.onDestinationSelected,
            extended: windowClass == DymWindowClass.large,
            leading: widget.railLeading,
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeLeft: true,
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
