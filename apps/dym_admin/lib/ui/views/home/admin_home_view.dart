import 'package:dym_admin/app/app.locator.dart';
import 'package:dym_admin/features/audit/audit_view.dart';
import 'package:dym_admin/features/disputes/disputes_view.dart';
import 'package:dym_admin/features/finance/finance_view.dart';
import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/orders/orders_views.dart';
import 'package:dym_admin/features/settings/settings_view.dart';
import 'package:dym_admin/features/stores/stores_view.dart';
import 'package:dym_admin/ui/inactivity_guard.dart';
import 'package:dym_admin/ui/navigation.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Onglet de l'admin (spec 013).
enum AdminTab { orders, disputes, stores, finance, settings, audit }

/// Admin des opérations : commandes (52, 53), litiges (54), boutiques (55),
/// finances (57), réglages (56) et journal (58). Déconnexion après 30 min
/// d'inactivité.
class AdminHomeView extends StatefulWidget {
  const new({
    super.key,
    this.service,
    this.admin,
    this.navigator,
    this.inactivity,
    this.initialTab = AdminTab.orders,
    this.clock = DateTime.now,
  });

  final AuthService? service;
  final AdminService? admin;
  final AdminNavigator? navigator;

  /// Délai d'inactivité (tests) ; 30 minutes par défaut.
  final Duration? inactivity;
  final AdminTab initialTab;
  final DateTime Function() clock;

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  late AdminTab _tab = widget.initialTab;
  String? _orderId;
  late final AuthService _service = widget.service ?? locator<AuthService>();
  late final AdminService _admin = widget.admin ?? locator<AdminService>();
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
    final orderId = _orderId;
    final body = switch (_tab) {
      AdminTab.orders when orderId != null => AdminOrderView(
        key: ValueKey(orderId),
        service: _admin,
        orderId: orderId,
        onBack: () => setState(() => _orderId = null),
        clock: widget.clock,
      ),
      AdminTab.orders => AdminOrdersView(
        service: _admin,
        onOpen: (id) => setState(() => _orderId = id),
        clock: widget.clock,
      ),
      AdminTab.disputes => AdminDisputesView(
        service: _admin,
        clock: widget.clock,
      ),
      AdminTab.stores => AdminStoresView(service: _admin),
      AdminTab.finance => AdminFinanceView(
        service: _admin,
        clock: widget.clock,
      ),
      AdminTab.settings => AdminSettingsView(
        service: _admin,
        onSignOut: _signOut,
      ),
      AdminTab.audit => AdminAuditView(service: _admin),
    };
    return InactivityGuard(
      timeout: widget.inactivity ?? const Duration(minutes: 30),
      onTimeout: () => _signOut(notice: AdminNotice.inactive),
      child: DymAdaptiveScaffold(
        backgroundColor: c.background,
        currentIndex: _tab.index,
        onDestinationSelected: (i) => setState(() {
          _tab = AdminTab.values[i];
          _orderId = null;
        }),
        railLeading: Padding(
          padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s3),
          child: Text(
            l10n.appNameAdmin,
            textAlign: TextAlign.center,
            style: t.title.copyWith(color: c.brandDeep),
          ),
        ),
        destinations: [
          DymNavItem(icon: Icons.receipt_long_rounded, label: l10n.navOrders),
          DymNavItem(
            icon: Icons.report_problem_rounded,
            label: l10n.adminNavDisputes,
          ),
          DymNavItem(icon: Icons.storefront_rounded, label: l10n.navStores),
          DymNavItem(
            icon: Icons.account_balance_wallet_rounded,
            label: l10n.adminNavFinance,
          ),
          DymNavItem(icon: Icons.tune_rounded, label: l10n.navSettings),
          DymNavItem(icon: Icons.history_rounded, label: l10n.adminNavAudit),
        ],
        body: SafeArea(
          child: KeyedSubtree(key: ValueKey(_tab), child: body),
        ),
      ),
    );
  }
}
