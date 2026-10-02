import 'package:dym_auth/src/auth_flow_viewmodel.dart';
import 'package:dym_auth/src/widgets/step_scaffold.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Saisie de l'email (maquette 10).
class EmailStep extends StatefulWidget {
  const new({required this.viewModel, super.key});

  final AuthFlowViewModel viewModel;

  @override
  State<EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends State<EmailStep> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.viewModel.email,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final status = !vm.emailTouched
        ? DymFieldStatus.none
        : vm.emailValid
        ? DymFieldStatus.valid
        : DymFieldStatus.error;
    return StepScaffold(
      title: l10n.authEmailTitle,
      subtitle: Text(l10n.authEmailSubtitle),
      onBack: vm.back,
      action: DymButton(
        label: l10n.authSendCode,
        trailing: const Icon(Icons.chevron_right_rounded),
        loading: vm.isBusy,
        onPressed: vm.emailValid ? vm.submitEmail : null,
      ),
      children: [
        DymTextField(
          label: l10n.authEmailLabel,
          controller: _controller,
          icon: Icons.mail_outline_rounded,
          hint: 'prenom@exemple.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          autofillHints: const [AutofillHints.email],
          autofocus: true,
          onChanged: vm.setEmail,
          onSubmitted: (_) => vm.submitEmail(),
          status: status,
          message: switch (status) {
            DymFieldStatus.valid => l10n.authEmailValid,
            DymFieldStatus.error => l10n.authEmailInvalid,
            DymFieldStatus.none => null,
          },
        ),
        if (vm.authError != AuthError.emailInvalid)
          AuthErrorBanner(error: vm.authError),
        const SizedBox(height: DymTokenSpace.s5),
        Row(
          children: [
            Icon(Icons.lock_rounded, color: c.brandDeep, size: 22),
            const SizedBox(width: DymTokenSpace.s2),
            Expanded(
              child: Text(
                l10n.authEmailPrivacy,
                style: t.label.copyWith(fontSize: 14, color: c.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
