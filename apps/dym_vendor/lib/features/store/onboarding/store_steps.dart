import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/store/onboarding/store_onboarding_viewmodel.dart';
import 'package:dym_vendor/features/store/store_format.dart';
import 'package:dym_vendor/features/store/widgets/store_widgets.dart';
import 'package:flutter/material.dart';

/// Titre et sous-titre d'une étape.
(String, String) storeStepTexts(
  DymLocalizations l10n,
  StoreStep step,
) => switch (step) {
  StoreStep.name => (l10n.storeNameTitle, l10n.storeNameSubtitle),
  StoreStep.origin => (l10n.storeOriginTitle, l10n.storeOriginSubtitle),
  StoreStep.address => (l10n.storeAddressTitle, l10n.storeAddressSubtitle),
  StoreStep.category => (l10n.storeCategoryTitle, l10n.storeCategorySubtitle),
  StoreStep.delivery => (l10n.storeDeliveryTitle, l10n.storeDeliverySubtitle),
  StoreStep.payment => (l10n.storePaymentTitle, l10n.storePaymentSubtitle),
  StoreStep.hours => (l10n.storeHoursTitle, l10n.storeHoursSubtitle),
};

/// Contenu d'une étape.
List<Widget> storeStepBody(BuildContext context, StoreOnboardingViewModel vm) =>
    switch (vm.step) {
      StoreStep.name => [_NameStep(vm: vm)],
      StoreStep.origin => [_OriginStep(vm: vm)],
      StoreStep.address => [_AddressStep(vm: vm)],
      StoreStep.category => [_CategoryStep(vm: vm)],
      StoreStep.delivery => [_DeliveryStep(vm: vm)],
      StoreStep.payment => [_PaymentStep(vm: vm)],
      StoreStep.hours => [_HoursStep(vm: vm)],
    };

const _gap = SizedBox(height: DymTokenSpace.s4);

// ---------------------------------------------------------- 1. nom

class _NameStep extends StatelessWidget {
  const new({required this.vm});

  final StoreOnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final showInvalid = vm.name.isNotEmpty && !vm.nameValid;
    final name = vm.name.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StoreTextField(
          label: l10n.storeNameLabel,
          initialValue: vm.name,
          onChanged: vm.setName,
          maxLength: StoreOnboardingViewModel.nameMax,
          status: showInvalid ? DymFieldStatus.error : DymFieldStatus.none,
          message: showInvalid ? l10n.storeNameInvalid : null,
        ),
        _gap,
        StoreSection(
          title: l10n.storeDescriptionLabel,
          children: [
            StoreTextField(
              label: l10n.storeDescriptionLabel,
              hint: l10n.storeDescriptionHint,
              initialValue: vm.description,
              onChanged: vm.setDescription,
              maxLength: StoreOnboardingViewModel.descriptionMax,
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: DymTokenSpace.s2),
            Text(
              l10n.storeCharCount(
                vm.description.length,
                StoreOnboardingViewModel.descriptionMax,
              ),
              textAlign: TextAlign.end,
              style: t.label.copyWith(color: c.textSecondary, fontSize: 14),
            ),
          ],
        ),
        if (name.isNotEmpty) ...[
          _gap,
          StoreSection(
            title: l10n.storePreviewTitle,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: c.tintPeche,
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: t.display.copyWith(
                        fontSize: 30,
                        color: c.originMaisonFg,
                      ),
                    ),
                  ),
                  const SizedBox(width: DymTokenSpace.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: t.title.copyWith(fontSize: 22)),
                        if (vm.zoneName != null)
                          Text(
                            l10n.storePreviewPlace(vm.zoneName!),
                            style: t.body.copyWith(color: c.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------- 2. origine

class _OriginStep extends StatelessWidget {
  const new({required this.vm});

  final StoreOnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final origins = vm.config?.storeOrigins ?? const <StoreOriginInfo>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final origin in origins) ...[
          DymSelectableCard(
            image:
                DymIllustrations.origin(origin.code) ??
                DymIllustrations.storeOpened,
            title: origin.label.resolve(locale),
            description: origin.description?.resolve(locale) ?? '',
            selected: vm.origin == origin.code,
            onTap: () => vm.selectOrigin(origin.code),
            footer: StorePrivacyNote(text: l10n.storeOriginPrivacy),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------- 3. adresse

class _AddressStep extends StatelessWidget {
  const new({required this.vm});

  final StoreOnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final zones = vm.config?.zones ?? const <Zone>[];
    return StoreSection(
      children: [
        StoreFieldLabel(l10n.storeZoneLabel, suffix: l10n.storeZoneVisible),
        Wrap(
          runSpacing: DymTokenSpace.s2,
          spacing: DymTokenSpace.s2,
          children: [
            for (final zone in zones)
              DymFilterChip(
                label: zone.name,
                selected: vm.zoneId == zone.id,
                onTap: () => vm.selectZone(zone.id),
              ),
          ],
        ),
        _gap,
        StoreTextField(
          label: l10n.storeAddressLabel,
          hint: l10n.storeAddressHint,
          initialValue: vm.address,
          onChanged: vm.setAddress,
          maxLength: StoreOnboardingViewModel.addressMax,
        ),
        _gap,
        StoreTextField(
          label: l10n.storeLandmarkLabel,
          hint: l10n.storeLandmarkHint,
          initialValue: vm.landmark,
          onChanged: vm.setLandmark,
          maxLength: StoreOnboardingViewModel.addressMax,
        ),
        _gap,
        StorePrivacyNote(text: l10n.storeAddressPrivacy),
      ],
    );
  }
}

// ---------------------------------------------------------- 4. rayon

class _CategoryStep extends StatelessWidget {
  const new({required this.vm});

  final StoreOnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final categories = vm.config?.topCategories ?? const <Category>[];
    return LayoutBuilder(
      builder: (context, box) {
        const spacing = DymTokenSpace.s3;
        final columns = DymLayout.columns(
          box.maxWidth,
          minTileWidth: 150,
          spacing: spacing,
          min: 2,
          max: 4,
        );
        final width = (box.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final category in categories)
              SizedBox(
                width: width,
                child: _CategoryTile(
                  label: category.label.resolve(locale),
                  image: DymIllustrations.aisle(category.icon),
                  selected: vm.categoryId == category.id,
                  onTap: () => vm.selectCategory(category.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const new({
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final ImageProvider? image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final picture = image;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: DymMotion.of(context, DymMotion.fast),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(DymTokenRadius.tile),
          border: Border.all(
            color: selected ? c.brand : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: const [DymTokenShadows.card],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DymTokenRadius.tile),
            child: Padding(
              padding: const EdgeInsets.all(DymTokenSpace.s2),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.tintVertTendre,
                            borderRadius: BorderRadius.circular(
                              DymTokenRadius.button,
                            ),
                          ),
                          child: picture == null
                              ? Icon(
                                  Icons.storefront_rounded,
                                  size: 48,
                                  color: c.brandDeep,
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Image(
                                    image: picture,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                        ),
                        if (selected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: c.brand,
                              child: Icon(
                                Icons.check_rounded,
                                color: c.onBrand,
                                size: 22,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DymTokenSpace.s2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.dym.text.title.copyWith(fontSize: 16),
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

// ---------------------------------------------------------- 5. livraison

class _DeliveryStep extends StatelessWidget {
  const new({required this.vm});

  final StoreOnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final zones = vm.cityZones;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StoreSection(
          title: l10n.storeDeliveryZonesTitle,
          trailing: TextButton(
            onPressed: vm.selectAllDeliveryZones,
            style: TextButton.styleFrom(
              minimumSize: const Size(DymTokenSize.touchMin, 48),
            ),
            child: Text(l10n.storeSelectAll),
          ),
          children: [
            Wrap(
              runSpacing: DymTokenSpace.s2,
              spacing: DymTokenSpace.s2,
              children: [
                for (final zone in zones)
                  DymFilterChip(
                    label: zone.name,
                    multiple: true,
                    selected: vm.deliveryZoneIds.contains(zone.id),
                    onTap: () => vm.toggleDeliveryZone(zone.id),
                  ),
              ],
            ),
          ],
        ),
        _gap,
        StoreSection(
          title: l10n.storePrepTitle,
          children: [
            Wrap(
              runSpacing: DymTokenSpace.s2,
              spacing: DymTokenSpace.s2,
              children: [
                for (final minutes in vm.prepChoices)
                  DymFilterChip(
                    label: prepLabel(l10n, minutes),
                    selected: vm.prepTimeMinutes == minutes,
                    onTap: () => vm.setPrepTime(minutes),
                  ),
              ],
            ),
          ],
        ),
        _gap,
        DymSwitchTile(
          title: l10n.storePickupTitle,
          subtitle: l10n.storePickupSubtitle,
          value: vm.offersPickup,
          onChanged: (value) => vm.setPickup(value: value),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------- 6. paiement

class _PaymentStep extends StatelessWidget {
  const new({required this.vm});

  final StoreOnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final soon = vm.paymentOptions.any((o) => !o.isAvailable);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in vm.paymentOptions) ...[
          _PaymentCard(
            option: option,
            selected: vm.paymentMethodIds.contains(option.id),
            onTap: () => vm.togglePaymentMethod(option),
          ),
          const SizedBox(height: DymTokenSpace.s3),
        ],
        if (soon)
          Text(
            l10n.storePaymentMomoNote,
            textAlign: TextAlign.center,
            style: context.dym.text.label.copyWith(
              color: c.textSecondary,
              fontSize: 14,
            ),
          ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const new({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PaymentOption option;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (option.kind) {
    'cash' => Icons.payments_rounded,
    'mobile_money' => Icons.phone_android_rounded,
    'card' => Icons.credit_card_rounded,
    _ => Icons.language_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final available = option.isAvailable;
    final title = option.label.resolve(locale);
    final subtitle = !available
        ? l10n.storePaymentSoonHint
        : option.kind == 'cash'
        ? l10n.storePaymentCashHint
        : null;
    final ink = available ? c.textPrimary : c.textSecondary;
    return Semantics(
      button: available,
      selected: selected,
      enabled: available,
      label: [title, ?subtitle].join('. '),
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: DymMotion.of(context, DymMotion.fast),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(DymTokenRadius.card),
          border: Border.all(
            color: selected ? c.brand : c.textSecondary.withValues(alpha: 0.15),
            width: selected ? 2.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: available ? onTap : null,
            borderRadius: BorderRadius.circular(DymTokenRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(DymTokenSpace.s3),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: available
                          ? c.tintVertTendre
                          : c.textSecondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                    ),
                    child: Icon(
                      _icon,
                      size: 34,
                      color: available ? c.brandDeep : c.textSecondary,
                    ),
                  ),
                  const SizedBox(width: DymTokenSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: DymTokenSpace.s2,
                          runSpacing: DymTokenSpace.s1,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              title,
                              style: t.title.copyWith(fontSize: 19, color: ink),
                            ),
                            if (!available)
                              DymPromoBadge(
                                label: l10n.storePaymentSoon,
                                tone: DymPromoTone.info,
                              ),
                          ],
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: t.body.copyWith(color: c.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DymTokenSpace.s2),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 32,
                    color: selected
                        ? c.brand
                        : c.textSecondary.withValues(alpha: 0.6),
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

// ---------------------------------------------------------- 7. horaires

class _HoursStep extends StatelessWidget {
  const new({required this.vm});

  final StoreOnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final invalid = vm.hours.any((h) => !h.isValid);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StoreSection(
          children: [
            for (final day in vm.hours) ...[
              if (day.weekday > 1)
                Divider(
                  height: DymTokenSpace.s3,
                  color: c.textSecondary.withValues(alpha: 0.12),
                ),
              _DayRow(vm: vm, day: day),
            ],
          ],
        ),
        if (invalid) ...[
          const SizedBox(height: DymTokenSpace.s3),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(Icons.error_rounded, color: c.pimentStrong),
                const SizedBox(width: DymTokenSpace.s2),
                Expanded(
                  child: Text(
                    l10n.storeHoursInvalid,
                    style: context.dym.text.label.copyWith(
                      color: c.pimentStrong,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: DymTokenSpace.s2),
        Center(
          child: TextButton(
            onPressed: vm.applyFirstDayToAll,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(
              l10n.storeHoursSameEveryDay,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const new({required this.vm, required this.day});

  final StoreOnboardingViewModel vm;
  final DayHours day;

  Future<void> _pick(BuildContext context, {required bool opens}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: parseTime(opens ? day.opensAt : day.closesAt),
    );
    if (picked == null) return;
    final value = formatTime(picked);
    opens
        ? vm.setOpensAt(day.weekday, value)
        : vm.setClosesAt(day.weekday, value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final name = weekdayName(l10n, day.weekday);
    final times = day.open
        ? Wrap(
            spacing: DymTokenSpace.s2,
            runSpacing: DymTokenSpace.s2,
            children: [
              _TimeButton(
                label: l10n.storeHoursOpens,
                value: displayTime(context, day.opensAt),
                error: !day.isValid,
                onTap: () => _pick(context, opens: true),
              ),
              _TimeButton(
                label: l10n.storeHoursCloses,
                value: displayTime(context, day.closesAt),
                error: !day.isValid,
                onTap: () => _pick(context, opens: false),
              ),
            ],
          )
        // Même largeur que les heures : les interrupteurs restent alignés.
        : ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 2 * 88 + 8),
            child: Text(
              l10n.storeHoursClosed,
              style: t.body.copyWith(color: c.textSecondary),
            ),
          );
    final toggle = Semantics(
      label: name,
      child: Switch(
        value: day.open,
        activeTrackColor: c.brand,
        onChanged: (open) => vm.setDayOpen(day.weekday, open: open),
      ),
    );
    final title = Text(name, style: t.title.copyWith(fontSize: 18));
    return LayoutBuilder(
      builder: (context, box) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        // Ligne unique si la place suffit, sinon heures sous le jour.
        // Jour (~90) + interrupteur (60) + heures (2 × 88 + 8) + marges.
        if (box.maxWidth / scale >= 344) {
          return Row(
            children: [
              Expanded(child: title),
              toggle,
              const SizedBox(width: DymTokenSpace.s3),
              times,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: title),
                toggle,
              ],
            ),
            times,
          ],
        );
      },
    );
  }
}

class _TimeButton extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.error,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    return Semantics(
      button: true,
      label: '$label $value',
      excludeSemantics: true,
      child: Material(
        color: error ? c.tintPimentClair : c.background,
        borderRadius: BorderRadius.circular(DymTokenRadius.button),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DymTokenRadius.button),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 88),
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DymTokenSpace.s3,
                ),
                child: Text(
                  value,
                  style: context.dym.text.title.copyWith(
                    fontSize: 17,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: error ? c.pimentStrong : c.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
