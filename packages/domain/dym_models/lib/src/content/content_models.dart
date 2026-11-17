import 'package:dym_core/dym_core.dart';
import 'package:dym_models/src/discovery/discovery_models.dart';
import 'package:dym_models/src/json.dart';
import 'package:dym_models/src/search/shopping_models.dart';
import 'package:meta/meta.dart';

/// Story 24 h, vidéo shoppable (spec 020) ou post de créatrice (spec 036).
enum ContentKind {
  story,
  video,
  post;

  static ContentKind fromCode(String? code) => switch (code) {
    'story' => story,
    'post' => post,
    _ => video,
  };
}

/// Autrice d'un post (spec 036).
@immutable
class ContentAuthor {
  const new({required this.id, required this.displayName, this.bio});

  factory fromJson(Map<String, dynamic> json) => ContentAuthor(
    id: json['id'] as String,
    displayName: json['display_name'] as String,
    bio: json['bio'] as String?,
  );

  final String id;
  final String displayName;
  final String? bio;
}

/// Catégorie d'un contenu (référentiel).
@immutable
class ContentCategory {
  const new({required this.id, required this.slug, required this.label});

  factory fromJson(Map<String, dynamic> json) => ContentCategory(
    id: json['id'] as String,
    slug: json['slug'] as String,
    label: LocalizedText.fromJson(json['label']),
  );

  final String id;
  final String slug;
  final LocalizedText label;
}

/// Profil créateur de la personne (spec 036).
@immutable
class CreatorProfile {
  const new({required this.displayName, this.bio, this.tiktokHandle});

  factory fromJson(Map<String, dynamic> json) => CreatorProfile(
    displayName: json['display_name'] as String,
    bio: json['bio'] as String?,
    tiktokHandle: json['tiktok_handle'] as String?,
  );

  final String displayName;
  final String? bio;

  /// Compte TikTok déclaré (spec 040), sans « @ ».
  final String? tiktokHandle;
}

/// État d'une commission d'affiliation.
enum CommissionStatus {
  pending,
  paid,
  cancelled;

  static CommissionStatus parse(Object? value) => switch (value) {
    'paid' => paid,
    'cancelled' => cancelled,
    _ => pending,
  };
}

/// Une commission gagnée grâce à un contenu (spec 039).
@immutable
class CreatorCommission {
  const new({
    required this.id,
    required this.status,
    required this.amountMinor,
    required this.rateBps,
    required this.createdAt,
    this.productName,
    this.contentCaption,
  });

  factory fromJson(Map<String, dynamic> json) => CreatorCommission(
    id: json['id']! as String,
    status: CommissionStatus.parse(json['status']),
    amountMinor: minorFromJson(json['amount_minor']),
    rateBps: (json['rate_bps']! as num).toInt(),
    createdAt: DateTime.parse(json['created_at']! as String),
    productName: json['product_name'] as String?,
    contentCaption: json['content_caption'] as String?,
  );

  final String id;
  final CommissionStatus status;
  final int amountMinor;

  /// Taux en points de base (500 = 5 %).
  final int rateBps;
  final DateTime createdAt;
  final String? productName;
  final String? contentCaption;
}

/// Gains d'affiliation de la créatrice (`public.my_commissions()`).
@immutable
class CreatorCommissions {
  const new({this.pendingMinor = 0, this.paidMinor = 0, this.items = const []});

  factory fromJson(Map<String, dynamic> json) => CreatorCommissions(
    pendingMinor: minorFromJson(json['pending_minor']),
    paidMinor: minorFromJson(json['paid_minor']),
    items: [
      for (final i in json['items'] as List? ?? const [])
        CreatorCommission.fromJson((i as Map).cast<String, dynamic>()),
    ],
  );

  final int pendingMinor;
  final int paidMinor;
  final List<CreatorCommission> items;
}

/// Taux d'affiliation d'une boutique (`public.my_affiliate_rate()`).
@immutable
class AffiliateRate {
  const new({required this.minRateBps, this.rateBps, this.storeRateBps});

  factory fromJson(Map<String, dynamic> json) => AffiliateRate(
    rateBps: (json['affiliate_rate_bps'] as num?)?.toInt(),
    storeRateBps: (json['store_rate_bps'] as num?)?.toInt(),
    minRateBps: (json['min_rate_bps']! as num).toInt(),
  );

  /// Taux choisi ; null : celui du niveau au-dessus (boutique, puis pays).
  final int? rateBps;

  /// Taux de la boutique ; null : minimum du pays.
  final int? storeRateBps;
  final int minRateBps;

  int get effectiveBps => rateBps ?? storeRateBps ?? minRateBps;
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
    required this.createdAt,
    this.store,
    this.author,
    this.category,
    this.isText = false,
    this.background,
    this.caption,
    this.status = 'published',
    this.expiresAt,
    this.likeCount = 0,
    this.liked = false,
    this.products = const [],
    this.viewCount = 0,
    this.clickCount = 0,
    this.reportCount = 0,
    this.commentCount = 0,
    this.followed = false,
    this.ingredients = const [],
    this.sourceUrl,
    this.saved = false,
    this.saveCount = 0,
    this.cooked = false,
    this.cookCount = 0,
    this.streamUrl,
    this.coverFrame,
    this.streamThumbCount = 0,
    this.stats,
  });

  factory fromJson(Map<String, dynamic> json) => ContentItem(
    id: json['id'] as String,
    kind: ContentKind.fromCode(json['kind'] as String?),
    mediaKey: json['media_key'] as String?,
    isVideo: json['media_type'] == 'video',
    isText: json['media_type'] == 'text',
    background: json['background'] as String?,
    caption: json['caption'] as String?,
    status: json['status'] as String? ?? 'published',
    createdAt: DateTime.parse(json['created_at'] as String),
    expiresAt: json['expires_at'] == null
        ? null
        : DateTime.parse(json['expires_at'] as String),
    store: switch (json['store']) {
      final Map<String, dynamic> s => ContentStore.fromJson(s),
      _ => null,
    },
    author: switch (json['author']) {
      final Map<String, dynamic> a => ContentAuthor.fromJson(a),
      _ => null,
    },
    category: switch (json['category']) {
      final Map<String, dynamic> c => ContentCategory.fromJson(c),
      _ => null,
    },
    likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
    liked: json['liked'] as bool? ?? false,
    products: [
      for (final p in json['products'] as List? ?? const [])
        if (p != null) CatalogItem.fromJson(p as Map<String, dynamic>),
    ],
    viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
    clickCount: (json['click_count'] as num?)?.toInt() ?? 0,
    reportCount: (json['report_count'] as num?)?.toInt() ?? 0,
    commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
    followed: json['followed'] as bool? ?? false,
    ingredients: [
      for (final i in json['ingredients'] as List? ?? const [])
        ShoppingItem.fromJson((i as Map).cast<String, dynamic>()),
    ],
    sourceUrl: json['source_url'] as String?,
    saved: json['saved'] as bool? ?? false,
    saveCount: (json['save_count'] as num?)?.toInt() ?? 0,
    cooked: json['cooked'] as bool? ?? false,
    cookCount: (json['cook_count'] as num?)?.toInt() ?? 0,
    streamUrl: json['stream_url'] as String?,
    coverFrame: (json['cover_frame'] as num?)?.toInt(),
    streamThumbCount: (json['stream_thumb_count'] as num?)?.toInt() ?? 0,
    stats: switch (json['stats']) {
      final Map<String, dynamic> m => ContentStats.fromJson(m),
      _ => null,
    },
  );

  /// Image de la vidéo choisie comme miniature (spec 103) ; null : par défaut.
  final int? coverFrame;

  /// Images de la vidéo proposées pour la miniature (spec 103).
  final int streamThumbCount;

  /// Statistiques pour la propriétaire (« Mes vidéos », spec 103).
  final ContentStats? stats;

  /// Dossier de la vidéo adaptative (`…/<id>/`), une fois convertie.
  String? get _streamBase {
    final url = streamUrl;
    if (url == null || !url.endsWith('/playlist.m3u8')) return null;
    return url.substring(0, url.length - 'playlist.m3u8'.length);
  }

  /// Miniature de la vidéo convertie : image choisie, sinon par défaut.
  String? get posterUrl => switch (_streamBase) {
    final base? =>
      coverFrame == null
          ? '${base}thumbnail.jpg'
          : '${base}thumbnail_$coverFrame.jpg',
    null => null,
  };

  /// Images proposées pour la miniature (1..n).
  List<String> get frameUrls => switch (_streamBase) {
    final base? => [
      for (var i = 1; i <= streamThumbCount; i++) '${base}thumbnail_$i.jpg',
    ],
    null => const [],
  };

  /// Aperçu animé de quelques secondes.
  String? get previewUrl => switch (_streamBase) {
    final base? => '${base}preview.webp',
    null => null,
  };

  /// Version légère (MP4 240p) pour l'économie de données.
  String? get lightVideoUrl => switch (_streamBase) {
    final base? => '${base}play_240p.mp4',
    null => null,
  };

  /// « Mes recettes » (spec 101).
  final bool saved;
  final int saveCount;

  /// « J'ai fait la recette » (spec 101).
  final bool cooked;
  final int cookCount;

  /// Lecture adaptative HLS, une fois la vidéo convertie (spec 101).
  final String? streamUrl;

  final String id;
  final ContentKind kind;

  /// Nul pour un statut texte.
  final String? mediaKey;
  final bool isVideo;

  /// Statut texte : [caption] sur un fond [background] (#rrggbb).
  final bool isText;
  final String? background;
  final String? caption;
  final String status;
  final DateTime createdAt;
  final DateTime? expiresAt;

  /// Boutique (contenus de vendeuse) ; nulle pour un post de créatrice.
  final ContentStore? store;

  /// Autrice (post de créatrice, spec 036).
  final ContentAuthor? author;
  final ContentCategory? category;
  final int likeCount;
  final bool liked;
  final List<CatalogItem> products;
  final int viewCount;
  final int clickCount;
  final int reportCount;

  /// Commentaires publiés (spec 037).
  final int commentCount;

  /// La personne suit l'autrice ou la boutique (spec 037).
  final bool followed;

  /// Ingrédients génériques d'une recette (spec 038).
  final List<ShoppingItem> ingredients;

  /// Vidéo d'origine sur TikTok (spec 040) ; null : créée sur DYM.
  final String? sourceUrl;

  /// « Tout pour la faire » possible.
  bool get hasRecipe => ingredients.isNotEmpty || products.isNotEmpty;

  ContentItem copyWith({
    int? likeCount,
    bool? liked,
    String? status,
    int? commentCount,
    bool? followed,
    bool? saved,
    int? saveCount,
    bool? cooked,
    int? cookCount,
    int? coverFrame,
    bool clearCover = false,
  }) => ContentItem(
    id: id,
    kind: kind,
    mediaKey: mediaKey,
    isVideo: isVideo,
    isText: isText,
    background: background,
    caption: caption,
    status: status ?? this.status,
    createdAt: createdAt,
    expiresAt: expiresAt,
    store: store,
    author: author,
    category: category,
    likeCount: likeCount ?? this.likeCount,
    liked: liked ?? this.liked,
    products: products,
    viewCount: viewCount,
    clickCount: clickCount,
    reportCount: reportCount,
    commentCount: commentCount ?? this.commentCount,
    followed: followed ?? this.followed,
    ingredients: ingredients,
    sourceUrl: sourceUrl,
    saved: saved ?? this.saved,
    saveCount: saveCount ?? this.saveCount,
    cooked: cooked ?? this.cooked,
    cookCount: cookCount ?? this.cookCount,
    streamUrl: streamUrl,
    coverFrame: clearCover ? null : coverFrame ?? this.coverFrame,
    streamThumbCount: streamThumbCount,
    stats: stats,
  );
}

/// Commentaire d'un contenu (spec 037).
@immutable
class ContentComment {
  const new({
    required this.id,
    required this.body,
    required this.authorName,
    required this.createdAt,
    this.mine = false,
  });

  factory fromJson(Map<String, dynamic> json) => ContentComment(
    id: json['id'] as String,
    body: json['body'] as String,
    authorName: json['author_name'] as String? ?? '?',
    createdAt: DateTime.parse(json['created_at'] as String),
    mine: json['mine'] as bool? ?? false,
  );

  final String id;
  final String body;
  final String authorName;
  final DateTime createdAt;
  final bool mine;
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
enum ReportTarget { content, product, review, comment }

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
    this.aiVerdict,
    this.aiReason,
  });

  factory fromJson(Map<String, dynamic> json) {
    final preview = (json['preview'] as Map?)?.cast<String, dynamic>() ?? {};
    final ai = (json['ai'] as Map?)?.cast<String, dynamic>();
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
      aiVerdict: ai?['verdict'] as String?,
      aiReason: ai?['reason'] as String?,
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

  /// Avis de l'IA (spec 054) : `keep`, `remove` ou `unsure` ; l'équipe décide.
  final String? aiVerdict;
  final String? aiReason;
}

/// Profil public d'une créatrice ou d'une boutique (spec 101).
@immutable
class ContentProfile {
  const new({
    required this.kind,
    required this.id,
    required this.name,
    this.bio,
    this.followers = 0,
    this.following = false,
    this.contents = const [],
  });

  factory fromJson(Map<String, dynamic> json) => ContentProfile(
    kind: json['kind'] as String? ?? 'creator',
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    bio: json['bio'] as String?,
    followers: (json['followers'] as num?)?.toInt() ?? 0,
    following: json['following'] as bool? ?? false,
    contents: [
      for (final c in json['contents'] as List? ?? const [])
        ContentItem.fromJson((c as Map).cast<String, dynamic>()),
    ],
  );

  /// `creator` ou `store`.
  final String kind;
  final String id;
  final String name;
  final String? bio;
  final int followers;
  final bool following;
  final List<ContentItem> contents;
}

/// Statistiques d'une vidéo pour sa propriétaire (spec 103) : temps moyen,
/// fin de lecture, ventes générées (commandes livrées des produits tagués,
/// passées dans les 7 jours après avoir regardé la vidéo).
@immutable
class ContentStats {
  const new({
    this.avgWatchMs = 0,
    this.completionRate = 0,
    this.salesOrders = 0,
    this.salesMinor = 0,
    this.salesCurrency,
  });

  factory fromJson(Map<String, dynamic> json) => ContentStats(
    avgWatchMs: (json['avg_watch_ms'] as num?)?.toInt() ?? 0,
    completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
    salesOrders: (json['sales_orders'] as num?)?.toInt() ?? 0,
    salesMinor: (json['sales_minor'] as num?)?.toInt() ?? 0,
    salesCurrency: json['sales_currency'] as String?,
  );

  final int avgWatchMs;

  /// Part des vues regardées jusqu'au bout (0..1).
  final double completionRate;
  final int salesOrders;
  final int salesMinor;
  final String? salesCurrency;
}
