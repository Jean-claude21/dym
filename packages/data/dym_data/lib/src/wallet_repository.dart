import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Wallet et poches (spec 025). Toutes les règles (soldes, devise, limites)
/// sont en base ; chaque écriture porte une clé d'idempotence.
class WalletRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<Wallet>> wallet() => _wallet('my_wallet');

  /// Recharge simulée (tests) : refusée si le pays l'a coupée.
  Future<Result<Wallet>> topupSimulated(int amountMinor, String key) => _wallet(
    'wallet_topup_simulated',
    {'p_amount_minor': amountMinor, 'p_key': key},
  );

  Future<Result<Wallet>> createPocket({
    required String name,
    int? goalMinor,
    int? roundUpMinor,
  }) => _wallet('create_pocket', {
    'p_name': name,
    'p_goal_minor': goalMinor,
    'p_round_up_minor': roundUpMinor,
  });

  /// De [fromPocket] vers [toPocket] ; `null` désigne le wallet.
  Future<Result<Wallet>> transfer({
    required int amountMinor,
    required String key,
    String? fromPocket,
    String? toPocket,
  }) => _wallet('wallet_transfer', {
    'p_from_pocket': fromPocket,
    'p_to_pocket': toPocket,
    'p_amount_minor': amountMinor,
    'p_key': key,
  });

  /// Archive une poche ; son solde revient au wallet.
  Future<Result<Wallet>> archivePocket(String id) =>
      _wallet('archive_pocket', {'p_pocket': id});

  Future<Result<Wallet>> _wallet(
    String fn, [
    Map<String, Object?>? params,
  ]) async {
    final result = await _data.rpc<Object?>(fn, params: params);
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        if (value is! Map<String, dynamic>) {
          return const Err(ServerFailure('wallet illisible'));
        }
        try {
          return Ok(Wallet.fromJson(value));
        } on Object catch (error) {
          return Err(ServerFailure('wallet illisible : ${error.runtimeType}'));
        }
    }
  }
}
