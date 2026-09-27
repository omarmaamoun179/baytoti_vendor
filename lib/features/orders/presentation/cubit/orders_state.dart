import 'package:equatable/equatable.dart';

import '../../../../core/domain/paged.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/vendor_order.dart';

enum OrdersStatus {
  initial,

  /// The first read of a tab, with nothing of it on screen yet.
  loading,

  loaded,

  /// A pull-to-refresh over a list that is already showing.
  refreshing,

  /// The next page is on its way; the list stays and gains a footer.
  loadingMore,

  /// The first read of a tab failed.
  error,
}

class OrdersState extends Equatable {
  final OrdersStatus status;
  final OrderTab tab;
  final Paged<VendorOrderSummary> page;

  /// Every tab's count, from the last answer. Kept while another tab loads,
  /// so the chips do not blank.
  final OrderCounts counts;

  final String? errorMessage;

  const OrdersState({
    this.status = OrdersStatus.initial,
    this.tab = OrderTab.all,
    this.page = const Paged<VendorOrderSummary>(),
    this.counts = const OrderCounts(),
    this.errorMessage,
  });

  List<VendorOrderSummary> get orders => page.items;

  bool get hasMore => page.hasMore;

  bool get isLoadingMore => status == OrdersStatus.loadingMore;

  bool get hasContent =>
      status == OrdersStatus.loaded ||
      status == OrdersStatus.refreshing ||
      status == OrdersStatus.loadingMore;

  /// [errorMessage] belongs to one attempt and is cleared on every copy
  /// unless passed again.
  OrdersState copyWith({
    OrdersStatus? status,
    OrderTab? tab,
    Paged<VendorOrderSummary>? page,
    OrderCounts? counts,
    String? errorMessage,
  }) {
    return OrdersState(
      status: status ?? this.status,
      tab: tab ?? this.tab,
      page: page ?? this.page,
      counts: counts ?? this.counts,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, tab, page, counts, errorMessage];
}
