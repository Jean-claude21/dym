import 'dart:async';

import 'package:dym_client/features/cart/widgets/cart_widgets.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/discovery/widgets/discovery_widgets.dart';
import 'package:dym_client/features/favorites/favorites_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

// ------------------------------------------------------------------ cœur

/// Cœur d'une boutique ou d'un produit (spec 030), sur photo.
class FavoriteButton extends StatelessWidget {
  const new({
    required this.service,
    required this.kind,
    required this.id,
    super.key,
  });

  final FavoritesService service;
  final FavoriteKind kind;
  final String id;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: service.ids,
      builder: (context, ids, _) {
        final on = ids.contains(kind, id);
        return Material(
          color: c.card,
          shape: const CircleBorder(),
          elevation: 1,
          child: IconButton(
            tooltip: on ? l10n.favoriteRemove : l10n.favoriteAdd,
            isSelected: on,
            onPressed: () async {
              final messenger = ScaffoldMessenger.maybeOf(context);
              final result = await service.toggle(kind, id);
              if (result case Err(:final failure)) {
                messenger?.showSnackBar(
                  SnackBar(
                    content: Text(
                      failure is NetworkFailure
                          ? l10n.errorOffline
                          : l10n.errorGeneric,
                    ),
                  ),
                );
              }
            },
            icon: Icon(
              on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: on ? c.pimentStrong : c.textPrimary,
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------------ favoris

class FavoritesViewModel extends BaseViewModel {
  new({required this.service, required this.discovery});

  final FavoritesService service;
  final DiscoveryService discovery;
  Favorites favorites = const Favorites();
  CountryConfig? config;
  bool ready = false;
  Failure? failure;

  Future<void> load() async {
    failure = null;
    setBusy(true);
    config = (await discovery.countryConfig()).valueOrNull;
    switch (await service.favorites()) {
      case Ok(:final value):
        favorites = value;
        ready = true;
      case Err(failure: final f):
        failure = f;
    }
    setBusy(false);
  }
}

/// « Mes favoris » : boutiques et produits gardés d'un cœur.
class FavoritesView extends StackedView<FavoritesViewModel> {
  const new({
    required this.service,
    required this.discovery,
    required this.onBack,
    required this.onOpenStore,
    required this.onOpenProduct,
    super.key,
  });

  final FavoritesService service;
  final DiscoveryService discovery;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenStore;
  final ValueChanged<String> onOpenProduct;

  @override
  FavoritesViewModel viewModelBuilder(BuildContext context) =>
      FavoritesViewModel(service: service, discovery: discovery);

  @override
  void onViewModelReady(FavoritesViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, FavoritesViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final f = vm.favorites;
    final Widget body;
    if (!vm.ready) {
      body = DiscoveryState(
        failure: vm.isBusy ? null : vm.failure,
        onRetry: vm.load,
      );
    } else if (f.isEmpty) {
      body = DymStateView(
        kind: DymStateKind.empty,
        title: l10n.favoritesTitle,
        message: l10n.favoritesEmpty,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (f.stores.isNotEmpty) ...[
              DymSectionHeader(title: l10n.favoritesStores),
              SizedBox(
                height:
                    252 *
                    MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.3),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: f.stores.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: DymTokenSpace.s3),
                  itemBuilder: (context, i) => StoreTile(
                    store: f.stores[i],
                    service: discovery,
                    config: vm.config,
                    onTap: () => onOpenStore(f.stores[i].id),
                  ),
                ),
              ),
              const SizedBox(height: DymTokenSpace.s4),
            ],
            if (f.products.isNotEmpty) ...[
              DymSectionHeader(title: l10n.favoritesProducts),
              ProductGrid(
                items: f.products,
                service: discovery,
                config: vm.config,
                onOpen: onOpenProduct,
              ),
            ],
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(title: l10n.favoritesTitle, onBack: onBack),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ paniers

/// Erreurs des paniers enregistrés.
enum BasketError { empty, tooMany, name, offline, generic }

BasketError basketErrorOf(Failure failure) => switch (failure) {
  NetworkFailure() => BasketError.offline,
  ValidationFailure(message: 'cart_empty') => BasketError.empty,
  ValidationFailure(message: 'too_many_baskets' || 'too_many_items') =>
    BasketError.tooMany,
  ValidationFailure(message: 'invalid_name') => BasketError.name,
  _ => BasketError.generic,
};

String basketErrorLabel(DymLocalizations l10n, BasketError error) =>
    switch (error) {
      BasketError.empty => l10n.basketErrorEmpty,
      BasketError.tooMany => l10n.basketErrorTooMany,
      BasketError.name => l10n.basketErrorName,
      BasketError.offline => l10n.errorOffline,
      BasketError.generic => l10n.errorGeneric,
    };

class BasketsViewModel extends BaseViewModel {
  new({required this.service, required this.discovery});

  final FavoritesService service;
  final DiscoveryService discovery;
  List<SavedBasket> baskets = const [];
  CountryConfig? config;
  bool ready = false;
  Failure? failure;

  /// Panier en cours d'action.
  String? acting;
  BasketError? problem;

  /// Articles non ajoutés à la dernière remise au panier.
  List<String> skipped = const [];

  Future<void> load() async {
    failure = null;
    setBusy(true);
    config = (await discovery.countryConfig()).valueOrNull;
    switch (await service.baskets()) {
      case Ok(:final value):
        baskets = value;
        ready = true;
      case Err(failure: final f):
        failure = f;
    }
    setBusy(false);
  }

  String? money(int minor) => moneyOf(config, minor)?.format();

  /// `true` : au moins un article est au panier.
  Future<bool> toCart(SavedBasket basket) async {
    if (acting != null) return false;
    acting = basket.id;
    problem = null;
    skipped = const [];
    notifyListeners();
    final result = await service.toCart(basket.id);
    acting = null;
    var ok = false;
    switch (result) {
      case Ok(:final value):
        skipped = value.skipped;
        ok = value.added > 0;
      case Err(failure: final f):
        problem = basketErrorOf(f);
    }
    notifyListeners();
    return ok;
  }

  Future<void> rename(SavedBasket basket, String name) async {
    if (name.trim().isEmpty) return;
    problem = null;
    switch (await service.rename(basket.id, name)) {
      case Ok(:final value):
        baskets = [
          for (final b in baskets)
            if (b.id == basket.id) value else b,
        ];
      case Err(failure: final f):
        problem = basketErrorOf(f);
    }
    notifyListeners();
  }

  Future<void> delete(SavedBasket basket) async {
    problem = null;
    switch (await service.delete(basket.id)) {
      case Ok():
        baskets = [
          for (final b in baskets)
            if (b.id != basket.id) b,
        ];
      case Err(failure: final f):
        problem = basketErrorOf(f);
    }
    notifyListeners();
  }
}

/// « Mes paniers » : paniers enregistrés, remis au panier d'un geste.
class BasketsView extends StackedView<BasketsViewModel> {
  const new({
    required this.service,
    required this.discovery,
    required this.onBack,
    required this.onAdded,
    super.key,
  });

  final FavoritesService service;
  final DiscoveryService discovery;
  final VoidCallback onBack;

  /// Articles au panier : ouvrir le panier.
  final VoidCallback onAdded;

  @override
  BasketsViewModel viewModelBuilder(BuildContext context) =>
      BasketsViewModel(service: service, discovery: discovery);

  @override
  void onViewModelReady(BasketsViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(BuildContext context, BasketsViewModel vm, Widget? child) {
    final c = context.dym.colors;
    final l10n = DymLocalizations.of(context);
    final Widget body;
    if (!vm.ready) {
      body = DiscoveryState(
        failure: vm.isBusy ? null : vm.failure,
        onRetry: vm.load,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (vm.problem case final p?)
              DymContentWidth.form(
                child: CartIssue(label: basketErrorLabel(l10n, p)),
              ),
            if (vm.skipped.isNotEmpty)
              DymContentWidth.form(
                child: CartIssue(
                  label: l10n.basketSkipped(vm.skipped.join(', ')),
                  blocking: false,
                ),
              ),
            if (vm.baskets.isEmpty)
              DymContentWidth.form(
                child: DymStateView(
                  kind: DymStateKind.empty,
                  title: l10n.basketsTitle,
                  message: l10n.basketsEmpty,
                ),
              ),
            for (final basket in vm.baskets)
              DymContentWidth.form(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: DymTokenSpace.s3),
                  child: _BasketCard(
                    vm: vm,
                    basket: basket,
                    onToCart: () async {
                      if (await vm.toCart(basket) && vm.skipped.isEmpty) {
                        onAdded();
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            CartHeader(title: l10n.basketsTitle, onBack: onBack),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _BasketCard extends StatelessWidget {
  const new({required this.vm, required this.basket, required this.onToCart});

  final BasketsViewModel vm;
  final SavedBasket basket;
  final VoidCallback onToCart;

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final unavailable = basket.items.length - basket.availableCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DymTokenSpace.s4,
        DymTokenSpace.s2,
        DymTokenSpace.s1,
        DymTokenSpace.s4,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(basket.name, style: t.title.copyWith(fontSize: 19)),
              ),
              PopupMenuButton<bool>(
                tooltip: l10n.basketMore(basket.name),
                onSelected: (rename) async {
                  if (rename) {
                    final name = await askBasketName(
                      context,
                      initial: basket.name,
                    );
                    if (name != null) await vm.rename(basket, name);
                  } else if (await _confirmDelete(context, basket.name)) {
                    await vm.delete(basket);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: true,
                    child: ListTile(
                      leading: const Icon(Icons.edit_rounded),
                      title: Text(l10n.basketRename),
                    ),
                  ),
                  PopupMenuItem(
                    value: false,
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_rounded,
                        color: c.pimentStrong,
                      ),
                      title: Text(l10n.basketDelete),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            basket.items.map((i) => '${i.quantity} × ${i.name}').join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.body.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: DymTokenSpace.s1),
          Text(
            l10n.basketMeta(
              basket.items.length,
              vm.money(basket.totalMinor) ?? '',
            ),
            style: t.label.copyWith(color: c.brandDeep),
          ),
          if (unavailable > 0)
            Text(
              l10n.basketUnavailable(unavailable),
              style: t.label.copyWith(color: c.pimentStrong),
            ),
          const SizedBox(height: DymTokenSpace.s3),
          Padding(
            padding: const EdgeInsets.only(right: DymTokenSpace.s3),
            child: DymButton(
              label: l10n.basketToCart,
              icon: Icons.add_shopping_cart_rounded,
              loading: vm.acting == basket.id,
              onPressed: vm.acting == null && basket.availableCount > 0
                  ? onToCart
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool> _confirmDelete(BuildContext context, String name) async {
    final l10n = DymLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: Text(l10n.basketDeleteConfirm(name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialog).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialog).pop(true),
                child: Text(l10n.basketDelete),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// Nom d'un panier ; `null` : annulé.
Future<String?> askBasketName(BuildContext context, {String initial = ''}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: initial),
    );

class _NameDialog extends StatefulWidget {
  const new({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _done() {
    if (_text.text.trim().isNotEmpty) Navigator.of(context).pop(_text.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.basketName),
      content: TextField(
        controller: _text,
        autofocus: true,
        maxLength: SavedBasket.maxNameLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.basketNameHint),
        onSubmitted: (_) => _done(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(onPressed: _done, child: Text(l10n.basketSaveAction)),
      ],
    );
  }
}

/// « Enregistrer ce panier » depuis le panier : nom, puis message.
Future<void> saveCartAsBasket(
  BuildContext context,
  FavoritesService service,
) async {
  final l10n = DymLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final name = await askBasketName(context);
  if (name == null) return;
  final result = await service.saveCart(name);
  messenger?.showSnackBar(
    SnackBar(
      content: Text(switch (result) {
        Ok() => l10n.basketSaved,
        Err(:final failure) => basketErrorLabel(l10n, basketErrorOf(failure)),
      }),
    ),
  );
}
