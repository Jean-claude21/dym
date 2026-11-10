import 'package:dym_client/features/discovery/copilot/copilot_service.dart';
import 'package:dym_client/features/shopping/shopping_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';

/// Assistant de courses en mémoire (tests, galerie). Jamais en production.
class MemoryShoppingService implements ShoppingService {
  new({
    required this.copilot,
    this.habitItems = const [],
    this.suggested,
    this.isAiEnabled = true,
  });

  /// Copilote pour la proposition (photos, devise, retrait).
  final CopilotService copilot;
  final List<ShoppingItem> habitItems;

  /// Réponse de l'IA ; absente : IA en échec.
  final List<ShoppingItem>? suggested;
  final bool isAiEnabled;
  final List<ShoppingList> stored = [];
  int _next = 0;

  /// Échec à renvoyer au prochain enregistrement.
  Failure? nextFailure;

  /// Derniers paramètres enregistrés.
  ({ShoppingPeriod? period, DateTime? startsOn})? lastSaved;

  @override
  Future<Result<List<ShoppingList>>> lists() async =>
      Ok(List.unmodifiable(stored));

  @override
  Future<Result<ShoppingList>> save({
    required String name,
    required List<ShoppingItem> items,
    String? id,
    ShoppingPeriod? period,
    DateTime? startsOn,
  }) async {
    if (nextFailure case final f?) {
      nextFailure = null;
      return Err(f);
    }
    lastSaved = (period: period, startsOn: startsOn);
    final list = ShoppingList(
      id: id ?? 'l${_next++}',
      name: name,
      items: items,
      period: period,
      nextDueOn: startsOn,
    );
    stored
      ..removeWhere((l) => l.id == list.id)
      ..add(list);
    return Ok(list);
  }

  @override
  Future<Result<void>> delete(String id) async {
    stored.removeWhere((l) => l.id == id);
    return const Ok(null);
  }

  @override
  Future<Result<List<ShoppingItem>>> habits() async => Ok(habitItems);

  @override
  Future<bool> aiEnabled() async => isAiEnabled;

  @override
  Future<Result<List<ShoppingItem>>> suggest(String text) async =>
      switch (suggested) {
        final items? => Ok(items),
        null => const Err(ServerFailure('assistant en échec')),
      };

  @override
  CopilotService copilotFor(ShoppingList list) => copilot;
}
