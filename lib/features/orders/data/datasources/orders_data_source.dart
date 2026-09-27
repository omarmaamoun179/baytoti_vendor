import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/order_status.dart';
import '../models/order_models.dart';

/// The vendor orders endpoints of the API contract. Only fixtures implement
/// it today ([OrdersMockDataSource]); `useMockData` decides which source the
/// repository is built with once a remote one exists.
abstract class OrdersDataSource {
  /// `GET /vendor/orders?state=&page=`.
  Future<Either<Failure, OrderListModel>> getOrders(OrderTab tab, int page);

  /// `GET /vendor/orders/{id}`. 404 is `order_not_found`.
  Future<Either<Failure, VendorOrderModel>> getOrder(String id);

  /// `POST /vendor/orders/{id}/status` with `{status}`.
  Future<Either<Failure, VendorOrderModel>> advance(
    String id,
    OrderStatus status,
  );

  /// `POST /vendor/orders/{id}/reject` with `{reason, note}`.
  Future<Either<Failure, VendorOrderModel>> reject(
    String id,
    RejectReason reason, {
    String? note,
  });
}
