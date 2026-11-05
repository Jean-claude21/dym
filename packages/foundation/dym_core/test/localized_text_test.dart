import 'package:dym_core/dym_core.dart';
import 'package:test/test.dart';

void main() {
  group('LocalizedText', () {
    final label = LocalizedText.fromJson(const {
      'fr': 'Légumes',
      'en': 'Vegetables',
    });

    test('langue demandée, avec ou sans région', () {
      expect(label.resolve('en'), 'Vegetables');
      expect(label.resolve('en_GH'), 'Vegetables');
      expect(label.resolve('fr-TG'), 'Légumes');
    });

    test('langue absente : repli en français', () {
      expect(label.resolve('ee'), 'Légumes');
    });

    test('JSON invalide ou valeurs non textuelles ignorés', () {
      expect(LocalizedText.fromJson('x').resolve('fr'), '');
      expect(
        LocalizedText.fromJson(const {'fr': 1, 'en': 'Fruit'}).resolve('fr'),
        'Fruit',
      );
    });

    test('égalité par valeur', () {
      expect(
        LocalizedText.fromJson(const {'en': 'A', 'fr': 'B'}),
        LocalizedText.fromJson(const {'fr': 'B', 'en': 'A'}),
      );
    });
  });

  group('Uuid', () {
    test('v4 bien formé, version et variante', () {
      final id = Uuid.v4();
      expect(Uuid.isValid(id), isTrue);
      expect(id[14], '4');
      expect('89ab'.contains(id[19]), isTrue);
    });

    test('identifiants distincts', () {
      expect({for (var i = 0; i < 1000; i++) Uuid.v4()}.length, 1000);
    });
  });
}
