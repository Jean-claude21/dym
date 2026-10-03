import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';

/// Liste des commandes (écran 52) : filtre, recherche, pages de 50.
class AdminOrdersViewModel extends AdminViewModel {
  new({required this.service});

  final AdminService service;
  static const pageSize = 50;

  AdminOrderFilter _filter = AdminOrderFilter.all;
  String _query = '';
  int _offset = 0;
  AdminOrderPage? _page;

  AdminOrderFilter get filter => _filter;
  String get query => _query;
  int get offset => _offset;
  AdminOrderPage? get page => _page;
  bool get ready => _page != null && !failed;
  bool get hasPrevious => _offset > 0;
  bool get hasNext => (_page?.total ?? 0) > _offset + pageSize;

  Future<void> load() => run(service.currencies, () async {
    final result = await service.orders(
      filter: _filter,
      query: _query.isEmpty ? null : _query,
      offset: _offset,
    );
    if (result case Ok(:final value)) _page = value;
    return result.failureOrNull;
  });

  Future<void> selectFilter(AdminOrderFilter value) async {
    _filter = value;
    _offset = 0;
    await load();
  }

  Future<void> search(String value) async {
    _query = value.trim();
    _offset = 0;
    await load();
  }

  Future<void> nextPage() async {
    if (!hasNext) return;
    _offset += pageSize;
    await load();
  }

  Future<void> previousPage() async {
    if (!hasPrevious) return;
    _offset = (_offset - pageSize).clamp(0, _offset);
    await load();
  }
}

/// Détail d'une commande (écran 53) : forcer un statut, annuler, livreur.
class AdminOrderViewModel extends AdminViewModel {
  new({required this.service, required this.orderId});

  final AdminService service;
  final String orderId;

  AdminOrder? _order;
  OrderStatus? _target;
  bool _acting = false;
  Failure? _actionFailure;

  AdminOrder? get order => _order;
  bool get ready => _order != null && !failed;
  bool get acting => _acting;
  Failure? get actionFailure => _actionFailure;

  /// Statut choisi dans la liste « Forcer un statut ».
  OrderStatus? get target => _target;

  Future<void> load() => run(service.currencies, () async {
    final result = await service.order(orderId);
    if (result case Ok(:final value)) _order = value;
    return result.failureOrNull;
  });

  void selectTarget(OrderStatus? value) {
    _target = value;
    notifyListeners();
  }

  Future<bool> forceStatus(String reason) {
    final to = _target;
    if (to == null) return Future.value(false);
    return _act((o) => service.forceStatus(o, to, reason.trim()));
  }

  Future<bool> cancel(String reason) =>
      _act((o) => service.cancel(o, reason.trim()));

  Future<bool> assignCourier(String name, String phone) => _act(
    (o) => service.assignCourier(o.id, name: name.trim(), phone: phone.trim()),
  );

  Future<bool> _act(
    Future<Result<AdminOrder>> Function(AdminOrder order) gesture,
  ) async {
    final current = _order;
    if (current == null || _acting) return false;
    _acting = true;
    _actionFailure = null;
    notifyListeners();
    final result = await gesture(current);
    switch (result) {
      case Ok(:final value):
        _order = value;
        _target = null;
      case Err(:final failure):
        _actionFailure = failure;
        if (await service.order(orderId) case Ok(:final value)) {
          _order = value;
        }
    }
    _acting = false;
    notifyListeners();
    return result.isOk;
  }
}
