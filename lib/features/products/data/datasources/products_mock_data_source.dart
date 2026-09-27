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

/// [ProductFixtures] behind the catalogue contract.
///
/// It enforces what the contract says the server does: a product is not
/// purchasable before review, so the switch refuses to publish a draft or a
/// product in review (`product_pending_review`), and stock 0 keeps a product
/// hidden. A save sends the product to review or keeps it a draft; nothing
/// here approves it.
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
            'stock': product.stock,
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
            stock: draft.stock,
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
              ProductState.draft ||
              ProductState.pendingReview =>
                'product_pending_review',
              ProductState.rejected => 'product_rejected_cannot_publish',
              _ when product.stock <= 0 => 'product_out_of_stock_publish',
              _ => null,
            };
            if (refusal != null) {
              throw RequestException(refusal, statusCode: 422);
            }
            product.state = ProductState.published;
          } else if (product.state == ProductState.published) {
            product.state = ProductState.hidden;
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
      ..stock = draft.stock
      ..preparationTime = draft.preparationTime
      ..description = Localized(description, description)
      // On fixtures an upload's URL is its path on the device, so the photo
      // shows wherever the server's copy would.
      ..photos = [...draft.photos]
      ..state = draft.submitForReview
          ? ProductState.pendingReview
          : ProductState.draft;
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
        'stock': product.stock,
        'state': product.state.wire,
        'images': [
          for (final photo in product.photos) {'url': photo.url},
        ],
      };
}
