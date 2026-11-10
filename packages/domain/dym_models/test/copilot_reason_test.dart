import 'package:dym_models/dym_models.dart';
import 'package:test/test.dart';

void main() {
  group('raison du copilote (spec 028)', () {
    Map<String, dynamic> line(Object? reason) => {
      'variant_id': 'v',
      'product_id': 'p',
      'name': 'Tomates',
      'quantity': 2,
      'unit_price_minor': 400,
      'line_minor': 800,
      'reason': reason,
    };

    test('raison connue lue', () {
      expect(
        CopilotLine.fromJson(line('best_price')).reason,
        CopilotReason.bestPrice,
      );
    });

    test('raison inconnue ou absente ignorée', () {
      expect(CopilotLine.fromJson(line('future_reason')).reason, isNull);
      expect(CopilotLine.fromJson(line(null)).reason, isNull);
    });
  });
}
