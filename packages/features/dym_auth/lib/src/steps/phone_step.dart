import 'package:dym_auth/src/auth_flow_viewmodel.dart';
import 'package:dym_auth/src/widgets/step_scaffold.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Numéro WhatsApp (spec 105) : indicatif du pays, puis le numéro ; le code
/// arrive par WhatsApp.
class PhoneStep extends StatefulWidget {
  const new({required this.viewModel, super.key});

  final AuthFlowViewModel viewModel;

  @override
  State<PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<PhoneStep> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.viewModel.phone,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final l10n = DymLocalizations.of(context);
    final dials = {
      for (final c in vm.dialCountries) c.dialCode,
      if (vm.dialCode.isNotEmpty) vm.dialCode,
    }.toList();
    return StepScaffold(
      title: l10n.authPhoneTitle,
      subtitle: Text(l10n.authPhoneSubtitle),
      onBack: vm.back,
      action: DymButton(
        label: l10n.authSendCode,
        trailing: const Icon(Icons.chevron_right_rounded),
        loading: vm.isBusy,
        onPressed: vm.phoneValid ? vm.submitPhone : null,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: DropdownButtonFormField<String>(
                initialValue: vm.dialCode.isEmpty ? null : vm.dialCode,
                decoration: InputDecoration(labelText: l10n.authDialCode),
                items: [
                  for (final d in dials)
                    DropdownMenuItem(value: d, child: Text(d)),
                ],
                onChanged: (v) => v == null ? null : vm.setDialCode(v),
              ),
            ),
            const SizedBox(width: DymTokenSpace.s2),
            Expanded(
              child: DymTextField(
                label: l10n.authPhoneLabel,
                controller: _controller,
                icon: Icons.phone_iphone_rounded,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.send,
                autofillHints: const [AutofillHints.telephoneNumber],
                autofocus: true,
                onChanged: vm.setPhone,
                onSubmitted: (_) => vm.submitPhone(),
              ),
            ),
          ],
        ),
        AuthErrorBanner(error: vm.authError),
      ],
    );
  }
}
