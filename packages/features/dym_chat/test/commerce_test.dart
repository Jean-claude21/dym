import 'package:dym_chat/dym_chat.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_map/dym_map.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _config = CountryConfig(
  country: Country.fromJson(const {
    'code': 'TG',
    'name': {'fr': 'Pays test', 'en': 'Test country'},
    'currency_code': 'XOF',
    'dial_code': '+228',
    'default_locale': 'fr',
    'timezone': 'UTC',
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

ChatMessage _msg(String id, MessageKind kind, Map<String, dynamic> payload) =>
    ChatMessage(
      id: id,
      conversationId: 'c1',
      authorRole: 'vendor',
      kind: kind,
      createdAt: DateTime.utc(2026, 11, 16, 10),
      payload: payload,
    );

/// Capacité de commerce factice : gestes enregistrés.
class _Commerce implements ChatCommerce {
  final done = <String>[];
  bool simulated = true;

  @override
  Future<Result<void>> acceptQuote(String quoteId) async {
    done.add('quote:$quoteId');
    return const Ok(null);
  }

  @override
  Future<Result<void>> claimCoupon(String couponId) async {
    done.add('coupon:$couponId');
    return const Ok(null);
  }

  @override
  Future<Result<void>> payRequest(
    String code, {
    required String idempotencyKey,
  }) async {
    done.add('pay:$code');
    return const Ok(null);
  }

  @override
  Future<Result<({String? text, bool simulated})>> transcribe(
    String messageId,
  ) async =>
      Ok((text: simulated ? null : 'Je passe à 18 h', simulated: simulated));

  @override
  Future<Result<List<QuoteChoice>>> quoteChoices() async => const Ok([
    QuoteChoice(variantId: 'v1', label: 'Tomates · le tas', priceMinor: 500),
  ]);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('devis, paiement, coupon : gestes transmis', () async {
    final commerce = _Commerce();
    final service = MemoryChatService.demo(
      role: ChatRole.client,
      config: _config,
    )..commerce = commerce;
    final vm = ChatViewModel(
      service: service,
      conversationId: 'c1',
      refreshEvery: null,
    );
    await vm.load();
    expect(
      await vm.acceptQuote(_msg('m1', MessageKind.quote, {'quote_id': 'q1'})),
      isTrue,
    );
    expect(
      await vm.payRequest(
        _msg('m2', MessageKind.paymentRequest, {'code': 'AB12CD'}),
      ),
      isTrue,
    );
    expect(
      await vm.claimCoupon(_msg('m3', MessageKind.coupon, {'coupon_id': 'k1'})),
      isTrue,
    );
    expect(commerce.done, ['quote:q1', 'pay:AB12CD', 'coupon:k1']);
  });

  test('transcription : simulée et signalée, puis réelle', () async {
    final commerce = _Commerce();
    final service = MemoryChatService.demo(
      role: ChatRole.client,
      config: _config,
    )..commerce = commerce;
    final vm = ChatViewModel(
      service: service,
      conversationId: 'c1',
      refreshEvery: null,
    );
    final voice = _msg('a1', MessageKind.audio, const {});
    await vm.transcribe(voice);
    expect(vm.simulatedTranscripts, contains('a1'));
    commerce.simulated = false;
    await vm.transcribe(_msg('a2', MessageKind.audio, const {}));
    expect(vm.transcripts['a2'], 'Je passe à 18 h');
  });

  test('montants saisis sans flottant', () {
    expect(minorFromText('1500', 0), 1500);
    expect(minorFromText('2,50', 2), 250);
    expect(minorFromText('2.5', 2), 250);
    expect(minorFromText('2,505', 2), isNull);
    expect(textFromMinor(250, 2), '2,50');
  });

  testWidgets('bulles : devis à accepter, coupon à garder, position', (
    tester,
  ) async {
    final previous = DymMap.engine;
    DymMap.engine = FakeMapEngine();
    addTearDown(() => DymMap.engine = previous);
    final service = MemoryChatService.demo(
      role: ChatRole.client,
      config: _config,
    )..commerce = _Commerce();
    final vm = ChatViewModel(
      service: service,
      conversationId: 'c1',
      refreshEvery: null,
    );
    await vm.load();
    Widget bubble(ChatMessage m) => CommerceBubble(
      message: m,
      vm: vm,
      mine: false,
      meta: const SizedBox.shrink(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: DymTheme.light(),
        locale: const Locale('fr'),
        localizationsDelegates: DymLocalizations.localizationsDelegates,
        supportedLocales: DymLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            children: [
              bubble(
                _msg('q', MessageKind.quote, {
                  'quote_id': 'q1',
                  'status': 'pending',
                  'total_minor': 1200,
                  'lines': [
                    {
                      'name': 'Tomates',
                      'quantity': 3,
                      'price_minor': 400,
                      'list_price_minor': 500,
                    },
                  ],
                }),
              ),
              bubble(
                _msg('k', MessageKind.coupon, {
                  'coupon_id': 'k1',
                  'percent': 20,
                  'expired': false,
                }),
              ),
              bubble(
                _msg('l', MessageKind.location, {
                  'latitude': 6.13,
                  'longitude': 1.22,
                }),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Accepter et mettre au panier'), findsOneWidget);
    expect(find.text('Garder le coupon'), findsOneWidget);
    expect(find.text('Position'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
