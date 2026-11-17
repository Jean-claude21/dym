import 'package:dym_auth/src/auth_flow_viewmodel.dart';
import 'package:dym_auth/src/widgets/step_scaffold.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Saisie du code à 6 chiffres (maquette 11). Vérification automatique dès la
/// dernière case ; renvoi possible après 60 s.
class CodeStep extends StatelessWidget {
  const new({required this.viewModel, super.key});

  final AuthFlowViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    return StepScaffold(
      title: l10n.authCodeTitle,
      subtitle: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: DymTokenSpace.s2,
        children: [
          Text(
            vm.viaWhatsApp
                ? l10n.authCodeSentToPhone(vm.phoneE164)
                : l10n.authCodeSentTo(vm.email),
          ),
          TextButton(
            onPressed: vm.changeEmail,
            child: Text(
              vm.viaWhatsApp ? l10n.authChangePhone : l10n.authChangeEmail,
              style: t.title.copyWith(
                fontSize: 16,
                color: c.brandDeep,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
      onBack: vm.back,
      action: vm.canResend
          ? DymButton(
              label: l10n.authResend,
              variant: DymButtonVariant.secondary,
              onPressed: vm.resendCode,
            )
          : Semantics(
              liveRegion: false,
              child: Text(
                l10n.authResendIn(vm.resendSeconds),
                textAlign: TextAlign.center,
                style: t.label.copyWith(fontSize: 16, color: c.textSecondary),
              ),
            ),
      children: [
        // Mode simulé (staging, sans compte Meta) : le code est affiché.
        if (vm.simulatedCode case final code?) ...[
          Container(
            padding: const EdgeInsets.all(DymTokenSpace.s3),
            decoration: BoxDecoration(
              color: c.muted,
              borderRadius: BorderRadius.circular(DymTokenRadius.field),
            ),
            child: Text(
              l10n.authSimulatedCode(code),
              style: t.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: DymTokenSpace.s3),
        ],
        DymCodeInput(
          label: l10n.authCodeLabel,
          error: vm.codeRejected,
          enabled: !vm.isBusy,
          onChanged: vm.setCode,
        ),
        if (vm.isBusy) ...[
          const SizedBox(height: DymTokenSpace.s4),
          Center(child: CircularProgressIndicator(color: c.brand)),
        ],
        AuthErrorBanner(error: vm.authError),
        const SizedBox(height: DymTokenSpace.s5),
        Container(
          padding: const EdgeInsets.all(DymTokenSpace.s3 + 2),
          decoration: BoxDecoration(
            color: c.muted,
            borderRadius: BorderRadius.circular(DymTokenRadius.field),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: c.textSecondary,
                size: 20,
              ),
              const SizedBox(width: DymTokenSpace.s2 + 2),
              Expanded(
                child: Text(
                  vm.viaWhatsApp ? l10n.authCodeTipWhatsApp : l10n.authCodeTip,
                  style: t.label.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
