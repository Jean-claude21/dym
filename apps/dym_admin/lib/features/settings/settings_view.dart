import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_texts.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_admin/features/settings/settings_viewmodel.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// « 10,5 » → 1 050 points de base (nul : invalide).
int? percentToBps(String text) {
  final m = RegExp(r'^(\d{1,3})(?:[.,](\d{1,2}))?$').firstMatch(text.trim());
  if (m == null) return null;
  final bps =
      int.parse(m.group(1)!) * 100 +
      int.parse((m.group(2) ?? '').padRight(2, '0'));
  return bps <= 10000 ? bps : null;
}

String bpsToPercent(int bps) {
  final whole = bps ~/ 100;
  final cents = bps % 100;
  if (cents == 0) return '$whole';
  final decimals = cents
      .toString()
      .padLeft(2, '0')
      .replaceAll(RegExp(r'0$'), '');
  return '$whole,$decimals';
}

/// Champ d'un formulaire de réglage (texte, ou liste si [options]).
class SettingField {
  const new(
    this.key,
    this.label, {
    this.initial,
    this.keyboard,
    this.required = true,
    this.options,
  });

  final String key;
  final String label;
  final String? initial;
  final TextInputType? keyboard;
  final bool required;

  /// Choix (valeur, libellé) ; une valeur nulle vaut « aucun ».
  final List<(String?, String)>? options;
}

/// Formulaire de réglage ; renvoie les valeurs saisies par clé.
Future<Map<String, String?>?> showSettingDialog(
  BuildContext context, {
  required String title,
  required List<SettingField> fields,
}) => showDialog<Map<String, String?>>(
  context: context,
  builder: (_) => _SettingDialog(title: title, fields: fields),
);

class _SettingDialog extends StatefulWidget {
  const new({required this.title, required this.fields});

  final String title;
  final List<SettingField> fields;

  @override
  State<_SettingDialog> createState() => _SettingDialogState();
}

class _SettingDialogState extends State<_SettingDialog> {
  late final Map<String, TextEditingController> _text = {
    for (final f in widget.fields)
      if (f.options == null) f.key: TextEditingController(text: f.initial),
  };
  late final Map<String, String?> _choice = {
    for (final f in widget.fields)
      if (f.options != null) f.key: f.initial,
  };

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid => widget.fields.every(
    (f) =>
        !f.required ||
        (f.options == null
            ? _text[f.key]!.text.trim().isNotEmpty
            : _choice[f.key] != null),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(_text.values.toList()),
      builder: (context, _) => AlertDialog(
        backgroundColor: context.dym.colors.card,
        title: Text(widget.title),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final f in widget.fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
                    child: f.options == null
                        ? DymTextField(
                            label: f.label,
                            controller: _text[f.key],
                            keyboardType: f.keyboard,
                          )
                        : DropdownButtonFormField<String?>(
                            initialValue: _choice[f.key],
                            isExpanded: true,
                            decoration: InputDecoration(labelText: f.label),
                            items: [
                              for (final (value, label) in f.options!)
                                DropdownMenuItem(
                                  value: value,
                                  child: Text(label),
                                ),
                            ],
                            onChanged: (v) =>
                                setState(() => _choice[f.key] = v),
                          ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          DymButton(
            label: l10n.adminSave,
            expanded: false,
            onPressed: _valid
                ? () => Navigator.pop(context, {
                    for (final e in _text.entries)
                      e.key: e.value.text.trim().isEmpty
                          ? null
                          : e.value.text.trim(),
                    ..._choice,
                  })
                : null,
          ),
        ],
      ),
    );
  }
}

/// Écran 56 : pays, villes et quartiers, paiement, commission, frais,
/// catégories.
class AdminSettingsView extends StackedView<AdminSettingsViewModel> {
  const new({required this.service, super.key, this.onSignOut});

  final AdminService service;
  final VoidCallback? onSignOut;

  @override
  AdminSettingsViewModel viewModelBuilder(BuildContext context) =>
      AdminSettingsViewModel(service: service);

  @override
  void onViewModelReady(AdminSettingsViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
    BuildContext context,
    AdminSettingsViewModel viewModel,
    Widget? child,
  ) {
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final locale = Localizations.localeOf(context).languageCode;
    final scoped =
        vm.tab != SettingsTab.countries &&
        vm.tab != SettingsTab.categories &&
        vm.tab != SettingsTab.flags;
    final signOut = onSignOut;
    return AdminPage(
      title: l10n.navSettings,
      subtitle: l10n.adminSettingsSubtitle,
      actions: [
        if (scoped && vm.countries.isNotEmpty)
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              initialValue: vm.country,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.adminEntityCountry),
              items: [
                for (final c in vm.countries)
                  DropdownMenuItem(
                    value: c.code,
                    child: Text(c.name.resolve(locale)),
                  ),
              ],
              onChanged: vm.selectCountry,
            ),
          ),
        if (signOut != null)
          DymButton(
            label: l10n.accountSignOut,
            icon: Icons.logout_rounded,
            variant: DymButtonVariant.secondary,
            expanded: false,
            onPressed: signOut,
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: DymTokenSpace.s2,
            runSpacing: DymTokenSpace.s2,
            children: [
              for (final t in SettingsTab.values)
                DymFilterChip(
                  label: switch (t) {
                    SettingsTab.countries => l10n.adminTabCountries,
                    SettingsTab.geography => l10n.adminTabGeography,
                    SettingsTab.payments => l10n.adminColPayment,
                    SettingsTab.commission => l10n.adminTabCommission,
                    SettingsTab.fees => l10n.adminTabFees,
                    SettingsTab.categories => l10n.adminTabCategories,
                    SettingsTab.flags => l10n.adminTabFlags,
                    SettingsTab.search => l10n.adminTabSearch,
                    SettingsTab.admins => l10n.adminTabAdmins,
                  },
                  selected: vm.tab == t,
                  onTap: () => vm.selectTab(t),
                ),
            ],
          ),
          const SizedBox(height: DymTokenSpace.s3),
          if (vm.actionFailure case final failure?)
            AdminAlert(adminFailureLabel(l10n, failure)),
          if (!vm.ready || vm.isBusy)
            AdminState(failure: vm.isBusy ? null : vm.failure, onRetry: vm.load)
          else
            switch (vm.tab) {
              SettingsTab.countries => _Countries(vm: vm),
              SettingsTab.geography => _Geography(vm: vm),
              SettingsTab.payments => _Payments(vm: vm),
              SettingsTab.commission => _Commission(vm: vm),
              SettingsTab.fees => _Fees(vm: vm),
              SettingsTab.categories => _Categories(vm: vm),
              SettingsTab.flags => _Flags(vm: vm),
              SettingsTab.search => _Search(vm: vm),
              SettingsTab.admins => _Admins(vm: vm),
            },
        ],
      ),
    );
  }
}

class _Countries extends StatelessWidget {
  const new({required this.vm});

  final AdminSettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    String missing(String m) => switch (m) {
      'zones' => l10n.adminTabGeography,
      'payment_methods' => l10n.adminEntityPaymentMethod,
      _ => l10n.adminTabFees,
    };
    final pending = [
      for (final country in vm.countries)
        if (!country.isActive) country,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pending.isNotEmpty)
          AdminCard(
            color: c.tintPlantainClair,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adminCountryChecklist,
                  style: t.title.copyWith(fontSize: 16),
                ),
                const SizedBox(height: DymTokenSpace.s2),
                for (final country in pending)
                  Wrap(
                    spacing: DymTokenSpace.s3,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        country.name.resolve(locale),
                        style: t.title.copyWith(fontSize: 16),
                      ),
                      for (final item in const [
                        'zones',
                        'payment_methods',
                        'delivery_fees',
                      ])
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              country.missing.contains(item)
                                  ? Icons.close_rounded
                                  : Icons.check_rounded,
                              color: country.missing.contains(item)
                                  ? c.pimentStrong
                                  : c.brand,
                            ),
                            Text(missing(item)),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        const SizedBox(height: DymTokenSpace.s3),
        AdminCard(
          child: Column(
            children: [
              for (final country in vm.countries)
                DymSwitchTile(
                  title: country.name.resolve(locale),
                  subtitle: [
                    country.currencyCode,
                    country.dialCode,
                    country.timezone,
                  ].join(' · '),
                  value: country.isActive,
                  onChanged: vm.acting
                      ? null
                      : (v) => vm.setCountryActive(country.code, active: v),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Geography extends StatelessWidget {
  const new({required this.vm});

  final AdminSettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    Future<void> editCity([AdminCity? current]) async {
      final values = await showSettingDialog(
        context,
        title: current == null ? l10n.adminAddCity : l10n.adminEditCity,
        fields: [
          SettingField('name', l10n.adminCityName, initial: current?.name),
          SettingField(
            'delivery_minutes',
            l10n.adminDeliveryMinutes,
            initial: '${current?.deliveryMinutes ?? 30}',
            keyboard: TextInputType.number,
          ),
        ],
      );
      if (values == null) return;
      await vm.saveCity({
        'id': ?current?.id,
        'name': values['name'],
        'delivery_minutes': int.tryParse(values['delivery_minutes'] ?? ''),
      });
    }

    Future<void> zone(AdminCity city, [AdminZone? current]) async {
      final values = await showSettingDialog(
        context,
        title: current == null ? l10n.adminAddZone : l10n.adminEditZone,
        fields: [
          SettingField('name', l10n.adminZoneName, initial: current?.name),
          SettingField(
            'latitude',
            l10n.adminLatitude,
            initial: current?.latitude?.toString(),
            keyboard: const TextInputType.numberWithOptions(decimal: true),
            required: false,
          ),
          SettingField(
            'longitude',
            l10n.adminLongitude,
            initial: current?.longitude?.toString(),
            keyboard: const TextInputType.numberWithOptions(decimal: true),
            required: false,
          ),
        ],
      );
      if (values == null) return;
      double? number(String? s) =>
          double.tryParse((s ?? '').replaceAll(',', '.'));
      final lat = number(values['latitude']);
      final lng = number(values['longitude']);
      await vm.saveZone({
        'id': ?current?.id,
        'city_id': city.id,
        'name': values['name'],
        if (lat != null && lng != null) ...{'latitude': lat, 'longitude': lng},
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.adminGeographyHelp,
          style: t.body.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: DymTokenSpace.s2),
        if (vm.cities.isEmpty) AdminEmpty(l10n.adminNoCities),
        for (final city in vm.cities)
          Padding(
            padding: const EdgeInsets.only(bottom: DymTokenSpace.s3),
            child: AdminCard(
              title: city.name,
              trailing: IconButton(
                tooltip: l10n.adminEditCity,
                onPressed: () => editCity(city),
                icon: const Icon(Icons.edit_rounded),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DymSwitchTile(
                    title: l10n.adminActive,
                    subtitle: l10n.adminDeliveryMinutesValue(
                      city.deliveryMinutes,
                    ),
                    value: city.isActive,
                    onChanged: vm.acting
                        ? null
                        : (v) => vm.saveCity({'id': city.id, 'is_active': v}),
                  ),
                  const Divider(),
                  for (final z in city.zones)
                    Row(
                      children: [
                        Expanded(
                          child: DymSwitchTile(
                            title: z.name,
                            subtitle: l10n.adminZoneStores(z.storeCount),
                            value: z.isActive,
                            onChanged: vm.acting
                                ? null
                                : (v) =>
                                      vm.saveZone({'id': z.id, 'is_active': v}),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.adminEditZone,
                          onPressed: () => zone(city, z),
                          icon: const Icon(Icons.edit_rounded),
                        ),
                      ],
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: vm.acting ? null : () => zone(city),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.adminAddZone),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: DymButton(
            label: l10n.adminAddCity,
            icon: Icons.add_location_alt_rounded,
            expanded: false,
            onPressed: vm.acting ? null : editCity,
          ),
        ),
      ],
    );
  }
}

class _Payments extends StatelessWidget {
  const new({required this.vm});

  final AdminSettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final settings = vm.payments;
    Future<void> add() async {
      final values = await showSettingDialog(
        context,
        title: l10n.adminAddPaymentMethod,
        fields: [
          SettingField(
            'provider_code',
            l10n.adminProvider,
            options: [
              for (final p
                  in settings?.providers ?? const <AdminPaymentProvider>[])
                if (p.isActive) (p.code, p.label.resolve(locale)),
            ],
          ),
          SettingField('operator_code', l10n.adminOperator, required: false),
          SettingField('label_fr', l10n.adminLabelFr),
          SettingField('label_en', l10n.adminLabelEn),
        ],
      );
      if (values == null) return;
      await vm.savePaymentMethod({
        'provider_code': values['provider_code'],
        'operator_code': values['operator_code'],
        'label': {'fr': values['label_fr'], 'en': values['label_en']},
        'is_active': true,
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminCard(
          child: Column(
            children: [
              if (settings == null || settings.methods.isEmpty)
                AdminEmpty(l10n.adminNoPaymentMethods),
              for (final m in settings?.methods ?? const <AdminPaymentMethod>[])
                DymSwitchTile(
                  title: m.label.resolve(locale),
                  subtitle: [m.providerCode, ?m.operatorCode].join(' · '),
                  value: m.isActive,
                  onChanged: vm.acting
                      ? null
                      : (v) =>
                            vm.savePaymentMethod({'id': m.id, 'is_active': v}),
                ),
            ],
          ),
        ),
        const SizedBox(height: DymTokenSpace.s3),
        Align(
          alignment: Alignment.centerLeft,
          child: DymButton(
            label: l10n.adminAddPaymentMethod,
            icon: Icons.add_card_rounded,
            expanded: false,
            onPressed: vm.acting || settings == null ? null : add,
          ),
        ),
      ],
    );
  }
}

class _Commission extends StatelessWidget {
  const new({required this.vm});

  final AdminSettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final pricing = vm.pricing;
    Future<void> edit() async {
      final values = await showSettingDialog(
        context,
        title: l10n.adminEditCommission,
        fields: [
          SettingField(
            'category',
            l10n.adminEntityCategory,
            required: false,
            options: [
              (null, l10n.adminWholeCountry),
              for (final c in vm.categories)
                if (c.parentId == null) (c.id, c.label.resolve(locale)),
            ],
          ),
          SettingField(
            'rate',
            l10n.adminRatePercent,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      );
      if (values == null) return;
      final bps = percentToBps(values['rate'] ?? '');
      if (bps == null) return;
      await vm.setCommission(bps, categoryId: values['category']);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pricing == null || pricing.commissions.isEmpty)
                AdminEmpty(l10n.adminNoCommission),
              for (final r in pricing?.commissions ?? const <AdminCommission>[])
                AdminField(
                  r.categoryLabel?.resolve(locale) ?? l10n.adminWholeCountry,
                  l10n.adminRateValue(bpsToPercent(r.rateBps)),
                ),
            ],
          ),
        ),
        const SizedBox(height: DymTokenSpace.s3),
        Align(
          alignment: Alignment.centerLeft,
          child: DymButton(
            label: l10n.adminEditCommission,
            icon: Icons.percent_rounded,
            expanded: false,
            onPressed: vm.acting ? null : edit,
          ),
        ),
      ],
    );
  }
}

class _Fees extends StatelessWidget {
  const new({required this.vm});

  final AdminSettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final pricing = vm.pricing;
    final currency = vm.currency;
    String money(int? minor) => minor == null || currency == null
        ? '—'
        : Money(minor, currency).format();
    Future<void> edit() async {
      if (currency == null) return;
      final values = await showSettingDialog(
        context,
        title: l10n.adminEditFees,
        fields: [
          SettingField(
            'city',
            l10n.adminEntityCity,
            required: false,
            options: [
              (null, l10n.adminWholeCountry),
              for (final c in vm.cities) (c.id, c.name),
            ],
          ),
          SettingField(
            'base',
            l10n.adminBaseFee(currency.symbol),
            keyboard: TextInputType.number,
          ),
          SettingField(
            'extra',
            l10n.adminExtraPickupFee(currency.symbol),
            keyboard: TextInputType.number,
          ),
          SettingField(
            'free',
            l10n.adminFreeThreshold(currency.symbol),
            keyboard: TextInputType.number,
            required: false,
          ),
        ],
      );
      if (values == null) return;
      final base = Money.parseMajor(values['base'] ?? '', currency);
      final extra = Money.parseMajor(values['extra'] ?? '', currency);
      if (base == null || extra == null) return;
      await vm.setDeliveryFee(
        baseFeeMinor: base,
        extraPickupFeeMinor: extra,
        freeThresholdMinor: values['free'] == null
            ? null
            : Money.parseMajor(values['free']!, currency),
        cityId: values['city'],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pricing == null || pricing.deliveryFees.isEmpty)
          AdminEmpty(l10n.adminNoFees),
        for (final f in pricing?.deliveryFees ?? const <AdminDeliveryFee>[])
          Padding(
            padding: const EdgeInsets.only(bottom: DymTokenSpace.s2),
            child: AdminCard(
              title: f.cityName ?? l10n.adminWholeCountry,
              child: Column(
                children: [
                  AdminField(l10n.adminBaseFee(''), money(f.baseFeeMinor)),
                  AdminField(
                    l10n.adminExtraPickupFee(''),
                    money(f.extraPickupFeeMinor),
                  ),
                  AdminField(
                    l10n.adminFreeThreshold(''),
                    money(f.freeThresholdMinor),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: DymTokenSpace.s2),
        Align(
          alignment: Alignment.centerLeft,
          child: DymButton(
            label: l10n.adminEditFees,
            icon: Icons.local_shipping_rounded,
            expanded: false,
            onPressed: vm.acting || currency == null ? null : edit,
          ),
        ),
      ],
    );
  }
}

class _Categories extends StatelessWidget {
  const new({required this.vm});

  final AdminSettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    Future<void> edit([AdminCategory? current]) async {
      final values = await showSettingDialog(
        context,
        title: current == null ? l10n.adminAddCategory : l10n.adminEditCategory,
        fields: [
          if (current == null)
            SettingField(
              'parent',
              l10n.adminParentCategory,
              required: false,
              options: [
                (null, l10n.adminNoParent),
                for (final c in vm.categories)
                  if (c.parentId == null) (c.id, c.label.resolve(locale)),
              ],
            ),
          SettingField(
            'fr',
            l10n.adminLabelFr,
            initial: current?.label.resolve('fr'),
          ),
          SettingField(
            'en',
            l10n.adminLabelEn,
            initial: current?.label.resolve('en'),
          ),
        ],
      );
      if (values == null) return;
      await vm.saveCategory({
        'id': ?current?.id,
        'parent_id': ?values['parent'],
        'label': {'fr': values['fr'], 'en': values['en']},
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminCard(
          child: Column(
            children: [
              for (final cat in vm.categories)
                Padding(
                  padding: EdgeInsets.only(
                    left: cat.parentId == null ? 0 : DymTokenSpace.s5,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DymSwitchTile(
                          title: cat.label.resolve(locale),
                          subtitle: cat.slug,
                          value: cat.isActive,
                          onChanged: vm.acting
                              ? null
                              : (v) => vm.saveCategory({
                                  'id': cat.id,
                                  'is_active': v,
                                }),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.adminEditCategory,
                        onPressed: () => edit(cat),
                        icon: const Icon(Icons.edit_rounded),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: DymTokenSpace.s3),
        Align(
          alignment: Alignment.centerLeft,
          child: DymButton(
            label: l10n.adminAddCategory,
            icon: Icons.add_rounded,
            expanded: false,
            onPressed: vm.acting ? null : edit,
          ),
        ),
      ],
    );
  }
}

/// Fonctionnalités (A-CFG-07) : les fonctions de la phase 4 restent coupées
/// tant que l'équipe ne les ouvre pas.
class _Flags extends StatelessWidget {
  const new({required this.vm});

  final AdminSettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    String scope(String? code) {
      if (code == null) return l10n.adminFlagEverywhere;
      final country = vm.countries.where((x) => x.code == code).firstOrNull;
      return country?.name.resolve(locale) ?? code;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.adminFlagsHelp,
          style: t.body.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: DymTokenSpace.s2),
        AdminCard(
          child: Column(
            children: [
              if (vm.flags.isEmpty) AdminEmpty(l10n.adminNoData),
              for (final f in vm.flags)
                DymSwitchTile(
                  title: f.key,
                  subtitle: [scope(f.countryCode), f.description].join(' · '),
                  value: f.isEnabled,
                  onChanged: vm.acting
                      ? null
                      : (v) => vm.setFlag(f, enabled: v),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Recherche (spec 028) : poids du classement et noms locaux du pays choisi.
class _Search extends StatelessWidget {
  const new({required this.vm});

  final AdminSettingsViewModel vm;

  static String weightLabel(DymLocalizations l10n, String key) => switch (key) {
    'weight_text' => l10n.adminWeightText,
    'weight_same_store' => l10n.adminWeightSameStore,
    'weight_open' => l10n.adminWeightOpen,
    'weight_rating' => l10n.adminWeightRating,
    'weight_price' => l10n.adminWeightPrice,
    _ => l10n.adminWeightSameZone,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final rule = vm.search.ruleFor(vm.country);
    final synonyms = vm.search.synonyms
        .where((s) => s.countryCode == vm.country || s.countryCode == null)
        .toList();

    Future<void> editWeights() async {
      final values = await showSettingDialog(
        context,
        title: l10n.adminEditRanking,
        fields: [
          for (final key in RankingRule.keys)
            SettingField(
              key,
              weightLabel(l10n, key),
              initial: '${rule.weights[key] ?? 0}',
              keyboard: TextInputType.number,
            ),
        ],
      );
      if (values == null) return;
      final weights = <String, int>{};
      for (final key in RankingRule.keys) {
        final v = int.tryParse(values[key]?.trim() ?? '');
        if (v == null || v < 0 || v > 100) return;
        weights[key] = v;
      }
      await vm.setRanking(weights);
    }

    Future<void> addSynonym() async {
      final values = await showSettingDialog(
        context,
        title: l10n.adminAddSynonym,
        fields: [
          SettingField('term', l10n.adminSynonymTerm),
          SettingField('synonyms', l10n.adminSynonymList),
        ],
      );
      if (values == null) return;
      final list = (values['synonyms'] ?? '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final term = values['term']?.trim() ?? '';
      if (term.isEmpty || list.isEmpty) return;
      await vm.setSynonym(term, list);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.adminRankingHelp,
          style: t.body.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: DymTokenSpace.s2),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final key in RankingRule.keys)
                AdminField(weightLabel(l10n, key), '${rule.weights[key] ?? 0}'),
            ],
          ),
        ),
        const SizedBox(height: DymTokenSpace.s3),
        Align(
          alignment: Alignment.centerLeft,
          child: DymButton(
            label: l10n.adminEditRanking,
            icon: Icons.tune_rounded,
            expanded: false,
            onPressed: vm.acting ? null : editWeights,
          ),
        ),
        const SizedBox(height: DymTokenSpace.s5),
        Text(l10n.adminSynonymsTitle, style: t.title),
        const SizedBox(height: DymTokenSpace.s2),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (synonyms.isEmpty) AdminEmpty(l10n.adminNoData),
              for (final s in synonyms)
                ListTile(
                  title: Text(s.term),
                  subtitle: Text(s.synonyms.join(', ')),
                  trailing: IconButton(
                    tooltip: l10n.adminRemoveSynonym(s.term),
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: vm.acting
                        ? null
                        : () => vm.setSynonym(s.term, const []),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: DymTokenSpace.s3),
        Align(
          alignment: Alignment.centerLeft,
          child: DymButton(
            label: l10n.adminAddSynonym,
            icon: Icons.add_rounded,
            variant: DymButtonVariant.secondary,
            expanded: false,
            onPressed: vm.acting ? null : addSynonym,
          ),
        ),
      ],
    );
  }
}

/// Admins : par défaut (ADMIN_EMAILS), actifs et invitations en attente.
class _Admins extends StatefulWidget {
  const new({required this.vm});

  final AdminSettingsViewModel vm;

  @override
  State<_Admins> createState() => _AdminsState();
}

class _AdminsState extends State<_Admins> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final email = _email.text.trim();
    if (!email.contains('@')) return;
    if (await widget.vm.inviteAdmin(email)) _email.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = widget.vm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.adminAdminsHelp,
          style: t.body.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: DymTokenSpace.s2),
        AdminCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: DymTextField(
                  label: l10n.authEmailLabel,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  onSubmitted: (_) => _invite(),
                ),
              ),
              const SizedBox(width: DymTokenSpace.s3),
              DymButton(
                label: l10n.adminAdminsInvite,
                icon: Icons.person_add_alt_1_rounded,
                expanded: false,
                loading: vm.acting,
                onPressed: _invite,
              ),
            ],
          ),
        ),
        const SizedBox(height: DymTokenSpace.s3),
        AdminCard(
          child: Column(
            children: [
              if (vm.admins.isEmpty) AdminEmpty(l10n.adminNoData),
              for (final a in vm.admins)
                ListTile(
                  leading: Icon(
                    a.isActive
                        ? Icons.verified_user_rounded
                        : Icons.schedule_send_rounded,
                    color: a.isActive ? c.brandDeep : c.textSecondary,
                  ),
                  title: Text(a.email),
                  subtitle: Text(
                    [
                      if (a.firstName != null) a.firstName!,
                      if (a.isDefault) l10n.adminAdminsDefault,
                      if (a.isActive)
                        l10n.adminAdminsActive
                      else
                        l10n.adminAdminsPending,
                    ].join(' · '),
                  ),
                  trailing: a.isDefault || a.isMe
                      ? null
                      : IconButton(
                          tooltip: l10n.adminAdminsRemove,
                          icon: const Icon(Icons.person_remove_rounded),
                          onPressed: vm.acting ? null : () => vm.removeAdmin(a),
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
