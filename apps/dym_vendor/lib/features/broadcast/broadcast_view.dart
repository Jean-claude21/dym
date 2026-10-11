import 'dart:async';
import 'dart:typed_data';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Relance des clientes et alerte de stock bas (spec 021, écran 78).
abstract interface class VendorBroadcastService {
  /// Flag `vendor_broadcast` du pays de la boutique.
  Future<bool> enabled();

  Future<Result<BroadcastAudience>> audience();

  /// Produits publiés, à joindre.
  Future<Result<List<Product>>> products();

  Future<Result<int>> send(
    BroadcastSegment segment,
    String message, {
    String? productId,
  });

  Future<Result<void>> setLowStockThreshold(int? threshold);

  Future<Result<CountryConfig>> countryConfig();

  ImageProvider photo(String objectKey);
}

/// Implémentation Neon.
class NeonVendorBroadcastService implements VendorBroadcastService {
  new({
    required this._repository,
    required this._products,
    required this._config,
    required this._photo,
  });

  final BroadcastRepository _repository;
  final Future<Result<List<Product>>> Function() _products;
  final Future<Result<CountryConfig>> Function() _config;
  final ImageProvider Function(String key) _photo;

  @override
  Future<bool> enabled() async =>
      (await _config()).valueOrNull?.isEnabled('vendor_broadcast') ?? false;

  @override
  Future<Result<BroadcastAudience>> audience() => _repository.audience();

  @override
  Future<Result<List<Product>>> products() async => (await _products()).map(
    (all) => [
      for (final p in all)
        if (p.status == ProductStatus.published) p,
    ],
  );

  @override
  Future<Result<int>> send(
    BroadcastSegment segment,
    String message, {
    String? productId,
  }) => _repository.send(segment, message, productId: productId);

  @override
  Future<Result<void>> setLowStockThreshold(int? threshold) =>
      _repository.setLowStockThreshold(threshold);

  @override
  Future<Result<CountryConfig>> countryConfig() => _config();

  @override
  ImageProvider photo(String objectKey) => _photo(objectKey);
}

class BroadcastViewModel extends BaseViewModel {
  new({required this.service});

  final VendorBroadcastService service;

  BroadcastAudience? audience;
  List<Product> products = const [];
  CountryConfig? config;
  Failure? failure;
  BroadcastSegment segment = BroadcastSegment.regular;
  String message = '';
  String? productId;
  bool sending = false;
  Failure? sendFailure;

  /// Nombre de clientes prévenues par la dernière relance.
  int? sent;

  static const thresholds = [3, 5, 10, 20];

  int get recipients => audience?.count(segment) ?? 0;
  bool get canSend =>
      !sending && message.trim().length >= 2 && recipients > 0 && sent == null;

  Future<void> load() async {
    failure = null;
    config = (await service.countryConfig()).valueOrNull;
    final result = await service.audience();
    switch (result) {
      case Ok(:final value):
        audience = value;
      case Err(failure: final f):
        failure = f;
    }
    products = (await service.products()).valueOrNull ?? const [];
    notifyListeners();
  }

  void selectSegment(BroadcastSegment value) {
    segment = value;
    notifyListeners();
  }

  void setMessage(String value) {
    message = value;
    notifyListeners();
  }

  void attach(String? id) {
    productId = id;
    notifyListeners();
  }

  Future<bool> send() async {
    if (!canSend) return false;
    sending = true;
    sendFailure = null;
    notifyListeners();
    switch (await service.send(segment, message.trim(), productId: productId)) {
      case Ok(:final value):
        sent = value;
      case Err(failure: final f):
        sendFailure = f;
    }
    sending = false;
    notifyListeners();
    return sent != null;
  }

  Future<void> setThreshold(int? value) async {
    final previous = audience;
    if (previous == null) return;
    audience = BroadcastAudience(
      regular: previous.regular,
      month: previous.month,
      all: previous.all,
      lastSentAt: previous.lastSentAt,
      lowStockThreshold: value,
    );
    notifyListeners();
    if (!(await service.setLowStockThreshold(value)).isOk) {
      audience = previous;
      notifyListeners();
    }
  }
}

/// Écran 78.
class BroadcastView extends StackedView<BroadcastViewModel> {
  const new({required this.service, required this.onBack, super.key});

  final VendorBroadcastService service;
  final VoidCallback onBack;

  @override
  BroadcastViewModel viewModelBuilder(BuildContext context) =>
      BroadcastViewModel(service: service);

  @override
  void onViewModelReady(BroadcastViewModel viewModel) =>
      unawaited(viewModel.load());

  @override
  Widget builder(
    BuildContext context,
    BroadcastViewModel viewModel,
    Widget? child,
  ) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    final vm = viewModel;
    final audience = vm.audience;
    final attached = vm.products.where((p) => p.id == vm.productId).firstOrNull;
    Widget card({
      required IconData icon,
      required String title,
      required Widget child,
    }) => Card(
      margin: const EdgeInsets.only(bottom: DymTokenSpace.s3),
      child: Padding(
        padding: const EdgeInsets.all(DymTokenSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: c.brandDeep),
                const SizedBox(width: DymTokenSpace.s2),
                Expanded(child: Text(title, style: t.title)),
              ],
            ),
            const SizedBox(height: DymTokenSpace.s2),
            child,
          ],
        ),
      ),
    );
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.brandDeep,
        foregroundColor: c.card,
        title: Text(l10n.broadcastTitle),
        leading: IconButton(
          tooltip: l10n.authBack,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: DymContentWidth(
          child: audience == null
              ? Center(
                  child: vm.failure == null
                      ? const CircularProgressIndicator()
                      : TextButton(onPressed: vm.load, child: Text(l10n.retry)),
                )
              : ListView(
                  padding: EdgeInsets.all(DymLayout.gutter(context)),
                  children: [
                    card(
                      icon: Icons.groups_rounded,
                      title: l10n.broadcastAudience,
                      child: RadioGroup<BroadcastSegment>(
                        groupValue: vm.segment,
                        onChanged: (s) {
                          if (s != null) vm.selectSegment(s);
                        },
                        child: Column(
                          children: [
                            for (final s in BroadcastSegment.values)
                              RadioListTile<BroadcastSegment>(
                                value: s,
                                title: Text(
                                  '${broadcastSegmentLabel(l10n, s)} · '
                                  '${audience.count(s)}',
                                ),
                                subtitle: s == BroadcastSegment.regular
                                    ? Text(l10n.broadcastRegularHint)
                                    : null,
                              ),
                          ],
                        ),
                      ),
                    ),
                    card(
                      icon: Icons.chat_rounded,
                      title: l10n.broadcastMessage,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DymTextField(
                            label: l10n.broadcastMessageHint,
                            maxLength: 300,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: vm.setMessage,
                          ),
                          const SizedBox(height: DymTokenSpace.s2),
                          DropdownButtonFormField<String?>(
                            initialValue: vm.productId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.broadcastAttach,
                            ),
                            items: [
                              DropdownMenuItem(
                                child: Text(l10n.broadcastNoProduct),
                              ),
                              for (final p in vm.products)
                                DropdownMenuItem(
                                  value: p.id,
                                  child: Text(
                                    [
                                      p.name,
                                      ?moneyText(vm.config, p.priceMinor),
                                    ].join(' · '),
                                  ),
                                ),
                            ],
                            onChanged: vm.attach,
                          ),
                          if (attached?.photoKeys.firstOrNull case final key?)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: DymTokenSpace.s2,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  DymTokenRadius.tile,
                                ),
                                child: Image(
                                  image: service.photo(key),
                                  height: 96,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          const SizedBox(height: DymTokenSpace.s2),
                          Container(
                            padding: const EdgeInsets.all(DymTokenSpace.s2),
                            decoration: BoxDecoration(
                              color: c.tintVertTendre,
                              borderRadius: BorderRadius.circular(
                                DymTokenRadius.tile,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: c.brandDeep),
                                const SizedBox(width: DymTokenSpace.s2),
                                Expanded(
                                  child: Text(
                                    l10n.broadcastRules,
                                    style: t.label,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (vm.sendFailure case final f?)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: DymTokenSpace.s2,
                              ),
                              child: Text(
                                broadcastFailureLabel(l10n, f),
                                style: t.body.copyWith(color: c.pimentStrong),
                              ),
                            ),
                          if (vm.sent case final n?)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: DymTokenSpace.s2,
                              ),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  l10n.broadcastSent(n),
                                  style: t.body.copyWith(color: c.brandDeep),
                                ),
                              ),
                            ),
                          const SizedBox(height: DymTokenSpace.s2),
                          DymButton(
                            label: l10n.broadcastSend(vm.recipients),
                            icon: Icons.send_rounded,
                            loading: vm.sending,
                            onPressed: vm.canSend ? vm.send : null,
                          ),
                        ],
                      ),
                    ),
                    card(
                      icon: Icons.notifications_active_rounded,
                      title: l10n.lowStockTitle,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DymSwitchTile(
                            title: l10n.lowStockEnabled,
                            value: audience.lowStockThreshold != null,
                            onChanged: (on) => vm.setThreshold(on ? 5 : null),
                          ),
                          if (audience.lowStockThreshold case final n?)
                            DropdownButtonFormField<int>(
                              initialValue: n,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: l10n.lowStockThreshold,
                              ),
                              items: [
                                for (final v in {
                                  ...BroadcastViewModel.thresholds,
                                  n,
                                })
                                  DropdownMenuItem(
                                    value: v,
                                    child: Text(l10n.lowStockUnder(v)),
                                  ),
                              ],
                              onChanged: (v) {
                                if (v != null) unawaited(vm.setThreshold(v));
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

String broadcastSegmentLabel(DymLocalizations l10n, BroadcastSegment s) =>
    switch (s) {
      BroadcastSegment.regular => l10n.broadcastRegular,
      BroadcastSegment.month => l10n.broadcastMonth,
      BroadcastSegment.all => l10n.broadcastAll,
    };

String broadcastFailureLabel(DymLocalizations l10n, Failure f) => switch (f) {
  NetworkFailure() => l10n.errorOffline,
  ValidationFailure(message: 'broadcast_daily_limit') =>
    l10n.broadcastDailyLimit,
  _ => l10n.errorGeneric,
};

/// Prix d'un produit dans la devise du pays.
String? moneyText(CountryConfig? config, int? minor) =>
    config == null || minor == null
    ? null
    : Money(minor, config.currency).format();

/// Relance en mémoire (tests, galerie).
class MemoryVendorBroadcastService implements VendorBroadcastService {
  new({
    this.isEnabled = true,
    this.catalog = const [],
    this.config,
    BroadcastAudience? audience,
    this.photoResolver,
    this.failure,
  }) : _audience =
           audience ??
           const BroadcastAudience(
             regular: 12,
             month: 31,
             all: 58,
             lowStockThreshold: 5,
           );

  final bool isEnabled;
  final List<Product> catalog;
  final CountryConfig? config;
  final ImageProvider Function(String key)? photoResolver;
  final Failure? failure;
  BroadcastAudience _audience;
  final gestures = <String>[];

  @override
  Future<bool> enabled() async => isEnabled;

  @override
  Future<Result<BroadcastAudience>> audience() async => Ok(_audience);

  @override
  Future<Result<List<Product>>> products() async => Ok(catalog);

  @override
  Future<Result<int>> send(
    BroadcastSegment segment,
    String message, {
    String? productId,
  }) async {
    if (failure case final f?) return Err(f);
    gestures.add('send:${segment.name}:${productId ?? '-'}');
    return Ok(_audience.count(segment));
  }

  @override
  Future<Result<void>> setLowStockThreshold(int? threshold) async {
    gestures.add('threshold:${threshold ?? 'off'}');
    _audience = BroadcastAudience(
      regular: _audience.regular,
      month: _audience.month,
      all: _audience.all,
      lowStockThreshold: threshold,
    );
    return const Ok(null);
  }

  @override
  Future<Result<CountryConfig>> countryConfig() async => switch (config) {
    final c? => Ok(c),
    null => const Err(NotFoundFailure('pays')),
  };

  @override
  ImageProvider photo(String objectKey) =>
      photoResolver?.call(objectKey) ?? MemoryImage(_pixel);
}

final _pixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);
