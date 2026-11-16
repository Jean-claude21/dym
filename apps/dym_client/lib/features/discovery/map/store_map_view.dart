import 'dart:async';

import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/map/store_map_viewmodel.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_map/dym_map.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Carte des boutiques (spec 095) : épingles par origine, regroupées,
/// filtres « ouvertes » et catégorie, explorateur pays et ville.
class StoreMapView extends StackedView<StoreMapViewModel> {
  const new({
    required this.service,
    required this.config,
    required this.onOpenStore,
    super.key,
  });

  final DiscoveryService service;
  final CountryConfig? config;
  final ValueChanged<String> onOpenStore;

  @override
  StoreMapViewModel viewModelBuilder(BuildContext context) =>
      StoreMapViewModel(service: service, config: config);

  @override
  Widget builder(
    BuildContext context,
    StoreMapViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final locale = Localizations.localeOf(context).languageCode;
    final styles = {
      for (final o in StoreOrigin.values)
        o.name: DymPinStyle(
          icon: o.icon,
          background: o.background(c),
          foreground: o.foreground(c),
        ),
    };
    String styleOf(String? origin) =>
        originOf(origin)?.name ?? StoreOrigin.magasin.name;
    final selected = vm.selected;
    return Stack(
      children: [
        Positioned.fill(
          child: DymMap(
            initialCenter: vm.initialCenter,
            initialZoom: vm.initialZoom,
            pins: vm.pins(styleOf),
            pinStyles: styles,
            areas: vm.areas,
            semanticLabel: l10n.mapSemantic,
            onReady: (controls) => vm.controls = controls,
            onCameraIdle: (view) => unawaited(vm.onCameraIdle(view)),
            onPinTap: vm.select,
            onMapTap: (_) => vm.select(null),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: DymTokenSpace.s2,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: DymTokenSpace.s4),
            child: Row(
              children: [
                _Raised(
                  child: DymFilterChip(
                    label: l10n.mapExplore,
                    icon: Icons.travel_explore_rounded,
                    selected: false,
                    onTap: () => unawaited(_explore(context, vm)),
                  ),
                ),
                const SizedBox(width: DymTokenSpace.s2),
                _Raised(
                  child: DymFilterChip(
                    label: l10n.mapFilterOpen,
                    icon: Icons.schedule_rounded,
                    multiple: true,
                    selected: vm.openOnly,
                    onTap: () => unawaited(vm.toggleOpen()),
                  ),
                ),
                const SizedBox(width: DymTokenSpace.s2),
                _Raised(
                  child: DymFilterChip(
                    label: l10n.mapFilterAll,
                    selected: vm.categoryId == null,
                    onTap: () => unawaited(vm.setCategory(null)),
                  ),
                ),
                for (final cat in vm.categories) ...[
                  const SizedBox(width: DymTokenSpace.s2),
                  _Raised(
                    child: DymFilterChip(
                      label: cat.label.resolve(locale),
                      selected: vm.categoryId == cat.id,
                      onTap: () => unawaited(vm.setCategory(cat.id)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (vm.isBusy)
          const Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ),
        Positioned(
          left: DymTokenSpace.s4,
          right: DymTokenSpace.s4,
          bottom: DymTokenSpace.s4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _Raised(
                  child: Material(
                    color: c.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DymTokenRadius.button,
                      ),
                      side: BorderSide(color: c.hairline),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        DymTokenRadius.button,
                      ),
                      onTap: () => unawaited(vm.locateMe()),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DymTokenSpace.s3,
                          vertical: DymTokenSpace.s3,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.my_location_rounded, color: c.brand),
                            const SizedBox(width: DymTokenSpace.s2),
                            Text(l10n.mapMyPosition, style: t.label),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DymTokenSpace.s2),
              if (selected != null)
                _StoreCard(
                  store: selected,
                  vm: vm,
                  config: config,
                  onOpen: () => onOpenStore(selected.id),
                )
              else if (_notice(l10n, vm) case final notice?)
                _Notice(text: notice, failed: vm.failure != null),
            ],
          ),
        ),
      ],
    );
  }

  static String? _notice(DymLocalizations l10n, StoreMapViewModel vm) {
    if (vm.offline) return l10n.errorOffline;
    if (vm.failure != null) return l10n.errorLoadMessage;
    if (vm.positionUnavailable) return l10n.mapPositionUnavailable;
    if (vm.empty) return l10n.mapEmpty;
    return null;
  }
}

/// Ombre portée légère pour ce qui flotte sur la carte.
class _Raised extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(DymTokenRadius.chip),
      boxShadow: const [DymTokenShadows.floating],
    ),
    child: child,
  );
}

class _Notice extends StatelessWidget {
  const new({required this.text, required this.failed});

  final String text;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        border: Border.all(color: c.hairline),
        boxShadow: const [DymTokenShadows.floating],
      ),
      child: Padding(
        padding: const EdgeInsets.all(DymTokenSpace.s3),
        child: Row(
          children: [
            Icon(
              failed ? Icons.wifi_off_rounded : Icons.info_outline_rounded,
              color: failed ? c.piment : c.textSecondary,
            ),
            const SizedBox(width: DymTokenSpace.s2),
            Expanded(child: Text(text, style: t.body)),
          ],
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const new({
    required this.store,
    required this.vm,
    required this.config,
    required this.onOpen,
  });

  final PublicStore store;
  final StoreMapViewModel vm;
  final CountryConfig? config;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final km = ((store.deliveryRadiusM ?? 5000) / 1000).round();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        border: Border.all(color: c.hairline),
        boxShadow: const [DymTokenShadows.floating],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DymTokenSpace.s3,
          DymTokenSpace.s1,
          DymTokenSpace.s3,
          DymTokenSpace.s3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StoreRow(
              store: store,
              service: vm.service,
              config: config,
              onTap: onOpen,
            ),
            Row(
              children: [
                Icon(Icons.radar_rounded, size: 18, color: c.brand),
                const SizedBox(width: DymTokenSpace.s1),
                Text(
                  l10n.mapDeliversWithin('$km'),
                  style: t.label.copyWith(color: c.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: DymTokenSpace.s2),
            DymButton(
              label: l10n.mapSeeStore,
              icon: Icons.storefront_rounded,
              onPressed: onOpen,
            ),
          ],
        ),
      ),
    );
  }
}

/// Explorateur : villes du pays affiché, puis les autres pays ouverts.
Future<void> _explore(BuildContext context, StoreMapViewModel vm) async {
  final chosen = await showModalBottomSheet<(CountryConfig, City)>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ExploreSheet(vm: vm),
  );
  if (chosen == null) return;
  await vm.showCity(chosen.$1, chosen.$2);
}

class _ExploreSheet extends StatefulWidget {
  const new({required this.vm});

  final StoreMapViewModel vm;

  @override
  State<_ExploreSheet> createState() => _ExploreSheetState();
}

class _ExploreSheetState extends State<_ExploreSheet> {
  CountryConfig? _country;
  List<Country> _countries = const [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _country = widget.vm.config;
    unawaited(_loadCountries());
  }

  Future<void> _loadCountries() async {
    final result = await widget.vm.countries();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = result is Err;
      _countries = result.valueOrNull ?? const [];
    });
  }

  Future<void> _pickCountry(Country country) async {
    setState(() => _loading = true);
    final result = await widget.vm.configOf(country.code);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = result is Err;
      if (result.valueOrNull case final config?) _country = config;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.dym.text;
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final country = _country;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            DymTokenSpace.s4,
            0,
            DymTokenSpace.s4,
            DymTokenSpace.s4,
          ),
          children: [
            Text(l10n.mapExploreTitle, style: t.title),
            if (country != null) ...[
              const SizedBox(height: DymTokenSpace.s3),
              DymSectionHeader(title: country.country.name.resolve(locale)),
              DymMenuGroup(
                children: [
                  for (final city in country.cities)
                    DymMenuRow(
                      icon: Icons.location_city_rounded,
                      label: city.name,
                      onTap: () => Navigator.of(context).pop((country, city)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: DymTokenSpace.s4),
            DymSectionHeader(title: l10n.mapCountries),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(DymTokenSpace.s4),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_failed)
              Text(
                l10n.errorLoadMessage,
                style: t.body.copyWith(color: c.textSecondary),
              )
            else
              DymMenuGroup(
                children: [
                  for (final other in _countries)
                    DymMenuRow(
                      icon: Icons.public_rounded,
                      label: other.name.resolve(locale),
                      value: other.code == country?.country.code ? '✓' : null,
                      onTap: () => unawaited(_pickCountry(other)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
