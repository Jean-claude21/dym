import 'package:dym_admin/features/dashboard/dashboard_view.dart';
import 'package:dym_admin/features/ops/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pilotage : six chiffres comparés à la période précédente', () async {
    final vm = AdminDashboardViewModel(service: MemoryAdminService());
    await vm.load();
    final kpis = vm.kpis;
    expect(kpis.map((k) => k.kind), KpiKind.values);
    final orders = kpis.firstWhere((k) => k.kind == KpiKind.orders);
    expect(orders.value, '58');
    expect(orders.delta, 14, reason: '58 contre 51');
    final deliveries = kpis.firstWhere((k) => k.kind == KpiKind.deliveries);
    expect(deliveries.delta, isNotNull, reason: 'écart en points');
    expect(vm.trend, isNotEmpty);
  });

  test('courbe : changer de série', () async {
    final vm = AdminDashboardViewModel(service: MemoryAdminService());
    await vm.load();
    vm.selectMetric(TrendMetric.sales);
    expect(vm.trend.any((v) => v > 0), isTrue);
    expect(vm.trendValue(vm.trend.length - 1), contains('F CFA'));
  });

  test('semaine : un point par jour écoulé', () async {
    final vm = AdminDashboardViewModel(service: MemoryAdminService());
    await vm.selectPeriod('week');
    expect(vm.overview!.series.length, inInclusiveRange(1, 7));
  });

  test('évolution et graduations', () {
    expect(AdminDashboardViewModel.change(58, 51), 14);
    expect(AdminDashboardViewModel.change(3, 0), isNull);
    expect(AdminDashboardViewModel.compact(186500), '187 k');
    expect(AdminDashboardViewModel.compact(1250000), '1,3 M');
    expect(AdminDashboardViewModel.compact(2.5), '2,5');
  });
}
