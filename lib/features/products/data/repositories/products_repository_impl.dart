import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../domain/entities/vendor_product.dart';
import '../../domain/repositories/products_repository.dart';
import '../datasources/products_data_source.dart';

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
  ) =>
      _dataSource.createProduct(draft);

  @override
  Future<Either<Failure, ProductSaveResult>> updateProduct(
    String id,
    ProductDraft draft,
  ) =>
      _dataSource.updateProduct(id, draft);

  @override
  Future<Either<Failure, VendorProductSummary>> setVisibility(
    String id, {
    required bool published,
  }) =>
      _dataSource.setVisibility(id, published: published);
}
