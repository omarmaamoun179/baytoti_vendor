import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../domain/entities/vendor_product.dart';
import '../models/product_models.dart';

/// The family's catalogue. [ProductsRemoteDataSource] calls the live API,
/// where products live under the family's store
/// (`/vendor/stores/{store}/products`); [ProductsMockDataSource] answers the
/// same calls from fixtures.
///
/// A save never sends a product to review by itself: review is
/// [submitForReview], called once the save has landed, as the API has it.
abstract class ProductsDataSource {
  /// One page of the catalogue — send `search` only when there is one.
  Future<Either<Failure, Paged<VendorProductSummaryModel>>> getProducts({
    String? search,
    int page = 1,
  });

  /// One product in full. 404 is `product_not_found`.
  Future<Either<Failure, VendorProductModel>> getProduct(String id);

  /// The categories a product may be filed under.
  Future<Either<Failure, List<ProductCategoryModel>>> getCategories();

  /// Makes a product from [draft].
  Future<Either<Failure, ProductSaveResultModel>> createProduct(
    ProductDraft draft,
  );

  /// Saves [draft] over the product [id].
  Future<Either<Failure, ProductSaveResultModel>> updateProduct(
    String id,
    ProductDraft draft,
  );

  /// Moves a draft or rejected product to `pending_review`.
  Future<Either<Failure, ProductSaveResultModel>> submitForReview(String id);

  /// The vendor's own switch. The server decides whether a product that has
  /// not passed review may be shown.
  Future<Either<Failure, VendorProductSummaryModel>> setVisibility(
    String id, {
    required bool published,
  });
}
