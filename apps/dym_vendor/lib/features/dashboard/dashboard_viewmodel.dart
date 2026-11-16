import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/dashboard/dashboard_service.dart';
import 'package:stacked/stacked.dart';

/// Dernière sélection prioritaire ; chiffres conservés si le réseau tombe.
class DashboardViewModel extends BaseViewModel {
  new({required this.service});

  final DashboardService service;
  DashboardPeriod period = DashboardPeriod.day;
  VendorDashboard? summary;

  /// Accueil poussé (spec 098) ; un échec garde la dernière lecture.
  VendorInsights? insights;
  CountryConfig? config;
  Failure? failure;

  /// Messages non lus (V-DASH-04) ; un échec garde la dernière valeur.
  int unreadMessages = 0;
  int _request = 0;
  Timer? _timer;
  StreamSubscription<LiveSignal>? _live;
  bool _disposed = false;

  bool get offline => failure is NetworkFailure;
  bool get ready => summary != null && config != null;
  Money? get revenue => switch ((summary, config)) {
    (final VendorDashboard s, final CountryConfig c) => c.money(s.revenueMinor),
    _ => null,
  };

  Future<void> load() async {
    final request = ++_request;
    failure = null;
    setBusy(true);
    final country = await service.countryConfig();
    if (_disposed || request != _request) return;
    switch (country) {
      case Err(:final failure):
        this.failure = failure;
      case Ok(:final value):
        config = value;
        final result = await service.summary(period);
        if (_disposed || request != _request) return;
        switch (result) {
          case Ok(:final value)
              when value.currencyCode == config?.currency.code:
            summary = value;
            if (await service.unreadMessages() case Ok(:final value)) {
              unreadMessages = value;
            }
            if (await service.insights(period) case Ok(:final value)
                when !_disposed && request == _request) {
              insights = value;
            }
          case Ok():
            failure = const ServerFailure('dashboard_currency_mismatch');
          case Err(:final failure):
            this.failure = failure;
        }
    }
    setBusy(false);
    // Relecture en filet ; le temps réel (spec 067) prévient d'abord.
    _timer ??= Timer.periodic(const Duration(seconds: 60), (_) {
      if (!isBusy) unawaited(load());
    });
    _live ??= watchLive(
      service.live,
      when: (s) => s.kind != '',
      reload: () {
        if (!isBusy && !_disposed) unawaited(load());
      },
    );
  }

  Future<void> selectPeriod(DashboardPeriod value) async {
    if (value == period) return;
    period = value;
    summary = null;
    insights = null;
    await load();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_live?.cancel());
    super.dispose();
  }
}
