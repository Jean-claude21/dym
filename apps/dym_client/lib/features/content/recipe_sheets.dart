import 'dart:async';

import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// « Dans cette vidéo » (spec 057, planche 02 étape 2) : produits de la vidéo
/// en rail, ajout d'un geste, puis « Tout pour la recette ». La vidéo reste
/// derrière la feuille. Retourne vrai si la recette est demandée.
Future<bool> showVideoProducts(
  BuildContext context, {
  required ContentService service,
  required ContentItem content,
  required CountryConfig? config,
  required Future<bool> Function(CatalogItem product) onAdd,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ProductsSheet(
        service: service,
        content: content,
        config: config,
        onAdd: onAdd,
      ),
    ) ??
    false;

/// « Sauce gombo · pour 4 » (planche 02 étape 3) : portions, articles cochés,
/// ajout au panier sans quitter la vidéo. Les quantités et les prix viennent
/// de la base. Retourne le nombre d'articles ajoutés (0 : rien).
Future<int> showRecipeSheet(
  BuildContext context, {
  required ContentService service,
  required ContentItem content,
  required CountryConfig? config,
}) async =>
    await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.82,
        child: CartScopeBridge(
          from: context,
          child: _RecipeSheet(
            service: service,
            content: content,
            config: config,
          ),
        ),
      ),
    ) ??
    0;

/// La feuille s'ouvre dans une nouvelle route : on y remet la portée du
/// panier de l'écran d'origine.
class CartScopeBridge extends StatelessWidget {
  const new({required this.from, required this.child, super.key});

  final BuildContext from;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = CartScope.maybeOf(from);
    if (scope == null) return child;
    return CartScope(
      service: scope.service,
      onOpenCart: scope.onOpenCart,
      child: child,
    );
  }
}

class _ProductsSheet extends StatefulWidget {
  const new({
    required this.service,
    required this.content,
    required this.config,
    required this.onAdd,
  });

  final ContentService service;
  final ContentItem content;
  final CountryConfig? config;
  final Future<bool> Function(CatalogItem product) onAdd;

  @override
  State<_ProductsSheet> createState() => _ProductsSheetState();
}

class _ProductsSheetState extends State<_ProductsSheet> {
  CopilotProposal? _recipe;
  final _added = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.content.hasRecipe) unawaited(_loadTotal());
  }

  Future<void> _loadTotal() async {
    final result = await widget.service.recipeBasket(widget.content);
    if (!mounted) return;
    setState(() => _recipe = result.valueOrNull);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final products = widget.content.products;
    final total = moneyOf(widget.config, _recipe?.totalMinor);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: l10n.feedInThisVideo, style: t.title),
                  TextSpan(
                    text: ' · ${l10n.feedProductCount(products.length)}',
                    style: t.body.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DymTokenSpace.s3),
            if (products.isNotEmpty)
              SizedBox(
                // Photo 150 + deux lignes + prix : suit le texte agrandi.
                height:
                    206 +
                    52 *
                        MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.5),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: DymTokenSpace.s2),
                  itemBuilder: (context, i) {
                    final p = products[i];
                    final price = moneyOf(
                      widget.config,
                      p.minPriceMinor ?? p.priceMinor,
                    );
                    final added = _added.contains(p.id);
                    return SizedBox(
                      width: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProductThumb(
                            image: switch (p.photoKey) {
                              final key? => widget.service.photo(key),
                              null => null,
                            },
                            size: 150,
                          ),
                          const SizedBox(height: DymTokenSpace.s1),
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.body.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            [
                              ?p.unitLabel?.resolve(locale),
                              p.store.name,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.label.copyWith(
                              color: c.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              if (price != null)
                                Expanded(
                                  child: MoneyText(
                                    price,
                                    size: 15,
                                    color: c.textPrimary,
                                  ),
                                )
                              else
                                const Spacer(),
                              IconButton.filled(
                                tooltip: l10n.feedAdd,
                                style: IconButton.styleFrom(
                                  backgroundColor: c.brand,
                                  foregroundColor: c.onBrand,
                                  minimumSize: const Size(40, 40),
                                ),
                                onPressed: !p.available || added
                                    ? null
                                    : () async {
                                        if (await widget.onAdd(p)) {
                                          unawaited(
                                            HapticFeedback.lightImpact(),
                                          );
                                          if (mounted) {
                                            setState(() => _added.add(p.id));
                                          }
                                        }
                                      },
                                icon: Icon(
                                  added
                                      ? Icons.check_rounded
                                      : Icons.add_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            if (widget.content.hasRecipe) ...[
              const SizedBox(height: DymTokenSpace.s3),
              DymButton(
                label: total == null
                    ? l10n.recipeAllForIt
                    : l10n.recipeAllForTotal(total.format()),
                icon: Icons.shopping_basket_outlined,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecipeSheet extends StatefulWidget {
  const new({
    required this.service,
    required this.content,
    required this.config,
  });

  final ContentService service;
  final ContentItem content;
  final CountryConfig? config;

  @override
  State<_RecipeSheet> createState() => _RecipeSheetState();
}

class _RecipeSheetState extends State<_RecipeSheet> {
  CopilotProposal? _proposal;
  Failure? _failure;
  int? _servings;
  bool _loading = true;
  bool _adding = false;
  Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    final result = await widget.service.recipeBasket(
      widget.content,
      servings: _servings,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Ok(:final value):
          _proposal = value;
          _servings = value.servings ?? _servings;
          _selected = {for (final l in value.lines) l.variantId};
        case Err(failure: final f):
          _failure = f;
      }
    });
  }

  Future<void> _setServings(int n) async {
    if (n < 1 || n == _servings) return;
    _servings = n;
    await _load();
  }

  Future<void> _add() async {
    final proposal = _proposal;
    final scope = CartScope.maybeOf(context);
    if (proposal == null || scope == null) return;
    setState(() => _adding = true);
    var count = 0;
    for (final line in proposal.lines) {
      if (!_selected.contains(line.variantId)) continue;
      final result = await scope.service.add(
        line.variantId,
        quantity: line.quantity,
      );
      if (result.isOk) {
        count++;
        widget.service.recipeAdded(widget.content, line.variantId);
      }
    }
    if (!mounted) return;
    setState(() => _adding = false);
    if (count > 0) unawaited(HapticFeedback.mediumImpact());
    Navigator.of(context).pop(count);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final proposal = _proposal;
    final servings = _servings;
    final title = widget.content.caption ?? l10n.recipeAllForIt;
    final lines = proposal?.lines ?? const <CopilotLine>[];
    final all = lines.isNotEmpty && _selected.length == lines.length;
    final total = all ? moneyOf(widget.config, proposal?.totalMinor) : null;
    final storeOf = {
      for (final s in proposal?.stores ?? const <CopilotStoreLines>[])
        for (final l in s.lines) l.variantId: s.name,
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: title, style: t.title),
                  if (servings != null)
                    TextSpan(
                      text: ' · ${l10n.recipeForPeople(servings)}',
                      style: t.body.copyWith(color: c.textSecondary),
                    ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: DymTokenSpace.s3),
            if (servings != null)
              Container(
                padding: const EdgeInsets.only(left: DymTokenSpace.s3),
                decoration: BoxDecoration(
                  border: Border.all(color: c.hairline),
                  borderRadius: BorderRadius.circular(DymTokenRadius.field),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(l10n.recipeServings(servings), style: t.body),
                    ),
                    DymQuantityStepper(
                      quantity: servings,
                      min: 1,
                      max: 50,
                      dense: true,
                      decreaseLabel: l10n.recipeServingsLess,
                      increaseLabel: l10n.recipeServingsMore,
                      onChanged: _loading ? (_) {} : _setServings,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: DymTokenSpace.s2),
            Expanded(
              child: _loading && proposal == null
                  ? const Center(child: CircularProgressIndicator())
                  : _failure != null
                  ? DiscoveryState(failure: _failure, onRetry: _load)
                  : ListView(
                      children: [
                        for (final (i, line) in lines.indexed) ...[
                          if (i > 0) Divider(height: 1, color: c.hairline),
                          _RecipeLine(
                            line: line,
                            store: storeOf[line.variantId],
                            selected: _selected.contains(line.variantId),
                            price: moneyOf(widget.config, line.lineMinor),
                            image: switch (line.photoKey) {
                              final key? => widget.service.photo(key),
                              null => null,
                            },
                            locale: locale,
                            onChanged: (on) => setState(() {
                              on
                                  ? _selected.add(line.variantId)
                                  : _selected.remove(line.variantId);
                            }),
                          ),
                        ],
                        if (proposal?.missing case final missing?
                            when missing.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: DymTokenSpace.s2,
                            ),
                            child: Text(
                              l10n.copilotMissing(missing.join(', ')),
                              style: t.label.copyWith(
                                color: c.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            if (proposal != null && proposal.stores.isNotEmpty) ...[
              Divider(height: 1, color: c.hairline),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s2),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 18,
                      color: c.textSecondary,
                    ),
                    const SizedBox(width: DymTokenSpace.s1),
                    Expanded(
                      child: Text(
                        l10n.recipeStores(proposal.stores.length),
                        style: t.label.copyWith(
                          color: c.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            DymButton(
              label: total != null
                  ? l10n.recipeAddLines(_selected.length, total.format())
                  : l10n.recipeAddSome(_selected.length),
              icon: Icons.add_shopping_cart_rounded,
              loading: _adding,
              onPressed: _selected.isEmpty || _loading ? null : _add,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeLine extends StatelessWidget {
  const new({
    required this.line,
    required this.store,
    required this.selected,
    required this.price,
    required this.image,
    required this.locale,
    required this.onChanged,
  });

  final CopilotLine line;
  final String? store;
  final bool selected;
  final Money? price;
  final ImageProvider? image;
  final String locale;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final unit = [
      if (line.quantity > 1) '${line.quantity} ×',
      ?line.variantLabel,
      ?line.unitLabel?.resolve(locale),
    ].join(' ');
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!selected),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DymTokenSpace.s2),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: (v) => onChanged(v ?? false),
              ),
              ProductThumb(image: image, size: 52),
              const SizedBox(width: DymTokenSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (unit.isNotEmpty)
                      Text(
                        unit,
                        style: t.label.copyWith(
                          color: c.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    if (store != null)
                      Text(
                        store!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.label.copyWith(
                          color: c.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              if (price != null)
                MoneyText(price!, size: 15, color: c.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
