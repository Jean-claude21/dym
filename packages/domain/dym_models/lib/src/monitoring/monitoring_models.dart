import 'package:meta/meta.dart';

/// Taux de compréhension d'un jour (série de l'écran 77).
@immutable
class AiDay {
  const new({required this.day, this.percent});

  factory fromJson(Map<String, dynamic> json) => AiDay(
    day: DateTime.parse(json['day'] as String),
    percent: (json['percent'] as num?)?.toInt(),
  );

  final DateTime day;

  /// Nul : aucune requête ce jour-là.
  final int? percent;
}

/// Requête IA non comprise (sans personne).
@immutable
class AiMiss {
  const new({
    required this.at,
    required this.usage,
    required this.outcome,
    this.query,
  });

  factory fromJson(Map<String, dynamic> json) => AiMiss(
    at: DateTime.parse(json['at'] as String),
    usage: json['usage'] as String,
    outcome: json['outcome'] as String,
    query: json['query'] as String?,
  );

  final DateTime at;

  /// `search_transcription`, `search_from_photo` ou `intent_copilot`.
  final String usage;

  /// `no_result` ou `failure`.
  final String outcome;
  final String? query;
}

/// Santé de l'IA et des paiements (écran 77, A-AI-01..03, A-DASH-06).
@immutable
class AiHealth {
  const new({
    this.requests = 0,
    this.understoodPercent,
    this.latencyMs,
    this.fallbackPercent,
    this.paymentsSucceeded = 0,
    this.paymentsFailed = 0,
    this.paymentsAlert = false,
    this.series = const [],
    this.misses = const [],
  });

  factory fromJson(Map<String, dynamic> json) {
    final payments = (json['payments_1h'] as Map?)?.cast<String, dynamic>();
    return AiHealth(
      requests: (json['requests'] as num?)?.toInt() ?? 0,
      understoodPercent: (json['understood_percent'] as num?)?.toInt(),
      latencyMs: (json['latency_ms'] as num?)?.toInt(),
      fallbackPercent: (json['fallback_percent'] as num?)?.toInt(),
      paymentsSucceeded: (payments?['succeeded'] as num?)?.toInt() ?? 0,
      paymentsFailed: (payments?['failed'] as num?)?.toInt() ?? 0,
      paymentsAlert: json['payments_alert'] as bool? ?? false,
      series: [
        for (final d in json['series_7d'] as List? ?? const [])
          AiDay.fromJson(d as Map<String, dynamic>),
      ],
      misses: [
        for (final m in json['misses'] as List? ?? const [])
          AiMiss.fromJson(m as Map<String, dynamic>),
      ],
    );
  }

  final int requests;
  final int? understoodPercent;
  final int? latencyMs;
  final int? fallbackPercent;
  final int paymentsSucceeded;
  final int paymentsFailed;

  /// Paiements de la dernière heure sous 90 % de réussite.
  final bool paymentsAlert;
  final List<AiDay> series;
  final List<AiMiss> misses;

  int? get paymentsPercent => paymentsSucceeded + paymentsFailed == 0
      ? null
      : (paymentsSucceeded * 100 / (paymentsSucceeded + paymentsFailed))
            .round();
}

/// Segment d'une relance (écran 78).
enum BroadcastSegment { regular, month, all }

/// Audience d'une relance et réglage du stock bas.
@immutable
class BroadcastAudience {
  const new({
    this.regular = 0,
    this.month = 0,
    this.all = 0,
    this.lastSentAt,
    this.lowStockThreshold,
  });

  factory fromJson(Map<String, dynamic> json) => BroadcastAudience(
    regular: (json['regular'] as num?)?.toInt() ?? 0,
    month: (json['month'] as num?)?.toInt() ?? 0,
    all: (json['all'] as num?)?.toInt() ?? 0,
    lastSentAt: json['last_sent_at'] == null
        ? null
        : DateTime.parse(json['last_sent_at'] as String),
    lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt(),
  );

  final int regular;
  final int month;
  final int all;
  final DateTime? lastSentAt;

  /// Nul : alerte de stock bas coupée.
  final int? lowStockThreshold;

  int count(BroadcastSegment s) => switch (s) {
    BroadcastSegment.regular => regular,
    BroadcastSegment.month => month,
    BroadcastSegment.all => all,
  };
}
