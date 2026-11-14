import 'dart:async';

import 'package:dym_admin/app/app.locator.dart';
import 'package:dym_admin/features/audit/audit_view.dart';
import 'package:dym_admin/features/clients/clients_view.dart';
import 'package:dym_admin/features/dashboard/dashboard_view.dart';
import 'package:dym_admin/features/disputes/disputes_view.dart';
import 'package:dym_admin/features/finance/finance_view.dart';
import 'package:dym_admin/features/moderation/moderation_view.dart';
import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_texts.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_admin/features/ops_center/ops_center_view.dart';
import 'package:dym_admin/features/orders/orders_views.dart';
import 'package:dym_admin/features/settings/settings_view.dart';
import 'package:dym_admin/features/stores/stores_view.dart';
import 'package:dym_admin/features/support/support_view.dart';
import 'package:dym_admin/ui/inactivity_guard.dart';
import 'package:dym_admin/ui/navigation.dart';
import 'package:dym_admin/ui/views/home/admin_shell.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
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

  /// Rôle et permissions (spec 085) ; `null` tant qu'ils ne sont pas lus :
  /// tout reste visible, la base refuse ce que le rôle ne permet pas.
  AdminAccess? _access;

  /// Compteurs du menu (litiges, boutiques à valider, demandes, commandes
  /// bloquées) ; absents tant qu'ils ne sont pas lus.
  AdminDashboard? _counts;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAccess());
    unawaited(_loadCounts());
  }

  Future<void> _loadCounts() async {
    if (await _admin.dashboard('day') case Ok(:final value) when mounted) {
      setState(() => _counts = value);
    }
  }

  Future<void> _loadAccess() async {
    if (await _admin.me() case Ok(:final value) when mounted) {
      setState(() {
        _access = value;
        if (!_allowed(_tab)) {
          _tab = _groups(DymLocalizations.of(context))
              .expand((g) => g.entries)
              .first
              .id;
        }
      });
    }
  }

  /// Onglet ouvert au rôle : lecture du domaine concerné. Les réglages
  /// restent toujours ouverts (déconnexion, sections filtrées).
  bool _allowed(AdminTab tab) {
    final access = _access;
    if (access == null) return true;
    return switch (tab) {
      AdminTab.dashboard => access.reads('dashboard'),
      AdminTab.ops || AdminTab.orders => access.reads('orders'),
      AdminTab.disputes => access.reads('disputes'),
      AdminTab.stores => access.reads('stores'),
      AdminTab.clients => access.reads('clients'),
      AdminTab.finance => access.reads('finance'),
      AdminTab.support => access.reads('support'),
      AdminTab.moderation => access.reads('content'),
      AdminTab.settings => true,
      AdminTab.audit => access.reads('system'),
    };
  }

  /// Adresse du serveur MCP (Functions + `/mcp`), si l'environnement est connu.
  String? get _mcpEndpoint => locator.isRegistered<DymEnvironment>()
      ? '${locator<DymEnvironment>().functionsUrl.toString().replaceAll(RegExp(r'/$'), '')}/mcp'
      : null;

  Future<void> _signOut({AdminNotice? notice}) async {
    await _service.signOut();
    _navigator.toSignIn(notice: notice);
  }

  @override
  Widget build(BuildContext context) {
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
            DashboardLink.drafts || DashboardLink.stores => AdminTab.stores,
            DashboardLink.orders => AdminTab.orders,
            DashboardLink.finance => AdminTab.finance,
            DashboardLink.clients => AdminTab.clients,
            DashboardLink.live => AdminTab.ops,
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
        access: _access,
        mcpEndpoint: _mcpEndpoint,
      ),
      AdminTab.audit => AdminAuditView(service: _admin),
    };
    final env = locator.isRegistered<DymEnvironment>()
        ? locator<DymEnvironment>()
        : null;
    final role = _access?.role;
    return InactivityGuard(
      timeout: widget.inactivity ?? const Duration(minutes: 30),
      onTimeout: () => _signOut(notice: AdminNotice.inactive),
      child: AdminShell<AdminTab>(
        groups: _groups(l10n),
        selected: _tab,
        onSelect: (tab) => setState(() {
          _tab = tab;
          _orderId = null;
        }),
        title: _label(l10n, _tab),
        account: _service.email ?? '',
        role: role == null ? null : adminRoleLabel(l10n, role),
        environment: env == null || env.isProduction ? null : env.name.name,
        onSignOut: _signOut,
        body: KeyedSubtree(key: ValueKey(_tab), child: body),
      ),
    );
  }

  String _label(DymLocalizations l10n, AdminTab tab) => switch (tab) {
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

  IconData _icon(AdminTab tab) => switch (tab) {
    AdminTab.dashboard => Icons.space_dashboard_outlined,
    AdminTab.ops => Icons.monitor_heart_outlined,
    AdminTab.orders => Icons.shopping_bag_outlined,
    AdminTab.stores => Icons.storefront_outlined,
    AdminTab.clients => Icons.people_outline_rounded,
    AdminTab.finance => Icons.account_balance_wallet_outlined,
    AdminTab.disputes => Icons.gavel_rounded,
    AdminTab.moderation => Icons.shield_outlined,
    AdminTab.support => Icons.chat_bubble_outline_rounded,
    AdminTab.settings => Icons.settings_outlined,
    AdminTab.audit => Icons.receipt_long_outlined,
  };

  int? _badge(AdminTab tab) {
    final d = _counts;
    if (d == null) return null;
    return switch (tab) {
      AdminTab.disputes => d.openDisputes,
      AdminTab.stores => d.draftStores,
      AdminTab.support => d.openTickets,
      AdminTab.orders => d.stuckOrders,
      _ => null,
    };
  }

  /// Menu groupé par métier ; seuls les onglets ouverts au rôle y figurent.
  List<AdminNavGroup<AdminTab>> _groups(DymLocalizations l10n) {
    AdminNavGroup<AdminTab> group(String label, List<AdminTab> tabs) => (
      label: label,
      entries: [
        for (final tab in tabs)
          if (_allowed(tab) && (tab != AdminTab.ops || _ops != null))
            (
              id: tab,
              icon: _icon(tab),
              label: _label(l10n, tab),
              badge: _badge(tab),
            ),
      ],
    );
    return [
      group(l10n.adminGroupPilot, const [AdminTab.dashboard, AdminTab.ops]),
      group(l10n.adminGroupCommerce, const [
        AdminTab.orders,
        AdminTab.stores,
        AdminTab.clients,
      ]),
      group(l10n.adminGroupMoney, const [AdminTab.finance]),
      group(l10n.adminGroupQuality, const [
        AdminTab.disputes,
        AdminTab.moderation,
        AdminTab.support,
      ]),
      group(l10n.adminGroupSettings, const [AdminTab.settings, AdminTab.audit]),
    ].where((g) => g.entries.isNotEmpty).toList();
  }
}
