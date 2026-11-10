import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';

/// Wallet et poches (spec 025).
abstract interface class WalletService {
  Future<Result<Wallet>> wallet();
  Future<Result<CountryConfig>> countryConfig();
  Future<Result<Wallet>> topupSimulated(int amountMinor);

  /// Retrait simulé (spec 043).
  Future<Result<Wallet>> withdrawSimulated(int amountMinor);

  /// Code de recharge en cash auprès d'un livreur.
  Future<Result<({String code, DateTime expiresAt})>> cashTopupCode();

  /// Paiement par QR (spec 046) : ce qui sera payé, puis le paiement.
  Future<Result<PaymentRequest>> qrPreview(String code);

  Future<Result<PaymentRequest>> qrPay(String code);
  Future<Result<Wallet>> createPocket({
    required String name,
    int? goalMinor,
    int? roundUpMinor,
  });
  Future<Result<Wallet>> transfer({
    required int amountMinor,
    String? fromPocket,
    String? toPocket,
  });
  Future<Result<Wallet>> archivePocket(String id);
}

/// Implémentation Neon. Une clé d'idempotence est gardée tant que l'écriture
/// n'a pas abouti : un nouvel essai après coupure ne crée pas de doublon.
class NeonWalletService implements WalletService {
  new({
    required this._wallet,
    required this._reference,
    required this._auth,
    required this._qr,
  });

  final WalletRepository _wallet;
  final ReferenceRepository _reference;
  final QrPaymentRepository _qr;
  final AuthService _auth;
  CountryConfig? _config;
  String? _pendingKey;

  @override
  Future<Result<Wallet>> wallet() => _wallet.wallet();

  @override
  Future<Result<CountryConfig>> countryConfig() async {
    final cached = _config;
    if (cached != null) return Ok(cached);
    final code = _auth.me?.profile?.countryCode;
    if (code == null) return const Err(UnauthenticatedFailure('profil'));
    final result = await _reference.countryConfig(code);
    if (result case Ok(:final value)) _config = value;
    return result;
  }

  @override
  Future<Result<Wallet>> topupSimulated(int amountMinor) =>
      _keyed((key) => _wallet.topupSimulated(amountMinor, key));

  @override
  Future<Result<Wallet>> withdrawSimulated(int amountMinor) =>
      _keyed((key) => _wallet.withdrawSimulated(amountMinor, key));

  @override
  Future<Result<({String code, DateTime expiresAt})>> cashTopupCode() =>
      _wallet.cashTopupCode();

  @override
  Future<Result<PaymentRequest>> qrPreview(String code) => _qr.preview(code);

  @override
  Future<Result<PaymentRequest>> qrPay(String code) =>
      _keyed((key) => _qr.pay(code, key: key));

  @override
  Future<Result<Wallet>> createPocket({
    required String name,
    int? goalMinor,
    int? roundUpMinor,
  }) => _wallet.createPocket(
    name: name,
    goalMinor: goalMinor,
    roundUpMinor: roundUpMinor,
  );

  @override
  Future<Result<Wallet>> transfer({
    required int amountMinor,
    String? fromPocket,
    String? toPocket,
  }) => _keyed(
    (key) => _wallet.transfer(
      amountMinor: amountMinor,
      key: key,
      fromPocket: fromPocket,
      toPocket: toPocket,
    ),
  );

  @override
  Future<Result<Wallet>> archivePocket(String id) => _wallet.archivePocket(id);

  Future<Result<T>> _keyed<T>(
    Future<Result<T>> Function(String key) write,
  ) async {
    final key = _pendingKey ??= Uuid.v4();
    final result = await write(key);
    // Clé gardée seulement si la réponse a pu se perdre (réseau, 5xx).
    if (result case Err(:final failure) when failure.isTransient) {
      return result;
    }
    _pendingKey = null;
    return result;
  }
}
