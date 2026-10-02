import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';
import 'package:neon_kit/testing.dart';
import 'package:test/test.dart';

const _user = '6f1c2a3b-0000-4000-8000-000000000004';

const Map<String, Object?> _cash = {
  'id': 'pm1',
  'country_code': 'TG',
  'provider_code': 'cash',
  'operator_code': null,
  'label': {'fr': 'Cash à la livraison', 'en': 'Cash on delivery'},
  'sort': 1,
};

const Map<String, Object?> _cart = {
  'country_code': 'TG',
  'currency_code': 'XOF',
  'address_id': 'a1',
  'zone_id': 'z1',
  'stores': [
    {
      'id': 's1',
      'name': 'Étal de Kodjo',
      'origin': 'marche',
      'zone_name': 'Bè',
      'fulfillment': 'delivery',
      'offers_pickup': false,
      'is_open': true,
      'prep_time_minutes': 30,
      'issues': ['closed', 'teleported'],
      'subtotal_minor': 1500,
      'delivery_fee_minor': 200,
      'lines': [
        {
          'variant_id': 'v1',
          'product_id': 'p1',
          'name': 'Tomates fraîches',
          'variant_label': null,
          'unit_label': {'fr': 'le tas'},
          'photo_key': 'stores/s1/products/p1.jpg',
          'quantity': 3,
          'unit_price_minor': 500,
          'amount_minor': 1500,
          'stock_quantity': null,
          'category_id': 'c1',
          'issues': ['price_changed'],
        },
      ],
    },
  ],
  'payment_methods': [_cash],
  'payment_method_id': 'pm1',
  'item_count': 3,
  'pickup_count': 1,
  'delivery_minutes': 50,
  'subtotal_minor': 1500,
  'delivery_fee_minor': 200,
  'total_minor': 1700,
  'free_threshold_minor': 4000,
  'remaining_for_free_minor': 2500,
  'blocking': true,
};

const Map<String, Object?> _purchase = {
  'id': 'pu1',
  'created_at': '2026-10-05T10:00:00+00:00',
  'country_code': 'TG',
  'currency_code': 'XOF',
  'payment_method': _cash,
  'address': {
    'id': 'a1',
    'kind': 'home',
    'label': null,
    'zone_id': 'z1',
    'zone_name': 'Bè',
    'city_name': 'Lomé',
    'landmark': 'Portail bleu',
    'phone': '+228 90 00 00 00',
  },
  'substitution_allowed': true,
  'subtotal_minor': 1500,
  'delivery_fee_minor': 500,
  'total_minor': 2000,
  'orders': [
    {
      'id': 'o1',
      'status': 'pending',
      'fulfillment': 'delivery',
      'store': {'id': 's1', 'name': 'Étal de Kodjo', 'origin': 'marche'},
      'subtotal_minor': 1500,
      'delivery_fee_minor': 500,
      'total_minor': 2000,
      'item_count': 3,
      'items': [
        {
          'product_id': 'p1',
          'variant_id': 'v1',
          'name': 'Tomates fraîches',
          'variant_label': null,
          'unit_label': {'fr': 'le tas'},
          'unit_price_minor': 500,
          'quantity': 3,
          'amount_minor': 1500,
        },
      ],
    },
  ],
};

void main() {
  late FakeServer server;
  late CartRepository cart;
  late AddressRepository addresses;
  late OrderRepository orders;

  setUp(() async {
    server = FakeServer();
    final now = DateTime.utc(2026, 10, 5);
    final session = InMemorySessionStore();
    await session.write(
      NeonSession(
        sessionToken: 's',
        accessToken: fakeJwt(
          sub: _user,
          expiresAt: now.add(const Duration(hours: 1)),
        ),
        accessTokenExpiresAt: now.add(const Duration(hours: 1)),
        userId: _user,
      ),
    );
    final neon = NeonClient(
      config: NeonConfig(
        authUrl: Uri.parse('https://auth.test/auth'),
        dataApiUrl: Uri.parse('https://data.test/rest/v1'),
        functionsUrl: Uri.parse('https://fn.test'),
      ),
      sessionStore: session,
      adapter: server.dioAdapter,
      httpClient: server.httpClient,
      clock: () => now,
      sleep: (_) async {},
    );
    await neon.auth.restore();
    cart = CartRepository(neon.data);
    addresses = AddressRepository(neon.data);
    orders = OrderRepository(functions: neon.functions, data: neon.data);
  });

  test('panier : modes transmis, montants et problèmes de la base', () async {
    Map<Object?, Object?>? sent;
    server.on('POST', '/rest/v1/rpc/my_cart', (r) {
      sent = r.body! as Map;
      return const FakeResponse(200, _cart);
    });
    final view = (await cart.cart(
      addressId: 'a1',
      modes: {'s1': Fulfillment.pickup},
    )).valueOrNull!;
    expect(sent!['p_modes'], {'s1': 'pickup'});
    expect(sent!['p_address'], 'a1');
    expect(view.totalMinor, 1700);
    expect(view.paymentMethod?.isCash, isTrue);
    final store = view.stores.single;
    expect(store.issues, [CartStoreIssue.closed, CartStoreIssue.unknown]);
    expect(store.blocking, isTrue);
    expect(store.lines.single.issues, [CartLineIssue.priceChanged]);
    expect(store.lines.single.blocking, isFalse);
    expect(view.modes, {'s1': Fulfillment.delivery});
  });

  test('ajout : variante et quantité ; refus de la base', () async {
    Map<Object?, Object?>? sent;
    server
      ..on('POST', '/rest/v1/rpc/cart_add', (r) {
        sent = r.body! as Map;
        return const FakeResponse(200, _cart);
      })
      ..on(
        'POST',
        '/rest/v1/rpc/cart_set_quantity',
        (_) => const FakeResponse(400, {
          'code': '22023',
          'message': 'other_country',
        }),
      );
    expect((await cart.add('v1', quantity: 2)).isOk, isTrue);
    expect(sent, {'p_variant': 'v1', 'p_quantity': 2});
    final refused = await cart.setQuantity('v1', 0);
    expect(refused.failureOrNull, isA<ValidationFailure>());
    expect(refused.failureOrNull?.message, 'other_country');
  });

  test('adresses : enregistrement rejouable, liste décodée', () async {
    Map<Object?, Object?>? sent;
    server.on('POST', '/rest/v1/rpc/save_address', (r) {
      sent = r.body! as Map;
      return const FakeResponse(200, [
        {
          'id': 'a1',
          'kind': 'work',
          'label': null,
          'zone_id': 'z1',
          'zone_name': 'Bè',
          'city_name': 'Lomé',
          'country_code': 'TG',
          'landmark': 'Immeuble jaune',
          'phone': '+228 90 00 00 00',
          'latitude': 6.13,
          'longitude': 1.239,
          'is_default': true,
        },
      ]);
    });
    final list = (await addresses.save(
      const AddressInput(
        id: 'a1',
        kind: AddressKind.work,
        zoneId: 'z1',
        landmark: 'Immeuble jaune',
        phone: '+228 90 00 00 00',
        latitude: 6.13,
        longitude: 1.239,
      ),
    )).valueOrNull!;
    expect((sent!['p_address']! as Map)['kind'], 'work');
    expect(list.single.hasPosition, isTrue);
    expect(list.single.isDefault, isTrue);
  });

  test("commande : reprise sur 503 avec la même clé d'idempotence", () async {
    final keys = <String?>[];
    server.on('POST', '/v1/orders', (r) {
      keys.add(r.headers['Idempotency-Key'] ?? r.headers['idempotency-key']);
      return keys.length == 1
          ? const FakeResponse(503, {
              'error': {'code': 'unavailable', 'message': 'indisponible'},
            })
          : const FakeResponse(201, _purchase);
    });
    final result = await orders.place(
      const OrderRequest(
        paymentMethodId: 'pm1',
        modes: {'s1': Fulfillment.delivery},
        addressId: 'a1',
        expectedTotalMinor: 2000,
      ),
      idempotencyKey: 'k1',
    );
    final purchase = result.valueOrNull!;
    expect(keys, ['k1', 'k1']);
    expect(purchase.orders.single.items.single.amountMinor, 1500);
    expect(purchase.address?.zoneName, 'Bè');
    expect(purchase.paymentMethod.isCash, isTrue);
  });

  test('commande refusée : code de la base', () async {
    server.on(
      'POST',
      '/v1/orders',
      (_) => const FakeResponse(422, {
        'error': {
          'code': 'validation',
          'message': 'cart_blocked',
          'fields': {'_': 'cart_blocked'},
        },
      }),
    );
    final result = await orders.place(
      const OrderRequest(paymentMethodId: 'pm1', modes: {}),
      idempotencyKey: 'k2',
    );
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(result.failureOrNull?.message, 'cart_blocked');
  });
}
