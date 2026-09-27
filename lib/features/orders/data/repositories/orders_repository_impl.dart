import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/vendor_order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_data_source.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersDataSource _dataSource;

  OrdersRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, OrderList>> getOrders(OrderTab tab, int page) =>
      _dataSource.getOrders(tab, page);

  @override
  Future<Either<Failure, VendorOrder>> getOrder(String id) =>
      _dataSource.getOrder(id);

  @override
  Future<Either<Failure, VendorOrder>> advance(String id, OrderStatus status) =>
      _dataSource.advance(id, status);

  @override
  Future<Either<Failure, VendorOrder>> reject(
    String id,
    RejectReason reason, {
    String? note,
  }) =>
      _dataSource.reject(id, reason, note: note);
}
