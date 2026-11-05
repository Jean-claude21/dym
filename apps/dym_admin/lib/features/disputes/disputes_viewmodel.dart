import 'package:dym_admin/features/ops/admin_service.dart';
import 'package:dym_admin/features/ops/admin_widgets.dart';
import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';

/// Litiges ouverts (écran 54) : liste, conversation, réponse, décision.
class AdminDisputesViewModel extends AdminViewModel {
  new({required this.service, this.initialId});

  final AdminService service;
  final String? initialId;

  List<AdminDisputeRow> _rows = const [];
  String? _selectedId;
  AdminDispute? _detail;
  bool _loadingDetail = false;
  bool _acting = false;
  Failure? _actionFailure;
  DisputeResolution _resolution = DisputeResolution.partialRefund;
  String _amount = '';
  bool _warnVendor = false;

  List<AdminDisputeRow> get rows => _rows;
  bool get ready => !failed && !isBusy;
  String? get selectedId => _selectedId;
  AdminDispute? get detail => _detail;
  bool get loadingDetail => _loadingDetail;
  bool get acting => _acting;
  Failure? get actionFailure => _actionFailure;
  DisputeResolution get resolution => _resolution;
  String get amount => _amount;
  bool get warnVendor => _warnVendor;

  Currency? get _currency => currencies[_detail?.order.currencyCode];

  /// Montant du remboursement partiel en unités mineures (nul : invalide).
  int? get amountMinor {
    final c = _currency;
    return c == null ? null : Money.parseMajor(_amount, c);
  }

  bool get canResolve {
    final d = _detail;
    if (d == null || !d.dispute.isOpen || _acting) return false;
    if (_resolution != DisputeResolution.partialRefund) return true;
    final a = amountMinor;
    return a != null && a > 0 && a <= d.order.totalMinor;
  }

  Future<void> load() => run(service.currencies, () async {
    final result = await service.disputes();
    if (result case Ok(:final value)) _rows = value;
    final first = initialId ?? (_rows.isEmpty ? null : _rows.first.id);
    if (_selectedId == null && first != null) await select(first);
    return result.failureOrNull;
  });

  Future<void> select(String id) async {
    _selectedId = id;
    _detail = null;
    _loadingDetail = true;
    _actionFailure = null;
    _resolution = DisputeResolution.partialRefund;
    _amount = '';
    _warnVendor = false;
    note = '';
    notifyListeners();
    final result = await service.dispute(id);
    if (_selectedId != id) return;
    _loadingDetail = false;
    switch (result) {
      case Ok(:final value):
        _detail = value;
      case Err(:final failure):
        _actionFailure = failure;
    }
    notifyListeners();
  }

  void close() {
    _selectedId = null;
    _detail = null;
    notifyListeners();
  }

  void setResolution(DisputeResolution value) {
    _resolution = value;
    notifyListeners();
  }

  void setAmount(String value) {
    _amount = value;
    notifyListeners();
  }

  void setWarnVendor({required bool value}) {
    _warnVendor = value;
    notifyListeners();
  }

  /// Note interne (équipe seulement).
  String note = '';

  /// Message de l'équipe ; `true` si envoyé.
  Future<bool> reply(String body) async {
    final d = _detail;
    if (d == null || body.trim().isEmpty || _acting) return false;
    return await _act(() async {
      final result = await service.replyDispute(d.dispute.id, body.trim());
      if (result case Ok(:final value)) {
        _detail = AdminDispute(dispute: value, order: d.order);
      }
      return result.failureOrNull;
    });
  }

  Future<bool> resolve() async {
    final d = _detail;
    if (d == null || !canResolve) return false;
    return await _act(() async {
      final result = await service.resolveDispute(
        d.dispute.id,
        resolution: _resolution,
        refundMinor: amountMinor,
        internalNote: note.trim().isEmpty ? null : note.trim(),
        warnVendor: _warnVendor,
      );
      if (result case Ok(:final value)) {
        _detail = AdminDispute(dispute: value, order: d.order);
        _rows = [
          for (final r in _rows)
            if (r.id != d.dispute.id) r,
        ];
      }
      return result.failureOrNull;
    });
  }

  Future<bool> _act(Future<Failure?> Function() gesture) async {
    _acting = true;
    _actionFailure = null;
    notifyListeners();
    final failure = await gesture();
    _actionFailure = failure;
    _acting = false;
    notifyListeners();
    return failure == null;
  }
}
