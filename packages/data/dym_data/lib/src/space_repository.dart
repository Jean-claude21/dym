import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Espaces partagés (spec 031). Rôles, prix, budget et validation sont en
/// base ; la validation passe par les règles du panier.
class SpaceRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<List<SpaceSummary>>> spaces() async {
    final result = await _data.rpc<Object?>('my_spaces');
    return result.map(
      (json) => [
        for (final s in json as List? ?? const [])
          SpaceSummary.fromJson(s as Map<String, dynamic>),
      ],
    );
  }

  Future<Result<Space>> space(String id) =>
      _space('space_detail', {'p_space': id});

  Future<Result<Space>> create(String name, {int? monthlyBudgetMinor}) =>
      _space('create_space', {
        'p_name': name,
        'p_monthly_budget_minor': monthlyBudgetMinor,
      });

  Future<Result<Space>> update(
    String id, {
    required String name,
    int? monthlyBudgetMinor,
  }) => _space('update_space', {
    'p_space': id,
    'p_name': name,
    'p_monthly_budget_minor': monthlyBudgetMinor,
  });

  /// Refus : `unknown_code`, `other_country`, `space_full`.
  Future<Result<Space>> join(String code) =>
      _space('join_space', {'p_code': code});

  Future<Result<Space>> setRole(String id, String userId, SpaceRole role) =>
      _space('set_space_role', {
        'p_space': id,
        'p_user': userId,
        'p_role': role.code,
      });

  /// Retire un membre, ou quitte l'espace ([userId] = soi-même).
  Future<Result<void>> removeMember(String id, String userId) =>
      _data.rpc<void>(
        'remove_space_member',
        params: {'p_space': id, 'p_user': userId},
      );

  Future<Result<void>> delete(String id) =>
      _data.rpc<void>('delete_space', params: {'p_space': id});

  /// Versement depuis le wallet dans la poche commune (clé d'idempotence).
  Future<Result<Space>> contribute(String id, int amountMinor, String key) =>
      _space('space_contribute', {
        'p_space': id,
        'p_amount_minor': amountMinor,
        'p_key': key,
      });

  /// Envoie le panier de la personne dans l'espace (et le vide).
  Future<Result<Space>> sendCart(String id) =>
      _space('send_cart_to_space', {'p_space': id});

  /// Quantité d'un article (0 : retiré).
  Future<Result<Space>> setItem(String id, String variantId, int quantity) =>
      _space('set_space_item', {
        'p_space': id,
        'p_variant': variantId,
        'p_quantity': quantity,
      });

  /// Valide : articles passés au panier ; refus `not_payer`, `budget_exceeded`.
  /// [usePocket] : financée par la poche commune (refus
  /// `space_pocket_insufficient`).
  Future<Result<ReorderResult>> validate(
    String id, {
    bool usePocket = false,
  }) async {
    final result = await _data.rpc<Object?>(
      'validate_space',
      params: {'p_space': id, 'p_use_pocket': usePocket},
    );
    return result.map(
      (json) => ReorderResult.fromJson((json! as Map).cast<String, dynamic>()),
    );
  }

  Future<Result<Space>> _space(String fn, Map<String, Object?> params) async {
    final result = await _data.rpc<Object?>(fn, params: params);
    return result.map(
      (json) => Space.fromJson((json! as Map).cast<String, dynamic>()),
    );
  }
}
