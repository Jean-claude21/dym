import 'package:dym_admin/app/app.locator.dart';
import 'package:dym_admin/ui/inactivity_guard.dart';
import 'package:dym_admin/ui/navigation.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Tableau de bord provisoire de l'admin (spec 005) : navigation, salutation,
/// déconnexion. Les écrans d'administration arrivent avec `admin-ops`.
class AdminHomeView extends StatefulWidget {
  const new({super.key, this.service, this.navigator, this.inactivity});

  final AuthService? service;
  final AdminNavigator? navigator;

  /// Délai d'inactivité (tests) ; 30 minutes par défaut.
  final Duration? inactivity;

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  int _tab = 0;
  late final AuthService _service = widget.service ?? locator<AuthService>();
  late final AdminNavigator _navigator =
      widget.navigator ?? StackedAdminNavigator();

  Future<void> _signOut({AdminNotice? notice}) async {
    await _service.signOut();
    _navigator.toSignIn(notice: notice);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final name = _service.me?.profile?.firstName ?? '';
    return InactivityGuard(
      timeout: widget.inactivity ?? const Duration(minutes: 30),
      onTimeout: () => _signOut(notice: AdminNotice.inactive),
      child: DymAdaptiveScaffold(
        backgroundColor: c.background,
        currentIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          DymNavItem(icon: Icons.space_dashboard_rounded, label: l10n.navHome),
          DymNavItem(icon: Icons.receipt_long_rounded, label: l10n.navOrders),
          DymNavItem(icon: Icons.storefront_rounded, label: l10n.navStores),
          DymNavItem(icon: Icons.tune_rounded, label: l10n.navSettings),
        ],
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(DymLayout.gutter(context)),
              child: DymContentWidth.form(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name.isEmpty ? l10n.appNameAdmin : l10n.homeHello(name),
                      textAlign: TextAlign.center,
                      style: t.display.copyWith(fontSize: 34),
                    ),
                    const SizedBox(height: DymTokenSpace.s2),
                    Text(
                      l10n.comingSoon,
                      textAlign: TextAlign.center,
                      style: t.body.copyWith(color: c.textSecondary),
                    ),
                    if (_tab == 3) ...[
                      const SizedBox(height: DymTokenSpace.s5),
                      DymMenuRow(
                        icon: Icons.logout_rounded,
                        label: l10n.accountSignOut,
                        onTap: _signOut,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
