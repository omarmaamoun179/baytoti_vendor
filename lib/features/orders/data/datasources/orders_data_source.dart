import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/order_status.dart';
import '../models/order_models.dart';

/// The family's orders. [OrdersRemoteDataSource] calls the live API;
/// [OrdersMockDataSource] answers from fixtures. `useMockData` decides which
/// the repository is built with.
abstract class OrdersDataSource {
  /// One page of [tab], with every tab's count.
  Future<Either<Failure, OrderListModel>> getOrders(OrderTab tab, int page);

  /// One order. 404 is `order_not_found`.
  Future<Either<Failure, VendorOrderModel>> getOrder(String id);

  /// Moves the order to [status] — its next one.
  Future<Either<Failure, VendorOrderModel>> advance(
    String id,
    OrderStatus status,
  );

  /// Turns a new order down. The fixtures keep [reason]; the live API
  /// cancels the order and takes no reason.
  Future<Either<Failure, VendorOrderModel>> reject(
    String id,
    RejectReason reason, {
    String? note,
  });
}
