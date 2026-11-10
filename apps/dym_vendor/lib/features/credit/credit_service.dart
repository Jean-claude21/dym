import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';

/// Ardoise (spec 047) : remplaçable en test.
abstract interface class CreditService {
  Future<Result<CountryConfig>> countryConfig();

  Future<Result<StoreCredits>> credits();

  Future<Result<StoreCredit>> detail(String id);

  Future<Result<StoreCredit>> save({
    required String name,
    String? id,
    String? phone,
    int? limitMinor,
  });

  Future<Result<StoreCredit>> addEntry(
    StoreCredit credit, {
    required bool debt,
    required int amountMinor,
    String? note,
  });

  /// Relance tracée en base, puis WhatsApp ouvert avec [message].
  Future<Result<StoreCredit>> remind(
    StoreCredit credit,
    String Function(StoreCredit reminded) message,
  );

  Future<Result<StoreCredits>> archive(StoreCredit credit);
}

class NeonCreditService implements CreditService {
  new({
    required this._credits,
    required this._config,
    this._pages = const PluginExternalPageOpener(),
  });

  final CreditRepository _credits;
  final Future<Result<CountryConfig>> Function() _config;
  final ExternalPageOpener _pages;
  String? _entryKey;

  @override
  Future<Result<CountryConfig>> countryConfig() => _config();

  @override
  Future<Result<StoreCredits>> credits() => _credits.credits();

  @override
  Future<Result<StoreCredit>> detail(String id) => _credits.detail(id);

  @override
  Future<Result<StoreCredit>> save({
    required String name,
    String? id,
    String? phone,
    int? limitMinor,
  }) => _credits.save(name: name, id: id, phone: phone, limitMinor: limitMinor);

  @override
  Future<Result<StoreCredit>> addEntry(
    StoreCredit credit, {
    required bool debt,
    required int amountMinor,
    String? note,
  }) async {
    final key = _entryKey ??= Uuid.v4();
    final result = await _credits.addEntry(
      credit.id,
      debt: debt,
      amountMinor: amountMinor,
      key: key,
      note: note,
    );
    if (result.failureOrNull is! NetworkFailure) _entryKey = null;
    return result;
  }

  @override
  Future<Result<StoreCredit>> remind(
    StoreCredit credit,
    String Function(StoreCredit reminded) message,
  ) async {
    final result = await _credits.remind(credit.id);
    if (result case Ok(:final value) when value.phone != null) {
      final digits = value.phone!.replaceAll(RegExp('[^0-9]'), '');
      await _pages.open(
        Uri.https('wa.me', '/$digits', {'text': message(value)}),
      );
    }
    return result;
  }

  @override
  Future<Result<StoreCredits>> archive(StoreCredit credit) =>
      _credits.archive(credit.id);
}
