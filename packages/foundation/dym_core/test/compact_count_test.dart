import 'package:dym_core/dym_core.dart';
import 'package:test/test.dart';

void main() {
  test('compteur court selon la langue', () {
    expect(compactCount(382, 'fr'), '382');
    expect(compactCount(12400, 'fr'), contains('12,4'));
    expect(compactCount(12400, 'en'), '12.4K');
  });
}
