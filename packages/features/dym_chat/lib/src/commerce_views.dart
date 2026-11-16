import 'dart:async';

import 'package:dym_chat/src/chat_commerce.dart';
import 'package:dym_chat/src/chat_viewmodels.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_map/dym_map.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';

/// Ouverture des vidéos et des cartes externes ; remplaçable en test.
@visibleForTesting
ExternalPageOpener commerceOpener = const PluginExternalPageOpener();

/// Bulles du chat de commerce (spec 099) : vidéo, position, devis, demande
/// de paiement, coupon. Les états (accepté, payé, expiré) viennent de la base.
class CommerceBubble extends StatelessWidget {
  const new({
    required this.message,
    required this.vm,
    required this.mine,
    required this.meta,
    super.key,
  });

  final ChatMessage message;
  final ChatViewModel vm;
  final bool mine;
  final Widget meta;

  String _money(int minor) => vm.config?.money(minor).format() ?? '$minor';

  @override
  Widget build(BuildContext context) {
    final c = context.dym.colors;
    final t = context.dym.text;
    final l10n = DymLocalizations.of(context);
    Widget card({required List<Widget> children, Color? color}) => Container(
      width: 280,
      padding: const EdgeInsets.all(DymTokenSpace.s3),
      decoration: BoxDecoration(
        color: color ?? (mine ? c.tintVertTendre : c.card),
        borderRadius: BorderRadius.circular(DymTokenRadius.card),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...children,
          const SizedBox(height: DymTokenSpace.s1),
          Align(alignment: Alignment.centerRight, child: meta),
        ],
      ),
    );
    Widget title(IconData icon, String text) => Row(
      children: [
        Icon(icon, color: c.brandDeep, size: 20),
        const SizedBox(width: DymTokenSpace.s2),
        Expanded(child: Text(text, style: t.title.copyWith(fontSize: 16))),
      ],
    );
    final status = message.payloadText('status');
    final busy = vm.commerceBusy;

    switch (message.kind) {
      case MessageKind.video:
        final url = vm.mediaUrl(message.id);
        final seconds = ((message.durationMs ?? 0) / 1000).round();
        return card(
          children: [
            InkWell(
              onTap: url == null
                  ? null
                  : () => unawaited(commerceOpener.open(Uri.parse(url))),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: c.textPrimary,
                  borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 56,
                    semanticLabel: l10n.chatVideoPlay,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DymTokenSpace.s1),
            Text(
              seconds > 0 ? l10n.chatVideoDuration(seconds) : l10n.chatVideo,
              style: t.label,
            ),
            if (message.body case final caption?) Text(caption, style: t.body),
          ],
        );

      case MessageKind.location:
        final lat = message.payloadNumber('latitude');
        final lng = message.payloadNumber('longitude');
        final live = message.isLive;
        final until = message.liveUntil;
        final point = lat == null || lng == null ? null : DymLatLng(lat, lng);
        return card(
          children: [
            title(
              live ? Icons.share_location_rounded : Icons.place_rounded,
              live
                  ? l10n.chatLocationLive(
                      TimeOfDay.fromDateTime(until!.toLocal()).format(context),
                    )
                  : l10n.chatLocation,
            ),
            if (point != null) ...[
              const SizedBox(height: DymTokenSpace.s2),
              ClipRRect(
                borderRadius: BorderRadius.circular(DymTokenRadius.tile),
                child: SizedBox(
                  height: 140,
                  child: DymMap(
                    initialCenter: point,
                    initialZoom: 15,
                    interactive: false,
                    pins: [DymMapPin(id: 'here', point: point, style: 'here')],
                    pinStyles: {
                      'here': DymPinStyle(
                        icon: Icons.person_pin_circle_rounded,
                        background: c.tintVertTendre,
                        foreground: c.brandDeep,
                      ),
                    },
                    semanticLabel: l10n.chatLocation,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => unawaited(
                  commerceOpener.open(
                    Uri.https('www.openstreetmap.org', '/', {
                      'mlat': '$lat',
                      'mlon': '$lng',
                    }).replace(fragment: 'map=17/$lat/$lng'),
                  ),
                ),
                icon: const Icon(Icons.directions_rounded),
                label: Text(l10n.chatLocationOpen),
              ),
            ],
            if (live && mine && vm.liveMessageId == message.id)
              TextButton.icon(
                onPressed: vm.stopLiveLocation,
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(l10n.chatLocationStop),
              ),
          ],
        );

      case MessageKind.quote:
        final lines = (message.payload?['lines'] as List? ?? const [])
            .cast<Map<dynamic, dynamic>>();
        final total = (message.payload?['total_minor'] as num?)?.toInt() ?? 0;
        return card(
          children: [
            title(Icons.request_quote_outlined, l10n.chatQuote),
            const SizedBox(height: DymTokenSpace.s2),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l['quantity']} × ${l['name'] ?? ''}',
                        style: t.body,
                      ),
                    ),
                    if ((l['list_price_minor'] as num?) != null &&
                        l['list_price_minor'] != l['price_minor'])
                      Text(
                        _money((l['list_price_minor'] as num).toInt()),
                        style: t.label.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: c.textSecondary,
                        ),
                      ),
                    const SizedBox(width: DymTokenSpace.s1),
                    Text(
                      _money((l['price_minor'] as num? ?? 0).toInt()),
                      style: t.label,
                    ),
                  ],
                ),
              ),
            if (message.payloadText('note') case final note?)
              Text(note, style: t.label.copyWith(color: c.textSecondary)),
            const Divider(),
            Text(l10n.chatQuoteTotal(_money(total)), style: t.title),
            const SizedBox(height: DymTokenSpace.s2),
            if (status == 'pending' && !mine)
              DymButton(
                label: l10n.chatQuoteAccept,
                icon: Icons.shopping_basket_rounded,
                loading: busy,
                onPressed: busy ? null : () => _acceptQuote(context),
              )
            else
              Text(switch (status) {
                'accepted' => l10n.chatQuoteAccepted,
                'expired' => l10n.chatExpired,
                _ => l10n.chatQuotePending,
              }, style: t.label.copyWith(color: c.textSecondary)),
          ],
        );

      case MessageKind.paymentRequest:
        final amount = (message.payload?['amount_minor'] as num?)?.toInt() ?? 0;
        return card(
          children: [
            title(Icons.payments_outlined, l10n.chatPaymentRequest),
            const SizedBox(height: DymTokenSpace.s1),
            Text(_money(amount), style: t.display.copyWith(fontSize: 28)),
            if (message.payloadText('label') case final label?)
              Text(label, style: t.body),
            const SizedBox(height: DymTokenSpace.s2),
            if (status == 'open' && !mine)
              DymButton(
                label: l10n.chatPay(_money(amount)),
                icon: Icons.account_balance_wallet_rounded,
                loading: busy,
                onPressed: busy ? null : () => _pay(context),
              )
            else
              Text(switch (status) {
                'paid' => l10n.chatPaid,
                'expired' || 'cancelled' => l10n.chatExpired,
                _ => l10n.chatPaymentWaiting,
              }, style: t.label.copyWith(color: c.textSecondary)),
          ],
        );

      case MessageKind.coupon:
        final percent = (message.payload?['percent'] as num?)?.toInt() ?? 0;
        final expired = message.payload?['expired'] == true;
        final until = DateTime.tryParse(
          message.payloadText('expires_at') ?? '',
        );
        return card(
          color: c.tintPlantainClair,
          children: [
            title(Icons.local_offer_rounded, l10n.chatCoupon(percent)),
            if (until != null)
              Text(
                l10n.chatCouponUntil(
                  MaterialLocalizations.of(context).formatShortDate(until),
                ),
                style: t.label,
              ),
            const SizedBox(height: DymTokenSpace.s2),
            if (!mine && !expired)
              DymButton(
                label: l10n.chatCouponClaim,
                icon: Icons.bookmark_add_rounded,
                variant: DymButtonVariant.secondary,
                loading: busy,
                onPressed: busy ? null : () => _claim(context),
              )
            else if (expired)
              Text(l10n.chatExpired, style: t.label),
          ],
        );

      case MessageKind.text ||
          MessageKind.image ||
          MessageKind.product ||
          MessageKind.audio ||
          MessageKind.call ||
          MessageKind.unknown:
        return const SizedBox.shrink();
    }
  }

  /// Résultat d'un geste : message de réussite ou d'échec.
  Future<void> _run(
    BuildContext context,
    Future<bool> Function() work,
    String Function(DymLocalizations l10n) success,
  ) async {
    final l10n = DymLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await work();
    messenger?.showSnackBar(
      SnackBar(content: Text(ok ? success(l10n) : l10n.errorGeneric)),
    );
  }

  Future<void> _acceptQuote(BuildContext context) =>
      _run(context, () => vm.acceptQuote(message), (l) => l.chatQuoteInCart);

  Future<void> _pay(BuildContext context) =>
      _run(context, () => vm.payRequest(message), (l) => l.chatPaid);

  Future<void> _claim(BuildContext context) =>
      _run(context, () => vm.claimCoupon(message), (l) => l.chatCouponClaimed);
}

/// Transcription d'un vocal, sous la bulle (spec 099).
class TranscriptLine extends StatelessWidget {
  const new({required this.message, required this.vm, super.key});

  final ChatMessage message;
  final ChatViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.commerce == null) return const SizedBox.shrink();
    final l10n = DymLocalizations.of(context);
    final t = context.dym.text;
    final c = context.dym.colors;
    final text = vm.transcripts[message.id] ?? message.transcript;
    if (text != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
        child: Text(
          '« $text »',
          style: t.label.copyWith(color: c.textSecondary),
        ),
      );
    }
    if (vm.simulatedTranscripts.contains(message.id)) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, left: 8),
        child: Text(
          l10n.chatTranscriptSimulated,
          style: t.label.copyWith(color: c.textSecondary),
        ),
      );
    }
    return TextButton.icon(
      onPressed: () => unawaited(vm.transcribe(message)),
      icon: const Icon(Icons.subtitles_outlined, size: 18),
      label: Text(l10n.chatTranscribe),
    );
  }
}

/// Gestes du chat de commerce dans le menu « + » (spec 099).
enum CommerceAction {
  videoCamera,
  videoGallery,
  location,
  liveLocation,
  quote,
  paymentRequest,
  coupon,
}

List<(CommerceAction, IconData, String)> commerceOptions(
  DymLocalizations l10n,
  ChatViewModel vm,
) => [
  if (vm.commerce != null) ...[
    (CommerceAction.videoCamera, Icons.videocam_rounded, l10n.chatVideoRecord),
    (
      CommerceAction.videoGallery,
      Icons.video_library_rounded,
      l10n.chatVideoShare,
    ),
    (CommerceAction.location, Icons.place_rounded, l10n.chatLocationSend),
    (
      CommerceAction.liveLocation,
      Icons.share_location_rounded,
      l10n.chatLocationLiveSend,
    ),
    if (vm.role == ChatRole.vendor) ...[
      (CommerceAction.quote, Icons.request_quote_outlined, l10n.chatQuoteSend),
      (
        CommerceAction.paymentRequest,
        Icons.payments_outlined,
        l10n.chatPaymentRequestSend,
      ),
      (CommerceAction.coupon, Icons.local_offer_outlined, l10n.chatCouponSend),
    ],
  ],
];

/// Exécute un geste choisi dans le menu.
Future<void> runCommerceAction(
  BuildContext context,
  ChatViewModel vm,
  CommerceAction action,
) async {
  switch (action) {
    case CommerceAction.videoCamera:
      await vm.sendVideo(PhotoSource.camera);
    case CommerceAction.videoGallery:
      await vm.sendVideo(PhotoSource.gallery);
    case CommerceAction.location:
      await vm.shareLocation();
    case CommerceAction.liveLocation:
      await vm.shareLocation(liveMinutes: 15);
    case CommerceAction.quote:
      await _quoteSheet(context, vm);
    case CommerceAction.paymentRequest:
      await _paymentSheet(context, vm);
    case CommerceAction.coupon:
      await _couponSheet(context, vm);
  }
}

/// Montant saisi (« 2,50 », « 1500 ») en unités mineures, sans flottant.
int? minorFromText(String text, int minorUnits) {
  final m = RegExp(r'^(\d{1,9})(?:[.,](\d{1,3}))?$')
      .firstMatch(text.replaceAll(RegExp(r'\s'), ''));
  if (m == null) return null;
  final decimals = (m.group(2) ?? '').padRight(minorUnits, '0');
  if (decimals.length > minorUnits) return null;
  return int.parse('${m.group(1)}${decimals.substring(0, minorUnits)}');
}

/// Montant en unités mineures affiché pour la saisie (« 2,50 »).
String textFromMinor(int minor, int minorUnits) {
  if (minorUnits == 0) return '$minor';
  final s = minor.toString().padLeft(minorUnits + 1, '0');
  return '${s.substring(0, s.length - minorUnits)},'
      '${s.substring(s.length - minorUnits)}';
}

Future<void> _paymentSheet(BuildContext context, ChatViewModel vm) async {
  final l10n = DymLocalizations.of(context);
  final amount = TextEditingController();
  final label = TextEditingController();
  final config = vm.config;
  final ok = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(l10n.chatPaymentRequestSend),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.chatAmount(config?.currency.symbol ?? ''),
            ),
          ),
          TextField(
            controller: label,
            maxLength: 80,
            decoration: InputDecoration(labelText: l10n.chatPaymentLabel),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(d, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(d, true),
          child: Text(l10n.chatSend),
        ),
      ],
    ),
  );
  final minor = config == null
      ? null
      : minorFromText(amount.text, config.currency.minorUnits);
  final text = label.text.trim();
  amount.dispose();
  label.dispose();
  if (ok != true || minor == null || minor <= 0) return;
  await vm.sendPaymentRequest(minor, label: text.isEmpty ? null : text);
}

Future<void> _couponSheet(BuildContext context, ChatViewModel vm) async {
  final l10n = DymLocalizations.of(context);
  var percent = 10.0;
  var days = 7.0;
  final ok = await showDialog<bool>(
    context: context,
    builder: (d) => StatefulBuilder(
      builder: (d, set) => AlertDialog(
        title: Text(l10n.chatCouponSend),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.chatCoupon(percent.round())),
            Slider(
              value: percent,
              min: 5,
              max: 50,
              divisions: 9,
              label: '${percent.round()} %',
              onChanged: (v) => set(() => percent = v),
            ),
            Text(l10n.chatCouponDays(days.round())),
            Slider(
              value: days,
              min: 1,
              max: 30,
              divisions: 29,
              label: '${days.round()}',
              onChanged: (v) => set(() => days = v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text(l10n.chatSend),
          ),
        ],
      ),
    ),
  );
  if (ok ?? false) await vm.sendCoupon(percent.round(), days.round());
}

Future<void> _quoteSheet(BuildContext context, ChatViewModel vm) async {
  final l10n = DymLocalizations.of(context);
  final choices = await vm.quoteChoices();
  if (!context.mounted) return;
  if (choices.isEmpty) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(l10n.chatQuoteEmpty)));
    return;
  }
  final lines = await showModalBottomSheet<List<QuoteLine>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _QuoteEditor(choices: choices, vm: vm),
  );
  if (lines != null && lines.isNotEmpty) await vm.sendQuote(lines);
}

class _QuoteEditor extends StatefulWidget {
  const new({required this.choices, required this.vm});

  final List<QuoteChoice> choices;
  final ChatViewModel vm;

  @override
  State<_QuoteEditor> createState() => _QuoteEditorState();
}

class _QuoteEditorState extends State<_QuoteEditor> {
  final _qty = <String, int>{};
  final _price = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _price.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _units => widget.vm.config?.currency.minorUnits ?? 0;

  TextEditingController _priceOf(QuoteChoice c) => _price.putIfAbsent(
    c.variantId,
    () => TextEditingController(text: textFromMinor(c.priceMinor, _units)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = DymLocalizations.of(context);
    final t = context.dym.text;
    final money = widget.vm.config;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          children: [
            Text(l10n.chatQuoteSend, style: t.title),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(DymTokenSpace.s3),
                children: [
                  for (final c in widget.choices)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.label),
                      subtitle: (_qty[c.variantId] ?? 0) > 0
                          ? TextField(
                              controller: _priceOf(c),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: l10n.chatQuoteUnitPrice(
                                  money?.money(c.priceMinor).format() ?? '',
                                ),
                              ),
                            )
                          : Text(money?.money(c.priceMinor).format() ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l10n.chatQuoteLess,
                            onPressed: (_qty[c.variantId] ?? 0) == 0
                                ? null
                                : () => setState(
                                    () => _qty[c.variantId] =
                                        _qty[c.variantId]! - 1,
                                  ),
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          Text('${_qty[c.variantId] ?? 0}'),
                          IconButton(
                            tooltip: l10n.chatQuoteMore,
                            onPressed: () => setState(
                              () => _qty[c.variantId] =
                                  (_qty[c.variantId] ?? 0) + 1,
                            ),
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DymTokenSpace.s3),
              child: DymButton(
                label: l10n.chatSend,
                icon: Icons.send_rounded,
                onPressed: () => Navigator.pop(context, [
                  for (final c in widget.choices)
                    if ((_qty[c.variantId] ?? 0) > 0)
                      QuoteLine(
                        choice: c,
                        quantity: _qty[c.variantId]!,
                        priceMinor:
                            minorFromText(_priceOf(c).text, _units) ??
                            c.priceMinor,
                      ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
