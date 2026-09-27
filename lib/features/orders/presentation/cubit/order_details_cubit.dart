import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/failure.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/vendor_order.dart';
import '../../domain/usecases/orders_usecases.dart';
import 'order_details_state.dart';

class OrderDetailsCubit extends BaseCubit<OrderDetailsState> {
  final GetOrderUseCase _getOrder;
  final AdvanceOrderUseCase _advanceOrder;
  final RejectOrderUseCase _rejectOrder;

  OrderDetailsCubit(this._getOrder, this._advanceOrder, this._rejectOrder)
      : super(const OrderDetailsState());

  Future<void> load(String id) async {
    emit(state.copyWith(status: OrderDetailsStatus.loading));

    final result = await _getOrder(id);

    result.fold(
      (failure) => emit(state.copyWith(
        status: OrderDetailsStatus.error,
        errorMessage: failure.message,
      )),
      (order) => emit(state.copyWith(
        status: OrderDetailsStatus.loaded,
        order: order,
      )),
    );
  }

  /// Sends the order's `next_status`. The server validates the move again
  /// and answers with the order's new state and its next move.
  Future<void> advance() async {
    final order = state.order;
    final next = order?.nextStatus;
    if (order == null || next == null || state.isBusy) return;

    emit(state.copyWith(actionStatus: OrderActionStatus.advancing));

    final result = await _advanceOrder(
      AdvanceOrderParams(orderId: order.id, status: next),
    );
    result.fold(_emitFailed, (updated) => _emitMoved(updated, next));
  }

  /// Turns the order down. The confirmation — and the reason — have already
  /// been asked for.
  Future<void> reject(RejectReason reason, {String? note}) async {
    final order = state.order;
    if (order == null || !order.canReject || state.isBusy) return;

    emit(state.copyWith(actionStatus: OrderActionStatus.rejecting));

    final result = await _rejectOrder(
      RejectOrderParams(orderId: order.id, reason: reason, note: note),
    );
    result.fold(
      _emitFailed,
      (updated) => _emitMoved(updated, OrderStatus.rejected),
    );
  }

  void _emitMoved(VendorOrder updated, OrderStatus movedTo) =>
      emit(state.copyWith(
        order: updated,
        actionStatus: OrderActionStatus.succeeded,
        movedTo: movedTo,
        changed: true,
      ));

  void _emitFailed(Failure failure) => emit(state.copyWith(
        actionStatus: OrderActionStatus.failed,
        errorMessage: failure.message,
      ));
}
