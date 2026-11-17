import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth_service.dart';

class _WhatsApp implements WhatsAppSignIn {
  final calls = <String>[];
  Result<String?> sendResult = const Ok('123456');

  @override
  Future<({bool available, bool simulated})> status() async =>
      (available: true, simulated: true);

  @override
  Future<Result<String?>> send(String phone) async {
    calls.add('send:$phone');
    return sendResult;
  }

  @override
  Future<Result<AuthState>> verify(String phone, String code) async {
    calls.add('verify:$phone:$code');
    return code == '123456'
        ? const Ok(AuthState(AuthStatus.ready, Me(userId: 'u1', roles: {})))
        : const Err(ValidationFailure('code'));
  }
}

void main() {
  test(
    'WhatsApp : numéro, code simulé affiché, connexion (spec 105)',
    () async {
      final wa = _WhatsApp();
      final ready = <Me>[];
      final vm = AuthFlowViewModel(
        service: FakeAuthService(),
        onReady: ready.add,
        whatsApp: wa,
      );
      await vm.loadWhatsApp();
      expect(vm.whatsAppAvailable, isTrue);
      await vm.chooseWhatsApp();
      expect(vm.step, AuthStep.phone);
      vm
        ..setDialCode('+228')
        ..setPhone('90 11 22 33');
      expect(vm.phoneE164, '+22890112233');
      await vm.submitPhone();
      expect(vm.step, AuthStep.code);
      expect(vm.simulatedCode, '123456');
      vm.setCode('000000');
      await Future<void>.delayed(Duration.zero);
      expect(vm.authError, AuthError.codeWrong);
      vm.setCode('123456');
      await Future<void>.delayed(Duration.zero);
      expect(ready.single.userId, 'u1');
      expect(wa.calls, contains('verify:+22890112233:123456'));
      vm.dispose();
    },
  );

  test('WhatsApp : numéro incomplet et trop de codes', () async {
    final wa = _WhatsApp()..sendResult = const Err(RateLimitedFailure('trop'));
    final vm = AuthFlowViewModel(
      service: FakeAuthService(),
      onReady: (_) {},
      whatsApp: wa,
    );
    await vm.chooseWhatsApp();
    vm
      ..setDialCode('+228')
      ..setPhone('12');
    await vm.submitPhone();
    expect(vm.authError, AuthError.phoneInvalid);
    expect(wa.calls, isEmpty);
    vm.setPhone('90112233');
    await vm.submitPhone();
    expect(vm.authError, AuthError.tooManyCodes);
    expect(vm.step, AuthStep.phone);
    vm.dispose();
  });
}
