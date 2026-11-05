import 'dart:async';

import 'package:dym_client/features/cart/cart_service.dart';
import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/widgets.dart';

/// Copilote d'intention (spec 019).
abstract interface class CopilotService {
  /// Point d'entrée proposé (flag `intent_copilot` du pays).
  Future<bool> enabled();

  /// Panier proposé pour une intention, dans le quartier choisi.
  Future<Result<CopilotProposal>> propose(String text);

  /// Rechiffrage sans une ligne (retrait).
  Future<Result<CopilotProposal>> remove(
    CopilotProposal proposal,
    String variantId,
  );

  /// Ajoute les lignes au panier (règles du panier) ; renvoie les lignes
  /// refusées (rupture entre-temps, autre pays).
  Future<List<CopilotLine>> addAll(CopilotProposal proposal);

  /// Référentiel du pays (devise d'affichage).
  Future<Result<CountryConfig>> countryConfig();

  ImageProvider photo(String objectKey);
}

/// Implémentation Neon.
class NeonCopilotService implements CopilotService {
  new({
    required this._repository,
    required this._discovery,
    required this._cart,
    required this._events,
  });

  final CopilotRepository _repository;
  final DiscoveryService _discovery;
  final CartService _cart;
  final EventsRepository _events;

  @override
  Future<bool> enabled() async =>
      (await _discovery.countryConfig()).valueOrNull?.isEnabled(
        'intent_copilot',
      ) ??
      false;

  @override
  Future<Result<CopilotProposal>> propose(String text) =>
      _repository.propose(text, zoneId: _discovery.zone.value);

  @override
  Future<Result<CopilotProposal>> remove(
    CopilotProposal proposal,
    String variantId,
  ) => _repository.quote(proposal, removedVariantId: variantId);

  @override
  Future<List<CopilotLine>> addAll(CopilotProposal proposal) async {
    final refused = <CopilotLine>[];
    for (final line in proposal.lines) {
      final added = await _cart.add(line.variantId, quantity: line.quantity);
      if (!added.isOk) refused.add(line);
    }
    final config = (await _discovery.countryConfig()).valueOrNull;
    unawaited(
      _events.track(
        'copilot_cart_added',
        countryCode: config?.country.code,
        props: {
          'items_count': proposal.lines.length - refused.length,
          'refused_count': refused.length,
        },
      ),
    );
    return refused;
  }

  @override
  Future<Result<CountryConfig>> countryConfig() => _discovery.countryConfig();

  @override
  ImageProvider photo(String objectKey) => _discovery.photo(objectKey);
}

/// Copilote en mémoire (tests, galerie) : renvoie la proposition donnée.
class MemoryCopilotService implements CopilotService {
  new({
    required this.discovery,
    this.isEnabled = true,
    this.proposal,
    this.failure,
  });

  final DiscoveryService discovery;
  final bool isEnabled;

  /// Proposition renvoyée telle quelle (galerie).
  final CopilotProposal? proposal;
  final Failure? failure;
  final added = <String>[];

  @override
  Future<bool> enabled() async => isEnabled;

  @override
  Future<Result<CopilotProposal>> propose(String text) async {
    if (failure case final f?) return Err(f);
    return Ok(proposal ?? const CopilotProposal());
  }

  @override
  Future<Result<CopilotProposal>> remove(
    CopilotProposal proposal,
    String variantId,
  ) async {
    final stores = [
      for (final s in proposal.stores)
        if (s.lines.any((l) => l.variantId != variantId))
          CopilotStoreLines(
            id: s.id,
            name: s.name,
            lines: [
              for (final l in s.lines)
                if (l.variantId != variantId) l,
            ],
          ),
    ];
    // Rechiffrage de la base, reproduit ici pour la démonstration.
    final total = stores
        .expand((s) => s.lines)
        .fold(0, (sum, l) => sum + l.lineMinor);
    return Ok(
      CopilotProposal(
        currencyCode: proposal.currencyCode,
        totalMinor: total,
        stores: stores,
        missing: proposal.missing,
      ),
    );
  }

  @override
  Future<List<CopilotLine>> addAll(CopilotProposal proposal) async {
    added.addAll(proposal.lines.map((l) => l.variantId));
    return const [];
  }

  @override
  Future<Result<CountryConfig>> countryConfig() => discovery.countryConfig();

  @override
  ImageProvider photo(String objectKey) => discovery.photo(objectKey);
}
