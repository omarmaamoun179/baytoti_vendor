import 'package:equatable/equatable.dart';

import '../../../../core/domain/paged.dart';
import '../../domain/entities/vendor_product.dart';

enum ProductsStatus { initial, loading, loaded, refreshing, loadingMore, error }

class ProductsState extends Equatable {
  final ProductsStatus status;
  final Paged<VendorProductSummary> page;

  /// What the list is searched for; empty for everything.
  final String query;

  /// Products whose switch is waiting on the server.
  final Set<String> togglingIds;

  final String? errorMessage;

  const ProductsState({
    this.status = ProductsStatus.initial,
    this.page = const Paged<VendorProductSummary>(),
    this.query = '',
    this.togglingIds = const {},
    this.errorMessage,
  });

  List<VendorProductSummary> get products => page.items;

  bool get hasMore => page.hasMore;

  bool get isLoadingMore => status == ProductsStatus.loadingMore;

  bool get hasContent =>
      status == ProductsStatus.loaded ||
      status == ProductsStatus.refreshing ||
      status == ProductsStatus.loadingMore;

  /// [errorMessage] belongs to one attempt and is cleared on every copy
  /// unless passed again.
  ProductsState copyWith({
    ProductsStatus? status,
    Paged<VendorProductSummary>? page,
    String? query,
    Set<String>? togglingIds,
    String? errorMessage,
  }) {
    return ProductsState(
      status: status ?? this.status,
      page: page ?? this.page,
      query: query ?? this.query,
      togglingIds: togglingIds ?? this.togglingIds,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, page, query, togglingIds, errorMessage];
}
