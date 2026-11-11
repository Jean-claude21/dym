// Fakes repris des tests d'écran : certaines aides n'y servent pas.
@Tags(['golden'])
library;

import 'package:dym_client/features/discovery/copilot/copilot_service.dart';
import 'package:dym_client/features/shopping/shopping_viewmodels.dart';
import 'package:dym_client/features/shopping/shopping_views.dart';
import 'package:dym_client/features/shopping/testing.dart';
import 'package:dym_models/dym_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/discovery_fixtures.dart';
import 'capture.dart';

void main() {
  testWidgets('liste_edition', (tester) async {
    await capture(
      tester,
      'liste_edition',
      ShoppingEditView(
        service: MemoryShoppingService(
          copilot: MemoryCopilotService(discovery: memoryDiscovery()),
        ),
        draft: const ShoppingDraft(
          name: 'Samedi',
          items: [
            ShoppingItem(label: 'Tomates', quantity: 2),
            ShoppingItem(label: 'Gombo'),
          ],
        ),
        today: DateTime(2026, 11, 10),
        onBack: () {},
        onSaved: (_) {},
      ),
    );
  });
}
