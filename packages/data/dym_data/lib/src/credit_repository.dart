import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Ardoise de la vendeuse (spec 047). Soldes et plafonds en base.
class CreditRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<StoreCredits>> credits() async =>
      (await _data.rpc<Object?>('my_credits')).map(
        (json) => StoreCredits.fromJson((json! as Map).cast<String, dynamic>()),
      );

  Future<Result<StoreCredit>> detail(String id) =>
      _credit('credit_detail', {'p_credit': id});

  Future<Result<StoreCredit>> save({
    required String name,
    String? id,
    String? phone,
    int? limitMinor,
  }) => _credit('save_credit', {
    'p_credit': id,
    'p_name': name,
    'p_phone': phone,
    'p_limit_minor': limitMinor,
  });

  Future<Result<StoreCredit>> addEntry(
    String id, {
    required bool debt,
    required int amountMinor,
    required String key,
    String? note,
  }) => _credit('add_credit_entry', {
    'p_credit': id,
    'p_kind': debt ? 'debt' : 'payment',
    'p_amount_minor': amountMinor,
    'p_key': key,
    'p_note': note,
  });

  Future<Result<StoreCredit>> remind(String id) =>
      _credit('remind_credit', {'p_credit': id});

  Future<Result<StoreCredits>> archive(String id) async =>
      (await _data.rpc<Object?>(
        'archive_credit',
        params: {'p_credit': id},
      )).map(
        (json) => StoreCredits.fromJson((json! as Map).cast<String, dynamic>()),
      );

  Future<Result<StoreCredit>> _credit(
    String fn,
    Map<String, Object?> params,
  ) async => (await _data.rpc<Object?>(fn, params: params)).map(
    (json) => StoreCredit.fromJson((json! as Map).cast<String, dynamic>()),
  );
}
