import '../../../../core/domain/paged.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/multipart_body.dart';
import '../../../../core/utils/json_read.dart';
import '../../../uploads/data/datasources/device_uploads_data_source.dart';
import '../../domain/entities/product_enums.dart';
import '../../domain/entities/vendor_product.dart';

// Each model reads two shapes. `fromJson` reads the fixtures, which answer
// in the design contract's shapes (`price_fils`, `state`, `images[].url`);
// `fromApi` reads the live API's `ProductResource`:
//
// ```json
// {"id": 12, "name": "كيك التمر بالهيل", "slug": "…",
//  "short_description": null, "description": "…",
//  "base_price": "4.250", "compare_price": null,
//  "status": true, "is_featured": false,
//  "approval_status": "approved",
//  "approval_status_data": {"key": "approved", "ar": "…", "en": "…"},
//  "is_available": true, "preparation_time_minutes": 1440,
//  "category": {"id": 4, "name": "…", "slug": "…"},
//  "store": {"id": 8, "name": "…", "slug": "…"},
//  "images": [{"id": 3, "image": "https://…", "is_primary": true}],
//  "colors": [ … ]}
// ```
//
// The spec types the vendor answers only as "object", and a list row may be
// the lighter `ProductListResource` (`price {current, original}`,
// `thumbnail {image}`), so both are read leniently. Photos are looked for
// in `images`, then in the legacy `colors[].images`, then `thumbnail`.

/// The first image of a contract `images` array — `[{url, width, height,
/// alt}]`, largest first — or null for an empty one.
String? _coverOf(Object? images) {
  final list = asMapList(images);
  return list.isEmpty ? null : asString(list.first['url']);
}

/// Dinars as the API writes them (`"4.250"`, or a number) in fils.
int _filsOf(Object? value) => ((asDouble(value) ?? 0) * 1000).round();

/// The product's price: `base_price`, or a list row's `price.current`.
int _priceOf(Map<String, dynamic> json) => _filsOf(
      json['base_price'] ?? asMap(json['price'])['current'] ?? json['price'],
    );

/// Every photo the product carries, the primary first: top-level `images`,
/// then those under the legacy `colors`.
List<ProductPhoto> _photosOf(Map<String, dynamic> json) {
  final rows = [
    ...asMapList(json['images']),
    for (final color in asMapList(json['colors']))
      ...asMapList(color['images']),
  ];
  final photos = [
    for (final row in rows)
      if (asString(row['id']) case final id?)
        if (asString(row['image']) ?? asString(row['url']) case final url?)
          (primary: asBool(row['is_primary']) ?? false,
              photo: ProductPhoto(uploadId: id, url: url)),
  ];
  // Partitioned rather than sorted: the rest keep the server's order.
  return [
    for (final entry in photos)
      if (entry.primary) entry.photo,
    for (final entry in photos)
      if (!entry.primary) entry.photo,
  ];
}

/// Where a live product stands: moderation first, then the vendor's switch.
ProductState _stateOf(Map<String, dynamic> json) {
  final approval = asString(json['approval_status']) ??
      asString(asMap(json['approval_status_data'])['key']);
  final shown = asBool(json['status']) ?? false;

  return switch (approval?.toLowerCase()) {
    'draft' => ProductState.draft,
    'pending_review' || 'pending' => ProductState.pendingReview,
    'rejected' => ProductState.rejected,
    'approved' => shown ? ProductState.published : ProductState.hidden,
    // No moderation field: an answer that predates it. The switch alone
    // decides, and unknown is not claimed to be on sale.
    _ => ProductState.hidden,
  };
}

/// A row of the products list.
///
/// The fixtures send:
///
/// ```json
/// {"id": "prd_1", "name": "كيك التمر بالهيل", "price_fils": 4250,
///  "is_available": true, "state": "published", "images": [ … ]}
/// ```
class VendorProductSummaryModel extends VendorProductSummary {
  const VendorProductSummaryModel({
    required super.id,
    required super.name,
    required super.priceFils,
    required super.isAvailable,
    required super.state,
    required super.isSwitchedOn,
    super.imageUrl,
  });

  /// The contract has no switch apart from `state`; the fixtures send
  /// `status` beside it, and without one a published product is on.
  factory VendorProductSummaryModel.fromJson(Map<String, dynamic> json) {
    final state = ProductState.fromWire(asString(json['state']));

    return VendorProductSummaryModel(
      id: requireString(json['id'], 'id'),
      name: asString(json['name']) ?? '',
      priceFils: asInt(json['price_fils']) ?? 0,
      isAvailable: asBool(json['is_available']) ?? true,
      state: state,
      isSwitchedOn:
          asBool(json['status']) ?? state == ProductState.published,
      imageUrl: _coverOf(json['images']),
    );
  }

  factory VendorProductSummaryModel.fromApi(Map<String, dynamic> json) {
    final photos = _photosOf(json);
    final thumbnail = json['thumbnail'];

    return VendorProductSummaryModel(
      id: requireString(json['id'], 'id'),
      name: asString(json['name']) ?? '',
      priceFils: _priceOf(json),
      isAvailable: asBool(json['is_available']) ?? true,
      state: _stateOf(json),
      isSwitchedOn: asBool(json['status']) ?? false,
      imageUrl: photos.firstOrNull?.url ??
          (thumbnail is Map
              ? asString(thumbnail['image'])
              : asString(thumbnail)),
    );
  }

  /// One page of `GET /vendor/stores/{store}/products`, positioned by
  /// `meta` — never by the row count.
  static Paged<VendorProductSummaryModel> pageFrom(ApiResponse envelope) {
    final items = [
      for (final row in asMapList(envelope.dataList))
        if (asString(row['id']) != null)
          VendorProductSummaryModel.fromApi(row),
    ];

    return Paged<VendorProductSummaryModel>(
      items: items,
      currentPage: envelope.currentPage,
      lastPage: envelope.lastPage,
      perPage: envelope.perPage,
      total: envelope.total,
    );
  }
}

/// One product in full, for the editor.
///
/// The fixtures send the design contract's `GET /vendor/products/{id}` —
/// the create request's fields plus `id`, `state` and `images`, each image
/// with the `upload_id` it is attached by.
class VendorProductModel extends VendorProduct {
  const VendorProductModel({
    required super.id,
    required super.name,
    super.categoryId,
    required super.priceFils,
    super.isAvailable,
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
      isAvailable: asBool(json['is_available']) ?? true,
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

  /// `GET /vendor/stores/{store}/products/{product}`. The reason review
  /// turned a product down is looked for under the names a moderation
  /// column takes; the spec names none.
  factory VendorProductModel.fromApi(Map<String, dynamic> json) {
    return VendorProductModel(
      id: requireString(json['id'], 'id'),
      name: asString(json['name']) ?? '',
      categoryId: asString(asMap(json['category'])['id']) ??
          asString(json['category_id']),
      priceFils: _priceOf(json),
      isAvailable: asBool(json['is_available']) ?? true,
      preparationTime: PreparationTime.fromMinutes(
        asInt(json['preparation_time_minutes']),
      ),
      description: asString(json['description']) ??
          asString(json['short_description']) ??
          '',
      photos: _photosOf(json),
      state: _stateOf(json),
      reviewNote: asString(json['rejection_reason']) ??
          asString(json['review_note']) ??
          asString(json['approval_note']),
    );
  }

  /// A single product, accepted under `data.product` as well as at `data`.
  static VendorProductModel fromResponse(ApiResponse envelope) =>
      VendorProductModel.fromApi(productMapOf(envelope));

  /// The product an answer carries, bare or under `product`.
  static Map<String, dynamic> productMapOf(ApiResponse envelope) {
    final data = envelope.dataMap;
    return data['product'] is Map ? asMap(data['product']) : data;
  }
}

/// A category chip. The fixtures send `{"id": "cat_sweets", "name":
/// "حلويات"}`.
class ProductCategoryModel extends ProductCategory {
  const ProductCategoryModel({required super.id, required super.name});

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    final id = requireString(json['id'], 'id');
    return ProductCategoryModel(id: id, name: asString(json['name']) ?? id);
  }

  /// `GET /categories/active`: root categories, each with its `children`.
  /// A product may sit in either, so the tree is flattened — a parent, then
  /// its children — and a switched-off one is left out.
  static List<ProductCategoryModel> listFromApi(List<dynamic> rows) {
    final categories = <ProductCategoryModel>[];

    void add(Map<String, dynamic> row) {
      if (!(asBool(row['status']) ?? true)) return;
      if (asString(row['id']) == null) return;
      categories.add(ProductCategoryModel.fromJson(row));
      asMapList(row['children']).forEach(add);
    }

    asMapList(rows).forEach(add);
    return categories;
  }
}

/// The fixtures' save answer: `{"id": "prd_9", "state": "pending_review",
/// "review_note": "…"}`.
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

  factory ProductSaveResultModel.fromProduct(VendorProduct product) =>
      ProductSaveResultModel(
        id: product.id,
        state: product.state,
        reviewNote: product.reviewNote,
      );
}

/// The fixtures' body for a save — exactly the fields on the form.
Map<String, dynamic> productDraftBody(ProductDraft draft) => {
      'name': draft.name.trim(),
      'category_id': draft.categoryId,
      'price_fils': draft.priceFils,
      'is_available': draft.isAvailable,
      'preparation_time': draft.preparationTime.wire,
      'description': draft.description.trim(),
      'image_upload_ids': draft.imageUploadIds,
      'submit_for_review': draft.submitForReview,
    };

/// Whether a save carries a photo still on the device — the body then goes
/// out as `multipart/form-data`, since JSON cannot carry a file.
bool hasDevicePhotos(ProductDraft draft) =>
    draft.photos.any((photo) => devicePathOf(photo.uploadId) != null);

/// The live body of a product save — `StoreProductRequest` on create,
/// `UpdateProductRequest` on update — with only the food fields the form
/// holds. Moderation (`approval_status`) and the vendor's switch (`status`)
/// are not sent: review is its own call, and the switch its own save.
///
/// **Photos are a guess to confirm with the backend.** The guide's food
/// product carries an `images` gallery, but the spec still types product
/// images under the clothing-era `colors[].images` (each colour needing a
/// size variant), which food has no use for. So photos go out as
/// `images[i]`: one picked on the device as the file itself (`image`, at
/// most 5120 KB), one the server holds by its `id`, the cover marked
/// `is_primary`, in the grid's order.
Map<String, dynamic> liveProductBody(ProductDraft draft) {
  final description = draft.description.trim();

  return {
    'name': draft.name.trim(),
    'category_id': int.tryParse(draft.categoryId) ?? draft.categoryId,
    'description': description.isEmpty ? null : description,
    // Dinars with the three decimals KWD is written in.
    'base_price': draft.priceFils / 1000,
    'is_available': draft.isAvailable,
    'preparation_time_minutes': draft.preparationTime.minutes,
    'images': [
      for (final (index, photo) in draft.photos.indexed)
        {
          if (devicePathOf(photo.uploadId) case final path?)
            'image': FileUpload(path)
          else
            'id': int.tryParse(photo.uploadId) ?? photo.uploadId,
          'is_primary': index == 0,
          'sort_order': index,
        },
    ],
  };
}
