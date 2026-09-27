import 'package:equatable/equatable.dart';

import 'product_enums.dart';

/// A row of the products list.
class VendorProductSummary extends Equatable {
  final String id;
  final String name;
  final int priceFils;

  /// Whether it can be ordered now — the API's `is_available`. The API
  /// keeps no stock count for food, only this.
  final bool isAvailable;

  final ProductState state;

  /// The cover photo, when there is one.
  final String? imageUrl;

  const VendorProductSummary({
    required this.id,
    required this.name,
    required this.priceFils,
    required this.isAvailable,
    required this.state,
    this.imageUrl,
  });

  bool get isOutOfStock => !isAvailable;

  /// On sale — what the list's switch shows.
  bool get isLive => state == ProductState.published && isAvailable;

  @override
  List<Object?> get props =>
      [id, name, priceFils, isAvailable, state, imageUrl];
}

/// A category chip — on the live API a food category of
/// `GET /categories/active`.
class ProductCategory extends Equatable {
  final String id;

  /// Already in the app's language.
  final String name;

  const ProductCategory({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// A photo attached to a product.
///
/// [uploadId] names it to the server: on fixtures the upload that holds it,
/// on the live API the product image's id — or, for a photo picked but not
/// yet sent, the device path the uploads feature marks it with, which the
/// save sends as the file itself.
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
  final bool isAvailable;
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
    this.isAvailable = true,
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
        isAvailable,
        preparationTime,
        description,
        photos,
        state,
        reviewNote,
      ];
}

/// Everything the product form sends — exactly the fields on the form.
class ProductDraft extends Equatable {
  final String name;
  final String categoryId;
  final int priceFils;
  final bool isAvailable;
  final PreparationTime preparationTime;
  final String description;

  /// In order: the first is the cover.
  final List<ProductPhoto> photos;

  /// False saves a draft; true also sends it to review, a call of its own
  /// once the save has landed.
  final bool submitForReview;

  const ProductDraft({
    required this.name,
    required this.categoryId,
    required this.priceFils,
    required this.isAvailable,
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
        isAvailable,
        preparationTime,
        description,
        photos,
        submitForReview,
      ];
}

/// What a save answers: the product's id and where it now stands.
class ProductSaveResult extends Equatable {
  final String id;
  final ProductState state;
  final String? reviewNote;

  /// Why a save that asked for review stayed a draft. The product is saved
  /// either way — sending the form again would make it twice — so this is
  /// news for the family, not a failure of the save.
  final String? reviewRefusal;

  const ProductSaveResult({
    required this.id,
    required this.state,
    this.reviewNote,
    this.reviewRefusal,
  });

  ProductSaveResult withReviewRefusal(String message) => ProductSaveResult(
        id: id,
        state: state,
        reviewNote: reviewNote,
        reviewRefusal: message,
      );

  @override
  List<Object?> get props => [id, state, reviewNote, reviewRefusal];
}
