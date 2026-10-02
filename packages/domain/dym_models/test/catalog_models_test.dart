import 'package:dym_models/dym_models.dart';
import 'package:test/test.dart';

void main() {
  test('Product : réponse de my_products()', () {
    final product = Product.fromJson(const {
      'id': 'p1',
      'name': 'Jus de bissap',
      'description': null,
      'category_id': 'c1',
      'unit_id': null,
      'price_minor': 500,
      'currency_code': 'XOF',
      'status': 'published',
      'is_available': true,
      'suggestion_id': null,
      'published_at': '2026-10-02T10:00:00Z',
      'created_at': '2026-10-02T10:00:00Z',
      'updated_at': '2026-10-02T10:00:00Z',
      'variants': [
        {
          'id': 'v1',
          'label': '50 cl',
          'price_minor': null,
          'stock_quantity': 12,
          'sort': 0,
        },
        {
          'id': 'v2',
          'label': '1 L',
          'price_minor': 900,
          'stock_quantity': 6,
          'sort': 1,
        },
      ],
      'photo_keys': ['stores/s/products/a.jpg'],
      'store_category_ids': ['sc1'],
      'missing': <String>[],
    });
    expect(product.isPublished, isTrue);
    expect(product.variants.last.priceMinor, 900);
    expect(product.trackedStock, 18);
    expect(product.photoKeys.single, endsWith('a.jpg'));
  });

  test('stock non suivi : nul', () {
    const product = Product(
      id: 'p',
      name: 'Riz au gras',
      currencyCode: 'XOF',
      status: ProductStatus.draft,
      variants: [ProductVariant(id: 'v')],
    );
    expect(product.trackedStock, isNull);
  });

  test('StoreCategory, proposition et envoi de photo', () {
    expect(
      StoreCategory.fromJson(const {
        'id': 'c',
        'name': 'Jus',
        'sort': 0,
        'is_archived': false,
        'product_count': 4,
      }).productCount,
      4,
    );
    expect(
      ProductSuggestion.fromJson(const {
        'suggestion_id': 's',
        'name': 'Jus de bissap 50 cl',
        'category_id': null,
        'description': null,
      }).categoryId,
      isNull,
    );
    expect(
      PhotoUpload.fromJson(const {
        'object_key': 'k',
        'upload_url': 'https://u',
        'public_url': 'https://p',
        'expires_in': 300,
      }).uploadUrl,
      'https://u',
    );
  });
}
