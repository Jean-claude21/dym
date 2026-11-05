import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/discovery_viewmodels.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

/// Écran 29 : recherche de produits et de boutiques.
class SearchView extends StackedView<SearchViewModel> {
  const new({
    required this.service,
    required this.onBack,
    required this.onOpenProduct,
    required this.onOpenStore,
    super.key,
    this.debounce = const Duration(milliseconds: 350),
    this.initialText = '',
  });

  final DiscoveryService service;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenProduct;
  final ValueChanged<String> onOpenStore;
  final Duration debounce;

  /// Recherche lancée à l'ouverture (texte d'un rayon, d'une suggestion).
  final String initialText;

  @override
  SearchViewModel viewModelBuilder(BuildContext context) =>
      SearchViewModel(service: service, debounce: debounce);

  @override
  void onViewModelReady(SearchViewModel viewModel) =>
      viewModel.init(initialText: initialText);

  @override
  Widget builder(
    BuildContext context,
    SearchViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final results = vm.results;
    final filtersLabel = vm.activeFilters == 0
        ? l10n.searchFilters
        : l10n.searchFiltersActive(vm.activeFilters);
    final Widget body;
    if (vm.tooShort) {
      body = _Message(text: l10n.searchPrompt);
    } else if (vm.isBusy && results == null) {
      body = const DiscoveryState(failure: null, onRetry: _noop);
    } else if (vm.failure != null) {
      body = DiscoveryState(failure: vm.failure, onRetry: vm.submit);
    } else if (results == null || results.isEmpty) {
      body = vm.isBusy
          ? const DiscoveryState(failure: null, onRetry: _noop)
          : _Message(text: l10n.searchEmpty);
    } else {
      body = _Results(
        viewModel: vm,
        onOpenProduct: onOpenProduct,
        onOpenStore: onOpenStore,
      );
    }
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(4, 8, DymLayout.gutter(context), 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.authBack,
                    onPressed: onBack,
                    icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                  ),
                  Expanded(
                    child: _SearchField(viewModel: vm, initial: initialText),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: DymLayout.gutter(context),
                vertical: DymTokenSpace.s2,
              ),
              child: Wrap(
                spacing: DymTokenSpace.s2,
                runSpacing: DymTokenSpace.s1,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final (tab, label) in [
                    (SearchTab.all, l10n.searchTabAll),
                    (SearchTab.products, l10n.searchTabProducts),
                    (SearchTab.stores, l10n.searchTabStores),
                  ])
                    DymFilterChip(
                      label: label,
                      selected: vm.tab == tab,
                      onTap: () => vm.selectTab(tab),
                    ),
                  Semantics(
                    button: true,
                    label: filtersLabel,
                    excludeSemantics: true,
                    child: ActionChip(
                      avatar: Icon(Icons.tune_rounded, color: c.brandDeep),
                      label: Text(
                        vm.activeFilters == 0
                            ? l10n.searchFilters
                            : '${l10n.searchFilters} · ${vm.activeFilters}',
                      ),
                      onPressed: () async {
                        final applied = await showFiltersSheet(
                          context,
                          config: vm.config,
                          current: vm.filters,
                        );
                        if (applied != null) await vm.applyFilters(applied);
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (results != null && !vm.tooShort)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: DymLayout.gutter(context),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      '${l10n.searchResultCount(results.total)} · '
                      '${_sortLabel(l10n, vm.filters.sort)}',
                      style: t.label.copyWith(color: c.textSecondary),
                    ),
                  ),
                ),
              ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

void _noop() {}

String _sortLabel(DymLocalizations l10n, SearchSort sort) => switch (sort) {
  SearchSort.relevance => l10n.sortRelevance,
  SearchSort.priceAsc => l10n.sortPriceAsc,
  SearchSort.priceDesc => l10n.sortPriceDesc,
};

class _Message extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DymTokenSpace.s5),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.dym.text.body.copyWith(
          color: context.dym.colors.textSecondary,
        ),
      ),
    ),
  );
}

class _SearchField extends StatefulWidget {
  const new({required this.viewModel, this.initial = ''});

  final SearchViewModel viewModel;
  final String initial;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return TextField(
      controller: _controller,
      autofocus: widget.initial.isEmpty,
      textInputAction: TextInputAction.search,
      onChanged: widget.viewModel.setText,
      onSubmitted: (_) => widget.viewModel.submit(),
      style: context.dym.text.body.copyWith(fontSize: 18),
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        filled: true,
        fillColor: c.card,
        prefixIcon: Icon(Icons.search_rounded, color: c.textSecondary),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: l10n.searchClear,
                onPressed: () {
                  _controller.clear();
                  widget.viewModel.setText('');
                  setState(() {});
                },
                icon: const Icon(Icons.cancel_rounded),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DymTokenRadius.chip),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const new({
    required this.viewModel,
    required this.onOpenProduct,
    required this.onOpenStore,
  });

  final SearchViewModel viewModel;
  final ValueChanged<String> onOpenProduct;
  final ValueChanged<String> onOpenStore;

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final results = vm.results!;
    final showProducts = vm.tab != SearchTab.stores;
    final showStores = vm.tab != SearchTab.products;
    return LayoutBuilder(
      builder: (context, box) {
        final inset = DymLayout.sideInset(
          box.maxWidth,
          gutter: DymLayout.gutter(context),
          maxWidth: DymTokenLayout.formMax,
        );
        final products = showProducts
            ? results.products
            : const <CatalogItem>[];
        final stores = showStores ? results.stores : const <PublicStore>[];
        return ListView(
          padding: EdgeInsets.fromLTRB(inset, 8, inset, 24),
          children: [
            for (final (i, item) in products.indexed) ...[
              // Les boutiques s'insèrent après le premier produit (écran 29).
              if (i == 1)
                for (final store in stores) ...[
                  _StoreResult(
                    store: store,
                    viewModel: vm,
                    onTap: () => onOpenStore(store.id),
                  ),
                  const SizedBox(height: DymTokenSpace.s3),
                ],
              _ProductResult(
                item: item,
                viewModel: vm,
                onTap: () => onOpenProduct(item.id),
              ),
              const SizedBox(height: DymTokenSpace.s3),
            ],
            if (products.length <= 1)
              for (final store in stores) ...[
                _StoreResult(
                  store: store,
                  viewModel: vm,
                  onTap: () => onOpenStore(store.id),
                ),
                const SizedBox(height: DymTokenSpace.s3),
              ],
            if (showProducts && vm.hasMore)
              DymButton(
                label: l10n.searchLoadMore,
                variant: DymButtonVariant.secondary,
                loading: vm.loadingMore,
                onPressed: vm.loadMore,
              ),
          ],
        );
      },
    );
  }
}

class _ProductResult extends StatelessWidget {
  const new({required this.item, required this.viewModel, required this.onTap});

  final CatalogItem item;
  final SearchViewModel viewModel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final config = viewModel.config;
    final price = moneyOf(config, item.displayPriceMinor);
    final unit = item.unitLabel?.resolve(locale);
    final origin = originOf(item.store.origin);
    final priceText = price == null
        ? ''
        : item.variantCount > 1
        ? l10n.productFrom(price.format())
        : price.format();
    return Opacity(
      opacity: item.available ? 1 : 0.6,
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(DymTokenRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(DymTokenSpace.s2),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                  child: SizedBox.square(
                    dimension: 96,
                    child: Image(
                      image: item.photoKey == null
                          ? storeFallback(item.store.origin)
                          : viewModel.service.photo(item.photoKey!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: DymTokenSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: t.title.copyWith(fontSize: 19)),
                      Wrap(
                        spacing: DymTokenSpace.s2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(item.store.name, style: t.body),
                          if (origin != null)
                            DymOriginBadge(
                              origin: origin,
                              label: originLabel(
                                config,
                                item.store.origin,
                                locale,
                              ),
                              dense: true,
                            ),
                        ],
                      ),
                      if (!item.available)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: DymPromoBadge(label: l10n.productOutOfStock),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        unit == null ? priceText : '$unit · $priceText',
                        style: t.title.copyWith(
                          fontSize: 17,
                          color: c.brandDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreResult extends StatelessWidget {
  const new({
    required this.store,
    required this.viewModel,
    required this.onTap,
  });

  final PublicStore store;
  final SearchViewModel viewModel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final locale = Localizations.localeOf(context).languageCode;
    final origin = originOf(store.origin);
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(DymTokenRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DymTokenSpace.s3),
          child: Row(
            children: [
              DymAvatar(
                image: store.coverKey == null
                    ? storeFallback(store.origin)
                    : viewModel.service.photo(store.coverKey!),
                size: 80,
              ),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name, style: t.title.copyWith(fontSize: 20)),
                    if (origin != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: DymOriginBadge(
                          origin: origin,
                          label: originLabel(
                            viewModel.config,
                            store.origin,
                            locale,
                          ),
                        ),
                      ),
                    Text(
                      storeMeta(context, store),
                      style: t.body.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ filtres

/// Écran 30 : feuille des filtres. Renvoie les filtres appliqués, ou rien.
Future<SearchFilters?> showFiltersSheet(
  BuildContext context, {
  required CountryConfig? config,
  required SearchFilters current,
}) => showModalBottomSheet<SearchFilters>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => SearchFiltersSheet(config: config, initial: current),
);

/// Contenu de la feuille des filtres (écran 30).
class SearchFiltersSheet extends StatefulWidget {
  const new({required this.config, required this.initial, super.key});

  final CountryConfig? config;
  final SearchFilters initial;

  @override
  State<SearchFiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<SearchFiltersSheet> {
  late SearchSort _sort = widget.initial.sort;
  late String? _origin = widget.initial.origin;
  late String? _category = widget.initial.categoryId;
  late bool _available = widget.initial.availableOnly;
  late final _min = TextEditingController(
    text: _text(widget.initial.minPriceMinor),
  );
  late final _max = TextEditingController(
    text: _text(widget.initial.maxPriceMinor),
  );

  Currency? get _currency => widget.config?.currency;

  String _text(int? minor) {
    final c = widget.config?.currency;
    if (minor == null || c == null) return '';
    final units = c.minorUnits;
    if (units == 0) return '$minor';
    final s = minor.toString().padLeft(units + 1, '0');
    final cut = s.length - units;
    return '${s.substring(0, cut)},${s.substring(cut)}';
  }

  int? _parse(TextEditingController controller) {
    final c = _currency;
    if (c == null || controller.text.trim().isEmpty) return null;
    return Money.parseMajor(controller.text, c);
  }

  SearchFilters get _draft => SearchFilters(
    sort: _sort,
    origin: _origin,
    categoryId: _category,
    minPriceMinor: _parse(_min),
    maxPriceMinor: _parse(_max),
    availableOnly: _available,
  );

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final config = widget.config;
    final valid = _draft.priceValid;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: DymTokenSpace.s4, bottom: 8),
      child: Text(text, style: t.title.copyWith(fontSize: 19)),
    );
    final digits = _currency?.minorUnits ?? 0;
    final formatter = FilteringTextInputFormatter.allow(
      RegExp(digits == 0 ? r'[\d\s]' : r'[\d\s.,]'),
    );
    Widget amount(String hint, TextEditingController controller) => Expanded(
      child: DymTextField(
        label: hint,
        hint: hint,
        controller: controller,
        suffixText: _currency?.symbol,
        keyboardType: TextInputType.numberWithOptions(decimal: digits > 0),
        inputFormatters: [formatter],
        onChanged: (_) => setState(() {}),
      ),
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.filtersTitle,
                        style: t.display.copyWith(fontSize: 30),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _sort = SearchSort.relevance;
                        _origin = null;
                        _category = null;
                        _available = false;
                        _min.clear();
                        _max.clear();
                      }),
                      child: Text(l10n.filtersClear),
                    ),
                  ],
                ),
                label(l10n.filtersSort),
                Wrap(
                  spacing: DymTokenSpace.s2,
                  children: [
                    for (final (sort, text) in [
                      (SearchSort.relevance, l10n.sortRelevance),
                      (SearchSort.priceAsc, l10n.sortPriceAsc),
                      (SearchSort.priceDesc, l10n.sortPriceDesc),
                    ])
                      DymFilterChip(
                        label: text,
                        selected: _sort == sort,
                        onTap: () => setState(() => _sort = sort),
                      ),
                  ],
                ),
                label(l10n.filtersOrigin),
                Wrap(
                  spacing: DymTokenSpace.s2,
                  children: [
                    for (final origin
                        in config?.storeOrigins ?? const <StoreOriginInfo>[])
                      DymFilterChip(
                        label: origin.label.resolve(locale),
                        selected: _origin == origin.code,
                        onTap: () => setState(
                          () => _origin = _origin == origin.code
                              ? null
                              : origin.code,
                        ),
                      ),
                  ],
                ),
                label(l10n.filtersPrice),
                Row(
                  children: [
                    amount(l10n.filtersMin, _min),
                    const SizedBox(width: DymTokenSpace.s3),
                    amount(l10n.filtersMax, _max),
                  ],
                ),
                if (!valid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.filtersPriceInvalid,
                      style: t.label.copyWith(color: c.pimentStrong),
                    ),
                  ),
                label(l10n.filtersAisle),
                Wrap(
                  spacing: DymTokenSpace.s2,
                  children: [
                    for (final category
                        in config?.topCategories ?? const <Category>[])
                      DymFilterChip(
                        label: category.label.resolve(locale),
                        selected: _category == category.id,
                        onTap: () => setState(
                          () => _category = _category == category.id
                              ? null
                              : category.id,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: DymTokenSpace.s3),
                DymSwitchTile(
                  title: l10n.filtersAvailable,
                  value: _available,
                  onChanged: (value) => setState(() => _available = value),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: DymButton(
                label: l10n.filtersApply,
                onPressed: valid ? () => Navigator.pop(context, _draft) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
