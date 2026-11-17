import 'package:dym_client/features/wallet/people/people_wallet.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

/// Avoir entre personnes en mémoire : codes connus, gestes enregistrés.
class _People implements PeopleWalletService {
  final done = <String>[];

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(togoConfig());

  @override
  Future<Result<PeopleWallet>> overview() async => const Ok(
    PeopleWallet(
      handle: 'AWA12345',
      requests: [
        PeopleRequest(
          id: 'r1',
          amountMinor: 500,
          currencyCode: 'XOF',
          toPay: true,
          otherName: 'Mia',
        ),
      ],
    ),
  );

  @override
  Future<Result<String?>> recipient(String handle) async =>
      Ok(handle == 'MIA12345' ? 'Mia' : null);

  @override
  Future<Result<void>> send(String h, int a, {String? note}) async {
    done.add('send:$h:$a');
    return a > 10000
        ? const Err(ValidationFailure('wallet_insufficient'))
        : const Ok(null);
  }

  @override
  Future<Result<void>> request(String h, int a, {String? note}) async {
    done.add('request:$h:$a');
    return const Ok(null);
  }

  @override
  Future<Result<void>> answer(String id, {required bool pay}) async {
    done.add('answer:$id:$pay');
    return const Ok(null);
  }

  @override
  Future<Result<void>> topupFor(String h, int a) async {
    done.add('topup:$h:$a');
    return const Ok(null);
  }

  @override
  Future<Result<Family>> family() async => const Ok(Family());

  @override
  Future<Result<Family>> invite(String h) async => const Ok(Family());

  @override
  Future<Result<Family>> accept(String p) async => const Ok(Family());

  @override
  Future<Result<Family>> setRules(
    String c, {
    int? allowanceMinor,
    int everyDays = 7,
    int? dailyLimitMinor,
  }) async {
    done.add('rules:$c:$allowanceMinor:$dailyLimitMinor');
    return const Ok(Family());
  }

  @override
  Future<Result<Family>> setCategories(String c, List<String> ids) async {
    done.add('categories:$c:${ids.join(',')}');
    return const Ok(Family());
  }
}

void main() {
  test('envoyer, demander, recharger, payer une demande (spec 100)', () async {
    final service = _People();
    final vm = PeopleWalletViewModel(service: service);
    await vm.load();
    expect(vm.wallet?.qr, 'DYM-P2P:AWA12345');
    expect(vm.minor('1500'), 1500, reason: 'franc CFA : sans décimales');
    expect(await vm.run(PeopleAction.send, 'MIA12345', 2000), isTrue);
    expect(await vm.run(PeopleAction.request, 'MIA12345', 500), isTrue);
    expect(await vm.run(PeopleAction.topupFor, 'MIA12345', 1000), isTrue);
    expect(await vm.answer(vm.wallet!.requests.single, pay: true), isTrue);
    expect(service.done, [
      'send:MIA12345:2000',
      'request:MIA12345:500',
      'topup:MIA12345:1000',
      'answer:r1:true',
    ]);
  });

  test('refus de la base : message clair', () async {
    final vm = PeopleWalletViewModel(service: _People());
    await vm.load();
    expect(await vm.run(PeopleAction.send, 'MIA12345', 99999), isFalse);
    expect(vm.actionFailure?.message, 'wallet_insufficient');
  });

  test('rayons autorisés et mouvements nommés (spec 104)', () async {
    final people = _People();
    final vm = PeopleWalletViewModel(service: people);
    await vm.setCategories(
      const FamilyMember(userId: 'yao', firstName: 'Yao', active: true),
      ['fruits'],
    );
    expect(people.done, contains('categories:yao:fruits'));
    final sent = WalletMovement.fromJson(const {
      'id': 't1',
      'kind': 'p2p_sent',
      'amount_minor': -1000,
      'occurred_at': '2026-11-17T08:00:00Z',
      'counterpart': 'Yao',
    });
    expect(sent.kind, WalletMovementKind.p2pSent);
    expect(sent.counterpart, 'Yao');
    expect(
      WalletMovementKind.parse('qr_payment'),
      WalletMovementKind.qrPayment,
    );
  });
}
