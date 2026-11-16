import 'package:dym_admin/features/delivery/delivery_admin_service.dart';
import 'package:dym_admin/features/delivery/delivery_admin_views.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fake implements DeliveryAdminService {
  DeliveryPricing? pricing;
  final reviewed = <String>[];
  final pending = [
    PendingAccount(
      id: 's1',
      kind: 'store',
      name: 'Primeur Saint-Sever',
      countryCode: 'FR',
      createdAt: DateTime(2026, 11, 16),
    ),
  ];

  @override
  Future<Result<List<Country>>> countries() async => const Ok([]);

  @override
  Future<Result<DeliveryConfig>> config(String countryCode) async => Ok(
    DeliveryConfig(
      countryCode: countryCode,
      maxDistanceM: 20000,
      pricing: pricing,
    ),
  );

  @override
  Future<Result<void>> savePricing(String c, DeliveryPricing p) async {
    pricing = p;
    return const Ok(null);
  }

  @override
  Future<Result<void>> saveSurcharges(
    String c,
    List<DeliverySurcharge> s,
  ) async => const Ok(null);

  @override
  Future<Result<void>> saveBands(String c, List<FeeBand> b) async =>
      const Ok(null);

  @override
  Future<Result<void>> saveMaxDistance(String c, int m) async => const Ok(null);

  @override
  Future<Result<void>> saveCityRadius(String c, int m) async => const Ok(null);

  @override
  Future<Result<(int?, int)>> preview(
    String c, {
    required int meters,
    required bool longDistance,
    DateTime? at,
  }) async => Ok((300 + meters ~/ 1000 * 150, 0));

  @override
  Future<Result<List<PendingAccount>>> pendingAccounts() async =>
      Ok([...pending]);

  @override
  Future<Result<void>> review(
    PendingAccount a, {
    required bool approve,
    String? note,
  }) async {
    reviewed.add('${a.id}:$approve');
    pending.removeWhere((p) => p.id == a.id);
    return const Ok(null);
  }

  @override
  Future<Result<List<DeliveryIncident>>> incidents() async => const Ok([]);

  @override
  Future<Result<void>> resolve(DeliveryIncident i) async => const Ok(null);
}

void main() {
  test('tarif : enregistré puis relu, simulateur', () async {
    final service = _Fake();
    final vm = AdminDeliveryViewModel(service: service)..country = 'FR';
    await vm.load();
    expect(
      await vm.savePricing(
        const DeliveryPricing(baseFeeMinor: 250, perKmMinor: 90),
      ),
      isTrue,
    );
    expect(vm.config?.pricing?.perKmMinor, 90);
    await vm.simulate(3000, longDistance: false);
    expect(vm.simulation?.$1, 750);
  });

  test('comptes : valider retire le compte de la liste', () async {
    final service = _Fake();
    final vm = AdminAccountsViewModel(service: service);
    await vm.load();
    expect(vm.accounts, hasLength(1));
    await vm.review(vm.accounts!.single, approve: true);
    expect(service.reviewed, ['s1:true']);
    expect(vm.accounts, isEmpty);
  });
}
