import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_delivery/app/app.locator.dart';
import 'package:dym_delivery/features/missions/missions_service.dart';
import 'package:dym_delivery/features/missions/missions_views.dart';
import 'package:dym_delivery/ui/navigation.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Onglets de l'accueil du livreur.
enum HomeTab { missions, runs, me }

/// Accueil du livreur : missions proposées, mes courses, « Moi ».
class HomeView extends StatefulWidget {
  const new({
    super.key,
    this.onboarding = false,
    this.service,
    this.missions,
    this.navigator,
  });

  /// Inscription comme livreur d'abord.
  final bool onboarding;

  /// Services (tests).
  final AuthService? service;
  final MissionsService? missions;
  final AppNavigator? navigator;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  HomeTab _tab = HomeTab.missions;
  late bool _onboarding = widget.onboarding;
  late final AuthService _service = widget.service ?? locator<AuthService>();
  late final MissionsService _missions =
      widget.missions ?? locator<MissionsService>();
  late final AppNavigator _navigator =
      widget.navigator ?? StackedAppNavigator();

  @override
  Widget build(BuildContext context) {
    if (_onboarding) {
      return CourierOnboardingView(
        service: _missions,
        firstName: _service.me?.profile?.firstName,
        onDone: () => setState(() => _onboarding = false),
      );
    }
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return DymAdaptiveScaffold(
      backgroundColor: c.background,
      currentIndex: _tab.index,
      onDestinationSelected: (i) => setState(() => _tab = HomeTab.values[i]),
      destinations: [
        DymNavItem(icon: Icons.near_me_rounded, label: l10n.missionsTitle),
        DymNavItem(icon: Icons.route_rounded, label: l10n.myRunsTitle),
        DymNavItem(icon: Icons.person_rounded, label: l10n.accountTitle),
      ],
      body: switch (_tab) {
        HomeTab.missions => MissionsView(
          service: _missions,
          onAccepted: () => setState(() => _tab = HomeTab.runs),
        ),
        HomeTab.runs => MyRunsView(service: _missions),
        HomeTab.me => AccountView(
          service: _service,
          onSignedOut: _navigator.toSignIn,
        ),
      },
    );
  }
}
