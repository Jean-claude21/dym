import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';

/// Caisse (spec 045) : remplaçable en test.
abstract interface class TillService {
  Future<Result<CountryConfig>> countryConfig();

  Future<Result<Till>> till();

  /// Texte → vente à confirmer.
  Future<Result<TillDraft>> parse(String text);

  /// Vente dictée : enregistrement puis transcription ; `Ok(null)` : rien
  /// compris. Refus `feature_disabled` : dictée coupée pour le pays.
  Future<Result<String?>> dictate();

  VoiceRecorder get recorder;

  Future<Result<Till>> record({
    required String label,
    required int amountMinor,
    required TillMethod method,
    String? variantId,
    int quantity = 1,
  });

  Future<Result<Till>> voidSale(TillSale sale);

  Future<Result<Till>> payout(int amountMinor);

  /// Encaissement par QR (spec 046).
  Future<Result<PaymentRequest>> requestPayment(
    int amountMinor, {
    String? label,
  });

  Future<Result<PaymentRequest>> requestStatus(PaymentRequest request);

  Future<Result<PaymentRequest>> cancelRequest(PaymentRequest request);
}

class NeonTillService implements TillService {
  new({
    required this._till,
    required this._qr,
    required this._search,
    required this.recorder,
    required this._config,
  });

  final TillRepository _till;
  final QrPaymentRepository _qr;
  String? _requestKey;
  final SearchAiRepository _search;
  final Future<Result<CountryConfig>> Function() _config;
  String? _saleKey;
  String? _payoutKey;

  @override
  final VoiceRecorder recorder;

  @override
  Future<Result<CountryConfig>> countryConfig() => _config();

  @override
  Future<Result<Till>> till() => _till.till();

  @override
  Future<Result<TillDraft>> parse(String text) => _till.parse(text);

  @override
  Future<Result<String?>> dictate() async {
    final recorded = await recorder.stop();
    switch (recorded) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: null):
        return const Ok(null);
      case Ok(value: final audio?):
        return await _search.transcribe(audio.bytes, audio.contentType);
    }
  }

  @override
  Future<Result<Till>> record({
    required String label,
    required int amountMinor,
    required TillMethod method,
    String? variantId,
    int quantity = 1,
  }) async {
    // Même clé tant que la vente n'a pas abouti (nouvelle tentative réseau).
    final key = _saleKey ??= Uuid.v4();
    final result = await _till.record(
      label: label,
      amountMinor: amountMinor,
      method: method,
      key: key,
      variantId: variantId,
      quantity: quantity,
    );
    if (result.failureOrNull is! NetworkFailure) _saleKey = null;
    return result;
  }

  @override
  Future<Result<Till>> voidSale(TillSale sale) => _till.voidSale(sale.id);

  @override
  Future<Result<PaymentRequest>> requestPayment(
    int amountMinor, {
    String? label,
  }) async {
    final key = _requestKey ??= Uuid.v4();
    final result = await _qr.create(
      amountMinor: amountMinor,
      key: key,
      label: label,
    );
    if (result.failureOrNull is! NetworkFailure) _requestKey = null;
    return result;
  }

  @override
  Future<Result<PaymentRequest>> requestStatus(PaymentRequest request) =>
      _qr.status(request.id);

  @override
  Future<Result<PaymentRequest>> cancelRequest(PaymentRequest request) =>
      _qr.cancel(request.id);

  @override
  Future<Result<Till>> payout(int amountMinor) async {
    final key = _payoutKey ??= Uuid.v4();
    final result = await _till.payout(amountMinor, key);
    if (result.failureOrNull is! NetworkFailure) _payoutKey = null;
    return result;
  }
}
