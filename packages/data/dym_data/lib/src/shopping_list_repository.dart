import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Assistant de courses (spec 029). Les règles (bornes, périodes, échéances,
/// composition et prix du panier) sont en base ; l'IA ne propose que des
/// articles.
class ShoppingListRepository {
  new({required this._data, required this._functions});

  final NeonDataClient _data;
  final NeonFunctionsClient _functions;

  Future<Result<List<ShoppingList>>> lists() async {
    final result = await _data.rpc<Object?>('my_shopping_lists');
    return result.map(
      (json) => [
        for (final l in json as List? ?? const [])
          ShoppingList.fromJson(l as Map<String, dynamic>),
      ],
    );
  }

  /// Crée ([id] absent) ou modifie une liste. [startsOn] : premier rappel.
  Future<Result<ShoppingList>> save({
    required String name,
    required List<ShoppingItem> items,
    String? id,
    ShoppingPeriod? period,
    DateTime? startsOn,
    String? zoneId,
  }) async {
    final result = await _data.rpc<Object?>(
      'save_shopping_list',
      params: {
        'p': {
          'id': ?id,
          'name': name,
          'items': [for (final i in items) i.toJson()],
          'every_days': period?.days,
          if (period != null && startsOn != null) 'starts_on': _date(startsOn),
          'zone_id': ?zoneId,
        },
      },
    );
    return result.map(
      (json) => ShoppingList.fromJson(json! as Map<String, dynamic>),
    );
  }

  Future<Result<void>> delete(String id) =>
      _data.rpc<void>('delete_shopping_list', params: {'p_id': id});

  /// Produits achetés dans au moins deux commandes (90 jours).
  Future<Result<List<ShoppingItem>>> habits() async {
    final result = await _data.rpc<Object?>('shopping_habits');
    return result.map(_items);
  }

  /// Description → articles proposés par l'IA (flag du copilote ; 503 si
  /// l'IA ne répond pas).
  Future<Result<List<ShoppingItem>>> suggest(String text) => _functions.post(
    '/v1/agent/list',
    body: {'text': text},
    decode: (json) => _items((json as Map<String, dynamic>?)?['items']),
  );

  /// Panier composé et chiffré en base pour la liste [id].
  Future<Result<CopilotProposal>> proposal(String id, {String? zoneId}) async {
    final result = await _data.rpc<Object?>(
      'shopping_list_proposal',
      params: {'p_id': id, 'p_zone': zoneId},
    );
    return result.map(
      (json) => CopilotProposal.fromJson(json! as Map<String, dynamic>),
    );
  }

  static List<ShoppingItem> _items(Object? json) => [
    for (final i in json as List? ?? const [])
      ShoppingItem.fromJson(i as Map<String, dynamic>),
  ];

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
