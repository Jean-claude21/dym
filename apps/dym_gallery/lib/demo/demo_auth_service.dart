import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_gallery/demo/demo_country.dart';
import 'package:dym_models/dym_models.dart';

/// Authentification de démonstration pour la galerie : aucune requête, le
/// parcours se déroule avec des données fictives clairement identifiées.
class DemoAuthService implements AuthService {
  new({required this.country, this.app = AccountApp.client});

  final DemoCountry country;

  @override
  final AccountApp app;

  @override
  bool get googleAvailable => true;

  @override
  String? get email => 'awa.mensah@gmail.com';

  @override
  Me? me = const Me(
    userId: 'demo',
    roles: {UserRole.client},
    profile: Profile(
      userId: 'demo',
      firstName: 'Awa',
      countryCode: 'TG',
      locale: 'fr',
      zoneId: 'be',
    ),
  );

  static const _zones = {
    'TG': [
      'Bè',
      'Tokoin',
      'Adawlato',
      'Bè Kpota',
      'Nyékonakpoè',
      'Hédzranawoé',
      'Agoè',
    ],
    'GH': ['Osu', 'Madina', 'Makola', 'Kaneshie', 'East Legon'],
  };

  Country get _country => Country.fromJson({
    'code': country.code,
    'name': {'fr': country.name, 'en': country.name},
    'currency_code': country.currency.code,
    'dial_code': country.code == 'GH' ? '+233' : '+228',
    'default_locale': country.code == 'GH' ? 'en' : 'fr',
    'timezone': country.code == 'GH' ? 'Africa/Accra' : 'Africa/Lome',
  });

  @override
  Future<Result<AuthState>> bootstrap() async =>
      const Ok(AuthState.signedOut());

  @override
  Future<Result<void>> sendEmailCode(String email) async => const Ok(null);

  @override
  Future<Result<AuthState>> verifyEmailCode(String email, String code) async =>
      const Ok(
        AuthState(AuthStatus.needsProfile, Me(userId: 'demo', roles: {})),
      );

  @override
  Future<Result<AuthState?>> signInWithGoogle() async => const Ok(null);

  @override
  Future<Result<AuthState>> signInWithGoogleIdToken(String idToken) async =>
      const Ok(
        AuthState(AuthStatus.needsProfile, Me(userId: 'demo', roles: {})),
      );

  @override
  Future<Result<List<Country>>> countries() async => Ok([_country]);

  @override
  Future<Result<ZoneMatch?>> locateZone() async => Ok(
    ZoneMatch(
      zoneId: country.code == 'TG' ? 'be' : _zones[country.code]!.first,
      zoneName: country.zone,
      cityId: 'city',
      cityName: country.city.split(',').last.trim(),
      countryCode: country.code,
      distanceM: 300,
    ),
  );

  @override
  Future<Result<CountryConfig>> countryConfig(String countryCode) async {
    final city = country.city.split(',').last.trim();
    return Ok(
      CountryConfig(
        country: _country,
        currency: country.currency,
        cities: [
          City.fromJson({
            'id': 'city',
            'country_code': country.code,
            'slug': 'city',
            'name': city,
          }),
        ],
        zones: [
          for (final name in _zones[country.code] ?? const <String>[])
            Zone.fromJson({
              'id': name == 'Bè' ? 'be' : name,
              'city_id': 'city',
              'slug': name,
              'name': name,
            }),
        ],
        categories: const [],
        storeOrigins: const [],
        units: const [],
        paymentMethods: const [],
        deliveryFees: const [],
        featureFlags: const [],
      ),
    );
  }

  @override
  Future<Result<AuthState>> completeProfile({
    required String firstName,
    required String zoneId,
    required String locale,
  }) async => Ok(AuthState(AuthStatus.ready, me));

  @override
  Future<Result<void>> signOut() async => const Ok(null);

  @override
  Future<Result<void>> deleteAccount() async => const Ok(null);
}
