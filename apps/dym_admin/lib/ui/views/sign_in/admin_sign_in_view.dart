import 'package:dym_admin/ui/navigation.dart';
import 'package:dym_admin/ui/views/sign_in/admin_sign_in_viewmodel.dart';
import 'package:dym_admin/ui/views/sign_in/google_button.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Connexion de l'équipe (maquette 15) : carte centrée, photo du marché à
/// gauche sur grand écran.
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
                const SizedBox(height: DymTokenSpace.s3),
                DymTextField(
                  label: l10n.authPasswordLabel,
                  obscureText: true,
                  onChanged: viewModel.setPassword,
                  onSubmitted: (_) => viewModel.signInWithPassword(),
                  autofillHints: const [AutofillHints.password],
                ),
              ],
              const SizedBox(height: DymTokenSpace.s3),
              DymButton(
                label: viewModel.usePassword
                    ? l10n.authSignInPassword
                    : l10n.authSendCode,
                loading: viewModel.isBusy,
                onPressed: viewModel.usePassword
                    ? viewModel.signInWithPassword
                    : viewModel.sendCode,
              ),
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
    final card = Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.all(DymTokenSpace.s6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        boxShadow: const [DymTokenShadows.card],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.appNameAdmin,
            style: t.title.copyWith(fontSize: 22, color: c.brandDeep),
          ),
          const SizedBox(height: DymTokenSpace.s4),
          Text(
            l10n.adminSignInTitle,
            textAlign: TextAlign.center,
            style: t.display.copyWith(fontSize: 32),
          ),
          const SizedBox(height: DymTokenSpace.s2),
          Text(
            l10n.adminSignInBody,
            textAlign: TextAlign.center,
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
                  borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                ),
                child: Text(
                  switch (notice) {
                    AdminNotice.accessDenied => l10n.adminAccessDenied,
                    AdminNotice.inactive => l10n.adminSignedOutInactive,
                    AdminNotice.offline => l10n.errorOffline,
                    AdminNotice.generic => l10n.errorGeneric,
                    AdminNotice.codeWrong => l10n.authCodeWrong,
                    AdminNotice.emailInvalid => l10n.authEmailInvalid,
                    AdminNotice.passwordWrong => l10n.authPasswordWrong,
                  },
                  textAlign: TextAlign.center,
                  style: t.label.copyWith(fontSize: 15, color: c.textPrimary),
                ),
              ),
            ),
          ],
          const SizedBox(height: DymTokenSpace.s5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded, color: c.brandDeep, size: 22),
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

    final page = Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(DymLayout.gutter(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            card,
            const SizedBox(height: DymTokenSpace.s5),
            Text(
              l10n.adminAuditNote,
              textAlign: TextAlign.center,
              style: t.label.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white.withValues(alpha: 0),
                        ],
                        stops: const [0.7, 1],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: const Image(
                        image: AssetImage(
                          'assets/admin_market.webp',
                          package: 'dym_auth',
                        ),
                        fit: BoxFit.cover,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  Expanded(flex: 3, child: page),
                ],
              )
            : page,
      ),
    );
  }
}
