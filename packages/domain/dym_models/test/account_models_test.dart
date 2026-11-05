import 'package:dym_models/dym_models.dart';
import 'package:test/test.dart';

void main() {
  test('Me : profil absent → à compléter', () {
    final me = Me.fromJson(const {
      'user_id': 'u1',
      'profile': null,
      'roles': <Object>[],
    });
    expect(me.needsProfile, isTrue);
    expect(me.roles, isEmpty);
  });

  test('Me : profil et rôles, rôle inconnu ignoré', () {
    final me = Me.fromJson(const {
      'user_id': 'u1',
      'profile': {
        'user_id': 'u1',
        'first_name': 'Awa',
        'country_code': 'TG',
        'zone_id': 'z1',
        'locale': 'fr',
        'avatar_key': null,
      },
      'roles': ['client', 'vendor', 'futur'],
    });
    expect(me.needsProfile, isFalse);
    expect(me.profile?.firstName, 'Awa');
    expect(me.roles, {UserRole.client, UserRole.vendor});
    expect(me.hasRole(UserRole.admin), isFalse);
  });
}
