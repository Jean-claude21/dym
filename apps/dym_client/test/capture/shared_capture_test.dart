@Tags(['golden'])
library;

import 'package:dym_account/dym_account.dart';
import 'package:dym_chat/dym_chat.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/discovery_fixtures.dart';
import 'capture.dart';

/// Captures des écrans partagés vus par la cliente : messages, aide, DYM+.
class _Membership implements MembershipService {
  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(togoConfig());

  @override
  Future<Result<MembershipOffer>> offer() async => Ok(
    MembershipOffer(
      plans: [
        MembershipPlan(
          id: 'p1',
          code: 'dym_plus',
          name: LocalizedText.fromJson(const {'fr': 'DYM+', 'en': 'DYM+'}),
          priceMinor: 1500,
          periodDays: 30,
          benefits: const {'delivery_refund': true, 'cashback_bonus_bps': 200},
        ),
      ],
      walletBalanceMinor: 12500,
    ),
  );

  @override
  Future<Result<MembershipOffer>> subscribe(MembershipPlan plan, String key) =>
      offer();
}

DateTime _clock() => DateTime.utc(2026, 11, 11, 11);

void main() {
  testWidgets('messages', (t) async {
    await capture(
      t,
      'messages',
      // Comme dans l'app (navigation) : la liste est posée dans un Scaffold.
      Scaffold(
        body: SafeArea(
          child: ConversationsView(
            service: MemoryChatService.demo(
              role: ChatRole.client,
              config: togoConfig(),
            ),
            onOpen: (_) {},
            clock: _clock,
            refreshEvery: null,
          ),
        ),
      ),
    );
  });
  testWidgets('conversation', (t) async {
    await capture(
      t,
      'conversation',
      ChatView(
        service: MemoryChatService.demo(
          role: ChatRole.client,
          config: togoConfig(),
        ),
        conversationId: 'c1',
        onBack: () {},
        onAddToCart: (_) async {},
        onOpenStore: (_) {},
        onOpenOrder: (_) {},
        clock: _clock,
        refreshEvery: null,
      ),
    );
  });
  testWidgets('conversation vendeuse', (t) async {
    await capture(
      t,
      'conversation_vendeuse',
      ChatView(
        service: MemoryChatService.demo(
          role: ChatRole.vendor,
          config: togoConfig(),
        ),
        conversationId: 'c1',
        onBack: () {},
        onOpenOrder: (_) {},
        pickProducts: (_, _) async => null,
        clock: _clock,
        refreshEvery: null,
      ),
    );
  });
  testWidgets('aide', (t) async {
    await capture(
      t,
      'aide',
      SupportView(
        service: MemorySupportService(
          orders: const [(id: 'o1', label: "7K2Q4F1A · Étal d'Akossiwa")],
        ),
        onBack: () {},
        clock: _clock,
      ),
    );
  });
  testWidgets('dym plus', (t) async {
    await capture(
      t,
      'dym_plus',
      MembershipView(service: _Membership(), title: 'DYM+', onBack: () {}),
    );
  });
}
