import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/mock/mock_locale.dart';
import '../../../../core/network/guarded_request.dart';
import '../../domain/entities/product_enums.dart';
import '../../domain/entities/vendor_product.dart';
import '../models/product_models.dart';
import 'product_fixtures.dart';
import 'products_data_source.dart';

/// [ProductFixtures] behind the catalogue calls.
///
/// It enforces what the server does: the switch is the product's own
/// `status`, kept whatever its review — switched on in review, a product
/// goes on sale when approved, and the live server accepts that (seen on
/// 2026-09-28). A rejected product and one marked unavailable are not
/// switched on. A save keeps the product a draft and [submitForReview]
/// sends it on; nothing here approves it.
class ProductsMockDataSource implements ProductsDataSource {
  static const int _perPage = 20;

  static const Localized _reviewNote = Localized(
    'لا يظهر المنتج للشراء قبل اجتياز المراجعة.',
    'The product is not purchasable until it passes review.',
  );

  final ProductFixtures _fixtures;
  final MockLocale _locale;

  ProductsMockDataSource(this._fixtures, this._locale);

  @override
  Future<Either<Failure, Paged<VendorProductSummaryModel>>> getProducts({
    String? search,
    int page = 1,
  }) =>
      guardedRequest(
        'ProductsMockDataSource.getProducts',
        () async {
          await Future<void>.delayed(mockLatency);
          final ar = await _locale.isArabic();
          final query = search?.trim().toLowerCase() ?? '';

          final matching = [
            for (final product in _fixtures.products)
              if (query.isEmpty ||
                  product.name.ar.toLowerCase().contains(query) ||
                  product.name.en.toLowerCase().contains(query))
                product,
          ];
          final rows = matching.skip((page - 1) * _perPage).take(_perPage);

          return Paged<VendorProductSummaryModel>(
            items: [
              for (final product in rows)
                VendorProductSummaryModel.fromJson(_summaryJson(product, ar)),
            ],
            currentPage: page,
            lastPage: (matching.length / _perPage).ceil().clamp(1, 1000),
            perPage: _perPage,
            total: matching.length,
          );
        },
        fallbackMessage: 'products_failed',
      );

  @override
  Future<Either<Failure, VendorProductModel>> getProduct(String id) =>
      guardedRequest(
        'ProductsMockDataSource.getProduct',
        () async {
          await Future<void>.delayed(mockLatency);
          final ar = await _locale.isArabic();
          final product = _find(id);

          return VendorProductModel.fromJson({
            'id': product.id,
            'name': product.name.pick(ar),
            'category_id': product.categoryId,
            'price_fils': product.priceFils,
            'is_available': product.isAvailable,
            'preparation_time': product.preparationTime.wire,
            'description': product.description.pick(ar),
            'images': [
              for (final photo in product.photos)
                {'upload_id': photo.uploadId, 'url': photo.url},
            ],
            'state': product.state.wire,
            'review_note': product.state == ProductState.pendingReview
                ? _reviewNote.pick(ar)
                : null,
          });
        },
        fallbackMessage: 'product_failed',
      );

  @override
  Future<Either<Failure, List<ProductCategoryModel>>> getCategories() =>
      guardedRequest(
        'ProductsMockDataSource.getCategories',
        () async {
          await Future<void>.delayed(mockLatency);
          final ar = await _locale.isArabic();

          return [
            for (final (id, name) in ProductFixtures.categories)
              ProductCategoryModel.fromJson({'id': id, 'name': name.pick(ar)}),
          ];
        },
        fallbackMessage: 'categories_failed',
      );

  @override
  Future<Either<Failure, ProductSaveResultModel>> createProduct(
    ProductDraft draft,
  ) =>
      guardedRequest(
        'ProductsMockDataSource.createProduct',
        () async {
          await Future<void>.delayed(mockLatency * 2);

          final product = ProductRecord(
            id: _fixtures.nextId(),
            name: const Localized('', ''),
            categoryId: draft.categoryId,
            priceFils: draft.priceFils,
            state: ProductState.draft,
          );
          _apply(product, draft);
          _fixtures.products.insert(0, product);
          return _saved(product);
        },
        fallbackMessage: 'product_save_failed',
      );

  @override
  Future<Either<Failure, ProductSaveResultModel>> updateProduct(
    String id,
    ProductDraft draft,
  ) =>
      guardedRequest(
        'ProductsMockDataSource.updateProduct',
        () async {
          await Future<void>.delayed(mockLatency * 2);
          final product = _find(id);
          _apply(product, draft);
          return _saved(product);
        },
        fallbackMessage: 'product_save_failed',
        messageForStatus: const {404: 'product_not_found'},
      );

  @override
  Future<Either<Failure, ProductSaveResultModel>> submitForReview(
    String id,
  ) =>
      guardedRequest(
        'ProductsMockDataSource.submitForReview',
        () async {
          await Future<void>.delayed(mockLatency);
          final product = _find(id)..state = ProductState.pendingReview;
          return _saved(product);
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
        'ProductsMockDataSource.setVisibility',
        () async {
          await Future<void>.delayed(mockLatency);
          final product = _find(id);

          if (published) {
            final refusal = switch (product.state) {
              ProductState.rejected => 'product_rejected_cannot_publish',
              _ when !product.isAvailable => 'product_out_of_stock_publish',
              _ => null,
            };
            if (refusal != null) {
              throw RequestException(refusal, statusCode: 422);
            }
          }

          product.switchedOn = published;
          // An approved product shows or hides at once; one still in review
          // keeps its state and waits for the approval.
          if (product.state == ProductState.published ||
              product.state == ProductState.hidden) {
            product.state =
                published ? ProductState.published : ProductState.hidden;
          }

          return VendorProductSummaryModel.fromJson(
            _summaryJson(product, await _locale.isArabic()),
          );
        },
        fallbackMessage: 'product_visibility_failed',
      );

  /// A vendor's own words are one text whichever language it is read in.
  void _apply(ProductRecord product, ProductDraft draft) {
    final name = draft.name.trim();
    final description = draft.description.trim();

    product
      ..name = Localized(name, name)
      ..categoryId = draft.categoryId
      ..priceFils = draft.priceFils
      ..isAvailable = draft.isAvailable
      ..preparationTime = draft.preparationTime
      ..description = Localized(description, description)
      // On fixtures an upload's URL is its path on the device, so the photo
      // shows wherever the server's copy would.
      ..photos = [...draft.photos]
      // An edit goes back through review, as a new product does.
      ..state = ProductState.draft;
  }

  Future<ProductSaveResultModel> _saved(ProductRecord product) async =>
      ProductSaveResultModel.fromJson({
        'id': product.id,
        'state': product.state.wire,
        'review_note': product.state == ProductState.pendingReview
            ? _reviewNote.pick(await _locale.isArabic())
            : null,
      });

  ProductRecord _find(String id) =>
      _fixtures.find(id) ??
      (throw const RequestException('product_not_found', statusCode: 404));

  Map<String, dynamic> _summaryJson(ProductRecord product, bool ar) => {
        'id': product.id,
        'name': product.name.pick(ar),
        'price_fils': product.priceFils,
        'is_available': product.isAvailable,
        'state': product.state.wire,
        'status': product.switchedOn,
        'images': [
          for (final photo in product.photos) {'url': photo.url},
        ],
      };
}
