import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/app/app.locator.dart';
import 'package:dym_vendor/features/store/my_store/my_store_view.dart';
import 'package:dym_vendor/features/store/store_service.dart';
import 'package:dym_vendor/ui/navigation.dart';
import 'package:flutter/material.dart';

/// Accueil de la vendeuse : onglets « Boutique » (écran 23) et « Moi ».
/// Commandes et produits arrivent avec leurs specs.
class HomeView extends StatefulWidget {
  const new({super.key, this.service, this.stores, this.navigator});

  /// Service d'authentification (tests).
  final AuthService? service;

  /// Boutique (tests).
  final StoreService? stores;

  /// Navigation (tests).
  final AppNavigator? navigator;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _tab = 0;

  late final AuthService _service = widget.service ?? locator<AuthService>();
  late final StoreService _stores = widget.stores ?? locator<StoreService>();
  late final AppNavigator _navigator =
      widget.navigator ?? StackedAppNavigator();

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return DymAdaptiveScaffold(
      backgroundColor: c.background,
      currentIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      destinations: [
        DymNavItem(icon: Icons.storefront_rounded, label: l10n.navStore),
        DymNavItem(icon: Icons.person_rounded, label: l10n.accountTitle),
      ],
      body: _tab == 1
          ? AccountView(service: _service, onSignedOut: _navigator.toSignIn)
          : MyStoreView(service: _stores, onEdit: _navigator.toStoreSetting),
    );
  }
}
