import 'package:dym_account/dym_account.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_delivery/app/app.locator.dart';
import 'package:dym_delivery/features/earnings/earnings_view.dart';
import 'package:dym_delivery/features/missions/missions_service.dart';
import 'package:dym_delivery/features/missions/missions_views.dart';
import 'package:dym_delivery/ui/navigation.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Onglets de l'accueil du livreur.
enum HomeTab { missions, runs, earnings, me }

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

  /// Change à chaque mission acceptée : la course en cours se recharge.
  int _runs = 0;

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
        DymNavItem(icon: Icons.inventory_2_outlined, label: l10n.missionsTitle),
        DymNavItem(icon: Icons.history_rounded, label: l10n.runsHistoryTitle),
        DymNavItem(icon: Icons.payments_outlined, label: l10n.earningsTitle),
        DymNavItem(
          icon: Icons.person_outline_rounded,
          label: l10n.accountTitle,
        ),
      ],
      body: switch (_tab) {
        // La course acceptée apparaît au-dessus des propositions (planche 05).
        HomeTab.missions => MissionsView(
          service: _missions,
          onAccepted: () => setState(() => _runs++),
          active: MyRunsView(key: ValueKey(_runs), service: _missions),
        ),
        HomeTab.runs => MyRunsView(service: _missions, history: true),
        HomeTab.earnings => EarningsView(service: _missions),
        HomeTab.me => AccountView(
          service: _service,
          onSignedOut: _navigator.toSignIn,
        ),
      },
    );
  }
}
