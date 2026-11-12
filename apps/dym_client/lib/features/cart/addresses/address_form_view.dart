import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/cart/cart_viewmodels.dart';
import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Écran 36 : nouvelle adresse ou modification. Le quartier est choisi par
/// la position ou par une recherche (aucune liste affichée d'avance).
class AddressFormView extends StackedView<AddressFormViewModel> {
  const new({
    required this.service,
    required this.onDone,
    super.key,
    this.initial,
  });

  final CartService service;
  final CustomerAddress? initial;

  /// Fin de l'écran : `true` si l'adresse est enregistrée.
  final ValueChanged<bool> onDone;

  @override
  AddressFormViewModel viewModelBuilder(BuildContext context) =>
      AddressFormViewModel(service: service, initial: initial);

  @override
  void onViewModelReady(AddressFormViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    AddressFormViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final header = CartHeader(
      title: vm.editing ? l10n.addressEditTitle : l10n.addressNewTitle,
      onBack: () => onDone(false),
    );
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            header,
            Expanded(
              child: vm.ready
                  ? _Form(vm: vm)
                  : DiscoveryState(
                      failure: vm.isBusy ? null : vm.failure,
                      onRetry: vm.load,
                    ),
            ),
            if (vm.ready)
              DymContentWidth.form(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: DymButton(
                    label: l10n.addressSave,
                    icon: Icons.check_rounded,
                    loading: vm.isBusy,
                    onPressed: vm.canSave
                        ? () async {
                            if (await vm.save()) onDone(true);
                          }
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const new({required this.vm});

  final AddressFormViewModel vm;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final _label = TextEditingController(text: widget.vm.label);
  late final _landmark = TextEditingController(text: widget.vm.landmark);
  late final _phone = TextEditingController(text: widget.vm.phone);

  @override
  void dispose() {
    _label.dispose();
    _landmark.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = widget.vm;
    final children = <Widget>[
      Wrap(
        spacing: DymTokenSpace.s2,
        runSpacing: DymTokenSpace.s1,
        children: [
          for (final kind in AddressKind.values)
            DymFilterChip(
              label: addressTitle(l10n, kind, null),
              icon: addressIcon(kind),
              selected: vm.kind == kind,
              onTap: () => vm.setKind(kind),
            ),
        ],
      ),
      if (vm.kind == AddressKind.other) ...[
        const SizedBox(height: DymTokenSpace.s2),
        DymTextField(
          label: l10n.addressLabel,
          controller: _label,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (v) => vm.label = v,
        ),
      ],
      const SizedBox(height: DymTokenSpace.s4),
      Text(l10n.addressWhere, style: t.title),
      const SizedBox(height: DymTokenSpace.s2),
      DymPlacePicker(
        places: [
          for (final zone in vm.zones)
            DymPlace(id: zone.id, name: zone.name, detail: vm.cityNameOf(zone)),
        ],
        selectedId: vm.zoneId,
        onSelected: vm.selectZone,
        searchLabel: l10n.zoneSearchLabel,
        searchHint: l10n.zoneSearchHint,
        noResultLabel: l10n.zoneNoResult,
        onLocate: vm.locate,
        locateLabel: vm.locating ? l10n.zoneLocating : l10n.zoneUseLocation,
        locating: vm.locating,
        message: vm.location == AddressLocation.unavailable
            ? l10n.zoneLocationUnavailable
            : null,
      ),
      if (vm.hasPosition)
        Padding(
          padding: const EdgeInsets.only(top: DymTokenSpace.s2),
          child: Row(
            children: [
              Icon(Icons.my_location_rounded, size: 18, color: c.brand),
              const SizedBox(width: DymTokenSpace.s1),
              Flexible(
                child: Text(
                  l10n.addressPositionSaved,
                  style: t.label.copyWith(
                    color: c.brandDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      if (vm.showErrors && vm.zoneId == null)
        CartIssue(label: l10n.authZoneRequired),
      // Le libellé du champ suffit : pas de titre qui le répète.
      const SizedBox(height: DymTokenSpace.s4),
      DymTextField(
        label: l10n.addressLandmark,
        hint: l10n.addressLandmarkHint,
        controller: _landmark,
        maxLength: 200,
        minLines: 2,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        onChanged: vm.setLandmark,
        status: vm.showErrors && !vm.landmarkValid
            ? DymFieldStatus.error
            : DymFieldStatus.none,
        message: vm.showErrors && !vm.landmarkValid
            ? l10n.addressLandmarkInvalid
            : null,
      ),
      const SizedBox(height: DymTokenSpace.s4),
      DymTextField(
        label: l10n.addressPhone,
        controller: _phone,
        icon: Icons.phone_rounded,
        keyboardType: TextInputType.phone,
        autofillHints: const [AutofillHints.telephoneNumber],
        onChanged: vm.setPhone,
        status: vm.showErrors && !vm.phoneValid
            ? DymFieldStatus.error
            : DymFieldStatus.none,
        message: vm.showErrors && !vm.phoneValid
            ? l10n.addressPhoneInvalid
            : null,
      ),
      const SizedBox(height: DymTokenSpace.s4),
      DymSwitchTile(
        title: l10n.addressMakeDefault,
        value: vm.isDefault,
        onChanged: (v) => vm.setDefault(value: v),
      ),
      if (vm.saveFailure != null)
        CartIssue(
          label: vm.saveFailure is NetworkFailure
              ? l10n.errorOffline
              : l10n.errorGeneric,
        ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [for (final w in children) DymContentWidth.form(child: w)],
    );
  }
}
