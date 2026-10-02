import 'package:dym_auth/src/auth_flow_viewmodel.dart';
import 'package:dym_auth/src/widgets/step_scaffold.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Prénom et quartier (maquette 12). La photo arrive avec le stockage.
class ProfileStep extends StatefulWidget {
  const new({required this.viewModel, super.key});

  final AuthFlowViewModel viewModel;

  @override
  State<ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<ProfileStep> {
  late final TextEditingController _name = TextEditingController(
    text: widget.viewModel.firstName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final selected = vm.selectedZone;
    return StepScaffold(
      title: l10n.authProfileTitle,
      subtitle: Text(l10n.authProfileSubtitle),
      action: DymButton(
        label: l10n.authStart,
        loading: vm.isBusy,
        onPressed: vm.canSubmitProfile ? vm.submitProfile : null,
      ),
      children: [
        Text(l10n.authFirstNameLabel, style: t.title),
        const SizedBox(height: DymTokenSpace.s2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DymTextField(
                label: l10n.authFirstNameLabel,
                controller: _name,
                hint: 'Awa',
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.givenName],
                onChanged: vm.setFirstName,
                status: vm.authError == AuthError.firstNameInvalid
                    ? DymFieldStatus.error
                    : DymFieldStatus.none,
                message: l10n.authFirstNameInvalid,
              ),
            ),
            const SizedBox(width: DymTokenSpace.s3),
            Tooltip(
              message: l10n.comingSoon,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: c.card,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.textSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s1),
                  SizedBox(
                    width: 88,
                    child: Text(
                      l10n.authPhotoOptional,
                      textAlign: TextAlign.center,
                      style: t.label.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: DymTokenSpace.s5),
        Text(l10n.authZoneLabel, style: t.title),
        const SizedBox(height: DymTokenSpace.s2),
        if (vm.countries.length > 1) ...[
          Wrap(
            spacing: DymTokenSpace.s2,
            runSpacing: DymTokenSpace.s2,
            children: [
              for (final country in vm.countries)
                DymFilterChip(
                  label: country.name.resolve(locale),
                  selected: country.code == vm.countryCode,
                  onTap: () => vm.selectCountry(country.code),
                ),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s3),
        ],
        if (selected != null)
          Container(
            margin: const EdgeInsets.only(bottom: DymTokenSpace.s3),
            padding: const EdgeInsets.all(DymTokenSpace.s4),
            decoration: BoxDecoration(
              color: c.tintPlantainClair,
              borderRadius: BorderRadius.circular(DymTokenRadius.tile),
              border: Border.all(color: c.card, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: c.brand, size: 28),
                const SizedBox(width: DymTokenSpace.s3),
                Expanded(
                  child: Text(
                    [selected.name, ?vm.cityNameOf(selected)].join(', '),
                    style: t.title.copyWith(fontSize: 19),
                  ),
                ),
              ],
            ),
          ),
        if (vm.zones.isEmpty && vm.isBusy)
          Center(child: CircularProgressIndicator(color: c.brand))
        else
          Wrap(
            spacing: DymTokenSpace.s2,
            runSpacing: DymTokenSpace.s2,
            children: [
              for (final zone in vm.zones)
                DymFilterChip(
                  label: zone.name,
                  selected: zone.id == vm.zoneId,
                  onTap: () => vm.selectZone(zone.id),
                ),
            ],
          ),
        const SizedBox(height: DymTokenSpace.s3),
        Text(
          l10n.authZoneHint,
          style: t.label.copyWith(fontSize: 14, color: c.textSecondary),
        ),
        if (vm.authError != AuthError.firstNameInvalid)
          AuthErrorBanner(error: vm.authError),
        if (vm.authError == AuthError.offline ||
            vm.authError == AuthError.generic) ...[
          const SizedBox(height: DymTokenSpace.s2),
          DymButton(
            label: l10n.retry,
            variant: DymButtonVariant.secondary,
            compact: true,
            onPressed: vm.zones.isEmpty ? vm.loadZones : vm.submitProfile,
          ),
        ],
      ],
    );
  }
}
