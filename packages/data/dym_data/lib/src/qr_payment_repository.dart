import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Paiement par QR (spec 046) : demande de la vendeuse, paiement de la
/// cliente depuis son wallet. Tout est décidé en base.
class QrPaymentRepository {
  new(this._data);

  final NeonDataClient _data;

  Future<Result<PaymentRequest>> create({
    required int amountMinor,
    required String key,
    String? label,
  }) => _request('create_payment_request', {
    'p_amount_minor': amountMinor,
    'p_key': key,
    'p_label': label,
  });

  Future<Result<PaymentRequest>> status(String id) =>
      _request('my_payment_request', {'p_id': id});

  Future<Result<PaymentRequest>> cancel(String id) =>
      _request('cancel_payment_request', {'p_id': id});

  /// Cliente : code scanné (« DYM-PAY:… ») ou tapé.
  Future<Result<PaymentRequest>> preview(String code) =>
      _request('payment_request_preview', {'p_code': code});

  Future<Result<PaymentRequest>> pay(String code, {required String key}) =>
      _request('pay_payment_request', {'p_code': code, 'p_key': key});

  Future<Result<PaymentRequest>> _request(
    String fn,
    Map<String, Object?> params,
  ) async => (await _data.rpc<Object?>(fn, params: params)).map(
    (json) => PaymentRequest.fromJson((json! as Map).cast<String, dynamic>()),
  );
}
