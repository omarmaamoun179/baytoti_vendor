import 'package:equatable/equatable.dart';

import '../../domain/entities/order_status.dart';
import '../../domain/entities/vendor_order.dart';

enum OrderDetailsStatus { initial, loading, loaded, error }

/// A move started from the details screen, kept apart from the screen's own
/// loading so a failed move never blanks the order.
enum OrderActionStatus { idle, advancing, rejecting, succeeded, failed }

class OrderDetailsState extends Equatable {
  final OrderDetailsStatus status;
  final VendorOrder? order;
  final String? errorMessage;
  final OrderActionStatus actionStatus;

  /// Where the last successful move took the order, for its toast.
  final OrderStatus? movedTo;

  /// True once any move has gone through, so the screen that opened this
  /// one knows to read its list again.
  final bool changed;

  const OrderDetailsState({
    this.status = OrderDetailsStatus.initial,
    this.order,
    this.errorMessage,
    this.actionStatus = OrderActionStatus.idle,
    this.movedTo,
    this.changed = false,
  });

  bool get isBusy =>
      actionStatus == OrderActionStatus.advancing ||
      actionStatus == OrderActionStatus.rejecting;

  /// [errorMessage], [actionStatus] and [movedTo] belong to one attempt and
  /// are cleared on every copy unless passed again.
  OrderDetailsState copyWith({
    OrderDetailsStatus? status,
    VendorOrder? order,
    String? errorMessage,
    OrderActionStatus? actionStatus,
    OrderStatus? movedTo,
    bool? changed,
  }) {
    return OrderDetailsState(
      status: status ?? this.status,
      order: order ?? this.order,
      errorMessage: errorMessage,
      actionStatus: actionStatus ?? OrderActionStatus.idle,
      movedTo: movedTo,
      changed: changed ?? this.changed,
    );
  }

  @override
  List<Object?> get props =>
      [status, order, errorMessage, actionStatus, movedTo, changed];
}
