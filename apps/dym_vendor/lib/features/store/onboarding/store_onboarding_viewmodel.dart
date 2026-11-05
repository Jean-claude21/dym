import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_vendor/features/store/store_format.dart';
import 'package:dym_vendor/features/store/store_service.dart';
import 'package:stacked/stacked.dart';

/// Les 7 étapes de l'onboarding (spec 006, US1).
enum StoreStep {
  name,
  origin,
  address,
  category,
  delivery,
  payment,
  hours;

  /// Numéro affiché (1 à 7), aussi `stores.onboarding_step`.
  int get number => index + 1;

  static StoreStep of(int number) => values[(number - 1).clamp(0, 6)];
}

/// Horaires d'un jour dans le formulaire (fermé : non envoyé).
class DayHours {
  new({
    required this.weekday,
    this.open = false,
    String? opensAt,
    String? closesAt,
  }) : opensAt = opensAt ?? '07:00',
       closesAt = closesAt ?? '19:00';

  final int weekday;
  bool open;
  String opensAt;
  String closesAt;

  bool get isValid => !open || opensAt.compareTo(closesAt) < 0;
}

/// Onboarding de la boutique : une étape à la fois, chaque étape enregistrée
/// en base avant de passer à la suivante (reprise après interruption, US2).
///
/// [editStep] : réglage d'une seule étape depuis « Ma boutique » (US4).
class StoreOnboardingViewModel extends BaseViewModel {
  new({
    required this._service,
    required this._onOpened,
    this.editStep,
    this._onSaved,
  });

  final StoreService _service;

  /// Boutique ouverte (fin de l'étape 7).
  final void Function(MyStore store, CountryConfig config) _onOpened;

  /// Réglage enregistré (mode [editStep]).
  final void Function(MyStore store)? _onSaved;

  final StoreStep? editStep;

  static const nameMin = 2;
  static const nameMax = 60;
  static const descriptionMax = 280;
  static const addressMin = 3;
  static const addressMax = 200;

  CountryConfig? _config;
  MyStore? _store;
  Failure? _loadFailure;
  Failure? _saveFailure;
  bool _incomplete = false;
  StoreStep _step = StoreStep.name;

  String name = '';
  String description = '';
  String? origin;
  String? zoneId;
  String address = '';
  String landmark = '';
  String? categoryId;
  final Set<String> deliveryZoneIds = {};
  int prepTimeMinutes = 30;
  bool offersPickup = false;
  List<PaymentOption> paymentOptions = const [];
  final Set<String> paymentMethodIds = {};
  final List<DayHours> hours = [
    for (var day = 1; day <= 7; day++) DayHours(weekday: day, open: day <= 6),
  ];

  CountryConfig? get config => _config;
  MyStore? get store => _store;
  StoreStep get step => _step;
  bool get isEditing => editStep != null;

  /// Chargement initial impossible.
  Failure? get loadFailure => _loadFailure;

  /// Dernier enregistrement refusé ou impossible.
  Failure? get saveFailure => _saveFailure;
  bool get offline => (_loadFailure ?? _saveFailure) is NetworkFailure;

  /// Ouverture refusée : boutique incomplète (base).
  bool get incomplete => _incomplete;

  bool get ready => _config != null;

  /// Retour possible vers l'étape précédente.
  bool get canGoBack => !isEditing && _step != StoreStep.name;

  /// Quartiers de la ville de la boutique (étape 5), ou de la première
  /// ville du pays tant que le quartier n'est pas choisi.
  List<Zone> get cityZones {
    final cfg = _config;
    if (cfg == null) return const [];
    final cityId =
        cfg.zones.where((z) => z.id == zoneId).firstOrNull?.cityId ??
        cfg.cities.firstOrNull?.id;
    return cityId == null ? const [] : cfg.zonesOf(cityId);
  }

  String? get zoneName =>
      _config?.zones.where((z) => z.id == zoneId).firstOrNull?.name;

  bool get nameValid {
    final length = name.trim().length;
    return length >= nameMin && length <= nameMax;
  }

  bool get hoursValid =>
      hours.any((h) => h.open) && hours.every((h) => h.isValid);

  /// L'étape courante peut être enregistrée (bouton actif).
  bool get canContinue => switch (_step) {
    StoreStep.name => nameValid && description.length <= descriptionMax,
    StoreStep.origin => origin != null,
    StoreStep.address =>
      zoneId != null &&
          address.trim().length >= addressMin &&
          address.trim().length <= addressMax &&
          landmark.length <= addressMax,
    StoreStep.category => categoryId != null,
    StoreStep.delivery => deliveryZoneIds.isNotEmpty,
    StoreStep.payment => paymentMethodIds.isNotEmpty,
    StoreStep.hours => hoursValid,
  };

  Future<void> load() async {
    _loadFailure = null;
    setBusy(true);
    final config = await _service.countryConfig();
    final store = await _service.myStore();
    switch ((config, store)) {
      case (Ok(value: final cfg), Ok(value: final current)):
        _config = cfg;
        _apply(current);
        _step =
            editStep ??
            StoreStep.of(current?.onboardingStep ?? StoreStep.name.number);
        zoneId ??= _service.profileZoneId;
        if (_step == StoreStep.payment) await _loadPaymentOptions();
      case (Err(:final failure), _) || (_, Err(:final failure)):
        _loadFailure = failure;
    }
    setBusy(false);
  }

  void _apply(MyStore? store) {
    _store = store;
    if (store == null) return;
    name = store.name;
    description = store.description ?? '';
    origin = store.origin;
    zoneId = store.zoneId;
    address = store.pickupAddress?.address ?? '';
    landmark = store.pickupAddress?.landmark ?? '';
    categoryId = store.mainCategoryId;
    deliveryZoneIds
      ..clear()
      ..addAll(store.deliveryZoneIds);
    prepTimeMinutes = store.prepTimeMinutes;
    offersPickup = store.offersPickup;
    paymentMethodIds
      ..clear()
      ..addAll(store.paymentMethodIds);
    if (store.hours.isNotEmpty) {
      for (final day in hours) {
        final saved = store.hours.where((h) => h.weekday == day.weekday);
        day.open = saved.isNotEmpty;
        if (saved.isNotEmpty) {
          day
            ..opensAt = saved.first.opensAt
            ..closesAt = saved.first.closesAt;
        }
      }
    }
  }

  Future<void> _loadPaymentOptions() async {
    final result = await _service.paymentOptions();
    switch (result) {
      case Ok(:final value):
        paymentOptions = value;
        // Par défaut : le premier moyen disponible (le cash).
        if (paymentMethodIds.isEmpty) {
          final first = value.where((o) => o.isAvailable).firstOrNull;
          if (first != null) paymentMethodIds.add(first.id);
        }
      case Err(:final failure):
        _saveFailure = failure;
    }
  }

  // ---------------------------------------------------------------- saisie

  void setName(String value) => _set(() => name = value);
  void setDescription(String value) => _set(() => description = value);
  void selectOrigin(String code) => _set(() => origin = code);
  void selectZone(String id) => _set(() {
    final cityChanged = _cityOf(id) != _cityOf(zoneId);
    zoneId = id;
    if (cityChanged) deliveryZoneIds.clear();
  });
  void setAddress(String value) => _set(() => address = value);
  void setLandmark(String value) => _set(() => landmark = value);
  void selectCategory(String id) => _set(() => categoryId = id);
  void toggleDeliveryZone(String id) => _set(
    () => deliveryZoneIds.contains(id)
        ? deliveryZoneIds.remove(id)
        : deliveryZoneIds.add(id),
  );
  void selectAllDeliveryZones() =>
      _set(() => deliveryZoneIds.addAll(cityZones.map((z) => z.id)));
  void setPrepTime(int minutes) => _set(() => prepTimeMinutes = minutes);
  void setPickup({required bool value}) => _set(() => offersPickup = value);
  void togglePaymentMethod(PaymentOption option) {
    if (!option.isAvailable) return;
    _set(
      () => paymentMethodIds.contains(option.id)
          ? paymentMethodIds.remove(option.id)
          : paymentMethodIds.add(option.id),
    );
  }

  void setDayOpen(int weekday, {required bool open}) =>
      _set(() => _day(weekday).open = open);
  void setOpensAt(int weekday, String value) =>
      _set(() => _day(weekday).opensAt = value);
  void setClosesAt(int weekday, String value) =>
      _set(() => _day(weekday).closesAt = value);

  /// Copie les heures du premier jour ouvert sur tous les jours ouverts.
  void applyFirstDayToAll() {
    final first = hours.where((h) => h.open).firstOrNull;
    if (first == null) return;
    _set(() {
      for (final day in hours.where((h) => h.open)) {
        day
          ..opensAt = first.opensAt
          ..closesAt = first.closesAt;
      }
    });
  }

  DayHours _day(int weekday) => hours[weekday - 1];

  String? _cityOf(String? id) =>
      _config?.zones.where((z) => z.id == id).firstOrNull?.cityId;

  void _set(void Function() change) {
    change();
    _saveFailure = null;
    _incomplete = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------- navigation

  void back() {
    if (!canGoBack) return;
    _step = StoreStep.values[_step.index - 1];
    _saveFailure = null;
    notifyListeners();
  }

  /// Enregistre l'étape puis passe à la suivante (ou ouvre la boutique).
  Future<void> submit() async {
    if (!canContinue || isBusy) return;
    _saveFailure = null;
    _incomplete = false;
    setBusy(true);
    final result = await _save(_step);
    switch (result) {
      case Ok(:final value) when value != null:
        _store = value;
        if (isEditing) {
          _onSaved?.call(value);
        } else if (_step == StoreStep.hours) {
          _onOpened(value, _config!);
        } else {
          _step = StoreStep.values[_step.index + 1];
          if (_step == StoreStep.payment) await _loadPaymentOptions();
        }
      case Ok():
        _saveFailure = const ServerFailure('boutique introuvable');
      case Err(:final failure):
        _saveFailure = failure;
        _incomplete = failure is ValidationFailure && _step == StoreStep.hours;
    }
    setBusy(false);
  }

  /// Étape suivante enregistrée avec la saisie (sauf en réglage).
  Map<String, Object?> _next(StoreStep step) =>
      isEditing ? const {} : {'onboarding_step': step.number + 1};

  Future<Result<MyStore?>> _save(StoreStep step) async {
    switch (step) {
      case StoreStep.name:
        final trimmed = description.trim();
        return await _service.start(
          name: name.trim(),
          description: trimmed.isEmpty ? null : trimmed,
        );
      case StoreStep.origin:
        return await _service.update({'origin': origin, ..._next(step)});
      case StoreStep.address:
        final zone = await _service.update({'zone_id': zoneId});
        if (zone is Err) return zone;
        final saved = await _service.setPickupAddress(
          PickupAddress(
            address: address.trim(),
            landmark: landmark.trim().isEmpty ? null : landmark.trim(),
          ),
        );
        if (saved is Err || isEditing) return saved;
        return await _service.update(_next(step));
      case StoreStep.category:
        return await _service.update({
          'main_category_id': categoryId,
          ..._next(step),
        });
      case StoreStep.delivery:
        final zones = await _service.setDeliveryZones(deliveryZoneIds.toList());
        if (zones is Err) return zones;
        return await _service.update({
          'prep_time_minutes': prepTimeMinutes,
          'offers_pickup': offersPickup,
          ..._next(step),
        });
      case StoreStep.payment:
        final methods = await _service.setPaymentMethods(
          paymentMethodIds.toList(),
        );
        if (methods is Err || isEditing) return methods;
        return await _service.update(_next(step));
      case StoreStep.hours:
        final saved = await _service.setHours([
          for (final day in hours.where((h) => h.open))
            StoreHours(
              weekday: day.weekday,
              opensAt: day.opensAt,
              closesAt: day.closesAt,
            ),
        ]);
        if (saved is Err || isEditing) return saved;
        return await _service.publish();
    }
  }

  /// Délais proposés, plus le délai enregistré s'il est hors liste.
  List<int> get prepChoices =>
      {...storePrepChoices, prepTimeMinutes}.toList()..sort();
}
