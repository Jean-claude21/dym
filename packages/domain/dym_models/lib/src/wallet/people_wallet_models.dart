import 'package:meta/meta.dart';

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;
int _int(Object? v) => (v as num?)?.toInt() ?? 0;

/// Mouvement d'avoir entre personnes (spec 100) : prénom de l'autre seul.
@immutable
class PeopleTransfer {
  const new({
    required this.id,
    required this.kind,
    required this.amountMinor,
    required this.currencyCode,
    required this.incoming,
    required this.otherName,
    required this.createdAt,
    this.note,
  });

  factory fromJson(Map<String, dynamic> j) => PeopleTransfer(
    id: j['id'] as String,
    kind: j['kind'] as String? ?? 'send',
    amountMinor: _int(j['amount_minor']),
    currencyCode: j['currency_code'] as String? ?? '',
    incoming: j['incoming'] as bool? ?? false,
    otherName: j['other_name'] as String? ?? '',
    createdAt: _date(j['created_at']) ?? DateTime.now(),
    note: j['note'] as String?,
  );

  final String id;

  /// `send`, `request_paid`, `topup_for`, `allowance`.
  final String kind;
  final int amountMinor;
  final String currencyCode;
  final bool incoming;
  final String otherName;
  final DateTime createdAt;
  final String? note;
}

/// Demande d'avoir en cours.
@immutable
class PeopleRequest {
  const new({
    required this.id,
    required this.amountMinor,
    required this.currencyCode,
    required this.toPay,
    required this.otherName,
    this.note,
  });

  factory fromJson(Map<String, dynamic> j) => PeopleRequest(
    id: j['id'] as String,
    amountMinor: _int(j['amount_minor']),
    currencyCode: j['currency_code'] as String? ?? '',
    toPay: j['to_pay'] as bool? ?? false,
    otherName: j['other_name'] as String? ?? '',
    note: j['note'] as String?,
  );

  final String id;
  final int amountMinor;
  final String currencyCode;

  /// Vrai : c'est à moi de payer ; faux : j'attends la réponse.
  final bool toPay;
  final String otherName;
  final String? note;
}

/// Avoir entre personnes : code personnel, mouvements, demandes.
@immutable
class PeopleWallet {
  const new({
    required this.handle,
    this.transfers = const [],
    this.requests = const [],
  });

  factory fromJson(Map<String, dynamic> j) => PeopleWallet(
    handle: j['handle'] as String? ?? '',
    transfers: [
      for (final t in j['transfers'] as List? ?? const [])
        PeopleTransfer.fromJson((t as Map).cast()),
    ],
    requests: [
      for (final r in j['requests'] as List? ?? const [])
        PeopleRequest.fromJson((r as Map).cast()),
    ],
  );

  final String handle;
  final List<PeopleTransfer> transfers;
  final List<PeopleRequest> requests;

  /// Contenu du QR personnel.
  String get qr => 'DYM-P2P:$handle';
}

/// Lien familial vu par le parent (enfant) ou par l'enfant (parent).
@immutable
class FamilyMember {
  const new({
    required this.userId,
    required this.firstName,
    required this.active,
    this.currencyCode,
    this.balanceMinor,
    this.spentTodayMinor,
    this.allowanceMinor,
    this.allowanceEveryDays = 7,
    this.dailyLimitMinor,
  });

  factory fromJson(Map<String, dynamic> j) => FamilyMember(
    userId: j['user_id'] as String,
    firstName: j['first_name'] as String? ?? '',
    active: j['status'] == 'active',
    currencyCode: j['currency_code'] as String?,
    balanceMinor: (j['balance_minor'] as num?)?.toInt(),
    spentTodayMinor: (j['spent_today_minor'] as num?)?.toInt(),
    allowanceMinor: (j['allowance_minor'] as num?)?.toInt(),
    allowanceEveryDays: switch (_int(j['allowance_every_days'])) {
      0 => 7,
      final d => d,
    },
    dailyLimitMinor: (j['daily_limit_minor'] as num?)?.toInt(),
  );

  final String userId;
  final String firstName;
  final bool active;
  final String? currencyCode;
  final int? balanceMinor;
  final int? spentTodayMinor;
  final int? allowanceMinor;
  final int allowanceEveryDays;
  final int? dailyLimitMinor;
}

/// Famille : mes enfants (vue parentale) et mes parents (invitations).
@immutable
class Family {
  const new({this.children = const [], this.parents = const []});

  factory fromJson(Map<String, dynamic> j) => Family(
    children: [
      for (final c in j['children'] as List? ?? const [])
        FamilyMember.fromJson((c as Map).cast()),
    ],
    parents: [
      for (final p in j['parents'] as List? ?? const [])
        FamilyMember.fromJson((p as Map).cast()),
    ],
  );

  final List<FamilyMember> children;
  final List<FamilyMember> parents;
}
