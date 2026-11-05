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
}
