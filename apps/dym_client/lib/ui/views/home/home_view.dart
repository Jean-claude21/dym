import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_client/app/app.locator.dart';
import 'package:dym_client/ui/navigation.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Accueil provisoire (spec 005) : salutation et onglet « Moi ». Le contenu
/// arrive avec la spec `discovery`.
class HomeView extends StatefulWidget {
  const new({super.key, this.service, this.navigator});

  /// Service d'authentification (tests).
  final AuthService? service;

  /// Navigation (tests).
  final AppNavigator? navigator;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _tab = 0;

  late final AuthService _service = widget.service ?? locator<AuthService>();
  late final AppNavigator _navigator =
      widget.navigator ?? StackedAppNavigator();

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final name = _service.me?.profile?.firstName ?? '';
    return DymAdaptiveScaffold(
      backgroundColor: c.background,
      currentIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      destinations: [
        DymNavItem(icon: Icons.home_rounded, label: l10n.navHome),
        DymNavItem(icon: Icons.person_rounded, label: l10n.accountTitle),
      ],
      body: _tab == 1
          ? AccountView(service: _service, onSignedOut: _navigator.toSignIn)
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(DymLayout.gutter(context)),
                  child: DymContentWidth.form(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.homeHello(name),
                          textAlign: TextAlign.center,
                          style: t.display.copyWith(fontSize: 34),
                        ),
                        const SizedBox(height: DymTokenSpace.s3),
                        Text(
                          l10n.comingSoon,
                          textAlign: TextAlign.center,
                          style: t.body.copyWith(
                            fontSize: 17,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
