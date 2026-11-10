import 'package:dym_client/features/wallet/qr_pay_view.dart';
import 'package:dym_client/features/wallet/testing.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

PaymentRequest _request() => PaymentRequest(
  id: 'r1',
  code: '123456',
  amountMinor: 2000,
  currencyCode: 'XOF',
  status: PaymentRequestStatus.open,
  expiresAt: DateTime(2026, 11, 10, 10, 10),
  storeName: 'Étal de Kodjo',
);

void main() {
  group('payer par QR (spec 046)', () {
    test('code scanné : aperçu puis paiement depuis le wallet', () async {
      final service = MemoryWalletService(
        config: togoConfig(),
        balanceMinor: 5000,
      )..qrRequest = _request();
      final vm = QrPayViewModel(service: service);
      await vm.init();
      await vm.read('DYM-PAY:123456');
      expect(vm.preview?.storeName, 'Étal de Kodjo');
      await vm.pay();
      expect(vm.paid?.status, PaymentRequestStatus.paid);
      expect(service.balanceMinor, 3000);
    });

    test('code inconnu ; wallet insuffisant', () async {
      final service = MemoryWalletService(
        config: togoConfig(),
        balanceMinor: 1000,
      )..qrRequest = _request();
      final vm = QrPayViewModel(service: service);
      await vm.init();
      await vm.read('999999');
      expect(vm.problem, 'invalid_code');
      await vm.read('123456');
      await vm.pay();
      expect(vm.problem, 'wallet_insufficient');
      expect(vm.paid, isNull);
    });
  });
}
