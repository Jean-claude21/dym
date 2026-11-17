import 'package:dym_account/dym_account.dart';
import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/content/feed_view.dart';
import 'package:dym_l10n/dym_l10n.dart';
import 'package:dym_models/dym_models.dart';
import 'package:dym_ui/dym_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/discovery_fixtures.dart';

const _cdn = 'https://cdn.test/0f8fad5b-d9cb-469f-a165-70867728950e';

ContentItem _video({String? stream, int? cover, ContentStats? stats}) =>
    ContentItem(
      id: 'v1',
      kind: ContentKind.video,
      mediaKey: 'stores/s1/contents/v1.mp4',
      isVideo: true,
      createdAt: DateTime.utc(2026, 11, 17),
      streamUrl: stream,
      coverFrame: cover,
      streamThumbCount: stream == null ? 0 : 6,
      stats: stats,
    );

void main() {
  group('médias de la vidéo convertie (spec 103)', () {
    test('miniature par défaut, choisie, images proposées', () {
      final v = _video(stream: '$_cdn/playlist.m3u8');
      expect(v.posterUrl, '$_cdn/thumbnail.jpg');
      expect(v.copyWith(coverFrame: 3).posterUrl, '$_cdn/thumbnail_3.jpg');
      expect(v.frameUrls, hasLength(6));
      expect(v.previewUrl, '$_cdn/preview.webp');
      expect(v.lightVideoUrl, '$_cdn/play_240p.mp4');
      expect(
        v.copyWith(coverFrame: 3).copyWith(clearCover: true).coverFrame,
        isNull,
      );
    });

    test('pas encore convertie : rien de Bunny', () {
      final v = _video();
      expect(v.posterUrl, isNull);
      expect(v.frameUrls, isEmpty);
      expect(v.lightVideoUrl, isNull);
    });

    test('source : légère, sinon HLS, sinon originale', () {
      final service = MemoryContentService(discovery: memoryDiscovery());
      final converted = _video(stream: '$_cdn/playlist.m3u8');
      expect(
        videoSource(converted, service, dataSaver: true).toString(),
        '$_cdn/play_240p.mp4',
      );
      expect(
        videoSource(converted, service, dataSaver: false).toString(),
        '$_cdn/playlist.m3u8',
      );
      expect(
        videoSource(_video(), service, dataSaver: true).path,
        endsWith('stores/s1/contents/v1.mp4'),
      );
    });
  });

  testWidgets('statistiques : temps moyen, fin de lecture, ventes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DymTheme.light(),
        localizationsDelegates: DymLocalizations.localizationsDelegates,
        supportedLocales: DymLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: ContentStatsLine(
            item: _video(
              stats: const ContentStats(
                avgWatchMs: 6400,
                completionRate: 0.25,
                salesOrders: 2,
                salesMinor: 3000,
              ),
            ),
            money: (minor) => '$minor F',
          ),
        ),
      ),
    );
    expect(find.textContaining('6 s'), findsOneWidget);
    expect(find.textContaining('25 %'), findsOneWidget);
    expect(find.textContaining('2 ventes générées · 3000 F'), findsOneWidget);
  });
}
