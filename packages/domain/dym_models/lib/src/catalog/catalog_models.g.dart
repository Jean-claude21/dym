// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoreCategory _$StoreCategoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'StoreCategory',
      json,
      ($checkedConvert) {
        final val = StoreCategory(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          sort: $checkedConvert('sort', (v) => (v as num?)?.toInt() ?? 0),
          isArchived: $checkedConvert(
            'is_archived',
            (v) => v as bool? ?? false,
          ),
          productCount: $checkedConvert(
            'product_count',
            (v) => (v as num?)?.toInt() ?? 0,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'isArchived': 'is_archived',
        'productCount': 'product_count',
      },
    );

ProductVariant _$ProductVariantFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ProductVariant',
      json,
      ($checkedConvert) {
        final val = ProductVariant(
          id: $checkedConvert('id', (v) => v as String),
          label: $checkedConvert('label', (v) => v as String?),
          priceMinor: $checkedConvert(
            'price_minor',
            (v) => nullableMinorFromJson(v),
          ),
          stockQuantity: $checkedConvert(
            'stock_quantity',
            (v) => (v as num?)?.toInt(),
          ),
          sort: $checkedConvert('sort', (v) => (v as num?)?.toInt() ?? 0),
        );
        return val;
      },
      fieldKeyMap: const {
        'priceMinor': 'price_minor',
        'stockQuantity': 'stock_quantity',
      },
    );

Product _$ProductFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Product',
  json,
  ($checkedConvert) {
    final val = Product(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      currencyCode: $checkedConvert('currency_code', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$ProductStatusEnumMap, v),
      ),
      description: $checkedConvert('description', (v) => v as String?),
      categoryId: $checkedConvert('category_id', (v) => v as String?),
      unitId: $checkedConvert('unit_id', (v) => v as String?),
      priceMinor: $checkedConvert(
        'price_minor',
        (v) => nullableMinorFromJson(v),
      ),
      isAvailable: $checkedConvert('is_available', (v) => v as bool? ?? true),
      suggestionId: $checkedConvert('suggestion_id', (v) => v as String?),
      variants: $checkedConvert(
        'variants',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      ),
      photoKeys: $checkedConvert(
        'photo_keys',
        (v) =>
            (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      ),
      storeCategoryIds: $checkedConvert(
        'store_category_ids',
        (v) =>
            (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      ),
      missing: $checkedConvert(
        'missing',
        (v) =>
            (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'currencyCode': 'currency_code',
    'categoryId': 'category_id',
    'unitId': 'unit_id',
    'priceMinor': 'price_minor',
    'isAvailable': 'is_available',
    'suggestionId': 'suggestion_id',
    'photoKeys': 'photo_keys',
    'storeCategoryIds': 'store_category_ids',
  },
);

const _$ProductStatusEnumMap = {
  ProductStatus.draft: 'draft',
  ProductStatus.published: 'published',
  ProductStatus.archived: 'archived',
};

ProductSuggestion _$ProductSuggestionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ProductSuggestion',
      json,
      ($checkedConvert) {
        final val = ProductSuggestion(
          suggestionId: $checkedConvert('suggestion_id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          categoryId: $checkedConvert('category_id', (v) => v as String?),
          description: $checkedConvert('description', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'suggestionId': 'suggestion_id',
        'categoryId': 'category_id',
      },
    );

PhotoUpload _$PhotoUploadFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PhotoUpload',
  json,
  ($checkedConvert) {
    final val = PhotoUpload(
      objectKey: $checkedConvert('object_key', (v) => v as String),
      uploadUrl: $checkedConvert('upload_url', (v) => v as String),
      publicUrl: $checkedConvert('public_url', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'objectKey': 'object_key',
    'uploadUrl': 'upload_url',
    'publicUrl': 'public_url',
  },
);
