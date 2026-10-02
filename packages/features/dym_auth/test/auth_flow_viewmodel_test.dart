import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth_service.dart';

void main() {
  late FakeAuthService service;
  late List<Me> ready;
  late AuthFlowViewModel vm;

  setUp(() {
    service = FakeAuthService();
    ready = [];
    vm = AuthFlowViewModel(service: service, onReady: ready.add);
  });

  tearDown(() => vm.dispose());

  test('bienvenue : passer mène au dernier écran', () {
    vm.skipWelcome();
    expect(vm.welcomePage, AuthFlowViewModel.welcomePages - 1);
  });

  test('email mal formé : aucune requête', () async {
    vm
      ..chooseEmail()
      ..setEmail('awa@');
    expect(vm.emailValid, isFalse);
    await vm.submitEmail();
    expect(service.calls, isEmpty);
    expect(vm.authError, AuthError.emailInvalid);
  });

  test('parcours email complet : code, profil, prête', () async {
    vm
      ..chooseEmail()
      ..setEmail('  Awa.Mensah@Gmail.com ');
    await vm.submitEmail();
    expect(service.calls.single, 'send:awa.mensah@gmail.com');
    expect(vm.step, AuthStep.code);
    expect(vm.resendSeconds, 60);

    vm.setCode('482913');
    await pumpEventQueue();
    expect(service.calls.last, 'verify:awa.mensah@gmail.com:482913');
    expect(vm.step, AuthStep.profile);
    expect(vm.zones, hasLength(7));

    vm
      ..setFirstName(' Awa ')
      ..selectZone('z-be');
    expect(vm.canSubmitProfile, isTrue);
    await vm.submitProfile();
    expect(service.calls.last, 'profile:Awa:z-be:fr');
    expect(ready.single.profile?.firstName, 'Awa');
  });

  test('code faux : message, cases en rouge, on peut corriger', () async {
    service.verifyResult = const Err(ValidationFailure('INVALID_OTP'));
    vm
      ..chooseEmail()
      ..setEmail('awa@example.com');
    await vm.submitEmail();
    vm.setCode('000000');
    await pumpEventQueue();
    expect(vm.authError, AuthError.codeWrong);
    expect(vm.codeRejected, isTrue);
    expect(vm.step, AuthStep.code);
    vm.setCode('1');
    expect(vm.codeRejected, isFalse);
    expect(vm.authError, isNull);
  });

  test(
    "réseau coupé à l'envoi : « Pas de connexion », email conservé",
    () async {
      service.sendResult = const Err(NetworkFailure('hors ligne'));
      vm
        ..chooseEmail()
        ..setEmail('awa@example.com');
      await vm.submitEmail();
      expect(vm.authError, AuthError.offline);
      expect(vm.step, AuthStep.email);
      expect(vm.email, 'awa@example.com');
    },
  );

  test('Google annulé : retour sans message', () async {
    await vm.chooseGoogle();
    expect(service.calls, ['google']);
    expect(vm.authError, isNull);
    expect(vm.step, AuthStep.welcome);
  });

  test('Google : compte existant → prête directement', () async {
    service.googleResult = Ok(
      AuthState(AuthStatus.ready, FakeAuthService.readyMe()),
    );
    await vm.chooseGoogle();
    expect(ready, hasLength(1));
  });

  test('Google non configuré : message dédié', () async {
    service.googleAvailable = false;
    await vm.chooseGoogle();
    expect(vm.authError, AuthError.googleUnavailable);
    expect(service.calls, isEmpty);
  });

  test('profil : prénom ou quartier manquant refusés sans requête', () async {
    await vm.startProfile();
    await vm.submitProfile();
    expect(vm.authError, AuthError.firstNameInvalid);
    vm.setFirstName('Awa');
    await vm.submitProfile();
    expect(vm.authError, AuthError.zoneRequired);
    expect(service.calls.where((c) => c.startsWith('profile')), isEmpty);
  });

  test("session expirée pendant le profil : retour à l'email", () async {
    service.profileResult = const Err(UnauthenticatedFailure('expirée'));
    await vm.startProfile();
    vm
      ..setFirstName('Awa')
      ..selectZone('z-be');
    await vm.submitProfile();
    expect(vm.authError, AuthError.sessionExpired);
    expect(vm.step, AuthStep.email);
  });

  test('retour : code → email → bienvenue ; profil sans retour', () async {
    vm
      ..chooseEmail()
      ..setEmail('awa@example.com');
    await vm.submitEmail();
    expect(vm.back(), isTrue);
    expect(vm.step, AuthStep.email);
    expect(vm.back(), isTrue);
    expect(vm.step, AuthStep.welcome);
    expect(vm.back(), isFalse);
    await vm.startProfile();
    expect(vm.back(), isFalse);
  });
}
