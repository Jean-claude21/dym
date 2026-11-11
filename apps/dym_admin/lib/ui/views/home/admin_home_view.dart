import 'package:dym_admin/app/app.locator.dart';
import 'package:dym_admin/features/audit/audit_view.dart';
import 'package:dym_admin/features/clients/clients_view.dart';
import 'package:dym_admin/features/dashboard/dashboard_view.dart';
import 'package:dym_admin/features/disputes/disputes_view.dart';
import 'package:dym_admin/features/finance/finance_view.dart';
import 'package:dym_admin/features/moderation/moderation_view.dart';
import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_admin/features/ops_center/ops_center_view.dart';
import 'package:dym_admin/features/orders/orders_views.dart';
import 'package:dym_admin/features/settings/settings_view.dart';
import 'package:dym_admin/features/stores/stores_view.dart';
import 'package:dym_admin/features/support/support_view.dart';
import 'package:dym_admin/ui/inactivity_guard.dart';
import 'package:dym_admin/ui/navigation.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Onglet de l'admin (specs 013 et 017), dans l'ordre de la maquette 67.
enum AdminTab {
  dashboard,
  ops,
  orders,
  disputes,
  stores,
  clients,
  finance,
  support,
  moderation,
  settings,
  audit,
}

/// Sept domaines de la console (design « Épuré », PARCOURS §4.4) ; chacun
/// regroupe des écrans existants, choisis par des puces.
enum AdminDomain { live, orders, support, accounts, finance, settings, audit }

/// Admin de l'équipe : tableau de bord (67), commandes (52, 53), litiges
/// (54), boutiques (55), clientes (68), finances (57, 70), support (69),
/// modération (76), réglages (56) et journal (58). Déconnexion après 30 min
/// d'inactivité.
class AdminHomeView extends StatefulWidget {
  const new({
    super.key,
    this.service,
    this.admin,
    this.ops,
    this.navigator,
    this.inactivity,
    this.initialTab = AdminTab.dashboard,
    this.clock = DateTime.now,
  });

  final AuthService? service;
  final AdminService? admin;

  /// Centre d'opérations (spec 053) ; absent : onglet vide.
  final OpsCenterService? ops;
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
  late final OpsCenterService? _ops =
      widget.ops ??
      (locator.isRegistered<OpsCenterService>()
          ? locator<OpsCenterService>()
          : null);
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
      AdminTab.dashboard => AdminDashboardView(
        service: _admin,
        onOpen: (link) => setState(() {
          _tab = switch (link) {
            DashboardLink.stuckOrders => AdminTab.orders,
            DashboardLink.disputes => AdminTab.disputes,
            DashboardLink.tickets => AdminTab.support,
            DashboardLink.drafts => AdminTab.stores,
          };
        }),
      ),
      AdminTab.ops => switch (_ops) {
        final ops? => OpsCenterView(
          service: ops,
          onOpenOrder: (id) => setState(() {
            _tab = AdminTab.orders;
            _orderId = id;
          }),
        ),
        null => AdminEmpty(l10n.opsNoCountry),
      },
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
      AdminTab.clients => AdminClientsView(
        service: _admin,
        clock: widget.clock,
      ),
      AdminTab.support => AdminSupportView(
        service: _admin,
        clock: widget.clock,
      ),
      AdminTab.moderation => AdminModerationView(
        service: _admin,
        clock: widget.clock,
      ),
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
    final domain = _domainOf(_tab);
    final tabs = _tabsOf(domain);
    String tabLabel(AdminTab tab) => switch (tab) {
      AdminTab.ops => l10n.opsTitle,
      AdminTab.dashboard => l10n.adminNavDashboard,
      AdminTab.support => l10n.adminNavSupport,
      AdminTab.disputes => l10n.adminNavDisputes,
      AdminTab.moderation => l10n.adminNavModeration,
      AdminTab.stores => l10n.navStores,
      AdminTab.clients => l10n.adminNavClients,
      AdminTab.orders => l10n.navOrders,
      AdminTab.finance => l10n.adminNavFinance,
      AdminTab.settings => l10n.adminNavConfig,
      AdminTab.audit => l10n.adminNavAudit,
    };
    return InactivityGuard(
      timeout: widget.inactivity ?? const Duration(minutes: 30),
      onTimeout: () => _signOut(notice: AdminNotice.inactive),
      child: DymAdaptiveScaffold(
        backgroundColor: c.background,
        currentIndex: domain.index,
        maxBottomItems: 4,
        moreItem: DymNavItem(icon: Icons.menu_rounded, label: l10n.navMore),
        onDestinationSelected: (i) => setState(() {
          _tab = _tabsOf(AdminDomain.values[i]).first;
          _orderId = null;
        }),
        railLeading: Padding(
          padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s3),
          child: Text(
            l10n.appNameAdmin,
            textAlign: TextAlign.center,
            style: t.display.copyWith(fontSize: 22),
          ),
        ),
        destinations: [
          DymNavItem(icon: Icons.show_chart_rounded, label: l10n.adminNavLive),
          DymNavItem(icon: Icons.shopping_cart_outlined, label: l10n.navOrders),
          DymNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: l10n.adminNavSupport,
          ),
          DymNavItem(
            icon: Icons.people_outline_rounded,
            label: l10n.adminNavAccounts,
          ),
          DymNavItem(
            icon: Icons.account_balance_outlined,
            label: l10n.adminNavFinance,
          ),
          DymNavItem(icon: Icons.settings_outlined, label: l10n.adminNavConfig),
          DymNavItem(icon: Icons.menu_book_outlined, label: l10n.adminNavAudit),
        ],
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sous-sections du domaine (ex. Support : demandes, litiges,
              // modération).
              if (tabs.length > 1)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    DymLayout.gutter(context),
                    DymTokenSpace.s3,
                    DymLayout.gutter(context),
                    0,
                  ),
                  child: Wrap(
                    spacing: DymTokenSpace.s2,
                    runSpacing: DymTokenSpace.s2,
                    children: [
                      for (final tab in tabs)
                        DymFilterChip(
                          label: tabLabel(tab),
                          selected: tab == _tab,
                          onTap: () => setState(() {
                            _tab = tab;
                            _orderId = null;
                          }),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: KeyedSubtree(key: ValueKey(_tab), child: body),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AdminDomain _domainOf(AdminTab tab) => switch (tab) {
    AdminTab.ops || AdminTab.dashboard => AdminDomain.live,
    AdminTab.orders => AdminDomain.orders,
    AdminTab.support ||
    AdminTab.disputes ||
    AdminTab.moderation => AdminDomain.support,
    AdminTab.stores || AdminTab.clients => AdminDomain.accounts,
    AdminTab.finance => AdminDomain.finance,
    AdminTab.settings => AdminDomain.settings,
    AdminTab.audit => AdminDomain.audit,
  };

  List<AdminTab> _tabsOf(AdminDomain domain) => switch (domain) {
    AdminDomain.live => [if (_ops != null) AdminTab.ops, AdminTab.dashboard],
    AdminDomain.orders => const [AdminTab.orders],
    AdminDomain.support => const [
      AdminTab.support,
      AdminTab.disputes,
      AdminTab.moderation,
    ],
    AdminDomain.accounts => const [AdminTab.stores, AdminTab.clients],
    AdminDomain.finance => const [AdminTab.finance],
    AdminDomain.settings => const [AdminTab.settings],
    AdminDomain.audit => const [AdminTab.audit],
  };
}
