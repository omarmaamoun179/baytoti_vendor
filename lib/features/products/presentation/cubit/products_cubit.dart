import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/paged.dart';
import '../../domain/entities/vendor_product.dart';
import '../../domain/usecases/products_usecases.dart';
import 'products_state.dart';

/// The products tab: the catalogue a page at a time, searched as the family
/// types, with the publish switch on every row.
class ProductsCubit extends BaseCubit<ProductsState> {
  static const Duration _searchPause = Duration(milliseconds: 500);

  final GetProductsUseCase _getProducts;
  final SetProductVisibilityUseCase _setVisibility;

  /// One read per pause in typing, not one per keystroke.
  final BehaviorSubject<String> _search = BehaviorSubject<String>();
  late final StreamSubscription<String> _searchSubscription;

  /// Bumped by every read that replaces the list; a page that lands under
  /// an older generation is dropped.
  int _generation = 0;

  ProductsCubit(this._getProducts, this._setVisibility)
      : super(const ProductsState()) {
    _searchSubscription = _search
        .debounceTime(_searchPause)
        .distinct()
        .listen((query) => load(query: query));
  }

  /// Reads the first page for [query] (the current one when omitted).
  /// [refresh] keeps the list on screen while it reloads.
  Future<void> load({String? query, bool refresh = false}) async {
    final generation = ++_generation;
    final target = query ?? state.query;
    final keep = refresh && state.hasContent;

    emit(state.copyWith(
      query: target,
      status: keep ? ProductsStatus.refreshing : ProductsStatus.loading,
    ));

    final result = await _getProducts(
      // Absent rather than empty: `q=` on the wire searches for nothing.
      ProductsQuery(search: target.isEmpty ? null : target),
    );
    if (generation != _generation) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: keep ? ProductsStatus.loaded : ProductsStatus.error,
        errorMessage: failure.message,
      )),
      (page) => emit(state.copyWith(
        status: ProductsStatus.loaded,
        page: page,
      )),
    );
  }

  /// Typed into the search box; read once typing pauses.
  void search(String text) => _search.add(text.trim());

  /// Appends the next page — only from a settled list, and never past the
  /// last one.
  Future<void> loadMore() async {
    if (state.status != ProductsStatus.loaded || !state.hasMore) return;

    final generation = _generation;
    emit(state.copyWith(status: ProductsStatus.loadingMore));

    final result = await _getProducts(ProductsQuery(
      search: state.query.isEmpty ? null : state.query,
      page: state.page.nextPage,
    ));
    if (generation != _generation) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProductsStatus.loaded,
        errorMessage: failure.message,
      )),
      (next) => emit(state.copyWith(
        status: ProductsStatus.loaded,
        page: state.page.append(next),
      )),
    );
  }

  /// Flips the row's switch. The server decides: a product in review, a
  /// draft or one out of stock is refused, and the row keeps its state.
  Future<void> toggleVisibility(VendorProductSummary product) async {
    if (state.togglingIds.contains(product.id)) return;

    emit(state.copyWith(togglingIds: {...state.togglingIds, product.id}));

    final result = await _setVisibility(SetProductVisibilityParams(
      productId: product.id,
      published: !product.isLive,
    ));

    final waiting = {...state.togglingIds}..remove(product.id);
    result.fold(
      (failure) => emit(state.copyWith(
        togglingIds: waiting,
        errorMessage: failure.message,
      )),
      (updated) => emit(state.copyWith(
        togglingIds: waiting,
        page: _replaced(updated),
      )),
    );
  }

  Paged<VendorProductSummary> _replaced(VendorProductSummary updated) =>
      Paged<VendorProductSummary>(
        items: [
          for (final product in state.products)
            product.id == updated.id ? updated : product,
        ],
        currentPage: state.page.currentPage,
        lastPage: state.page.lastPage,
        perPage: state.page.perPage,
        total: state.page.total,
      );

  @override
  Future<void> close() async {
    await _searchSubscription.cancel();
    await _search.close();
    return super.close();
  }
}
