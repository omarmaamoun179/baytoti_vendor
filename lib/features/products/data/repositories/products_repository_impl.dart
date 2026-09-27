import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../domain/entities/vendor_product.dart';
import '../../domain/repositories/products_repository.dart';
import '../datasources/products_data_source.dart';
import '../models/product_models.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsDataSource _dataSource;

  ProductsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, Paged<VendorProductSummary>>> getProducts({
    String? search,
    int page = 1,
  }) =>
      _dataSource.getProducts(search: search, page: page);

  @override
  Future<Either<Failure, VendorProduct>> getProduct(String id) =>
      _dataSource.getProduct(id);

  @override
  Future<Either<Failure, List<ProductCategory>>> getCategories() =>
      _dataSource.getCategories();

  @override
  Future<Either<Failure, ProductSaveResult>> createProduct(
    ProductDraft draft,
  ) async =>
      _thenReview(await _dataSource.createProduct(draft), draft);

  @override
  Future<Either<Failure, ProductSaveResult>> updateProduct(
    String id,
    ProductDraft draft,
  ) async =>
      _thenReview(await _dataSource.updateProduct(id, draft), draft);

  @override
  Future<Either<Failure, VendorProductSummary>> setVisibility(
    String id, {
    required bool published,
  }) =>
      _dataSource.setVisibility(id, published: published);

  /// Sends a saved product to review when the family asked for it. A refused
  /// review is carried on the result rather than failing the save: the
  /// product exists, and a failure here would have the family make it again.
  Future<Either<Failure, ProductSaveResult>> _thenReview(
    Either<Failure, ProductSaveResultModel> saved,
    ProductDraft draft,
  ) =>
      saved.fold<Future<Either<Failure, ProductSaveResult>>>(
        (failure) async => Left(failure),
        (result) async {
          if (!draft.submitForReview) return Right(result);
          // An answer that named no product leaves nothing to send.
          if (result.id.isEmpty) {
            return Right(
              result.withReviewRefusal('product_review_not_sent'.tr()),
            );
          }

          final reviewed = await _dataSource.submitForReview(result.id);
          return Right(reviewed.fold<ProductSaveResult>(
            (failure) => result.withReviewRefusal(
              failure.message ?? 'product_review_not_sent'.tr(),
            ),
            (submitted) => submitted,
          ));
        },
      );
}
