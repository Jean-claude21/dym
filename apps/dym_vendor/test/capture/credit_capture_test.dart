// Fakes repris des tests d'écran : certaines aides n'y servent pas.
@Tags(['golden'])
library;

import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:dym_vendor/features/credit/credit_service.dart';
import 'package:dym_vendor/features/credit/credit_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CountryConfig _togo() => CountryConfig(
  country: Country.fromJson(const {
    'code': 'TG',
    'name': {'fr': 'Togo'},
    'currency_code': 'XOF',
    'dial_code': '+228',
    'default_locale': 'fr',
    'timezone': 'Africa/Lome',
  }),
  currency: Currency.xof,
  cities: const [],
  zones: const [],
  categories: const [],
  storeOrigins: const [],
  units: const [],
  paymentMethods: const [],
  deliveryFees: const [],
  featureFlags: const [],
);

/// Ardoise en mémoire : mêmes règles utiles que la base.
class _Credits implements CreditService {
  final map = <String, StoreCredit>{};
  final messages = <String>[];

  StoreCredit _with(StoreCredit c, int balance, List<CreditEntry> entries) =>
      StoreCredit(
        id: c.id,
        customerName: c.customerName,
        phone: c.phone,
        limitMinor: c.limitMinor,
        balanceMinor: balance,
        canRemind: c.phone != null && balance > 0,
        entries: entries,
        storeName: 'Étal de Kodjo',
      );

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(_togo());

  @override
  Future<Result<StoreCredits>> credits() async => Ok(
    StoreCredits(
      totalMinor: map.values.fold(0, (s, c) => s + c.balanceMinor),
      credits: map.values.toList(),
    ),
  );

  @override
  Future<Result<StoreCredit>> detail(String id) async => Ok(map[id]!);

  @override
  Future<Result<StoreCredit>> save({
    required String name,
    String? id,
    String? phone,
    int? limitMinor,
  }) async {
    final c = StoreCredit(
      id: id ?? 'c${map.length + 1}',
      customerName: name,
      phone: phone,
      limitMinor: limitMinor,
      balanceMinor: 0,
    );
    return Ok(map[c.id] = c);
  }

  @override
  Future<Result<StoreCredit>> addEntry(
    StoreCredit credit, {
    required bool debt,
    required int amountMinor,
    String? note,
  }) async {
    final c = map[credit.id]!;
    if (debt &&
        c.limitMinor != null &&
        c.balanceMinor + amountMinor > c.limitMinor!) {
      return const Err(ValidationFailure('credit_limit'));
    }
    if (!debt && amountMinor > c.balanceMinor) {
      return const Err(ValidationFailure('payment_too_high'));
    }
    final entry = CreditEntry(
      id: 'e${c.entries.length + 1}',
      isDebt: debt,
      amountMinor: amountMinor,
      at: DateTime(2026, 11, 10),
      note: note,
    );
    return Ok(
      map[c.id] = _with(
        c,
        c.balanceMinor + (debt ? amountMinor : -amountMinor),
        [entry, ...c.entries],
      ),
    );
  }

  @override
  Future<Result<StoreCredit>> remind(
    StoreCredit credit,
    String Function(StoreCredit reminded) message,
  ) async {
    final c = map[credit.id]!;
    final reminded = _with(c, c.balanceMinor, c.entries);
    messages.add(message(reminded));
    return Ok(
      map[c.id] = StoreCredit(
        id: c.id,
        customerName: c.customerName,
        phone: c.phone,
        balanceMinor: c.balanceMinor,
        entries: c.entries,
      ),
    );
  }

  @override
  Future<Result<StoreCredits>> archive(StoreCredit credit) async {
    map.remove(credit.id);
    return await credits();
  }
}

Future<void> _capture(WidgetTester tester, String name, Widget child) async {
  const size = Size(412, 915);
  tester.view
    ..physicalSize = size * 2
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: DymTheme.light(),
      locale: const Locale('fr'),
      localizationsDelegates: DymLocalizations.localizationsDelegates,
      supportedLocales: DymLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: size,
          devicePixelRatio: 2,
          disableAnimations: true,
          padding: EdgeInsets.only(top: 24, bottom: 16),
        ),
        child: child,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 600));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  testWidgets('credit', (tester) async {
    final service = _Credits();
    await service.save(name: 'Ama', phone: '+228 90 00 00 07');
    await service.addEntry(service.map['c1']!, debt: true, amountMinor: 3000);

    await _capture(
      tester,
      'v_credit',
      CreditView(service: service, onBack: () {}),
    );
  });
}
