import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';

/// Service d'authentification simulé : réponses programmables, appels notés.
class FakeAuthService implements AuthService {
  new({this.app = AccountApp.client, this.googleAvailable = true});

  @override
  final AccountApp app;

  @override
  bool googleAvailable;

  @override
  Me? me;

  @override
  String? email = 'awa.mensah@gmail.com';

  final calls = <String>[];

  Result<void> sendResult = const Ok(null);
  Result<AuthState> verifyResult = const Ok(
    AuthState(AuthStatus.needsProfile, Me(userId: 'u1', roles: {})),
  );
  Result<AuthState?> googleResult = const Ok(null);
  Result<AuthState>? profileResult;
  Result<List<Country>> countriesResult = Ok([togo]);
  Result<ZoneMatch?> locateResult = const Ok(null);

  static final togo = Country.fromJson(const {
    'code': 'TG',
    'name': {'fr': 'Togo', 'en': 'Togo'},
    'currency_code': 'XOF',
    'dial_code': '+228',
    'default_locale': 'fr',
    'timezone': 'Africa/Lome',
  });

  static final config = CountryConfig(
    country: togo,
    currency: Currency.xof,
    cities: [
      City.fromJson(const {
        'id': 'lome',
        'country_code': 'TG',
        'slug': 'lome',
        'name': 'Lomé',
      }),
    ],
    zones: [
      for (final (slug, name) in const [
        ('be', 'Bè'),
        ('tokoin', 'Tokoin'),
        ('adawlato', 'Adawlato'),
        ('be-kpota', 'Bè Kpota'),
        ('nyekonakpoe', 'Nyékonakpoè'),
        ('hedzranawoe', 'Hédzranawoé'),
        ('agoe', 'Agoè'),
      ])
        Zone.fromJson({
          'id': 'z-$slug',
          'city_id': 'lome',
          'slug': slug,
          'name': name,
        }),
    ],
    categories: const [],
    storeOrigins: const [],
    units: const [],
    paymentMethods: const [],
    deliveryFees: const [],
    featureFlags: const [],
  );

  static Me readyMe({String firstName = 'Awa'}) => Me(
    userId: 'u1',
    roles: const {UserRole.client},
    profile: Profile(
      userId: 'u1',
      firstName: firstName,
      countryCode: 'TG',
      zoneId: 'z-be',
      locale: 'fr',
    ),
  );

  @override
  Future<Result<AuthState>> bootstrap() async =>
      const Ok(AuthState.signedOut());

  @override
  Future<Result<void>> sendEmailCode(String email) async {
    calls.add('send:$email');
    return sendResult;
  }

  @override
  Future<Result<AuthState>> verifyEmailCode(String email, String code) async {
    calls.add('verify:$email:$code');
    return verifyResult;
  }

  @override
  Future<Result<AuthState?>> signInWithGoogle() async {
    calls.add('google');
    return googleResult;
  }

  @override
  Future<Result<AuthState>> signInWithGoogleIdToken(String idToken) async {
    calls.add('googleToken:$idToken');
    return verifyResult;
  }

  @override
  Future<Result<List<Country>>> countries() async => countriesResult;

  @override
  Future<Result<CountryConfig>> countryConfig(String countryCode) async =>
      Ok(config);

  @override
  Future<Result<ZoneMatch?>> locateZone() async {
    calls.add('locate');
    return locateResult;
  }

  @override
  Future<Result<AuthState>> completeProfile({
    required String firstName,
    required String zoneId,
    required String locale,
  }) async {
    calls.add('profile:$firstName:$zoneId:$locale');
    return profileResult ??
        Ok(AuthState(AuthStatus.ready, readyMe(firstName: firstName)));
  }

  @override
  Future<Result<AuthState>> updateProfile({
    String? firstName,
    String? locale,
  }) async {
    calls.add('updateProfile:${firstName ?? '-'}:${locale ?? '-'}');
    return Ok(AuthState(AuthStatus.ready, me));
  }

  @override
  Future<Result<List<String>>> supportedLocales() async =>
      const Ok(['en', 'fr']);

  @override
  Future<Result<void>> signOut() async {
    calls.add('signOut');
    return const Ok(null);
  }

  @override
  Future<Result<void>> deleteAccount() async {
    calls.add('delete');
    return const Ok(null);
  }
}
