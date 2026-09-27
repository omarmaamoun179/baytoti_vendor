import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/network/multipart_body.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/utils/json_read.dart';
import '../../../store/data/datasources/vendor_store_resolver.dart';
import '../../domain/entities/product_enums.dart';
import '../../domain/entities/vendor_product.dart';
import '../models/product_models.dart';
import 'products_data_source.dart';

/// The catalogue on the live API: `/vendor/stores/{store}/products` under
/// the family's store ([VendorStoreResolver]), the food categories of
/// `GET /categories/active`, and review as its own call.
class ProductsRemoteDataSource implements ProductsDataSource {
  final NetworkService _networkService;
  final VendorStoreResolver _stores;

  ProductsRemoteDataSource(this._networkService, this._stores);

  @override
  Future<Either<Failure, Paged<VendorProductSummaryModel>>> getProducts({
    String? search,
    int page = 1,
  }) =>
      guardedRequest(
        'ProductsRemoteDataSource.getProducts',
        () async {
          final store = await _stores.storeId();
          final query = search?.trim() ?? '';

          final response = await _networkService.get(
            ApiEndPoint.vendorStoreProducts('$store'),
            // Absent when there is nothing to search: `search=` would filter
            // on the empty string.
            queryParameters: {
              'page': page,
              if (query.isNotEmpty) 'search': query,
            },
          );
          final rows = VendorProductSummaryModel.pageFrom(
            checkedResponse(response),
          );
          if (query.isEmpty) return rows;

          // The spec documents no search on this endpoint, and the server
          // answers an unknown filter with every row — so what comes back is
          // matched here too. `meta` still decides whether a page follows.
          final needle = query.toLowerCase();
          return Paged<VendorProductSummaryModel>(
            items: [
              for (final product in rows.items)
                if (product.name.toLowerCase().contains(needle)) product,
            ],
            currentPage: rows.currentPage,
            lastPage: rows.lastPage,
            perPage: rows.perPage,
            total: rows.total,
          );
        },
        fallbackMessage: 'products_failed',
        messageForStatus: const {404: 'store_missing'},
      );

  @override
  Future<Either<Failure, VendorProductModel>> getProduct(String id) =>
      guardedRequest(
        'ProductsRemoteDataSource.getProduct',
        () async => _read(await _stores.storeId(), id),
        fallbackMessage: 'product_failed',
        messageForStatus: const {404: 'product_not_found'},
      );

  @override
  Future<Either<Failure, List<ProductCategoryModel>>> getCategories() =>
      guardedRequest(
        'ProductsRemoteDataSource.getCategories',
        () async {
          final response = await _networkService.get(
            ApiEndPoint.activeCategories,
            // Public, and the same for every family.
            skipAuthRefresh: true,
          );
          return ProductCategoryModel.listFromApi(
            checkedResponse(response).dataList,
          );
        },
        fallbackMessage: 'categories_failed',
      );

  @override
  Future<Either<Failure, ProductSaveResultModel>> createProduct(
    ProductDraft draft,
  ) =>
      guardedRequest(
        'ProductsRemoteDataSource.createProduct',
        () async {
          final store = await _stores.storeId();
          final body = liveProductBody(draft);

          final envelope = checkedResponse(
            await _networkService.post(
              ApiEndPoint.vendorStoreProducts('$store'),
              data: hasDevicePhotos(draft)
                  ? await multipartBodyFrom(body)
                  : body,
            ),
          );

          // A product the server made must never come back as a failure —
          // the family would make it again. So an answer that names no
          // product is still a save, with no id to send to review.
          final product = VendorProductModel.productMapOf(envelope);
          return asString(product['id']) == null
              ? const ProductSaveResultModel(id: '', state: ProductState.draft)
              : ProductSaveResultModel.fromProduct(
                  VendorProductModel.fromApi(product),
                );
        },
        fallbackMessage: 'product_save_failed',
        messageForStatus: const {
          404: 'store_missing',
          413: 'product_images_too_large',
        },
      );

  @override
  Future<Either<Failure, ProductSaveResultModel>> updateProduct(
    String id,
    ProductDraft draft,
  ) =>
      guardedRequest(
        'ProductsRemoteDataSource.updateProduct',
        () async {
          final store = await _stores.storeId();
          final url = ApiEndPoint.vendorStoreProduct('$store', id);
          final body = liveProductBody(draft);

          final response = hasDevicePhotos(draft)
              // PHP reads a multipart body only on POST; Laravel takes
              // `_method` as the verb meant.
              ? await _networkService.post(
                  url,
                  data: await multipartBodyFrom({...body, '_method': 'PUT'}),
                )
              : await _networkService.put(url, data: body);

          return ProductSaveResultModel.fromProduct(
            await _carried(checkedResponse(response), store, id),
          );
        },
        fallbackMessage: 'product_save_failed',
        messageForStatus: const {
          404: 'product_not_found',
          413: 'product_images_too_large',
        },
      );

  @override
  Future<Either<Failure, ProductSaveResultModel>> submitForReview(
    String id,
  ) =>
      guardedRequest(
        'ProductsRemoteDataSource.submitForReview',
        () async {
          final store = await _stores.storeId();
          final envelope = checkedResponse(
            await _networkService.post(
              ApiEndPoint.submitProductReview('$store', id),
            ),
          );
          return ProductSaveResultModel.fromProduct(
            await _carried(envelope, store, id),
          );
        },
        fallbackMessage: 'product_review_not_sent',
        messageForStatus: const {404: 'product_not_found'},
      );

  @override
  Future<Either<Failure, VendorProductSummaryModel>> setVisibility(
    String id, {
    required bool published,
  }) =>
      guardedRequest(
        'ProductsRemoteDataSource.setVisibility',
        () async {
          final store = await _stores.storeId();
          // `UpdateProductRequest` requires nothing, so the switch goes out
          // alone.
          final envelope = checkedResponse(
            await _networkService.put(
              ApiEndPoint.vendorStoreProduct('$store', id),
              data: {'status': published},
            ),
          );

          final product = VendorProductModel.productMapOf(envelope);
          return VendorProductSummaryModel.fromApi(
            asString(product['id']) == null
                ? VendorProductModel.productMapOf(await _get(store, id))
                : product,
          );
        },
        fallbackMessage: 'product_visibility_failed',
        messageForStatus: const {404: 'product_not_found'},
      );

  Future<ApiResponse> _get(int store, String id) async => checkedResponse(
        await _networkService.get(ApiEndPoint.vendorStoreProduct('$store', id)),
      );

  Future<VendorProductModel> _read(int store, String id) async =>
      VendorProductModel.fromResponse(await _get(store, id));

  /// The product an answer carried, or — for a bare confirmation — the
  /// product read back.
  Future<VendorProductModel> _carried(
    ApiResponse envelope,
    int store,
    String id,
  ) async {
    final product = VendorProductModel.productMapOf(envelope);
    return asString(product['id']) == null
        ? _read(store, id)
        : VendorProductModel.fromApi(product);
  }
}
