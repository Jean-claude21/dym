import 'package:dym_client/features/discovery/discovery_service.dart';
import 'package:dym_client/features/spaces/spaces_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter/widgets.dart';

/// Espaces en mémoire (tests, galerie). Jamais en production. Reproduit les
/// règles de la base utiles à l'écran (rôle, budget, panier commun).
class MemorySpacesService implements SpacesService {
  new({required this.discovery, List<Space> spaces = const []})
    : stored = [...spaces];

  final DiscoveryService discovery;
  final List<Space> stored;
  final validated = <String>[];
  final sent = <String>[];

  /// Échec à renvoyer au prochain appel d'écriture.
  Failure? nextFailure;

  Space _find(String id) => stored.firstWhere((s) => s.id == id);

  void _put(Space space) {
    final i = stored.indexWhere((s) => s.id == space.id);
    if (i < 0) {
      stored.add(space);
    } else {
      stored[i] = space;
    }
  }

  Failure? _take() {
    final f = nextFailure;
    nextFailure = null;
    return f;
  }

  static Space _copy(
    Space s, {
    List<SpaceItem>? items,
    List<SpaceMember>? members,
    int? spent,
  }) {
    final list = items ?? s.items;
    return Space(
      id: s.id,
      name: s.name,
      joinCode: s.joinCode,
      myRole: s.myRole,
      isOwner: s.isOwner,
      currencyCode: s.currencyCode,
      monthlyBudgetMinor: s.monthlyBudgetMinor,
      spentMonthMinor: spent ?? s.spentMonthMinor,
      totalMinor: list.fold(0, (t, i) => t + i.unitPriceMinor * i.quantity),
      members: members ?? s.members,
      items: list,
    );
  }

  @override
  Future<Result<List<SpaceSummary>>> spaces() async => Ok([
    for (final s in stored)
      SpaceSummary(
        id: s.id,
        name: s.name,
        myRole: s.myRole,
        currencyCode: s.currencyCode,
        monthlyBudgetMinor: s.monthlyBudgetMinor,
        spentMonthMinor: s.spentMonthMinor,
        membersCount: s.members.length,
        itemsCount: s.items.length,
      ),
  ]);

  @override
  Future<Result<Space>> space(String id) async => Ok(_find(id));

  @override
  Future<Result<Space>> create(String name, {int? monthlyBudgetMinor}) async {
    if (_take() case final f?) return Err(f);
    final space = Space(
      id: 'sp${stored.length}',
      name: name.trim(),
      joinCode: 'ABCD2345',
      myRole: SpaceRole.payer,
      isOwner: true,
      currencyCode: 'XOF',
      monthlyBudgetMinor: monthlyBudgetMinor,
      members: const [
        SpaceMember(
          userId: 'me',
          firstName: 'Awa',
          role: SpaceRole.payer,
          isOwner: true,
          isMe: true,
        ),
      ],
    );
    stored.add(space);
    return Ok(space);
  }

  @override
  Future<Result<Space>> join(String code) async {
    if (_take() case final f?) return Err(f);
    return stored.isEmpty
        ? const Err(NotFoundFailure('unknown_code'))
        : Ok(stored.first);
  }

  @override
  Future<Result<Space>> setRole(
    String id,
    String userId,
    SpaceRole role,
  ) async {
    final s = _find(id);
    final updated = _copy(
      s,
      members: [
        for (final m in s.members)
          if (m.userId == userId)
            SpaceMember(
              userId: m.userId,
              firstName: m.firstName,
              role: role,
              isOwner: m.isOwner,
              isMe: m.isMe,
            )
          else
            m,
      ],
    );
    _put(updated);
    return Ok(updated);
  }

  @override
  Future<Result<void>> removeMember(String id, String userId) async {
    final s = _find(id);
    _put(
      _copy(
        s,
        members: [
          for (final m in s.members)
            if (m.userId != userId) m,
        ],
      ),
    );
    return const Ok(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    stored.removeWhere((s) => s.id == id);
    return const Ok(null);
  }

  @override
  Future<Result<Space>> sendCart(String id) async {
    if (_take() case final f?) return Err(f);
    sent.add(id);
    return Ok(_find(id));
  }

  @override
  Future<Result<Space>> setItem(
    String id,
    String variantId,
    int quantity,
  ) async {
    final s = _find(id);
    final updated = _copy(
      s,
      items: [
        for (final i in s.items)
          if (i.variantId != variantId)
            i
          else if (quantity > 0)
            SpaceItem(
              variantId: i.variantId,
              productId: i.productId,
              name: i.name,
              quantity: quantity,
              unitPriceMinor: i.unitPriceMinor,
              available: i.available,
              addedBy: i.addedBy,
            ),
      ],
    );
    _put(updated);
    return Ok(updated);
  }

  @override
  Future<Result<ReorderResult>> validate(String id) async {
    if (_take() case final f?) return Err(f);
    final s = _find(id);
    if (!s.canValidate) return const Err(ForbiddenFailure('not_payer'));
    if (s.overBudget) return const Err(ValidationFailure('budget_exceeded'));
    validated.add(id);
    _put(_copy(s, items: const [], spent: s.spentMonthMinor + s.totalMinor));
    return Ok(ReorderResult(added: s.items.length));
  }

  @override
  Future<Result<CountryConfig>> countryConfig() => discovery.countryConfig();

  @override
  ImageProvider photo(String objectKey) => discovery.photo(objectKey);
}
