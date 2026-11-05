import 'package:dym_ui/src/components/dym_bottom_nav.dart';
import 'package:dym_ui/src/components/dym_nav_rail.dart';
import 'package:dym_ui/src/layout/dym_window_class.dart';
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
    this.railLeading,
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

  /// Élément en tête du rail (moyenne et au-delà).
  final Widget? railLeading;

  @override
  State<DymAdaptiveScaffold> createState() => _DymAdaptiveScaffoldState();
}

class _DymAdaptiveScaffoldState extends State<DymAdaptiveScaffold> {
  // Conserve l'état du corps quand il change de place dans l'arbre.
  final GlobalKey _bodyKey = GlobalKey(debugLabel: 'DymAdaptiveScaffold.body');

  @override
  Widget build(BuildContext context) {
    final windowClass = DymWindowClass.of(context);
    final body = KeyedSubtree(key: _bodyKey, child: widget.body);
    if (windowClass == DymWindowClass.compact) {
      return Scaffold(
        backgroundColor: widget.backgroundColor,
        bottomNavigationBar: DymBottomNav(
          items: widget.destinations,
          currentIndex: widget.currentIndex,
          onTap: widget.onDestinationSelected,
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
