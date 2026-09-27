import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../entities/vendor_product.dart';

abstract class ProductsRepository {
  Future<Either<Failure, Paged<VendorProductSummary>>> getProducts({
    String? search,
    int page = 1,
  });

  Future<Either<Failure, VendorProduct>> getProduct(String id);

  /// Read each time the editor opens rather than kept: the names come back
  /// in the app's language, and a kept list would outlive a language switch.
  Future<Either<Failure, List<ProductCategory>>> getCategories();

  Future<Either<Failure, ProductSaveResult>> createProduct(ProductDraft draft);

  Future<Either<Failure, ProductSaveResult>> updateProduct(
    String id,
    ProductDraft draft,
  );

  /// The list's switch. Answers with the row as the server now has it.
  Future<Either<Failure, VendorProductSummary>> setVisibility(
    String id, {
    required bool published,
  });
}
