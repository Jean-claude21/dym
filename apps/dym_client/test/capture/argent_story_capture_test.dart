@Tags(['golden'])
library;

import 'package:dym_client/features/content/content_service.dart';
import 'package:dym_client/features/content/stories.dart';
import 'package:dym_client/features/wallet/qr_pay_view.dart';
import 'package:dym_client/features/wallet/testing.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/discovery_fixtures.dart';
import 'capture.dart';

/// Paiement par QR et story (spec 064, revue des dernières pages).
void main() {
  testWidgets('payer par QR', (tester) async {
    await capture(
      tester,
      'payer_qr',
      QrPayView(
        service: MemoryWalletService(config: togoConfig(), balanceMinor: 12500),
        onDone: () {},
      ),
    );
  });
  testWidgets('story', (tester) async {
    await capture(
      tester,
      'story',
      StoryViewer(
        service: MemoryContentService(discovery: memoryDiscovery()),
        groups: [
          StoryGroup(
            store: const ContentStore(
              id: 's1',
              name: "Étal d'Akossiwa",
              origin: 'marche',
            ),
            stories: [
              ContentItem(
                id: 'st0',
                kind: ContentKind.story,
                isText: true,
                mediaKey: null,
                isVideo: false,
                background: '#145C43',
                caption: 'Arrivage de tomates ce matin !',
                createdAt: DateTime.utc(2026, 11, 12, 7),
              ),
            ],
          ),
        ],
        onClose: () {},
      ),
    );
    await tester.pump(const Duration(seconds: 10));
  });
}
