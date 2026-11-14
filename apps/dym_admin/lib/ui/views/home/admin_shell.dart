import 'package:dym_admin/ui/admin_theme.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Entrée du menu : icône, libellé, compteur d'actions en attente.
typedef AdminNavEntry<T> = ({T id, IconData icon, String label, int? badge});

/// Groupe du menu (Pilotage, Commerce…).
typedef AdminNavGroup<T> = ({String label, List<AdminNavEntry<T>> entries});

/// Coque de la console (spec 091) : menu latéral groupé, barre du haut avec
/// fil d'Ariane et compte, panneau blanc. Sur petit écran, le menu passe dans
/// un tiroir ouvert par le bouton de la barre du haut.
class AdminShell<T> extends StatelessWidget {
  const new({
    required this.groups,
    required this.selected,
    required this.onSelect,
    required this.title,
    required this.account,
    required this.role,
    required this.onSignOut,
    required this.body,
    super.key,
    this.environment,
  });

  final List<AdminNavGroup<T>> groups;
  final T selected;
  final ValueChanged<T> onSelect;

  /// Page ouverte (fil d'Ariane).
  final String title;

  /// Compte connecté (email) et rôle affiché.
  final String account;
  final String? role;
  final VoidCallback onSignOut;
  final Widget body;

  /// Environnement hors production (badge « staging »).
  final String? environment;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    Widget menu({required bool drawer}) => _Sidebar<T>(
      groups: groups,
      selected: selected,
      account: account,
      role: role,
      onSelect: (id) {
        if (drawer) Navigator.of(context).pop();
        onSelect(id);
      },
    );
    final panel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(
          title: title,
          account: account,
          role: role,
          environment: environment,
          onSignOut: onSignOut,
          showMenu: !wide,
        ),
        const Divider(height: 1),
        Expanded(child: body),
      ],
    );
    if (!wide) {
      return Scaffold(
        backgroundColor: AdminPalette.panel,
        drawer: Drawer(
          backgroundColor: AdminPalette.shell,
          shape: const RoundedRectangleBorder(),
          child: SafeArea(child: menu(drawer: true)),
        ),
        body: SafeArea(child: panel),
      );
    }
    return Scaffold(
      backgroundColor: AdminPalette.shell,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 248, child: menu(drawer: false)),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AdminPalette.panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AdminPalette.line),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 24,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: panel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar<T> extends StatelessWidget {
  const new({
    required this.groups,
    required this.selected,
    required this.onSelect,
    required this.account,
    required this.role,
  });

  final List<AdminNavGroup<T>> groups;
  final T selected;
  final ValueChanged<T> onSelect;
  final String account;
  final String? role;

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 14),
          child: Row(
            children: [
              DymLogoMark(size: 34, semanticLabel: l10n.appNameAdmin),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appNameAdmin,
                      style: t.title.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      l10n.adminBrandSub,
                      style: t.label.copyWith(
                        fontSize: 12,
                        color: AdminPalette.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              for (final g in groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
                  child: Text(
                    g.label,
                    style: t.label.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AdminPalette.ink3,
                    ),
                  ),
                ),
                for (final e in g.entries)
                  _NavTile(
                    entry: e,
                    selected: e.id == selected,
                    onTap: () => onSelect(e.id),
                  ),
              ],
            ],
          ),
        ),
        const Divider(height: 1, indent: 14, endIndent: 14),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 14, 14),
          child: Row(
            children: [
              _Avatar(account: account),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.label.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (role case final r?)
                      Text(
                        r,
                        style: t.label.copyWith(
                          fontSize: 12,
                          color: AdminPalette.ink3,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavTile<T> extends StatelessWidget {
  const new({required this.entry, required this.selected, required this.onTap});

  final AdminNavEntry<T> entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final badge = entry.badge;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? AdminPalette.panel : Colors.transparent,
          elevation: selected ? 0.6 : 0,
          shadowColor: const Color(0x33000000),
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(
                      entry.icon,
                      size: 18,
                      color: selected ? c.brand : const Color(0xFF4A514E),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.label.copyWith(
                          fontSize: 13.5,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    if (badge != null && badge > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AdminPalette.rose.$2,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '$badge',
                          style: t.label.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AdminPalette.rose.$1,
                          ),
                        ),
                      ),
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

class _TopBar extends StatelessWidget {
  const new({
    required this.title,
    required this.account,
    required this.role,
    required this.onSignOut,
    required this.showMenu,
    this.environment,
  });

  final String? environment;
  final String title;
  final String account;
  final String? role;
  final VoidCallback onSignOut;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return SizedBox(
      height: 58,
      child: Padding(
        padding: EdgeInsets.fromLTRB(showMenu ? 4 : 24, 0, 16, 0),
        child: Row(
          children: [
            if (showMenu)
              IconButton(
                tooltip: l10n.adminOpenMenu,
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            Text(
              l10n.adminCrumbRoot,
              style: t.label.copyWith(color: AdminPalette.ink3),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AdminPalette.ink3,
              ),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.label.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (environment case final env?)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AdminPalette.amber.$2,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  env,
                  style: t.label.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AdminPalette.amber.$1,
                  ),
                ),
              ),
            PopupMenuButton<void>(
              tooltip: account,
              position: PopupMenuPosition.under,
              itemBuilder: (_) => [
                PopupMenuItem<void>(
                  enabled: false,
                  child: Text(
                    [account, ?role].join(' · '),
                    style: t.label.copyWith(color: AdminPalette.ink2),
                  ),
                ),
                PopupMenuItem<void>(
                  onTap: onSignOut,
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(l10n.accountSignOut),
                    ],
                  ),
                ),
              ],
              child: _Avatar(account: account),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const new({required this.account});

  final String account;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final letters = account.isEmpty
        ? '·'
        : account.substring(0, account.length < 2 ? 1 : 2).toUpperCase();
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.tintVertTendre,
        shape: BoxShape.circle,
      ),
      child: Text(
        letters,
        style: context.dym.text.label.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: c.brandDeep,
        ),
      ),
    );
  }
}
