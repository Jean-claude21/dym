import 'package:dym_core/dym_core.dart';
import 'package:dym_models/dym_models.dart';
import 'package:neon_kit/neon_kit.dart';

/// Média envoyé, prêt à publier.
typedef ContentUpload = ({String contentId, String objectKey});

/// Contenus shoppables (spec 020) : lectures et gestes par la Data API,
/// envoi des médias par URL présignée (Function).
class ContentRepository {
  new({required this._data, required this._functions, required this._uploads});

  final NeonDataClient _data;
  final NeonFunctionsClient _functions;
  final NeonObjectUploader _uploads;

  Future<Result<List<ContentItem>>> feed({
    String? zoneId,
    bool following = false,
    DateTime? before,
    String? productId,
  }) async => (await _data.rpc<Object?>(
    'content_feed',
    params: {
      'p_zone': zoneId,
      'p_tab': following ? 'following' : 'for_you',
      'p_before': before?.toUtc().toIso8601String(),
      'p_product': productId,
    },
  )).map(_items);

  Future<Result<List<StoryGroup>>> stories({String? zoneId}) async =>
      (await _data.rpc<Object?>(
        'content_stories',
        params: {'p_zone': zoneId},
      )).map(
        (json) => [
          for (final g in json! as List)
            StoryGroup.fromJson(g as Map<String, dynamic>),
        ],
      );

  Future<Result<int>> productVideoCount(String productId) async =>
      (await _data.rpc<Object?>(
        'product_video_count',
        params: {'p_product': productId},
      )).map((json) => (json! as num).toInt());

  Future<Result<void>> viewed(String contentId) async =>
      (await _data.rpc<Object?>(
        'content_viewed',
        params: {'p_content': contentId},
      )).map((_) {});

  Future<Result<void>> clicked(String contentId, String productId) async =>
      (await _data.rpc<Object?>(
        'content_clicked',
        params: {'p_content': contentId, 'p_product': productId},
      )).map((_) {});

  /// Renvoie le nombre de « j'aime ».
  Future<Result<int>> like(String contentId, {required bool like}) async =>
      (await _data.rpc<Object?>(
        'like_content',
        params: {'p_content': contentId, 'p_like': like},
      )).map((json) => (json! as num).toInt());

  Future<Result<void>> report(
    ReportTarget target,
    String targetId,
    ReportReason reason, {
    String? note,
  }) async => (await _data.rpc<Object?>(
    'report',
    params: {
      'p_target_type': target.name,
      'p_target_id': targetId,
      'p_reason': reason.name,
      'p_note': note,
    },
  )).map((_) {});

  /// Envoie une photo ou une vidéo dans le dossier de la boutique.
  Future<Result<ContentUpload>> upload(
    List<int> bytes, {
    required String contentType,
  }) async {
    final grant = await _functions.post<Map<String, dynamic>>(
      '/v1/content/uploads',
      body: {'content_type': contentType},
      // Présigner n'a pas d'effet : une nouvelle tentative est sans risque.
      idempotencyKey: Uuid.v4(),
      decode: (json) => json! as Map<String, dynamic>,
    );
    switch (grant) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final g):
        final sent = await _uploads.put(
          Uri.parse(g['upload_url'] as String),
          bytes,
          contentType: contentType,
        );
        return sent.map(
          (_) => (
            contentId: g['content_id'] as String,
            objectKey: g['object_key'] as String,
          ),
        );
    }
  }

  Future<Result<ContentItem>> publish({
    required ContentUpload upload,
    required ContentKind kind,
    String? caption,
    List<String> productIds = const [],
  }) async => (await _data.rpc<Object?>(
    'save_content',
    params: {
      'p_content': {
        'id': upload.contentId,
        'kind': kind.name,
        'media_key': upload.objectKey,
        'caption': caption,
        'product_ids': productIds,
      },
    },
  )).map((json) => ContentItem.fromJson(json! as Map<String, dynamic>));

  /// Statut texte (story sans média) : un texte sur un fond #rrggbb.
  Future<Result<ContentItem>> publishText({
    required String id,
    required String text,
    required String background,
    List<String> productIds = const [],
  }) async => (await _data.rpc<Object?>(
    'save_content',
    params: {
      'p_content': {
        'id': id,
        'kind': 'story',
        'text': text,
        'background': background,
        'product_ids': productIds,
      },
    },
  )).map((json) => ContentItem.fromJson(json! as Map<String, dynamic>));

  Future<Result<List<ContentItem>>> mine() async =>
      (await _data.rpc<Object?>('my_contents')).map(_items);

  Future<Result<void>> archive(String contentId) async =>
      (await _data.rpc<Object?>(
        'archive_content',
        params: {'p_content': contentId},
      )).map((_) {});

  Future<Result<void>> delete(String contentId) async =>
      (await _data.rpc<Object?>(
        'delete_content',
        params: {'p_content': contentId},
      )).map((_) {});

  static List<ContentItem> _items(Object? json) => [
    for (final c in json! as List)
      ContentItem.fromJson(c as Map<String, dynamic>),
  ];

  // ---------------------------------------------------------------- créatrices

  Future<Result<CreatorProfile?>> creatorProfile() async =>
      (await _data.rpc<Object?>('my_creator_profile')).map(
        (json) => json == null
            ? null
            : CreatorProfile.fromJson((json as Map).cast<String, dynamic>()),
      );

  Future<Result<CreatorProfile>> becomeCreator(
    String name, {
    String? bio,
  }) async =>
      (await _data.rpc<Object?>(
        'become_creator',
        params: {'p_display_name': name, 'p_bio': bio},
      )).map(
        (json) =>
            CreatorProfile.fromJson((json! as Map).cast<String, dynamic>()),
      );

  /// Catégories du référentiel (actives), dans l'ordre.
  Future<Result<List<ContentCategory>>> categories() async {
    final result = await _data.run(
      (db) => db
          .from('content_categories')
          .select('id, slug, label')
          .order('sort', ascending: true),
    );
    return result.map(
      (rows) => [for (final r in rows) ContentCategory.fromJson(r)],
    );
  }

  /// Catégorie proposée par l'IA pour une légende ; `Ok(null)` : aucune.
  Future<Result<String?>> classify(String caption) => _functions.post(
    '/v1/creator-content/classify',
    body: {'caption': caption},
    decode: (json) => (json as Map?)?['slug'] as String?,
  );

  /// Envoie une photo ou une vidéo dans le dossier de la créatrice.
  Future<Result<ContentUpload>> uploadCreator(
    List<int> bytes, {
    required String contentType,
  }) async {
    final grant = await _functions.post<Map<String, dynamic>>(
      '/v1/creator-content/uploads',
      body: {'content_type': contentType},
      idempotencyKey: Uuid.v4(),
      decode: (json) => json! as Map<String, dynamic>,
    );
    switch (grant) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final g):
        final sent = await _uploads.put(
          Uri.parse(g['upload_url'] as String),
          bytes,
          contentType: contentType,
        );
        return sent.map(
          (_) => (
            contentId: g['content_id'] as String,
            objectKey: g['object_key'] as String,
          ),
        );
    }
  }

  /// [categorySource] : `chosen`, `ai` ou `default` (nulle : « Autre »).
  Future<Result<ContentItem>> publishCreator({
    required ContentUpload upload,
    required bool video,
    String? caption,
    String? categoryId,
    String categorySource = 'chosen',
    List<String> productIds = const [],
  }) async => (await _data.rpc<Object?>(
    'save_creator_content',
    params: {
      'p_content': {
        'id': upload.contentId,
        'kind': video ? 'video' : 'post',
        'media_key': upload.objectKey,
        'caption': caption,
        'category_id': categoryId,
        'category_source': categorySource,
        'product_ids': productIds,
      },
    },
  )).map((json) => ContentItem.fromJson(json! as Map<String, dynamic>));

  Future<Result<List<ContentItem>>> myCreatorContents() async =>
      (await _data.rpc<Object?>('my_creator_contents')).map(_items);

  // ---------------------------------------------------------------- fil classé

  /// Fil classé par la base (spec 037) : onglet, catégorie, décalage.
  Future<Result<List<ContentItem>>> rankedFeed({
    String? zoneId,
    bool following = false,
    String? category,
    int offset = 0,
  }) async => (await _data.rpc<Object?>(
    'content_feed_ranked',
    params: {
      'p_zone': zoneId,
      'p_tab': following ? 'following' : 'for_you',
      'p_category': category,
      'p_offset': offset,
    },
  )).map(_items);

  /// S'abonner à une créatrice ([creatorId]) ou une boutique ([storeId]).
  Future<Result<bool>> follow({
    required bool on,
    String? creatorId,
    String? storeId,
  }) async => (await _data.rpc<Object?>(
    'follow',
    params: {
      'p_kind': creatorId != null ? 'creator' : 'store',
      'p_id': creatorId ?? storeId,
      'p_on': on,
    },
  )).map((json) => json == true);

  Future<Result<List<ContentComment>>> comments(String contentId) async =>
      (await _data.rpc<Object?>(
        'content_comments_list',
        params: {'p_content': contentId},
      )).map(_comments);

  Future<Result<List<ContentComment>>> addComment(
    String contentId,
    String body, {
    required String idempotencyKey,
  }) async => (await _data.rpc<Object?>(
    'add_comment',
    params: {'p_content': contentId, 'p_body': body, 'p_key': idempotencyKey},
  )).map(_comments);

  Future<Result<void>> deleteComment(String commentId) =>
      _data.rpc<void>('delete_comment', params: {'p_comment': commentId});

  static List<ContentComment> _comments(Object? json) => [
    for (final c in json as List? ?? const [])
      ContentComment.fromJson((c as Map).cast<String, dynamic>()),
  ];
}
