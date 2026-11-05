import 'package:dym_account/src/account_viewmodel.dart';
import 'package:dym_auth/dym_auth.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Écran « Moi » (maquette 13) : profil, réglages à venir, déconnexion et
/// suppression du compte avec confirmation.
class AccountView extends StackedView<AccountViewModel> {
  const new({
    required this.service,
    required this.onSignedOut,
    super.key,
    this.onAddresses,
    this.onNotifications,
    this.onMessages,
  });

  final AuthService service;
  final void Function() onSignedOut;

  /// Mes adresses (app cliente) ; nul : « bientôt ».
  final VoidCallback? onAddresses;

  /// Réglages des notifications ; nul : « bientôt ».
  final VoidCallback? onNotifications;

  /// Mes messages (app cliente, spec 015) ; nul : non affiché.
  final VoidCallback? onMessages;

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
    void soon() => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.comingSoon)));

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
                Text(
                  l10n.accountTitle,
                  textAlign: TextAlign.center,
                  style: t.display.copyWith(fontSize: 30),
                ),
                const SizedBox(height: DymTokenSpace.s5),
                Container(
                  padding: const EdgeInsets.all(DymTokenSpace.s4),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(DymTokenRadius.card),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: c.tintVertTendre,
                        child: Text(
                          viewModel.initial,
                          style: t.display.copyWith(
                            fontSize: 28,
                            color: c.brandDeep,
                          ),
                        ),
                      ),
                      const SizedBox(width: DymTokenSpace.s4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              viewModel.firstName,
                              style: t.display.copyWith(fontSize: 26),
                            ),
                            if (viewModel.email != null)
                              Text(
                                viewModel.email!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.body.copyWith(color: c.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DymTokenSpace.s4),
                if (onMessages case final messages?) ...[
                  DymMenuRow(
                    icon: Icons.chat_bubble_rounded,
                    label: l10n.chatMyMessages,
                    onTap: messages,
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                ],
                DymMenuRow(
                  icon: Icons.location_on_rounded,
                  label: l10n.accountAddresses,
                  onTap: onAddresses ?? soon,
                ),
                const SizedBox(height: DymTokenSpace.s3),
                DymMenuRow(
                  icon: Icons.notifications_rounded,
                  label: l10n.accountNotifications,
                  onTap: onNotifications ?? soon,
                ),
                const SizedBox(height: DymTokenSpace.s3),
                for (final (icon, label) in [
                  (
                    Icons.language_rounded,
                    l10n.accountLanguage(l10n.languageName),
                  ),
                  (Icons.help_rounded, l10n.accountHelp),
                ]) ...[
                  DymMenuRow(icon: icon, label: label, onTap: soon),
                  const SizedBox(height: DymTokenSpace.s3),
                ],
                DymMenuRow(
                  icon: Icons.logout_rounded,
                  label: l10n.accountSignOut,
                  onTap: viewModel.isBusy ? null : viewModel.signOut,
                ),
                const SizedBox(height: DymTokenSpace.s3),
                DymMenuRow(
                  icon: Icons.delete_rounded,
                  label: l10n.accountDelete,
                  destructive: true,
                  onTap: viewModel.isBusy
                      ? null
                      : () => _confirmDelete(context, viewModel),
                ),
                AuthErrorBanner(error: viewModel.authError),
              ],
            );
          },
        ),
      ),
    );
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
