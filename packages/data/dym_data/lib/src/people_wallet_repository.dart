import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Avoir DYM entre personnes (spec 100), simulé : jamais de retrait.
/// Soldes, plafonds et identités vérifiés en base.
class PeopleWalletRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<PeopleWallet>> overview() async =>
      (await _data.rpc<Object?>('my_p2p'))
          .map((j) => PeopleWallet.fromJson((j! as Map).cast()));

  /// Prénom du destinataire d'un code ; `null` : code inconnu.
  Future<Result<String?>> recipient(String handle) async =>
      (await _data.rpc<Object?>(
        'wallet_recipient',
        params: {'p_handle': handle},
      )).map((j) => j == null ? null : (j as Map)['first_name'] as String?);

  Future<Result<void>> send(
    String handle,
    int amountMinor, {
    required String idempotencyKey,
    String? note,
  }) async => (await _data.rpc<Object?>(
    'wallet_send',
    params: {
      'p_handle': handle,
      'p_amount_minor': amountMinor,
      'p_note': note,
      'p_key': idempotencyKey,
    },
  )).map((_) {});

  Future<Result<void>> request(
    String handle,
    int amountMinor, {
    String? note,
  }) async => (await _data.rpc<Object?>(
    'wallet_request',
    params: {
      'p_handle': handle,
      'p_amount_minor': amountMinor,
      'p_note': note,
      'p_purchase': null,
    },
  )).map((_) {});

  Future<Result<void>> answer(
    String requestId, {
    required bool pay,
    required String idempotencyKey,
  }) async => (await _data.rpc<Object?>(
    'wallet_answer_request',
    params: {'p_request': requestId, 'p_pay': pay, 'p_key': idempotencyKey},
  )).map((_) {});

  Future<Result<void>> topupFor(
    String handle,
    int amountMinor, {
    required String idempotencyKey,
  }) async => (await _data.rpc<Object?>(
    'wallet_topup_for',
    params: {
      'p_handle': handle,
      'p_amount_minor': amountMinor,
      'p_key': idempotencyKey,
    },
  )).map((_) {});

  Future<Result<Family>> family() async =>
      (await _data.rpc<Object?>('my_family')).map(_family);

  Future<Result<Family>> invite(String handle) async =>
      (await _data.rpc<Object?>(
        'family_invite',
        params: {'p_handle': handle},
      )).map(_family);

  Future<Result<Family>> accept(String parentId) async =>
      (await _data.rpc<Object?>(
        'family_accept',
        params: {'p_parent': parentId},
      )).map(_family);

  Future<Result<Family>> setRules(
    String childId, {
    int? allowanceMinor,
    int everyDays = 7,
    int? dailyLimitMinor,
  }) async => (await _data.rpc<Object?>(
    'family_set_rules',
    params: {
      'p_child': childId,
      'p_allowance_minor': allowanceMinor ?? 0,
      'p_every_days': everyDays,
      'p_daily_limit_minor': dailyLimitMinor ?? 0,
    },
  )).map(_family);

  /// Rayons autorisés pour un enfant (spec 104) ; vide : tous.
  Future<Result<Family>> setCategories(
    String childId,
    List<String> categoryIds,
  ) async => (await _data.rpc<Object?>(
    'family_set_categories',
    params: {'p_child': childId, 'p_categories': categoryIds},
  )).map(_family);

  static Family _family(Object? j) => Family.fromJson((j! as Map).cast());
}
