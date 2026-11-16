import 'dart:async';

import 'package:dym_core/dym_core.dart';
import 'package:dym_data/dym_data.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_platform/dym_platform.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Article proposable dans un devis (boutique) : variante et prix affiché.
@immutable
class QuoteChoice {
  const new({
    required this.variantId,
    required this.label,
    required this.priceMinor,
  });

  final String variantId;
  final String label;

  /// Prix affiché : le devis ne peut pas le dépasser (vérifié en base).
  final int priceMinor;
}

/// Ligne de devis choisie par la vendeuse.
@immutable
class QuoteLine {
  const new({
    required this.choice,
    required this.quantity,
    required this.priceMinor,
  });

  final QuoteChoice choice;
  final int quantity;
  final int priceMinor;

  Map<String, Object> toJson() => {
    'variant_id': choice.variantId,
    'quantity': quantity,
    'price_minor': priceMinor,
  };
}

/// Chat de commerce (spec 099) : vidéo, position, devis, paiement, coupon,
/// transcription. Capacité facultative du chat ; absente : menu réduit.
abstract interface class ChatCommerce {
  Future<Result<PickedVideo?>> pickVideo(PhotoSource source);

  Future<Result<ChatMessage>> sendVideo(
    String conversationId,
    PickedVideo video, {
    required String idempotencyKey,
  });

  /// Position de l'appareil ; [liveMinutes] > 0 : partage en direct.
  Future<Result<ChatMessage>> sendLocation(
    String conversationId, {
    required String idempotencyKey,
    int liveMinutes = 0,
  });

  /// Met à jour une position en direct (appelé régulièrement).
  Future<Result<ChatMessage>> refreshLocation(String messageId);

  Future<Result<ChatMessage>> stopLocation(String messageId);

  /// Boutique : articles proposables dans un devis.
  Future<Result<List<QuoteChoice>>> quoteChoices();

  Future<Result<ChatMessage>> sendQuote(
    String conversationId,
    List<QuoteLine> lines, {
    required String idempotencyKey,
    String? note,
  });

  Future<Result<void>> acceptQuote(String quoteId);

  Future<Result<ChatMessage>> sendPaymentRequest(
    String conversationId, {
    required int amountMinor,
    required String idempotencyKey,
    String? label,
  });

  Future<Result<void>> payRequest(
    String code, {
    required String idempotencyKey,
  });

  Future<Result<ChatMessage>> sendCoupon(
    String conversationId, {
    required int percent,
    required int days,
    required String idempotencyKey,
  });

  Future<Result<void>> claimCoupon(String couponId);

  /// Texte d'un vocal ; `simulated` : pas de fournisseur (signalé).
  Future<Result<({String? text, bool simulated})>> transcribe(String messageId);
}

class NeonChatCommerce implements ChatCommerce {
  new({
    required this._repository,
    required this._videos,
    required this._location,
    this._choices,
  });

  final MessagingRepository _repository;
  final VideoPicker _videos;
  final LocationProvider _location;

  /// Boutique : articles du catalogue ; absent (cliente) : liste vide.
  final Future<Result<List<QuoteChoice>>> Function()? _choices;

  @override
  Future<Result<PickedVideo?>> pickVideo(PhotoSource source) =>
      _videos.pick(source);

  @override
  Future<Result<ChatMessage>> sendVideo(
    String conversationId,
    PickedVideo video, {
    required String idempotencyKey,
  }) => _repository.sendVideo(
    conversationId,
    video.bytes,
    contentType: video.contentType,
    idempotencyKey: idempotencyKey,
  );

  Future<Result<GeoPoint>> _here() async => switch (await _location.current()) {
    Ok(value: final p?) => Ok(p),
    Ok() => const Err(ValidationFailure('location_unavailable')),
    Err(:final failure) => Err(failure),
  };

  @override
  Future<Result<ChatMessage>> sendLocation(
    String conversationId, {
    required String idempotencyKey,
    int liveMinutes = 0,
  }) async {
    switch (await _here()) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final p):
        return await _repository.sendLocation(
          conversationId,
          latitude: p.latitude,
          longitude: p.longitude,
          idempotencyKey: idempotencyKey,
          liveMinutes: liveMinutes,
        );
    }
  }

  @override
  Future<Result<ChatMessage>> refreshLocation(String messageId) async {
    switch (await _here()) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final p):
        return await _repository.updateLocation(
          messageId,
          latitude: p.latitude,
          longitude: p.longitude,
        );
    }
  }

  @override
  Future<Result<ChatMessage>> stopLocation(String messageId) =>
      _repository.stopLocation(messageId);

  @override
  Future<Result<List<QuoteChoice>>> quoteChoices() async =>
      await _choices?.call() ?? const Ok([]);

  @override
  Future<Result<ChatMessage>> sendQuote(
    String conversationId,
    List<QuoteLine> lines, {
    required String idempotencyKey,
    String? note,
  }) => _repository.sendQuote(
    conversationId,
    [for (final l in lines) l.toJson()],
    idempotencyKey: idempotencyKey,
    note: note,
  );

  @override
  Future<Result<void>> acceptQuote(String quoteId) =>
      _repository.acceptQuote(quoteId);

  @override
  Future<Result<ChatMessage>> sendPaymentRequest(
    String conversationId, {
    required int amountMinor,
    required String idempotencyKey,
    String? label,
  }) => _repository.sendPaymentRequest(
    conversationId,
    amountMinor: amountMinor,
    idempotencyKey: idempotencyKey,
    label: label,
  );

  @override
  Future<Result<void>> payRequest(
    String code, {
    required String idempotencyKey,
  }) => _repository.payRequest(code, idempotencyKey: idempotencyKey);

  @override
  Future<Result<ChatMessage>> sendCoupon(
    String conversationId, {
    required int percent,
    required int days,
    required String idempotencyKey,
  }) => _repository.sendCoupon(
    conversationId,
    percent: percent,
    days: days,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<Result<void>> claimCoupon(String couponId) =>
      _repository.claimCoupon(couponId);

  @override
  Future<Result<({String? text, bool simulated})>> transcribe(
    String messageId,
  ) => _repository.transcribe(messageId);
}
