import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_delivery/features/missions/missions_service.dart';
import 'package:dym_delivery/ui/navigation.dart';
import 'package:dym_delivery/ui/views/startup/startup_viewmodel.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth implements AuthService {
  new(this.result);

  final Result<AuthState> result;

  @override
  Future<Result<AuthState>> bootstrap() async => result;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Missions implements MissionsService {
  new(this.result);

  final Result<CourierProfile?> result;

  @override
  Stream<LiveSignal> get live => const Stream.empty();

  @override
  Future<Result<CourierProfile?>> profile() async => result;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Navigator implements AppNavigator {
  final routes = <String>[];

  @override
  void toSignIn({bool startWithProfile = false}) =>
      routes.add(startWithProfile ? 'profile' : 'signIn');

  @override
  void toStartup() => routes.add('startup');

  @override
  void toHome({bool onboarding = false}) =>
      routes.add(onboarding ? 'onboarding' : 'home');
}

final _env = DymEnvironment.resolve(env: 'dev');

Future<List<String>> _route(
  Result<AuthState> auth, [
  Result<CourierProfile?> courier = const Ok(null),
]) async {
  final navigator = _Navigator();
  await StartupViewModel(
    introDelay: Duration.zero,
    auth: _Auth(auth),
    missions: _Missions(courier),
    environment: _env,
    navigator: navigator,
  ).runStartupLogic();
  return navigator.routes;
}

void main() {
  const ready = Ok(AuthState(AuthStatus.ready));

  test('sans session : connexion', () async {
    expect(await _route(const Ok(AuthState.signedOut())), ['signIn']);
  });

  test('profil à compléter : étape profil', () async {
    expect(await _route(const Ok(AuthState(AuthStatus.needsProfile))), [
      'profile',
    ]);
  });

  test('pas encore livreur : inscription', () async {
    expect(await _route(ready), ['onboarding']);
  });

  test('livreur : missions', () async {
    expect(
      await _route(
        ready,
        const Ok(
          CourierProfile(
            displayName: 'Kofi',
            phone: '+228 90 11 22 33',
            vehicle: CourierVehicle.moto,
          ),
        ),
      ),
      ['home'],
    );
  });

  test('hors ligne : reprise proposée', () async {
    final navigator = _Navigator();
    final vm = StartupViewModel(
      introDelay: Duration.zero,
      auth: _Auth(const Err(NetworkFailure('hors ligne'))),
      missions: _Missions(const Ok(null)),
      environment: _env,
      navigator: navigator,
    );
    await vm.runStartupLogic();
    expect(vm.offline, isTrue);
    expect(navigator.routes, isEmpty);
  });
}
