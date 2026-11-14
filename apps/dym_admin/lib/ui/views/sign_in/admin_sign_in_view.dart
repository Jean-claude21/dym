import 'package:dym_admin/ui/admin_theme.dart';
import 'package:dym_admin/ui/navigation.dart';
import 'package:dym_admin/ui/views/sign_in/admin_sign_in_viewmodel.dart';
import 'package:dym_admin/ui/views/sign_in/google_button.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Connexion de l'équipe (spec 091) : sur grand écran, carte blanche centrée
/// sur le fond de la console, photo du marché encadrée à gauche.
class AdminSignInView extends StackedView<AdminSignInViewModel> {
  const new({super.key, this.notice, this.viewModelFactory});

  /// Message à afficher à l'arrivée (accès refusé, inactivité…).
  final AdminNotice? notice;

  /// Fabrique du viewmodel (tests).
  final AdminSignInViewModel Function()? viewModelFactory;

  static const _clientId = String.fromEnvironment('DYM_GOOGLE_CLIENT_ID');

  @override
  AdminSignInViewModel viewModelBuilder(BuildContext context) =>
      viewModelFactory?.call() ?? AdminSignInViewModel(notice: notice);

  @override
  Widget builder(
    BuildContext context,
    AdminSignInViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final wide = DymWindowClass.of(context) >= DymWindowClass.expanded;

    final webButton = googleWebButton(
      clientId: _clientId,
      onIdToken: viewModel.signInWithIdToken,
    );
    Widget? googleAction;
    if (webButton != null) {
      googleAction = Center(child: webButton);
    } else if (viewModel.nativeGoogleAvailable) {
      googleAction = DymButton(
        label: l10n.adminContinueGoogle,
        variant: DymButtonVariant.surface,
        leading: const DymGoogleLogo(),
        loading: viewModel.isBusy,
        onPressed: viewModel.signInWithGoogle,
      );
    }

    final Widget emailAction = viewModel.codeSent
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.authCodeSentTo(viewModel.email.trim()),
                textAlign: TextAlign.center,
                style: t.body.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: DymTokenSpace.s3),
              DymCodeInput(
                label: l10n.authCodeLabel,
                onChanged: viewModel.setCode,
                onCompleted: viewModel.verifyCode,
                error: viewModel.notice == AdminNotice.codeWrong,
                enabled: !viewModel.isBusy,
              ),
              const SizedBox(height: DymTokenSpace.s3),
              DymButton(
                label: l10n.storeContinue,
                loading: viewModel.isBusy,
                onPressed: viewModel.verifyCode,
              ),
              TextButton(
                onPressed: viewModel.changeEmail,
                child: Text(l10n.authEmailLabel),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DymTextField(
                label: l10n.authEmailLabel,
                onChanged: viewModel.setEmail,
                onSubmitted: (_) => viewModel.usePassword
                    ? viewModel.signInWithPassword()
                    : viewModel.sendCode(),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.send,
                autofillHints: const [AutofillHints.email],
              ),
              if (viewModel.usePassword) ...[
                const SizedBox(height: DymTokenSpace.s4),
                DymTextField(
                  label: l10n.authPasswordLabel,
                  obscureText: true,
                  onChanged: viewModel.setPassword,
                  onSubmitted: (_) => viewModel.signInWithPassword(),
                  autofillHints: const [AutofillHints.password],
                ),
              ],
              const SizedBox(height: DymTokenSpace.s4),
              DymButton(
                label: viewModel.usePassword
                    ? l10n.authSignInPassword
                    : l10n.authSendCode,
                loading: viewModel.isBusy,
                onPressed: viewModel.usePassword
                    ? viewModel.signInWithPassword
                    : viewModel.sendCode,
              ),
              if (DymEnvironment.testToolsEnabled)
                TextButton(
                  onPressed: viewModel.toggleUsePassword,
                  child: Text(
                    viewModel.usePassword
                        ? l10n.authUseCode
                        : l10n.authUsePassword,
                  ),
                ),
            ],
          );

    final notice = viewModel.notice;
    final card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const DymLogoMark(size: 36),
              const SizedBox(width: DymTokenSpace.s2),
              Text(l10n.appNameAdmin, style: t.title.copyWith(fontSize: 17)),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s6),
          Text(l10n.adminSignInTitle, style: t.display.copyWith(fontSize: 28)),
          const SizedBox(height: DymTokenSpace.s2),
          Text(
            l10n.adminSignInBody,
            style: t.body.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: DymTokenSpace.s5),
          emailAction,
          if (googleAction != null) ...[
            const SizedBox(height: DymTokenSpace.s4),
            googleAction,
          ],
          if (notice != null) ...[
            const SizedBox(height: DymTokenSpace.s4),
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(DymTokenSpace.s3),
                decoration: BoxDecoration(
                  color: c.tintPimentClair,
                  borderRadius: BorderRadius.circular(DymTokenRadius.field),
                ),
                child: Text(switch (notice) {
                  AdminNotice.accessDenied => l10n.adminAccessDenied,
                  AdminNotice.inactive => l10n.adminSignedOutInactive,
                  AdminNotice.offline => l10n.errorOffline,
                  AdminNotice.generic => l10n.errorGeneric,
                  AdminNotice.codeWrong => l10n.authCodeWrong,
                  AdminNotice.emailInvalid => l10n.authEmailInvalid,
                  AdminNotice.passwordWrong => l10n.authPasswordWrong,
                }, style: t.label.copyWith(color: c.textPrimary)),
              ),
            ),
          ],
          const SizedBox(height: DymTokenSpace.s5),
          Row(
            children: [
              Icon(Icons.shield_outlined, color: c.textSecondary, size: 20),
              const SizedBox(width: DymTokenSpace.s2),
              Flexible(
                child: Text(
                  l10n.adminSecurityNote,
                  style: t.label.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final form = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card,
          const SizedBox(height: DymTokenSpace.s3),
          Text(
            l10n.adminAuditNote,
            style: t.label.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AdminPalette.ink3,
            ),
          ),
        ],
      ),
    );

    if (!wide) {
      return Scaffold(
        backgroundColor: AdminPalette.panel,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(DymLayout.gutter(context)),
              child: form,
            ),
          ),
        ),
      );
    }

    // Grand écran : carte blanche centrée, photo encadrée à gauche (spec 091).
    final hero = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Image(
            image: AssetImage('assets/admin_hero.webp', package: 'dym_auth'),
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0xB3102A20)],
                stops: [0.45, 1],
              ),
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adminSignInHeroTitle,
                  style: t.display.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.adminSignInHeroBody,
                  style: t.body.copyWith(color: const Color(0xE6FFFFFF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: AdminPalette.shell,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1120),
              height: 660,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AdminPalette.panel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AdminPalette.line),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 40,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: hero),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: form,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
