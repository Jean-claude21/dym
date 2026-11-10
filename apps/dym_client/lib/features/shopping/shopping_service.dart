import 'dart:async';

import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/discovery/copilot/copilot_service.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/widgets.dart';

/// Assistant de courses (spec 029) : listes, habitudes, liste proposée par
/// l'IA, panier composé en base. Rien n'est commandé sans validation.
abstract interface class ShoppingService {
  Future<Result<List<ShoppingList>>> lists();

  Future<Result<ShoppingList>> save({
    required String name,
    required List<ShoppingItem> items,
    String? id,
    ShoppingPeriod? period,
    DateTime? startsOn,
  });

  Future<Result<void>> delete(String id);

  /// Produits achetés dans au moins deux commandes (90 jours).
  Future<Result<List<ShoppingItem>>> habits();

  /// « Décrire mes courses » proposé (flag `intent_copilot` du pays).
  Future<bool> aiEnabled();

  /// Description → articles proposés par l'IA.
  Future<Result<List<ShoppingItem>>> suggest(String text);

  /// Proposition d'une liste, affichée par l'écran du copilote.
  CopilotService copilotFor(ShoppingList list);
}

/// Implémentation Neon.
class NeonShoppingService implements ShoppingService {
  new({
    required this._repository,
    required this._copilot,
    required this._discovery,
    required this._cart,
    required this._events,
  });

  final ShoppingListRepository _repository;
  final CopilotService _copilot;
  final DiscoveryService _discovery;
  final CartService _cart;
  final EventsRepository _events;

  @override
  Future<Result<List<ShoppingList>>> lists() => _repository.lists();

  @override
  Future<Result<ShoppingList>> save({
    required String name,
    required List<ShoppingItem> items,
    String? id,
    ShoppingPeriod? period,
    DateTime? startsOn,
  }) => _repository.save(
    id: id,
    name: name,
    items: items,
    period: period,
    startsOn: startsOn,
  );

  @override
  Future<Result<void>> delete(String id) => _repository.delete(id);

  @override
  Future<Result<List<ShoppingItem>>> habits() => _repository.habits();

  @override
  Future<bool> aiEnabled() => _copilot.enabled();

  @override
  Future<Result<List<ShoppingItem>>> suggest(String text) =>
      _repository.suggest(text);

  @override
  CopilotService copilotFor(ShoppingList list) => ListCopilotService(
    base: _copilot,
    proposeList: () =>
        _repository.proposal(list.id, zoneId: _discovery.zone.value),
    addToCart: (variantId, quantity) async =>
        (await _cart.add(variantId, quantity: quantity)).isOk,
    onAdded: (added, refused) async {
      final config = (await _discovery.countryConfig()).valueOrNull;
      await _events.track(
        'shopping_list_cart_added',
        countryCode: config?.country.code,
        props: {'items_count': added, 'refused_count': refused},
      );
    },
  );
}

/// Copilote d'une liste : la proposition vient de la liste (pas d'une
/// intention) ; retrait, devise et photos comme le copilote.
class ListCopilotService implements CopilotService {
  new({
    required this.base,
    required this.proposeList,
    required this.addToCart,
    this.onAdded,
  });

  final CopilotService base;

  /// Panier composé en base pour la liste.
  final Future<Result<CopilotProposal>> Function() proposeList;

  /// `true` : ligne ajoutée (règles du panier).
  final Future<bool> Function(String variantId, int quantity) addToCart;

  /// Mesure (articles ajoutés, refusés).
  final Future<void> Function(int added, int refused)? onAdded;

  @override
  Future<bool> enabled() async => true;

  @override
  Future<Result<CopilotProposal>> propose(String text) => proposeList();

  @override
  Future<Result<CopilotProposal>> remove(
    CopilotProposal proposal,
    String variantId,
  ) => base.remove(proposal, variantId);

  @override
  Future<List<CopilotLine>> addAll(CopilotProposal proposal) async {
    final refused = <CopilotLine>[];
    for (final line in proposal.lines) {
      if (!await addToCart(line.variantId, line.quantity)) refused.add(line);
    }
    unawaited(
      onAdded?.call(proposal.lines.length - refused.length, refused.length),
    );
    return refused;
  }

  @override
  Future<Result<CountryConfig>> countryConfig() => base.countryConfig();

  @override
  ImageProvider photo(String objectKey) => base.photo(objectKey);
}
