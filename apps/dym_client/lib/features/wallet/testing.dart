import 'package:dym_client/features/wallet/wallet_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';

/// Wallet en mémoire (tests, galerie). Jamais en production. Reproduit les
/// règles de la base utiles à l'écran (solde, poches, refus).
class MemoryWalletService implements WalletService {
  new({this._config, this.balanceMinor = 0, this.simulatedTopup = true});

  final CountryConfig? _config;
  int balanceMinor;
  bool simulatedTopup;
  final List<WalletPocket> pockets = [];
  final List<WalletMovement> movements = [];

  /// Échec à renvoyer au prochain appel d'écriture.
  Failure? nextFailure;

  Wallet get _wallet => Wallet(
    currencyCode: _config?.currency.code ?? 'XOF',
    balanceMinor: balanceMinor,
    simulatedTopup: simulatedTopup,
    pockets: List.unmodifiable(pockets),
    movements: List.unmodifiable(movements.reversed),
  );

  @override
  Future<Result<Wallet>> wallet() async => Ok(_wallet);

  @override
  Future<Result<CountryConfig>> countryConfig() async {
    final config = _config;
    return config == null
        ? const Err(UnauthenticatedFailure('profil'))
        : Ok(config);
  }

  @override
  Future<Result<Wallet>> topupSimulated(int amountMinor) async {
    if (_take() case final failure?) return Err(failure);
    if (!simulatedTopup) {
      return const Err(ValidationFailure('feature_disabled'));
    }
    balanceMinor += amountMinor;
    _move(WalletMovementKind.walletTopup, amountMinor);
    return Ok(_wallet);
  }

  @override
  Future<Result<Wallet>> createPocket({
    required String name,
    int? goalMinor,
    int? roundUpMinor,
  }) async {
    if (_take() case final failure?) return Err(failure);
    pockets.add(
      WalletPocket(
        id: 'pocket-${pockets.length + 1}',
        name: name,
        balanceMinor: 0,
        goalMinor: goalMinor,
        roundUpMinor: roundUpMinor,
      ),
    );
    return Ok(_wallet);
  }

  @override
  Future<Result<Wallet>> transfer({
    required int amountMinor,
    String? fromPocket,
    String? toPocket,
  }) async {
    if (_take() case final failure?) return Err(failure);
    if (_balance(fromPocket) < amountMinor) {
      return const Err(ValidationFailure('wallet_insufficient'));
    }
    _adjust(fromPocket, -amountMinor);
    _adjust(toPocket, amountMinor);
    _move(WalletMovementKind.walletTransfer, -amountMinor);
    return Ok(_wallet);
  }

  @override
  Future<Result<Wallet>> archivePocket(String id) async {
    if (_take() case final failure?) return Err(failure);
    final pocket = pockets.firstWhere((p) => p.id == id);
    balanceMinor += pocket.balanceMinor;
    pockets.remove(pocket);
    return Ok(_wallet);
  }

  Failure? _take() {
    final failure = nextFailure;
    nextFailure = null;
    return failure;
  }

  int _balance(String? pocket) => pocket == null
      ? balanceMinor
      : pockets.firstWhere((p) => p.id == pocket).balanceMinor;

  void _adjust(String? pocket, int delta) {
    if (pocket == null) {
      balanceMinor += delta;
      return;
    }
    final i = pockets.indexWhere((p) => p.id == pocket);
    final p = pockets[i];
    pockets[i] = WalletPocket(
      id: p.id,
      name: p.name,
      balanceMinor: p.balanceMinor + delta,
      goalMinor: p.goalMinor,
      roundUpMinor: p.roundUpMinor,
    );
  }

  void _move(WalletMovementKind kind, int amount) => movements.add(
    WalletMovement(
      id: 'm-${movements.length + 1}',
      kind: kind,
      amountMinor: amount,
      occurredAt: DateTime.utc(2026, 11, 9, 12),
    ),
  );
}
