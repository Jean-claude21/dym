import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_client/app/app.locator.dart';
import 'package:dym_client/features/discovery/aisle/aisles_view.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/home/discovery_home_view.dart';
import 'package:dym_client/ui/navigation.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Onglets de la cliente. Les commandes arrivent avec leur spec.
enum ClientTab { home, aisles, me }

/// Accueil de la cliente : découverte (écran 02), rayons et « Moi ».
class HomeView extends StatefulWidget {
  const new({
    super.key,
    this.service,
    this.discovery,
    this.navigator,
    this.initialTab = ClientTab.home,
  });

  /// Service d'authentification (tests).
  final AuthService? service;

  /// Découverte (tests).
  final DiscoveryService? discovery;

  /// Navigation (tests).
  final AppNavigator? navigator;

  final ClientTab initialTab;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late ClientTab _tab = widget.initialTab;

  late final AuthService _service = widget.service ?? locator<AuthService>();
  late final DiscoveryService _discovery =
      widget.discovery ?? locator<DiscoveryService>();
  late final AppNavigator _navigator =
      widget.navigator ?? StackedAppNavigator();

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return DymAdaptiveScaffold(
      backgroundColor: c.background,
      currentIndex: _tab.index,
      onDestinationSelected: (i) => setState(() => _tab = ClientTab.values[i]),
      destinations: [
        DymNavItem(icon: Icons.home_rounded, label: l10n.navHome),
        DymNavItem(icon: Icons.grid_view_rounded, label: l10n.navAisles),
        DymNavItem(icon: Icons.person_rounded, label: l10n.accountTitle),
      ],
      body: switch (_tab) {
        ClientTab.home => DiscoveryHomeView(
          service: _discovery,
          onSearch: _navigator.toSearch,
          onOpenStore: _navigator.toStore,
          onOpenAisle: _navigator.toAisle,
        ),
        ClientTab.aisles => AislesView(
          service: _discovery,
          onOpenAisle: _navigator.toAisle,
        ),
        ClientTab.me => AccountView(
          service: _service,
          onSignedOut: _navigator.toSignIn,
        ),
      },
    );
  }
}
