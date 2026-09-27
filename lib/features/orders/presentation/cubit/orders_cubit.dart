import '../../../../core/abstract/base_cubit.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/usecases/orders_usecases.dart';
import 'orders_state.dart';

/// The orders tab: one page at a time of the chosen state, with every tab's
/// count from the same answer.
class OrdersCubit extends BaseCubit<OrdersState> {
  final GetOrdersUseCase _getOrders;

  /// Bumped by every read that replaces the list. A page requested under an
  /// older generation — a tab switch or a refresh landed while it was in
  /// flight — is dropped instead of being appended to a list it does not
  /// belong to.
  int _generation = 0;

  OrdersCubit(this._getOrders) : super(const OrdersState());

  /// Reads the first page of [tab] (the current one when omitted),
  /// replacing whatever is shown. [refresh] keeps the list on screen while
  /// it reloads.
  Future<void> load({OrderTab? tab, bool refresh = false}) async {
    final generation = ++_generation;
    final target = tab ?? state.tab;
    final keep = refresh && target == state.tab && state.hasContent;

    emit(state.copyWith(
      tab: target,
      status: keep ? OrdersStatus.refreshing : OrdersStatus.loading,
    ));

    final result = await _getOrders(OrdersQuery(tab: target));
    if (generation != _generation) return;

    result.fold(
      (failure) => emit(state.copyWith(
        // A failed refresh keeps the list and says so in a toast.
        status: keep ? OrdersStatus.loaded : OrdersStatus.error,
        errorMessage: failure.message,
      )),
      (list) => emit(state.copyWith(
        status: OrdersStatus.loaded,
        page: list.page,
        counts: list.counts,
      )),
    );
  }

  Future<void> selectTab(OrderTab tab) async {
    if (tab == state.tab && state.status != OrdersStatus.error) return;
    await load(tab: tab);
  }

  /// Appends the next page — only from a settled list, and never past the
  /// last one. A second call while one is in flight would ask for the same
  /// page, which the network layer rejects as a duplicate request.
  Future<void> loadMore() async {
    if (state.status != OrdersStatus.loaded || !state.hasMore) return;

    final generation = _generation;
    emit(state.copyWith(status: OrdersStatus.loadingMore));

    final result = await _getOrders(
      OrdersQuery(tab: state.tab, page: state.page.nextPage),
    );
    if (generation != _generation) return;

    result.fold(
      // A failed next page is a toast, never a blanked list.
      (failure) => emit(state.copyWith(
        status: OrdersStatus.loaded,
        errorMessage: failure.message,
      )),
      (list) => emit(state.copyWith(
        status: OrdersStatus.loaded,
        page: state.page.append(list.page),
        counts: list.counts,
      )),
    );
  }
}
