import 'package:dym_platform/dym_platform.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_kit/neon_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final session = NeonSession(
    sessionToken: 's',
    accessToken: 'a',
    accessTokenExpiresAt: DateTime.utc(2026, 10, 2),
    userId: 'u-1',
    email: 'awa@example.com',
  );

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('écriture, lecture, effacement', () async {
    final store = SecureSessionStore();
    expect(await store.read(), isNull);
    await store.write(session);
    expect((await store.read())?.userId, 'u-1');
    await store.clear();
    expect(await store.read(), isNull);
  });

  test('valeur illisible : effacée et ignorée', () async {
    FlutterSecureStorage.setMockInitialValues({'dym.neon.session': '{oups'});
    final store = SecureSessionStore();
    expect(await store.read(), isNull);
    expect(
      await const FlutterSecureStorage().read(key: 'dym.neon.session'),
      isNull,
    );
  });
}
