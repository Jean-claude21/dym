import 'package:dym_auth/src/auth_flow_viewmodel.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Gabarit des étapes : retour, titre, sous-titre, contenu défilant borné à la
/// largeur d'un formulaire, action principale en bas.
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
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return Scaffold(
      backgroundColor: backgroundColor ?? c.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final inset = DymLayout.sideInset(
                    box.maxWidth,
                    gutter: DymLayout.gutter(context),
                    maxWidth: DymTokenLayout.formMax,
                  );
                  return ListView(
                    padding: EdgeInsets.fromLTRB(inset, 8, inset, 24),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: onBack == null
                            ? const SizedBox(height: DymTokenSize.touchMin)
                            : _BackButton(label: l10n.authBack, onTap: onBack!),
                      ),
                      const SizedBox(height: DymTokenSpace.s5),
                      Text(
                        title,
                        style: t.display.copyWith(fontSize: 40, height: 1.1),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: DymTokenSpace.s2),
                        DefaultTextStyle.merge(
                          style: t.body.copyWith(
                            fontSize: 17,
                            color: c.textSecondary,
                          ),
                          child: subtitle!,
                        ),
                      ],
                      const SizedBox(height: DymTokenSpace.s5),
                      ...children,
                    ],
                  );
                },
              ),
            ),
            DymContentWidth.form(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DymLayout.gutter(context),
                  4,
                  DymLayout.gutter(context),
                  12,
                ),
                child: action,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const new({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Material(
      color: c.card,
      shape: const CircleBorder(),
      elevation: 0.5,
      child: IconButton(
        tooltip: label,
        onPressed: onTap,
        icon: Icon(Icons.arrow_back_rounded, color: c.brandDeep),
      ),
    );
  }
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
