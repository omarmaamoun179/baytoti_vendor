import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../domain/entities/vendor_product.dart';
import '../models/product_models.dart';

/// The vendor catalogue endpoints of the API contract. Only fixtures
/// implement it today ([ProductsMockDataSource]).
abstract class ProductsDataSource {
  /// `GET /vendor/products?q=&page=` — send `q` only when there is one.
  Future<Either<Failure, Paged<VendorProductSummaryModel>>> getProducts({
    String? search,
    int page = 1,
  });

  /// `GET /vendor/products/{id}`. 404 is `product_not_found`.
  Future<Either<Failure, VendorProductModel>> getProduct(String id);

  /// `GET /vendor/categories`.
  Future<Either<Failure, List<ProductCategoryModel>>> getCategories();

  /// `POST /vendor/products` with [productDraftBody].
  Future<Either<Failure, ProductSaveResultModel>> createProduct(
    ProductDraft draft,
  );

  /// `PATCH /vendor/products/{id}` with [productDraftBody].
  Future<Either<Failure, ProductSaveResultModel>> updateProduct(
    String id,
    ProductDraft draft,
  );

  /// `PATCH /vendor/products/{id}/visibility` with `{published}`. Before
  /// approval the server answers `422 product_pending_review`.
  Future<Either<Failure, VendorProductSummaryModel>> setVisibility(
    String id, {
    required bool published,
  });
}
