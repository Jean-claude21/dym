import 'package:dym_client/features/shopping/shopping_service.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:stacked/stacked.dart';

/// Erreurs affichées par l'assistant de courses.
enum ShoppingError { name, items, tooMany, offline, generic }

ShoppingError shoppingErrorOf(Failure failure) => switch (failure) {
  NetworkFailure() => ShoppingError.offline,
  ValidationFailure(message: 'invalid_name') => ShoppingError.name,
  ValidationFailure(message: 'invalid_items' || 'invalid_quantity') =>
    ShoppingError.items,
  ValidationFailure(message: 'too_many_lists') => ShoppingError.tooMany,
  _ => ShoppingError.generic,
};

/// Nom tiré d'une description : 40 caractères au plus, coupé au dernier mot
/// entier, sans ponctuation finale.
String shortName(String text) {
  final value = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (value.length <= ShoppingList.maxNameLength) return value;
  final cut = value.substring(0, ShoppingList.maxNameLength + 1);
  final space = cut.lastIndexOf(' ');
  final head = space > 0
      ? cut.substring(0, space)
      : cut.substring(0, ShoppingList.maxNameLength);
  return head.replaceAll(RegExp(r'[\s,;:.\-]+$'), '');
}

/// Brouillon à ouvrir dans l'édition (nouvelle liste, habitudes, IA).
class ShoppingDraft {
  const new({this.list, this.name = '', this.items = const []});

  /// Liste existante à modifier.
  final ShoppingList? list;
  final String name;
  final List<ShoppingItem> items;
}

/// « Mes courses » : listes, liste habituelle, liste décrite à l'IA.
class ShoppingListsViewModel extends BaseViewModel {
  new({required this.service});

  final ShoppingService service;

  List<ShoppingList> lists = const [];
  bool ready = false;
  bool aiEnabled = false;
  Failure? failure;

  /// Action en cours (habitudes, IA, suppression).
  bool acting = false;

  /// Habitudes demandées sans résultat.
  bool noHabits = false;

  /// Réponse de l'IA : rien, ou en échec.
  bool aiNothing = false;
  bool aiFailed = false;
  ShoppingError? problem;

  Future<void> load() async {
    failure = null;
    setBusy(true);
    final (result, ai) = (await service.lists(), await service.aiEnabled());
    aiEnabled = ai;
    switch (result) {
      case Ok(:final value):
        lists = value;
        ready = true;
      case Err(failure: final f):
        failure = f;
    }
    setBusy(false);
  }

  void _start() {
    acting = true;
    noHabits = false;
    aiNothing = false;
    aiFailed = false;
    problem = null;
    notifyListeners();
  }

  /// Brouillon tiré des habitudes ; `null` : rien à proposer (message).
  Future<ShoppingDraft?> fromHabits(String name) async {
    if (acting) return null;
    _start();
    final result = await service.habits();
    acting = false;
    ShoppingDraft? draft;
    switch (result) {
      case Ok(:final value) when value.isNotEmpty:
        draft = ShoppingDraft(name: name, items: value);
      case Ok():
        noHabits = true;
      case Err(failure: final f):
        problem = shoppingErrorOf(f);
    }
    notifyListeners();
    return draft;
  }

  /// Brouillon proposé par l'IA ; `null` : rien, ou IA en échec (message).
  Future<ShoppingDraft?> describe(String text) async {
    final value = text.trim();
    if (acting || value.length < 2) return null;
    _start();
    final result = await service.suggest(value);
    acting = false;
    ShoppingDraft? draft;
    switch (result) {
      case Ok(:final value) when value.isNotEmpty:
        draft = ShoppingDraft(name: shortName(text), items: value);
      case Ok():
        aiNothing = true;
      case Err(failure: NetworkFailure()):
        problem = ShoppingError.offline;
      case Err():
        aiFailed = true;
    }
    notifyListeners();
    return draft;
  }

  Future<bool> delete(ShoppingList list) async {
    if (acting) return false;
    _start();
    final result = await service.delete(list.id);
    acting = false;
    switch (result) {
      case Ok():
        lists = [
          for (final l in lists)
            if (l.id != list.id) l,
        ];
      case Err(failure: final f):
        problem = shoppingErrorOf(f);
    }
    notifyListeners();
    return result.isOk;
  }
}

/// Édition d'une liste : nom, articles et quantités, rappel.
class ShoppingEditViewModel extends BaseViewModel {
  new({required this.service, required ShoppingDraft draft, DateTime? today})
    : id = draft.list?.id,
      name = draft.list?.name ?? draft.name,
      items = [...?draft.list?.items, ...draft.items],
      period = draft.list?.period,
      startsOn = draft.list?.nextDueOn,
      _today = today ?? DateTime.now();

  final ShoppingService service;
  final String? id;
  final DateTime _today;

  String name;
  List<ShoppingItem> items;
  ShoppingPeriod? period;
  DateTime? startsOn;
  bool saving = false;
  ShoppingError? problem;

  DateTime get today => DateTime(_today.year, _today.month, _today.day);

  bool get canAdd => items.length < ShoppingList.maxItems;

  /// Premier rappel affiché : choisi, sinon dans une période.
  DateTime? get firstReminder => switch (period) {
    null => null,
    final p => startsOn ?? today.add(Duration(days: p.days)),
  };

  void setName(String value) {
    name = value;
    if (problem == ShoppingError.name) problem = null;
    notifyListeners();
  }

  void add(String label) {
    final value = label.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty || !canAdd) return;
    items = [...items, ShoppingItem(label: value)];
    if (problem == ShoppingError.items) problem = null;
    notifyListeners();
  }

  void remove(int index) {
    items = [...items]..removeAt(index);
    notifyListeners();
  }

  void setQuantity(int index, int quantity) {
    items = [...items]..[index] = items[index].withQuantity(quantity);
    notifyListeners();
  }

  void setPeriod(ShoppingPeriod? value) {
    period = value;
    if (value == null) startsOn = null;
    notifyListeners();
  }

  void setStartsOn(DateTime value) {
    startsOn = DateTime(value.year, value.month, value.day);
    notifyListeners();
  }

  /// Enregistre ; vérifie d'abord ce qui peut l'être à l'écran (le serveur
  /// reste juge).
  Future<ShoppingList?> save() async {
    if (saving) return null;
    if (name.trim().isEmpty) {
      problem = ShoppingError.name;
      notifyListeners();
      return null;
    }
    if (items.isEmpty) {
      problem = ShoppingError.items;
      notifyListeners();
      return null;
    }
    saving = true;
    problem = null;
    notifyListeners();
    final result = await service.save(
      id: id,
      name: name.trim(),
      items: items,
      period: period,
      startsOn: period == null ? null : firstReminder,
    );
    saving = false;
    ShoppingList? saved;
    switch (result) {
      case Ok(:final value):
        saved = value;
      case Err(failure: final f):
        problem = shoppingErrorOf(f);
    }
    notifyListeners();
    return saved;
  }
}
