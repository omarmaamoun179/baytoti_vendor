import 'package:equatable/equatable.dart';

import 'product_enums.dart';

/// A row of the products list — `GET /vendor/products` `items`.
class VendorProductSummary extends Equatable {
  final String id;
  final String name;
  final int priceFils;
  final int stock;
  final ProductState state;

  /// The cover photo, when there is one.
  final String? imageUrl;

  const VendorProductSummary({
    required this.id,
    required this.name,
    required this.priceFils,
    required this.stock,
    required this.state,
    this.imageUrl,
  });

  bool get isOutOfStock => stock <= 0;

  /// On sale — what the list's switch shows.
  bool get isLive => state == ProductState.published && !isOutOfStock;

  @override
  List<Object?> get props => [id, name, priceFils, stock, state, imageUrl];
}

/// A category chip — `GET /vendor/categories`.
class ProductCategory extends Equatable {
  final String id;

  /// Already in the app's language.
  final String name;

  const ProductCategory({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// A photo attached to a product, by the upload that holds it.
class ProductPhoto extends Equatable {
  final String uploadId;
  final String url;

  const ProductPhoto({required this.uploadId, required this.url});

  @override
  List<Object?> get props => [uploadId, url];
}

/// One product in full, for the editor.
class VendorProduct extends Equatable {
  final String id;
  final String name;
  final String? categoryId;
  final int priceFils;
  final int stock;
  final PreparationTime preparationTime;
  final String description;
  final List<ProductPhoto> photos;
  final ProductState state;

  /// Why review turned it down, or what review will look at.
  final String? reviewNote;

  const VendorProduct({
    required this.id,
    required this.name,
    this.categoryId,
    required this.priceFils,
    required this.stock,
    this.preparationTime = PreparationTime.oneDay,
    this.description = '',
    this.photos = const [],
    required this.state,
    this.reviewNote,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        categoryId,
        priceFils,
        stock,
        preparationTime,
        description,
        photos,
        state,
        reviewNote,
      ];
}

/// Everything the product form sends — exactly the fields on the form, as
/// the contract's `POST /vendor/products` puts it.
class ProductDraft extends Equatable {
  final String name;
  final String categoryId;
  final int priceFils;
  final int stock;
  final PreparationTime preparationTime;
  final String description;

  /// In order: the first is the cover. The request sends only their
  /// upload ids.
  final List<ProductPhoto> photos;

  /// False saves a draft; true sends it to review.
  final bool submitForReview;

  const ProductDraft({
    required this.name,
    required this.categoryId,
    required this.priceFils,
    required this.stock,
    required this.preparationTime,
    required this.description,
    required this.photos,
    required this.submitForReview,
  });

  List<String> get imageUploadIds => [
        for (final photo in photos) photo.uploadId,
      ];

  @override
  List<Object?> get props => [
        name,
        categoryId,
        priceFils,
        stock,
        preparationTime,
        description,
        photos,
        submitForReview,
      ];
}

/// What a save answers: `{"id": "prd_9", "state": "pending_review",
/// "review_note": "…"}`.
class ProductSaveResult extends Equatable {
  final String id;
  final ProductState state;
  final String? reviewNote;

  const ProductSaveResult({
    required this.id,
    required this.state,
    this.reviewNote,
  });

  @override
  List<Object?> get props => [id, state, reviewNote];
}
