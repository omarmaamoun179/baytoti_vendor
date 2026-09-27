import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/order_status.dart';
import '../entities/vendor_order.dart';

abstract class OrdersRepository {
  Future<Either<Failure, OrderList>> getOrders(OrderTab tab, int page);

  Future<Either<Failure, VendorOrder>> getOrder(String id);

  /// Sends [status] — the order's `next_status` — and answers with the
  /// order as the server now has it.
  Future<Either<Failure, VendorOrder>> advance(String id, OrderStatus status);

  Future<Either<Failure, VendorOrder>> reject(
    String id,
    RejectReason reason, {
    String? note,
  });
}
