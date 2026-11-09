import 'package:dym_auth/src/auth_flow_viewmodel.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Gabarit des étapes de connexion : `DymFormScaffold` avec le libellé de
/// retour localisé.
class StepScaffold extends StatelessWidget {
  const new({
    required this.title,
    required this.children,
    required this.action,
    super.key,
    this.subtitle,
    this.onBack,
    this.backgroundColor,
  });

  final String title;
  final Widget? subtitle;
  final List<Widget> children;
  final Widget action;
  final VoidCallback? onBack;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => DymFormScaffold(
    title: title,
    subtitle: subtitle,
    action: action,
    onBack: onBack,
    backLabel: DymLocalizations.of(context).authBack,
    backgroundColor: backgroundColor,
    children: children,
  );
}

/// Message d'erreur du parcours (icône + texte, annoncé aux lecteurs d'écran).
class AuthErrorBanner extends StatelessWidget {
  const new({required this.error, super.key, this.onDark = false});

  final AuthError? error;
  final bool onDark;

  static String messageFor(DymLocalizations l10n, AuthError error) =>
      switch (error) {
        AuthError.offline => l10n.errorOffline,
        AuthError.generic => l10n.errorGeneric,
        AuthError.codeWrong => l10n.authCodeWrong,
        AuthError.passwordWrong => l10n.authPasswordWrong,
        AuthError.sessionExpired => l10n.errorSessionExpired,
        AuthError.emailInvalid => l10n.authEmailInvalid,
        AuthError.firstNameInvalid => l10n.authFirstNameInvalid,
        AuthError.zoneRequired => l10n.authZoneRequired,
        AuthError.googleUnavailable => l10n.adminGoogleUnavailable,
      };

  @override
  Widget build(BuildContext context) {
    final current = error;
    if (current == null) return const SizedBox.shrink();
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: DymTokenSpace.s3),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(DymTokenSpace.s3),
          decoration: BoxDecoration(
            color: onDark ? c.card : c.tintPimentClair,
            borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          ),
          child: Row(
            children: [
              Icon(
                current == AuthError.offline
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                color: c.pimentStrong,
              ),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Text(
                  messageFor(l10n, current),
                  style: context.dym.text.label.copyWith(
                    fontSize: 15,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
