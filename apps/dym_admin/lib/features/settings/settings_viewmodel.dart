import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_texts.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';

/// Onglet des réglages (écran 56).
enum SettingsTab {
  countries,
  geography,
  payments,
  commission,
  fees,
  categories,
  flags,
  search,
  admins,
  mcp,
}

/// Réglages : ouvrir un pays est une opération de configuration.
class AdminSettingsViewModel extends AdminViewModel {
  new({required this.service, this.access, this.mcpEndpoint}) {
    _tab = tabs.firstOrNull ?? SettingsTab.countries;
  }

  final AdminService service;

  /// Rôle de l'admin (spec 085) ; `null` : toutes les sections.
  final AdminAccess? access;

  /// Adresse du serveur MCP (spec 086), montrée avec une nouvelle clé.
  final String? mcpEndpoint;

  List<AdminMcpKey> _mcpKeys = const [];
  List<AdminMcpKey> get mcpKeys => _mcpKeys;

  /// Clé tout juste créée, montrée une seule fois.
  String? newMcpKey;

  /// Sections ouvertes au rôle (lecture du domaine).
  List<SettingsTab> get tabs => [
    for (final t in SettingsTab.values)
      if (_opens(t)) t,
  ];

  /// Rôles proposés, du plus large au plus restreint.
  List<String> get roles {
    final known = access?.roles ?? const <String>[];
    return known.isNotEmpty ? known : adminRoles;
  }

  /// Gérer les admins et leurs rôles (super-admin).
  bool get managesAdmins => access?.writes('admins') ?? true;

  bool _opens(SettingsTab t) {
    final a = access;
    if (a == null) return true;
    return switch (t) {
      SettingsTab.countries || SettingsTab.geography => a.reads('geography'),
      SettingsTab.payments ||
      SettingsTab.commission ||
      SettingsTab.fees ||
      SettingsTab.categories => a.reads('catalog'),
      SettingsTab.flags => a.reads('system'),
      SettingsTab.search => a.reads('content'),
      SettingsTab.admins => a.reads('admins'),
      SettingsTab.mcp => a.can('mcp.write'),
    };
  }

  late SettingsTab _tab;
  List<AdminCountry> _countries = const [];
  String? _country;
  List<AdminCity> _cities = const [];
  AdminPaymentSettings? _payments;
  AdminPricing? _pricing;
  List<AdminCategory> _categories = const [];
  List<AdminFeatureFlag> _flags = const [];
  AdminSearchSettings _search = const AdminSearchSettings();
  List<AdminMember> _admins = const [];
  bool _acting = false;
  Failure? _actionFailure;

  SettingsTab get tab => _tab;
  List<AdminCountry> get countries => _countries;
  String? get country => _country;
  AdminCountry? get selectedCountry =>
      _countries.where((c) => c.code == _country).firstOrNull;
  List<AdminCity> get cities => _cities;
  AdminPaymentSettings? get payments => _payments;
  AdminPricing? get pricing => _pricing;
  List<AdminCategory> get categories => _categories;
  List<AdminFeatureFlag> get flags => _flags;
  AdminSearchSettings get search => _search;
  List<AdminMember> get admins => _admins;
  bool get ready => !failed && _countries.isNotEmpty;
  bool get acting => _acting;
  Failure? get actionFailure => _actionFailure;

  /// Unité mineure par unité majeure de la devise du pays choisi.
  Currency? get currency => currencies[selectedCountry?.currencyCode];

  Future<void> load() => run(service.currencies, () async {
    final result = await service.countries();
    if (result case Ok(:final value)) {
      _countries = value;
      _country ??=
          value.where((c) => c.isActive).firstOrNull?.code ??
          value.firstOrNull?.code;
    }
    return result.failureOrNull ?? await _loadTab();
  });

  Future<void> selectTab(SettingsTab value) async {
    _tab = value;
    _actionFailure = null;
    notifyListeners();
    await load();
  }

  Future<void> selectCountry(String? code) async {
    if (code == null) return;
    _country = code;
    await load();
  }

  Future<Failure?> _loadTab() async {
    final code = _country;
    switch (_tab) {
      case SettingsTab.countries:
        return null;
      case SettingsTab.geography:
        if (code == null) return null;
        final r = await service.geography(code);
        if (r case Ok(:final value)) _cities = value;
        return r.failureOrNull;
      case SettingsTab.payments:
        if (code == null) return null;
        final r = await service.paymentMethods(code);
        if (r case Ok(:final value)) _payments = value;
        return r.failureOrNull;
      case SettingsTab.commission:
      case SettingsTab.fees:
        if (code == null) return null;
        final r = await service.pricing(code);
        if (r case Ok(:final value)) _pricing = value;
        final cities = await service.geography(code);
        if (cities case Ok(:final value)) _cities = value;
        final categories = await service.categories();
        if (categories case Ok(:final value)) _categories = value;
        return r.failureOrNull;
      case SettingsTab.categories:
        final r = await service.categories();
        if (r case Ok(:final value)) _categories = value;
        return r.failureOrNull;
      case SettingsTab.flags:
        final r = await service.featureFlags();
        if (r case Ok(:final value)) _flags = value;
        return r.failureOrNull;
      case SettingsTab.search:
        final r = await service.searchSettings();
        if (r case Ok(:final value)) _search = value;
        return r.failureOrNull;
      case SettingsTab.admins:
        final r = await service.admins();
        if (r case Ok(:final value)) _admins = value;
        return r.failureOrNull;
      case SettingsTab.mcp:
        final r = await service.mcpKeys();
        if (r case Ok(:final value)) _mcpKeys = value;
        return r.failureOrNull;
    }
  }

  Future<bool> setCountryActive(String code, {required bool active}) =>
      _act(() async {
        final r = await service.setCountryActive(code, active: active);
        if (r case Ok(:final value)) _countries = value;
        return r.failureOrNull;
      });

  Future<bool> saveCity(Map<String, Object?> city) => _act(() async {
    final r = await service.saveCity({'country_code': _country, ...city});
    if (r case Ok(:final value)) _cities = value;
    return r.failureOrNull;
  });

  Future<bool> saveZone(Map<String, Object?> zone) => _act(() async {
    final r = await service.saveZone(zone);
    if (r case Ok(:final value)) _cities = value;
    return r.failureOrNull;
  });

  Future<bool> savePaymentMethod(Map<String, Object?> method) => _act(() async {
    final r = await service.savePaymentMethod({
      'country_code': _country,
      ...method,
    });
    if (r case Ok(:final value)) _payments = value;
    return r.failureOrNull;
  });

  Future<bool> setCommission(int rateBps, {String? categoryId}) =>
      _act(() async {
        final r = await service.setCommission(
          _country!,
          rateBps: rateBps,
          categoryId: categoryId,
        );
        if (r case Ok(:final value)) _pricing = value;
        return r.failureOrNull;
      });

  Future<bool> setDeliveryFee({
    required int baseFeeMinor,
    required int extraPickupFeeMinor,
    int? freeThresholdMinor,
    String? cityId,
  }) => _act(() async {
    final r = await service.setDeliveryFee(
      _country!,
      baseFeeMinor: baseFeeMinor,
      extraPickupFeeMinor: extraPickupFeeMinor,
      freeThresholdMinor: freeThresholdMinor,
      cityId: cityId,
    );
    if (r case Ok(:final value)) _pricing = value;
    return r.failureOrNull;
  });

  Future<bool> saveCategory(Map<String, Object?> category) => _act(() async {
    final r = await service.saveCategory(category);
    if (r case Ok(:final value)) _categories = value;
    return r.failureOrNull;
  });

  /// Fonctionnalité activée ou coupée (pays ou partout), journalisé.
  Future<bool> setFlag(AdminFeatureFlag flag, {required bool enabled}) =>
      _act(() async {
        final r = await service.setFeatureFlag(
          flag.key,
          enabled: enabled,
          countryCode: flag.countryCode,
        );
        if (r case Ok(:final value)) _flags = value;
        return r.failureOrNull;
      });

  /// Poids de classement du pays choisi (spec 028), journalisé.
  Future<bool> setRanking(Map<String, int> weights) => _act(() async {
    final r = await service.setRanking(_country, weights);
    if (r case Ok(:final value)) _search = value;
    return r.failureOrNull;
  });

  /// Synonymes d'un nom local du pays choisi ; liste vide : retiré.
  Future<bool> setSynonym(String term, List<String> synonyms) => _act(() async {
    final r = await service.setSynonym(_country, term, synonyms);
    if (r case Ok(:final value)) _search = value;
    return r.failureOrNull;
  });

  Future<bool> createMcpKey(String name) => _act(() async {
    final r = await service.createMcpKey(name.trim());
    if (r case Ok(:final value)) {
      newMcpKey = value.secret;
      _mcpKeys = [value.key, ..._mcpKeys];
    }
    return r.failureOrNull;
  });

  Future<bool> revokeMcpKey(AdminMcpKey key) => _act(() async {
    final r = await service.revokeMcpKey(key.id);
    if (r case Ok(:final value)) _mcpKeys = value;
    return r.failureOrNull;
  });

  void forgetNewMcpKey() {
    newMcpKey = null;
    notifyListeners();
  }

  Future<bool> setAdminRole(AdminMember member, String role) => _act(() async {
    final r = await service.setAdminRole(member.email, role);
    if (r case Ok(:final value)) _admins = value;
    return r.failureOrNull;
  });

  Future<bool> inviteAdmin(String email, {String role = 'analyst'}) =>
      _act(() async {
        final r = await service.inviteAdmin(
          email.trim().toLowerCase(),
          role: role,
        );
        if (r case Ok(:final value)) _admins = value;
        return r.failureOrNull;
      });

  Future<bool> removeAdmin(AdminMember member) => _act(() async {
    final r = await service.removeAdmin(member.email);
    if (r case Ok(:final value)) _admins = value;
    return r.failureOrNull;
  });

  /// Après un changement : la liste des pays (ce qui manque) est relue.
  Future<bool> _act(Future<Failure?> Function() gesture) async {
    if (_acting) return false;
    _acting = true;
    _actionFailure = null;
    notifyListeners();
    final failure = await gesture();
    _actionFailure = failure;
    if (failure == null && _tab != SettingsTab.countries) {
      if (await service.countries() case Ok(:final value)) _countries = value;
    }
    _acting = false;
    notifyListeners();
    return failure == null;
  }
}
