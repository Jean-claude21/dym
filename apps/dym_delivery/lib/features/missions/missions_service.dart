import 'dart:async';

import 'package:dym_auth/dym_auth.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';

/// Livreur (spec 041) : profil, missions proposées et en cours, gestes.
abstract interface class MissionsService {
  /// Changements en direct (course proposée, commande prête…, spec 067).
  Stream<LiveSignal> get live;

  Future<Result<CountryConfig>> countryConfig();

  Future<Result<CourierProfile?>> profile();

  Future<Result<CourierProfile>> become({
    required String name,
    required String phone,
    required CourierVehicle vehicle,
    required List<String> zoneIds,
  });

  Future<Result<CourierProfile>> setOnline({required bool online});

  Future<Result<List<Mission>>> available();

  Future<Result<List<Mission>>> mine();

  Future<Result<Mission>> accept(Mission mission);

  Future<Result<void>> release(Mission mission);

  /// Geste « récupérée » (`out_for_delivery`).
  Future<Result<Mission>> advance(Mission mission, String to);

  /// Remise avec le code de la cliente (spec 042).
  Future<Result<HandoverResult>> deliver(Mission mission, String code);

  /// Gains du jour, wallet, cash à remettre (spec 043).
  Future<Result<CourierEarnings>> earnings();

  /// Point de recharge : cash de la cliente vers son wallet.
  Future<Result<CourierEarnings>> cashTopup(String code, int amountMinor);

  /// Retrait simulé du wallet.
  Future<Result<void>> withdraw(int amountMinor);

  /// Code de récupération à montrer en QR à la vendeuse (spec 096).
  Future<Result<String>> pickupCode(Mission mission);

  /// Cliente injoignable devant la porte : minutes d'attente conseillées.
  Future<Result<int>> reportUnreachable(Mission mission);

  /// Alerte SOS à l'équipe (avec la position si elle est disponible).
  Future<Result<void>> sos({Mission? mission});

  /// Lien de suivi de la course en cours, à envoyer à un proche (spec 104).
  Future<Result<Uri>> shareRun(Mission mission);

  /// Envoie la position pendant une course (rien hors course).
  Future<void> ping();
}

/// Implémentation Neon.
class NeonMissionsService implements MissionsService {
  new({
    required this._couriers,
    required this._reference,
    required this._auth,
    required this._wallet,
    this._live = LiveFeed.none,
    this._delivery,
    this._location,
    this._trackingBase,
  });

  /// Suivi et outils de course (spec 096) ; absents : simulés comme refusés.
  final DeliveryRepository? _delivery;

  /// Adresse publique des Functions (page `/t/<jeton>`).
  final Uri? _trackingBase;
  final LocationProvider? _location;

  @override
  Future<Result<String>> pickupCode(Mission mission) async =>
      await _delivery?.pickupCode(mission.orderId) ??
      const Err(NotFoundFailure('livraison'));

  @override
  Future<Result<int>> reportUnreachable(Mission mission) async =>
      await _delivery?.reportUnreachable(mission.orderId) ??
      const Err(NotFoundFailure('livraison'));

  @override
  Future<Result<Uri>> shareRun(Mission mission) async {
    final delivery = _delivery;
    final base = _trackingBase;
    if (delivery == null || base == null) {
      return const Err(NotFoundFailure('suivi'));
    }
    return (await delivery.share(mission.orderId))
        .map((share) => base.replace(path: '${base.path}/t/${share.token}'));
  }

  @override
  Future<Result<void>> sos({Mission? mission}) async {
    final delivery = _delivery;
    if (delivery == null) return const Err(NotFoundFailure('livraison'));
    final point = (await _location?.current())?.valueOrNull;
    return await delivery.sos(
      orderId: mission?.orderId,
      latitude: point?.latitude,
      longitude: point?.longitude,
    );
  }

  @override
  Future<void> ping() async {
    final delivery = _delivery;
    final location = _location;
    if (delivery == null || location == null) return;
    if ((await location.current()).valueOrNull case final point?) {
      await delivery.ping(point.latitude, point.longitude);
    }
  }

  final LiveFeed _live;

  @override
  Stream<LiveSignal> get live => _live.signals;

  final CourierRepository _couriers;
  final WalletRepository _wallet;
  String? _topupKey;
  String? _withdrawKey;
  final ReferenceRepository _reference;
  final AuthService _auth;
  CountryConfig? _config;

  @override
  Future<Result<CountryConfig>> countryConfig() async {
    final cached = _config;
    if (cached != null) return Ok(cached);
    final code = _auth.me?.profile?.countryCode;
    if (code == null) {
      return const Err(UnauthenticatedFailure('profil incomplet'));
    }
    final result = await _reference.countryConfig(code);
    if (result case Ok(:final value)) _config = value;
    return result;
  }

  @override
  Future<Result<CourierProfile?>> profile() => _couriers.myProfile();

  @override
  Future<Result<CourierProfile>> become({
    required String name,
    required String phone,
    required CourierVehicle vehicle,
    required List<String> zoneIds,
  }) => _couriers.become(
    name: name,
    phone: phone,
    vehicle: vehicle,
    zoneIds: zoneIds,
  );

  @override
  Future<Result<CourierProfile>> setOnline({required bool online}) =>
      _couriers.setOnline(online: online);

  @override
  Future<Result<List<Mission>>> available() => _couriers.available();

  @override
  Future<Result<List<Mission>>> mine() => _couriers.mine();

  @override
  Future<Result<Mission>> accept(Mission mission) =>
      _couriers.accept(mission.orderId);

  @override
  Future<Result<void>> release(Mission mission) =>
      _couriers.release(mission.orderId);

  @override
  Future<Result<Mission>> advance(Mission mission, String to) =>
      _couriers.transition(mission.orderId, to: to, expected: mission.status);

  @override
  Future<Result<HandoverResult>> deliver(Mission mission, String code) =>
      _couriers.deliver(mission.orderId, code);

  @override
  Future<Result<CourierEarnings>> earnings() => _couriers.earnings();

  @override
  Future<Result<CourierEarnings>> cashTopup(
    String code,
    int amountMinor,
  ) async {
    // Même clé tant que l'essai n'a pas abouti (nouvelle tentative réseau).
    final key = _topupKey ??= Uuid.v4();
    final result = await _couriers.cashTopup(
      code: code,
      amountMinor: amountMinor,
      key: key,
    );
    if (result is! Err || result.failureOrNull is! NetworkFailure) {
      _topupKey = null;
    }
    return result;
  }

  @override
  Future<Result<void>> withdraw(int amountMinor) async {
    final key = _withdrawKey ??= Uuid.v4();
    final result = await _wallet.withdrawSimulated(amountMinor, key);
    if (result is! Err || result.failureOrNull is! NetworkFailure) {
      _withdrawKey = null;
    }
    return result.map((_) {});
  }
}

/// Implémentation en mémoire (tests, galerie).
class MemoryMissionsService implements MissionsService {
  new({
    required this.config,
    this.current,
    List<Mission>? open,
    List<Mission>? accepted,
  }) : open = open ?? [],
       accepted = accepted ?? [];

  final CountryConfig config;
  CourierProfile? current;
  final List<Mission> open;
  final List<Mission> accepted;
  final gestures = <String>[];

  /// Signaux en direct simulés (tests).
  final liveSignals = StreamController<LiveSignal>.broadcast();

  @override
  Stream<LiveSignal> get live => liveSignals.stream;

  @override
  Future<Result<CountryConfig>> countryConfig() async => Ok(config);

  @override
  Future<Result<CourierProfile?>> profile() async => Ok(current);

  @override
  Future<Result<CourierProfile>> become({
    required String name,
    required String phone,
    required CourierVehicle vehicle,
    required List<String> zoneIds,
  }) async {
    if (zoneIds.isEmpty) return const Err(ValidationFailure('invalid_zones'));
    if (!RegExp(r'^\+?[0-9 ]{8,20}$').hasMatch(phone)) {
      return const Err(ValidationFailure('invalid_phone'));
    }
    return Ok(
      current = CourierProfile(
        displayName: name,
        phone: phone,
        vehicle: vehicle,
        zoneIds: zoneIds,
      ),
    );
  }

  @override
  Future<Result<CourierProfile>> setOnline({required bool online}) async {
    final c = current!;
    return Ok(
      current = CourierProfile(
        displayName: c.displayName,
        phone: c.phone,
        vehicle: c.vehicle,
        zoneIds: c.zoneIds,
        isOnline: online,
      ),
    );
  }

  @override
  Future<Result<List<Mission>>> available() async =>
      Ok(current?.isOnline ?? false ? List.of(open) : const []);

  @override
  Future<Result<List<Mission>>> mine() async => Ok(List.of(accepted));

  @override
  Future<Result<Mission>> accept(Mission mission) async {
    gestures.add('accept:${mission.orderId}');
    if (!open.any((m) => m.orderId == mission.orderId)) {
      return const Err(ValidationFailure('mission_taken'));
    }
    open.removeWhere((m) => m.orderId == mission.orderId);
    final taken = _with(mission, mission.status, accepted: true);
    accepted.add(taken);
    return Ok(taken);
  }

  @override
  Future<Result<void>> release(Mission mission) async {
    gestures.add('release:${mission.orderId}');
    accepted.removeWhere((m) => m.orderId == mission.orderId);
    return const Ok(null);
  }

  @override
  Future<Result<Mission>> advance(Mission mission, String to) async {
    gestures.add('$to:${mission.orderId}');
    final next = _with(mission, to, accepted: true);
    final i = accepted.indexWhere((m) => m.orderId == mission.orderId);
    if (i >= 0) accepted[i] = next;
    return Ok(next);
  }

  CourierEarnings money = const CourierEarnings();

  @override
  Future<Result<CourierEarnings>> earnings() async => Ok(money);

  @override
  Future<Result<CourierEarnings>> cashTopup(
    String code,
    int amountMinor,
  ) async {
    gestures.add('topup:$code:$amountMinor');
    if (code != '482913') return const Err(ValidationFailure('invalid_code'));
    return Ok(
      money = CourierEarnings(
        todayCount: money.todayCount,
        todayFeesMinor: money.todayFeesMinor,
        walletMinor: money.walletMinor,
        cash: [
          ...money.cash,
          CourierCashLine(amountMinor: amountMinor),
        ],
      ),
    );
  }

  @override
  Future<Result<void>> withdraw(int amountMinor) async {
    gestures.add('withdraw:$amountMinor');
    if (amountMinor > money.walletMinor) {
      return const Err(ValidationFailure('wallet_insufficient'));
    }
    money = CourierEarnings(
      todayCount: money.todayCount,
      todayFeesMinor: money.todayFeesMinor,
      walletMinor: money.walletMinor - amountMinor,
      cash: money.cash,
    );
    return const Ok(null);
  }

  /// Codes de remise attendus (tests) : par commande.
  final codes = <String, String>{};

  @override
  Future<Result<HandoverResult>> deliver(Mission mission, String code) async {
    gestures.add('deliver:${mission.orderId}:$code');
    if (codes[mission.orderId] != code) {
      return const Ok(HandoverResult(ok: false, attemptsLeft: 4));
    }
    final done = _with(mission, 'delivered', accepted: true);
    final i = accepted.indexWhere((m) => m.orderId == mission.orderId);
    if (i >= 0) accepted[i] = done;
    return Ok(HandoverResult(ok: true, mission: done));
  }

  static Mission _with(Mission m, String status, {required bool accepted}) =>
      Mission(
        orderId: m.orderId,
        status: status,
        createdAt: m.createdAt,
        deliveryFeeMinor: m.deliveryFeeMinor,
        currencyCode: m.currencyCode,
        itemCount: m.itemCount,
        store: m.store,
        customer: m.customer,
        purchaseId: m.purchaseId,
        runSize: m.runSize,
        storage: m.storage,
        acceptedAt: accepted ? DateTime(2026, 11, 10, 10) : null,
        next: switch (status) {
          'ready' => const ['out_for_delivery'],
          'out_for_delivery' => const ['delivered'],
          _ => const [],
        },
      );

  /// Codes de récupération, signalements, SOS et positions (spec 096).
  final pickupCodes = <String, String>{};
  final unreachable = <String>[];
  int sosCount = 0;
  int pings = 0;

  @override
  Future<Result<String>> pickupCode(Mission mission) async {
    final code = pickupCodes[mission.orderId];
    return code == null ? const Err(NotFoundFailure('code')) : Ok(code);
  }

  @override
  Future<Result<int>> reportUnreachable(Mission mission) async {
    unreachable.add(mission.orderId);
    return const Ok(10);
  }

  @override
  Future<Result<Uri>> shareRun(Mission mission) async {
    gestures.add('share:${mission.orderId}');
    return Ok(Uri.parse('https://dym.test/t/${mission.orderId}'));
  }

  @override
  Future<Result<void>> sos({Mission? mission}) async {
    sosCount++;
    return const Ok(null);
  }

  @override
  Future<void> ping() async => pings++;
}
