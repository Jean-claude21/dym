@Tags(['neon'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';
import 'package:test/test.dart';

/// Commande de bout en bout sur une branche Neon (spec 009), avec les dépôts
/// de l'app : deux vendeuses ouvrent leur boutique et publient un produit,
/// une cliente enregistre une adresse, remplit un panier multi-boutiques et
/// commande ; rejeu, lecture limitée, nettoyage.
///
/// Ignoré sans `NEON_LIVE_AUTH_URL`, `NEON_LIVE_DATA_API_URL`,
/// `NEON_LIVE_FUNCTIONS_URL`. Les comptes sont créés pour l'essai (adresses
/// `example.com`, non routables) puis supprimés. Aucun lieu n'est écrit ici :
/// le premier pays actif et ses quartiers viennent du référentiel.
void main() {
  final env = Platform.environment;
  final authUrl = env['NEON_LIVE_AUTH_URL'];
  final skip = [
    authUrl,
    env['NEON_LIVE_DATA_API_URL'],
    env['NEON_LIVE_FUNCTIONS_URL'],
  ].any((v) => v == null || v.isEmpty);

  final run = Random.secure().nextInt(1 << 32).toRadixString(36);
  final accounts = <NeonClient>[];

  Future<NeonClient> signUp(String who) async {
    final email = 'dym-e2e-$who-$run@example.com';
    final password = base64Url.encode(
      List.generate(18, (_) => Random.secure().nextInt(256)),
    );
    await _post('$authUrl/sign-up/email', {
      'name': who,
      'email': email,
      'password': password,
    });
    final signIn = await _post('$authUrl/sign-in/email', {
      'email': email,
      'password': password,
    });
    final user = signIn.body['user'] as Map<String, dynamic>;
    final store = InMemorySessionStore();
    await store.write(
      NeonSession(
        sessionToken: signIn.body['token'] as String,
        accessToken: 'à renouveler',
        accessTokenExpiresAt: DateTime.utc(2000),
        userId: user['id'] as String,
        sessionCookie: signIn.cookie,
      ),
    );
    final neon = NeonClient(
      config: NeonConfig(
        authUrl: Uri.parse(authUrl!),
        dataApiUrl: Uri.parse(env['NEON_LIVE_DATA_API_URL']!),
        functionsUrl: Uri.parse(env['NEON_LIVE_FUNCTIONS_URL']!),
      ),
      sessionStore: store,
    );
    expect((await neon.auth.restore()).isOk, isTrue, reason: who);
    accounts.add(neon);
    return neon;
  }

  Future<T> ok<T>(Future<Result<T>> call, [String? what]) async {
    final result = await call;
    expect(result.isOk, isTrue, reason: '$what : $result');
    return result.valueOrNull as T;
  }

  /// Boutique complète, ouverte tous les jours, qui livre [zones] et accepte
  /// le cash ; un produit publié à [price]. Renvoie (boutique, variante).
  Future<(String, String)> openStore(
    NeonClient neon, {
    required String name,
    required String origin,
    required String zoneId,
    required List<String> zones,
    required String categoryId,
    required List<String> methodIds,
    required int price,
    bool pickup = false,
  }) async {
    final data = neon.data;
    await ok(
      data.rpc<Object?>(
        'complete_profile',
        params: {'p_first_name': name, 'p_zone_id': zoneId, 'p_app': 'vendor'},
      ),
      'profil vendeuse',
    );
    final store = await ok(
      data.rpc<Map<String, dynamic>>('start_store', params: {'p_name': name}),
      'boutique',
    );
    final storeId = store['id'] as String;
    for (final (fn, params) in [
      (
        'update_store',
        {
          'p_patch': {
            'origin': origin,
            'zone_id': zoneId,
            'main_category_id': categoryId,
            'offers_pickup': pickup,
          },
        },
      ),
      ('set_store_pickup_address', {'p_address': 'Adresse de test'}),
      ('set_store_delivery_zones', {'p_zone_ids': zones}),
      (
        'set_store_hours',
        {
          'p_hours': [
            for (var d = 1; d <= 7; d++)
              {'weekday': d, 'opens_at': '00:00', 'closes_at': '23:59'},
          ],
        },
      ),
      ('set_store_payment_methods', {'p_method_ids': methodIds}),
      ('publish_store', <String, Object?>{}),
    ]) {
      await ok(data.rpc<Object?>(fn, params: params), fn);
    }
    final productId = Uuid.v4();
    final variantId = Uuid.v4();
    await ok(
      data.rpc<Object?>(
        'save_product',
        params: {
          'p_product': {
            'id': productId,
            'name': 'Produit $name',
            'category_id': categoryId,
            'price_minor': price,
            'photo_keys': ['stores/$storeId/products/$productId.jpg'],
            'variants': [
              {'id': variantId, 'stock_quantity': 10},
            ],
          },
        },
      ),
      'produit',
    );
    await ok(
      data.rpc<Object?>('publish_product', params: {'p_id': productId}),
      'publication',
    );
    return (storeId, variantId);
  }

  tearDownAll(() async {
    // Clientes d'abord : leurs achats partent avec elles, puis les boutiques.
    for (final neon in accounts.reversed) {
      await neon.data.rpc<Object?>('delete_my_account');
    }
  });

  test(
    'commande multi-boutiques de bout en bout',
    () async {
      final vendorA = await signUp('va');
      final vendorB = await signUp('vb');
      final client = await signUp('cl');
      final other = await signUp('ot');

      // Référentiel : premier pays actif, deux quartiers, un rayon, le cash.
      final reference = ReferenceRepository(client.data);
      final country = (await ok(reference.countries(), 'pays')).first;
      final config = await ok(reference.countryConfig(country.code), 'config');
      final zones = config.zones.take(2).map((z) => z.id).toList();
      expect(zones, hasLength(2));
      final category = config.topCategories.first.id;
      final cash = await ok(
        client.data.run(
          (db) => db
              .from('payment_methods')
              .select('id')
              .eq('country_code', country.code)
              .eq('provider_code', 'cash'),
        ),
        'cash',
      );
      final cashId = ((cash as List).first as Map)['id'] as String;

      final (storeA, variantA) = await openStore(
        vendorA,
        name: 'E2E A $run',
        origin: 'marche',
        zoneId: zones[0],
        zones: zones,
        categoryId: category,
        methodIds: [cashId],
        price: 900,
      );
      final (storeB, variantB) = await openStore(
        vendorB,
        name: 'E2E B $run',
        origin: 'maison',
        zoneId: zones[1],
        zones: zones,
        categoryId: category,
        methodIds: [cashId],
        price: 400,
        pickup: true,
      );

      // Cliente : profil, adresse par défaut, panier de deux boutiques.
      await ok(
        client.data.rpc<Object?>(
          'complete_profile',
          params: {
            'p_first_name': 'Cliente',
            'p_zone_id': zones[0],
            'p_app': 'client',
          },
        ),
        'profil cliente',
      );
      final addresses = AddressRepository(client.data);
      final saved = await ok(
        addresses.save(
          AddressInput(
            id: Uuid.v4(),
            kind: AddressKind.home,
            zoneId: zones[0],
            landmark: 'Repère de test',
            phone: '+000 0000 0000',
          ),
        ),
        'adresse',
      );
      expect(saved.single.isDefault, isTrue);

      final cart = CartRepository(client.data);
      await ok(cart.add(variantA, quantity: 2), 'ajout A');
      final quote = await ok(cart.add(variantB), 'ajout B');
      expect(quote.storeCount, 2);
      expect(quote.subtotalMinor, 2200);
      expect(
        quote.blocking,
        isFalse,
        reason: '${quote.stores.map((s) => s.issues)}',
      );
      expect(quote.addressId, saved.single.id);
      expect(quote.currency?.code, config.currency.code);
      expect(
        quote.totalMinor,
        quote.subtotalMinor + quote.deliveryFeeMinor,
        reason: 'total = sous-total + frais',
      );

      // Retrait chez B : un seul ramassage.
      final withPickup = await ok(
        cart.cart(modes: {storeB: Fulfillment.pickup}),
        'devis retrait',
      );
      expect(withPickup.pickupCount, 1);
      final storeQuoteB = withPickup.stores.firstWhere((s) => s.id == storeB);
      expect(storeQuoteB.deliveryFeeMinor, 0);

      // Commande, puis rejeu de la même clé.
      final orders = OrderRepository(
        functions: client.functions,
        data: client.data,
      );
      final request = OrderRequest(
        addressId: withPickup.addressId,
        modes: withPickup.modes,
        paymentMethodId: withPickup.paymentMethodId!,
        expectedTotalMinor: withPickup.totalMinor,
      );
      final key = Uuid.v4();
      final purchase = await ok(
        orders.place(request, idempotencyKey: key),
        'commande',
      );
      expect(purchase.orders, hasLength(2));
      expect(purchase.totalMinor, withPickup.totalMinor);
      expect(purchase.orders.every((o) => o.status == 'pending'), isTrue);
      expect(
        purchase.orders.firstWhere((o) => o.store.id == storeB).fulfillment,
        Fulfillment.pickup,
      );
      final replay = await ok(
        orders.place(request, idempotencyKey: key),
        'rejeu',
      );
      expect(replay.id, purchase.id, reason: 'même achat');
      expect((await ok(cart.cart(), 'panier après')).isEmpty, isTrue);
      expect(
        (await ok(orders.purchase(purchase.id), 'relecture')).totalMinor,
        purchase.totalMinor,
      );

      // Une nouvelle commande avec une autre clé : panier vide, refus.
      final empty = await orders.place(request, idempotencyKey: Uuid.v4());
      expect(empty.failureOrNull?.message, 'cart_empty');

      // Lecture : chaque vendeuse voit sa commande seulement ; une autre
      // cliente ne voit rien.
      for (final (neon, store) in [(vendorA, storeA), (vendorB, storeB)]) {
        final rows = await ok(
          neon.data.run((db) => db.from('orders').select('store_id')),
          'commandes vendeuse',
        );
        expect((rows as List).map((r) => (r as Map)['store_id']), [store]);
      }
      final foreign = await OrderRepository(
        functions: other.functions,
        data: other.data,
      ).purchase(purchase.id);
      expect(foreign.failureOrNull, isA<NotFoundFailure>());
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'paiement simulé : réussite, puis échec et paiement à la livraison',
    () async {
      final vendor = await signUp('vp');
      final client = await signUp('cp');

      final reference = ReferenceRepository(client.data);
      final country = (await ok(reference.countries(), 'pays')).first;
      final config = await ok(reference.countryConfig(country.code), 'config');
      final zones = config.zones.take(2).map((z) => z.id).toList();
      final methods = await ok(
        client.data.run(
          (db) => db
              .from('payment_methods')
              .select('id, provider_code')
              .eq('country_code', country.code),
        ),
        'moyens',
      );
      String? methodOf(String provider) => (methods as List)
          .map((m) => m as Map)
          .where((m) => m['provider_code'] == provider)
          .map((m) => m['id'] as String)
          .firstOrNull;
      final cashId = methodOf('cash')!;
      final simId = methodOf('simulator');
      if (simId == null) {
        markTestSkipped('simulateur non activé pour ${country.code}');
        return;
      }

      final (_, variant) = await openStore(
        vendor,
        name: 'E2E P $run',
        origin: 'marche',
        zoneId: zones[0],
        zones: zones,
        categoryId: config.topCategories.first.id,
        methodIds: [cashId, simId],
        price: 1500,
      );
      await ok(
        client.data.rpc<Object?>(
          'complete_profile',
          params: {
            'p_first_name': 'Payeuse',
            'p_zone_id': zones[0],
            'p_app': 'client',
          },
        ),
        'profil',
      );
      await ok(
        AddressRepository(client.data).save(
          AddressInput(
            id: Uuid.v4(),
            kind: AddressKind.home,
            zoneId: zones[0],
            landmark: 'Repère de test',
            phone: '+000 0000 0000',
          ),
        ),
        'adresse',
      );
      final cart = CartRepository(client.data);
      final orders = OrderRepository(
        functions: client.functions,
        data: client.data,
      );
      final vendorOrders = VendorOrderRepository(vendor.data);

      Future<Purchase> order() async {
        await ok(cart.add(variant), 'ajout');
        final quote = await ok(cart.cart(paymentMethodId: simId), 'devis');
        expect(quote.paymentMethods.map((m) => m.id), contains(simId));
        return await ok(
          orders.place(
            OrderRequest(
              addressId: quote.addressId,
              modes: quote.modes,
              paymentMethodId: simId,
              expectedTotalMinor: quote.totalMinor,
            ),
            idempotencyKey: Uuid.v4(),
          ),
          'commande',
        );
      }

      Future<Purchase> waitFor(String id, PaymentStatus status) async {
        for (var i = 0; i < 20; i++) {
          final p = await ok(orders.purchase(id), 'relecture');
          if (p.paymentStatus == status) return p;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        fail('état $status non atteint');
      }

      // 1. Réussite : page du simulateur, confirmation signée, vendeuse.
      final first = await order();
      expect(first.awaitingPayment, isTrue);
      final page = first.payment!.checkoutUrl!;
      expect(page, contains('/v1/payments/simulator/'));
      expect(
        await ok(vendorOrders.orders(), 'liste avant'),
        isEmpty,
        reason: 'commande non payée invisible',
      );
      expect(await _postForm('$page/succeeded'), 200);
      final paid = await waitFor(first.id, PaymentStatus.paid);
      expect(paid.payment?.status, PaymentAttemptStatus.succeeded);
      final seen = await ok(vendorOrders.orders(), 'liste après');
      expect(seen.single.isPaid, isTrue);
      final detail = await ok(vendorOrders.order(seen.single.id), 'détail');
      expect(detail.payment?.reference, first.payment!.reference);
      expect(detail.delivery?.landmark, 'Repère de test');

      // 2. Échec, réessai, échec, puis paiement à la livraison.
      final second = await order();
      expect(await _postForm('${second.payment!.checkoutUrl}/failed'), 200);
      await waitFor(second.id, PaymentStatus.failed);
      final retried = await ok(
        orders.retryPayment(second.id, idempotencyKey: Uuid.v4()),
        'réessai',
      );
      expect(retried.awaitingPayment, isTrue);
      expect(retried.payment?.checkoutUrl, isNot(second.payment!.checkoutUrl));
      expect(await _postForm('${retried.payment!.checkoutUrl}/cancelled'), 200);
      await waitFor(second.id, PaymentStatus.failed);
      final cash = await ok(orders.payOnDelivery(second.id), 'cash');
      expect(cash.paymentStatus, PaymentStatus.cashOnDelivery);
      final both = await ok(vendorOrders.orders(), 'liste finale');
      expect(both.map((o) => o.paymentStatus).toSet(), {
        PaymentStatus.paid,
        PaymentStatus.cashOnDelivery,
      });
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

/// POST sans corps (page du simulateur de paiement).
Future<int> _postForm(String url) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(url));
    final response = await request.close();
    await response.drain<void>();
    return response.statusCode;
  } finally {
    client.close();
  }
}

/// POST JSON (Neon Auth) : corps et cookie de session.
Future<({Map<String, dynamic> body, String? cookie})> _post(
  String url,
  Map<String, Object?> body,
) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(url));
    request.headers
      ..contentType = ContentType.json
      ..set('Origin', 'http://localhost');
    request.write(jsonEncode(body));
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode >= 300) {
      throw StateError('$url : ${response.statusCode} $text');
    }
    final cookie = response.cookies
        .where((c) => c.name.endsWith('session_token'))
        .map((c) => '${c.name}=${c.value}')
        .firstOrNull;
    return (body: jsonDecode(text) as Map<String, dynamic>, cookie: cookie);
  } finally {
    client.close();
  }
}
