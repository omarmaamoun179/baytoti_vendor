import '../../../../core/utils/json_read.dart';
import '../../domain/entities/product_enums.dart';
import '../../domain/entities/vendor_product.dart';

/// The first image of a contract `images` array — `[{url, width, height,
/// alt}]`, largest first — or null for an empty one.
String? _coverOf(Object? images) {
  final list = asMapList(images);
  return list.isEmpty ? null : asString(list.first['url']);
}

/// A row of `GET /vendor/products`:
///
/// ```json
/// {"id": "prd_1", "name": "كيك التمر بالهيل", "price_fils": 4250,
///  "stock": 8, "state": "published", "images": [ … ]}
/// ```
class VendorProductSummaryModel extends VendorProductSummary {
  const VendorProductSummaryModel({
    required super.id,
    required super.name,
    required super.priceFils,
    required super.stock,
    required super.state,
    super.imageUrl,
  });

  factory VendorProductSummaryModel.fromJson(Map<String, dynamic> json) {
    return VendorProductSummaryModel(
      id: requireString(json['id'], 'id'),
      name: asString(json['name']) ?? '',
      priceFils: asInt(json['price_fils']) ?? 0,
      stock: asInt(json['stock']) ?? 0,
      state: ProductState.fromWire(asString(json['state'])),
      imageUrl: _coverOf(json['images']),
    );
  }
}

/// `GET /vendor/products/{id}` — not in the contract, which lists only the
/// `PATCH`. Read as the create request's fields plus `id`, `state` and
/// `images`; each image is read with the `upload_id` it is attached by, a
/// guess to check against the API.
class VendorProductModel extends VendorProduct {
  const VendorProductModel({
    required super.id,
    required super.name,
    super.categoryId,
    required super.priceFils,
    required super.stock,
    super.preparationTime,
    super.description,
    super.photos,
    required super.state,
    super.reviewNote,
  });

  factory VendorProductModel.fromJson(Map<String, dynamic> json) {
    return VendorProductModel(
      id: requireString(json['id'], 'id'),
      name: asString(json['name']) ?? '',
      categoryId: asString(json['category_id']),
      priceFils: asInt(json['price_fils']) ?? 0,
      stock: asInt(json['stock']) ?? 0,
      preparationTime: PreparationTime.fromWire(
        asString(json['preparation_time']),
      ),
      description: asString(json['description']) ?? '',
      photos: [
        for (final image in asMapList(json['images']))
          if (asString(image['upload_id']) case final uploadId?)
            ProductPhoto(uploadId: uploadId, url: asString(image['url']) ?? ''),
      ],
      state: ProductState.fromWire(asString(json['state'])),
      reviewNote: asString(json['review_note']),
    );
  }
}

/// `GET /vendor/categories` rows — `{"id": "cat_sweets", "name": "حلويات"}`.
class ProductCategoryModel extends ProductCategory {
  const ProductCategoryModel({required super.id, required super.name});

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    final id = requireString(json['id'], 'id');
    return ProductCategoryModel(id: id, name: asString(json['name']) ?? id);
  }
}

/// `201 {"id": "prd_9", "state": "pending_review", "review_note": "…"}`.
class ProductSaveResultModel extends ProductSaveResult {
  const ProductSaveResultModel({
    required super.id,
    required super.state,
    super.reviewNote,
  });

  factory ProductSaveResultModel.fromJson(Map<String, dynamic> json) {
    return ProductSaveResultModel(
      id: requireString(json['id'], 'id'),
      state: ProductState.fromWire(asString(json['state'])),
      reviewNote: asString(json['review_note']),
    );
  }
}

/// The body of `POST /vendor/products` and `PATCH /vendor/products/{id}` —
/// exactly the fields on the form.
Map<String, dynamic> productDraftBody(ProductDraft draft) => {
      'name': draft.name.trim(),
      'category_id': draft.categoryId,
      'price_fils': draft.priceFils,
      'stock': draft.stock,
      'preparation_time': draft.preparationTime.wire,
      'description': draft.description.trim(),
      'image_upload_ids': draft.imageUploadIds,
      'submit_for_review': draft.submitForReview,
    };
