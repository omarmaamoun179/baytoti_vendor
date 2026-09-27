import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/vendor_product.dart';
import '../repositories/products_repository.dart';

class ProductsQuery extends Equatable {
  /// Null or blank searches nothing.
  final String? search;
  final int page;

  const ProductsQuery({this.search, this.page = 1});

  @override
  List<Object?> get props => [search, page];
}

class GetProductsUseCase
    implements UseCase<Either<Failure, Paged<VendorProductSummary>>,
        ProductsQuery> {
  final ProductsRepository _repository;

  GetProductsUseCase(this._repository);

  @override
  Future<Either<Failure, Paged<VendorProductSummary>>> call(
    ProductsQuery query,
  ) =>
      _repository.getProducts(search: query.search, page: query.page);
}

class GetProductUseCase
    implements UseCase<Either<Failure, VendorProduct>, String> {
  final ProductsRepository _repository;

  GetProductUseCase(this._repository);

  @override
  Future<Either<Failure, VendorProduct>> call(String id) =>
      _repository.getProduct(id);
}

class GetCategoriesUseCase
    implements UseCase<Either<Failure, List<ProductCategory>>, NoParams> {
  final ProductsRepository _repository;

  GetCategoriesUseCase(this._repository);

  @override
  Future<Either<Failure, List<ProductCategory>>> call(NoParams params) =>
      _repository.getCategories();
}

class SaveProductParams extends Equatable {
  /// Null creates the product.
  final String? productId;
  final ProductDraft draft;

  const SaveProductParams({this.productId, required this.draft});

  @override
  List<Object?> get props => [productId, draft];
}

class SaveProductUseCase
    implements UseCase<Either<Failure, ProductSaveResult>, SaveProductParams> {
  final ProductsRepository _repository;

  SaveProductUseCase(this._repository);

  @override
  Future<Either<Failure, ProductSaveResult>> call(SaveProductParams params) {
    final id = params.productId;
    return id == null
        ? _repository.createProduct(params.draft)
        : _repository.updateProduct(id, params.draft);
  }
}

class SetProductVisibilityParams extends Equatable {
  final String productId;
  final bool published;

  const SetProductVisibilityParams({
    required this.productId,
    required this.published,
  });

  @override
  List<Object?> get props => [productId, published];
}

class SetProductVisibilityUseCase
    implements UseCase<Either<Failure, VendorProductSummary>,
        SetProductVisibilityParams> {
  final ProductsRepository _repository;

  SetProductVisibilityUseCase(this._repository);

  @override
  Future<Either<Failure, VendorProductSummary>> call(
    SetProductVisibilityParams params,
  ) =>
      _repository.setVisibility(params.productId, published: params.published);
}
