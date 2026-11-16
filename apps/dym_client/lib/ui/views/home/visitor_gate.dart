import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Onglet réservé aux comptes, vu par une visiteuse (spec 093) : invitation
/// à se connecter, sans perdre ce qu'elle a découvert.
class VisitorGate extends StatelessWidget {
  const new({required this.message, required this.onSignIn, super.key});

  final String message;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return SafeArea(
      child: DymStateView(
        kind: DymStateKind.empty,
        title: l10n.visitorTitle,
        message: message,
        actionLabel: l10n.visitorSignIn,
        onAction: onSignIn,
      ),
    );
  }
}
