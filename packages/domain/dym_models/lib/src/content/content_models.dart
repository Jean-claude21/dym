import 'package:dym_models/src/discovery/discovery_models.dart';
import 'package:meta/meta.dart';

/// Story 24 h ou vidéo shoppable (spec 020).
enum ContentKind {
  story,
  video;

  static ContentKind fromCode(String? code) => code == 'story' ? story : video;
}

/// Boutique d'un contenu.
@immutable
class ContentStore {
  const new({required this.id, required this.name, this.origin, this.coverKey});

  factory fromJson(Map<String, dynamic> json) => ContentStore(
    id: json['id'] as String,
    name: json['name'] as String,
    origin: json['origin'] as String?,
    coverKey: json['cover_key'] as String?,
  );

  final String id;
  final String name;
  final String? origin;
  final String? coverKey;
}

/// Contenu publié, avec ses produits tagués et ses statistiques (vendeuse).
@immutable
class ContentItem {
  const new({
    required this.id,
    required this.kind,
    required this.mediaKey,
    required this.isVideo,
    required this.store,
    required this.createdAt,
    this.caption,
    this.status = 'published',
    this.expiresAt,
    this.likeCount = 0,
    this.liked = false,
    this.products = const [],
    this.viewCount = 0,
    this.clickCount = 0,
    this.reportCount = 0,
  });

  factory fromJson(Map<String, dynamic> json) => ContentItem(
    id: json['id'] as String,
    kind: ContentKind.fromCode(json['kind'] as String?),
    mediaKey: json['media_key'] as String,
    isVideo: json['media_type'] == 'video',
    caption: json['caption'] as String?,
    status: json['status'] as String? ?? 'published',
    createdAt: DateTime.parse(json['created_at'] as String),
    expiresAt: json['expires_at'] == null
        ? null
        : DateTime.parse(json['expires_at'] as String),
    store: ContentStore.fromJson(json['store'] as Map<String, dynamic>),
    likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
    liked: json['liked'] as bool? ?? false,
    products: [
      for (final p in json['products'] as List? ?? const [])
        if (p != null) CatalogItem.fromJson(p as Map<String, dynamic>),
    ],
    viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
    clickCount: (json['click_count'] as num?)?.toInt() ?? 0,
    reportCount: (json['report_count'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final ContentKind kind;
  final String mediaKey;
  final bool isVideo;
  final String? caption;
  final String status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final ContentStore store;
  final int likeCount;
  final bool liked;
  final List<CatalogItem> products;
  final int viewCount;
  final int clickCount;
  final int reportCount;

  ContentItem copyWith({int? likeCount, bool? liked, String? status}) =>
      ContentItem(
        id: id,
        kind: kind,
        mediaKey: mediaKey,
        isVideo: isVideo,
        caption: caption,
        status: status ?? this.status,
        createdAt: createdAt,
        expiresAt: expiresAt,
        store: store,
        likeCount: likeCount ?? this.likeCount,
        liked: liked ?? this.liked,
        products: products,
        viewCount: viewCount,
        clickCount: clickCount,
        reportCount: reportCount,
      );
}

/// Stories d'une boutique (rangée de l'accueil, C-HOME-07).
@immutable
class StoryGroup {
  const new({required this.store, this.stories = const []});

  factory fromJson(Map<String, dynamic> json) => StoryGroup(
    store: ContentStore.fromJson(json['store'] as Map<String, dynamic>),
    stories: [
      for (final s in json['stories'] as List? ?? const [])
        ContentItem.fromJson(s as Map<String, dynamic>),
    ],
  );

  final ContentStore store;
  final List<ContentItem> stories;
}

/// Motif d'un signalement.
enum ReportReason { misleading, offensive, forbidden, spam, other }

/// Cible d'un signalement.
enum ReportTarget { content, product, review }

/// Ligne de la file de modération (écran 76) : une cible signalée.
@immutable
class ModerationItem {
  const new({
    required this.target,
    required this.targetId,
    required this.count,
    required this.firstAt,
    this.reasons = const [],
    this.notes = const [],
    this.status = 'open',
    this.decisionReason,
    this.title = '',
    this.storeName,
    this.mediaKey,
    this.isVideo = false,
    this.contentKind,
    this.tags = const [],
    this.rating,
  });

  factory fromJson(Map<String, dynamic> json) {
    final preview = (json['preview'] as Map?)?.cast<String, dynamic>() ?? {};
    return ModerationItem(
      target: ReportTarget.values.byName(json['target_type'] as String),
      targetId: json['target_id'] as String,
      count: (json['count'] as num).toInt(),
      firstAt: DateTime.parse(json['first_at'] as String),
      reasons: [
        for (final r in json['reasons'] as List? ?? const [])
          ReportReason.values.byName(r as String),
      ],
      notes: [for (final n in json['notes'] as List? ?? const []) n as String],
      status: json['status'] as String? ?? 'open',
      decisionReason: json['decision_reason'] as String?,
      title: preview['title'] as String? ?? '',
      storeName: preview['store_name'] as String?,
      mediaKey: preview['media_key'] as String?,
      isVideo: preview['media_type'] == 'video',
      contentKind: preview['kind'] == null
          ? null
          : ContentKind.fromCode(preview['kind'] as String),
      tags: [for (final t in preview['tags'] as List? ?? const []) t as String],
      rating: (preview['rating'] as num?)?.toInt(),
    );
  }

  final ReportTarget target;
  final String targetId;
  final int count;
  final DateTime firstAt;
  final List<ReportReason> reasons;
  final List<String> notes;

  /// `open`, `kept` ou `removed`.
  final String status;
  final String? decisionReason;
  final String title;
  final String? storeName;
  final String? mediaKey;
  final bool isVideo;
  final ContentKind? contentKind;
  final List<String> tags;
  final int? rating;
}
