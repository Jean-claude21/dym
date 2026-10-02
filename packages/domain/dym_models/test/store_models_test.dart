import 'package:dym_models/dym_models.dart';
import 'package:test/test.dart';

void main() {
  test('MyStore : réponse de my_store()', () {
    final store = MyStore.fromJson(const {
      'id': 's1',
      'name': "Les jus d'Esi",
      'description': null,
      'origin': 'maison',
      'zone_id': 'z1',
      'country_code': 'TG',
      'currency_code': 'XOF',
      'main_category_id': 'c1',
      'prep_time_minutes': 30,
      'offers_pickup': true,
      'delivery_fee_minor': null,
      'status': 'draft',
      'is_open': false,
      'onboarding_step': 5,
      'published_at': null,
      'pickup_address': {
        'address': 'Rue des Hibiscus',
        'landmark': 'Derrière la pharmacie',
        'latitude': 6.1375,
        'longitude': 1.2123,
        'contact_phone': null,
        'updated_at': '2026-10-02T10:00:00Z',
      },
      'delivery_zone_ids': ['z1', 'z2'],
      'payment_method_ids': <String>[],
      'hours': [
        {'weekday': 1, 'opens_at': '07:00', 'closes_at': '19:00'},
      ],
      'missing': ['payment_methods'],
    });
    expect(store.status, StoreStatus.draft);
    expect(store.onboardingStep, 5);
    expect(store.pickupAddress?.landmark, 'Derrière la pharmacie');
    expect(store.deliveryZoneIds, ['z1', 'z2']);
    expect(store.hours.single.opensAt, '07:00');
    expect(store.isComplete, isFalse);
  });

  test('StoreHours : aller-retour JSON', () {
    const hours = StoreHours(weekday: 6, opensAt: '07:00', closesAt: '13:00');
    expect(StoreHours.fromJson(hours.toJson()).closesAt, '13:00');
  });
}
