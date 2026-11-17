import 'package:dym_account/src/account_viewmodel.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Écran « Moi » (maquette 13) : profil (prénom, langue), réglages,
/// déconnexion et suppression du compte avec confirmation. Une entrée sans
/// destination (app qui ne la propose pas) n'est pas affichée.
class AccountView extends StackedView<AccountViewModel> {
  const new({
    required this.service,
    required this.onSignedOut,
    super.key,
    this.onAddresses,
    this.onNotifications,
    this.onMessages,
    this.onHelp,
    this.onWallet,
    this.onFavorites,
    this.onBaskets,
    this.onSpaces,
    this.onCreator,
    this.onGroupBuys,
    this.onMembership,
    this.onOrders,
    this.onDataSaver,
    this.banner,
  });

  final AuthService service;
  final void Function() onSignedOut;

  /// Mes adresses (app cliente) ; nul : non affiché.
  final VoidCallback? onAddresses;

  /// Réglages des notifications ; nul : non affiché.
  final VoidCallback? onNotifications;

  /// Mes messages (app cliente, spec 015) ; nul : non affiché.
  final VoidCallback? onMessages;

  /// Aide (spec 016) ; nul : non affiché.
  final VoidCallback? onHelp;

  /// Wallet et poches (spec 025) ; absent : ligne masquée.
  final VoidCallback? onWallet;

  /// Favoris et paniers enregistrés (spec 030) ; absents : lignes masquées.
  final VoidCallback? onFavorites;
  final VoidCallback? onBaskets;

  /// Espaces partagés (spec 031) ; absent : ligne masquée.
  final VoidCallback? onSpaces;

  /// Achats groupés entre voisins (spec 051) ; absent : ligne masquée.
  final VoidCallback? onGroupBuys;

  /// Économie de données (spec 103) ; null : pas de réglage.
  final VoidCallback? onDataSaver;

  /// DYM+ (spec 052) ; absent : ligne masquée.
  final VoidCallback? onMembership;

  /// Studio créatrice (spec 036) ; absent : ligne masquée.
  final VoidCallback? onCreator;

  /// Mes commandes (app cliente, design « Épuré ») ; absent : ligne masquée.
  final VoidCallback? onOrders;

  /// Bandeau en tête (commande en cours) ; nul : rien.
  final Widget? banner;

  @override
  AccountViewModel viewModelBuilder(BuildContext context) =>
      AccountViewModel(service: service, onSignedOut: onSignedOut);

  @override
  Widget builder(
    BuildContext context,
    AccountViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);

    DymMenuRow? row(IconData icon, String label, VoidCallback? tap) =>
        tap == null ? null : DymMenuRow(icon: icon, label: label, onTap: tap);
    List<Widget> rows(List<DymMenuRow?> items) => [...items.nonNulls];
    final groups = [
      rows([
        row(Icons.receipt_long_outlined, l10n.ordersMineTitle, onOrders),
        row(
          Icons.account_balance_wallet_outlined,
          l10n.accountWallet,
          onWallet,
        ),
        row(
          Icons.workspace_premium_outlined,
          l10n.accountMembership,
          onMembership,
        ),
        row(Icons.groups_outlined, l10n.accountSpaces, onSpaces),
        row(Icons.diversity_3_outlined, l10n.accountGroupBuys, onGroupBuys),
        row(Icons.chat_bubble_outline_rounded, l10n.chatMyMessages, onMessages),
      ]),
      rows([
        row(Icons.favorite_border_rounded, l10n.accountFavorites, onFavorites),
        row(Icons.shopping_basket_outlined, l10n.accountBaskets, onBaskets),
        row(Icons.location_on_outlined, l10n.accountAddresses, onAddresses),
        row(Icons.auto_awesome_outlined, l10n.accountCreator, onCreator),
        row(
          Icons.notifications_none_rounded,
          l10n.accountNotifications,
          onNotifications,
        ),
      ]),
      rows([
        row(
          Icons.language_rounded,
          l10n.accountLanguage(l10n.languageName),
          viewModel.isBusy ? null : () => _chooseLanguage(context, viewModel),
        ),
        row(Icons.data_saver_on_outlined, l10n.accountDataSaver, onDataSaver),
        row(Icons.help_outline_rounded, l10n.accountHelp, onHelp),
      ]),
      [
        DymMenuRow(
          icon: Icons.logout_rounded,
          label: l10n.accountSignOut,
          onTap: viewModel.isBusy ? null : viewModel.signOut,
        ),
        DymMenuRow(
          icon: Icons.delete_outline_rounded,
          label: l10n.accountDelete,
          destructive: true,
          onTap: viewModel.isBusy
              ? null
              : () => _confirmDelete(context, viewModel),
        ),
      ],
    ].where((g) => g.isNotEmpty);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final inset = DymLayout.sideInset(
              box.maxWidth,
              gutter: DymLayout.gutter(context),
              maxWidth: DymTokenLayout.formMax,
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(inset, 16, inset, 24),
              children: [
                Semantics(
                  header: true,
                  child: Text(l10n.accountTitle, style: t.display),
                ),
                const SizedBox(height: DymTokenSpace.s4),
                if (banner case final b?) ...[
                  b,
                  const SizedBox(height: DymTokenSpace.s3),
                ],
                Semantics(
                  button: true,
                  label: l10n.accountEditName,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(DymTokenRadius.card),
                    onTap: viewModel.isBusy
                        ? null
                        : () => _rename(context, viewModel),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: DymTokenSpace.s2,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: c.tintVertTendre,
                            child: Text(
                              viewModel.initial,
                              style: t.title.copyWith(color: c.brandDeep),
                            ),
                          ),
                          const SizedBox(width: DymTokenSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  viewModel.firstName,
                                  style: t.title.copyWith(fontSize: 18),
                                ),
                                if (viewModel.email != null)
                                  Text(
                                    viewModel.email!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.label.copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: c.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: c.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DymTokenSpace.s3),
                for (final group in groups) ...[
                  DymMenuGroup(children: group),
                  const SizedBox(height: DymTokenSpace.s3),
                ],
                AuthErrorBanner(error: viewModel.authError),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, AccountViewModel viewModel) async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.dym.colors.card,
      constraints: const BoxConstraints(maxWidth: DymTokenLayout.formMax),
      builder: (_) => _NameSheet(initial: viewModel.firstName),
    );
    if (name != null && name.trim().isNotEmpty) await viewModel.rename(name);
  }

  Future<void> _chooseLanguage(
    BuildContext context,
    AccountViewModel viewModel,
  ) async {
    final current = Localizations.localeOf(context).languageCode;
    final codes = await viewModel.languages([
      for (final l in DymLocalizations.supportedLocales) l.languageCode,
    ]);
    if (!context.mounted || codes.isEmpty) return;
    final code = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.dym.colors.card,
      constraints: const BoxConstraints(maxWidth: DymTokenLayout.formMax),
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final code in codes)
                ListTile(
                  minTileHeight: 56,
                  leading: Icon(
                    code == current
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                  ),
                  // Chaque langue s'écrit dans sa propre langue.
                  title: Text(
                    lookupDymLocalizations(Locale(code)).languageName,
                  ),
                  onTap: () => Navigator.of(sheet).pop(code),
                ),
            ],
          ),
        ),
      ),
    );
    if (code != null && code != current) await viewModel.setLanguage(code);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AccountViewModel viewModel,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.dym.colors.card,
      constraints: const BoxConstraints(maxWidth: DymTokenLayout.formMax),
      builder: (context) => const _DeleteSheet(),
    );
    if (confirmed ?? false) await viewModel.deleteAccount();
  }
}

class _DeleteSheet extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          DymLayout.gutter(context),
          0,
          DymLayout.gutter(context),
          DymTokenSpace.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: c.tintPimentClair,
              child: Icon(
                Icons.delete_rounded,
                color: c.pimentStrong,
                size: 36,
              ),
            ),
            const SizedBox(height: DymTokenSpace.s4),
            Text(
              l10n.accountDeleteTitle,
              textAlign: TextAlign.center,
              style: t.display.copyWith(fontSize: 26),
            ),
            const SizedBox(height: DymTokenSpace.s2),
            Text(
              l10n.accountDeleteBody,
              textAlign: TextAlign.center,
              style: t.body.copyWith(fontSize: 16, color: c.textSecondary),
            ),
            const SizedBox(height: DymTokenSpace.s5),
            DymButton(
              label: l10n.accountDeleteConfirm,
              variant: DymButtonVariant.destructive,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            DymButton(
              label: l10n.cancel,
              variant: DymButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Saisie du prénom (40 caractères au plus).
class _NameSheet extends StatefulWidget {
  const new({required this.initial});

  final String initial;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    void save() => Navigator.of(context).pop(_name.text);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          DymLayout.gutter(context),
          0,
          DymLayout.gutter(context),
          MediaQuery.viewInsetsOf(context).bottom + DymTokenSpace.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.accountEditName,
              style: context.dym.text.display.copyWith(fontSize: 24),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            DymTextField(
              label: l10n.authFirstNameLabel,
              controller: _name,
              maxLength: 40,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.givenName],
              onSubmitted: (_) => save(),
            ),
            const SizedBox(height: DymTokenSpace.s4),
            ListenableBuilder(
              listenable: _name,
              builder: (context, _) => DymButton(
                label: l10n.accountSave,
                onPressed: _name.text.trim().isEmpty ? null : save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
