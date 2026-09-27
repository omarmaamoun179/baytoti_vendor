import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/order_status.dart';
import '../entities/vendor_order.dart';
import '../repositories/orders_repository.dart';

class OrdersQuery extends Equatable {
  final OrderTab tab;
  final int page;

  const OrdersQuery({this.tab = OrderTab.all, this.page = 1});

  @override
  List<Object?> get props => [tab, page];
}

class GetOrdersUseCase
    implements UseCase<Either<Failure, OrderList>, OrdersQuery> {
  final OrdersRepository _repository;

  GetOrdersUseCase(this._repository);

  @override
  Future<Either<Failure, OrderList>> call(OrdersQuery query) =>
      _repository.getOrders(query.tab, query.page);
}

class GetOrderUseCase implements UseCase<Either<Failure, VendorOrder>, String> {
  final OrdersRepository _repository;

  GetOrderUseCase(this._repository);

  @override
  Future<Either<Failure, VendorOrder>> call(String id) =>
      _repository.getOrder(id);
}

class AdvanceOrderParams extends Equatable {
  final String orderId;
  final OrderStatus status;

  const AdvanceOrderParams({required this.orderId, required this.status});

  @override
  List<Object?> get props => [orderId, status];
}

class AdvanceOrderUseCase
    implements UseCase<Either<Failure, VendorOrder>, AdvanceOrderParams> {
  final OrdersRepository _repository;

  AdvanceOrderUseCase(this._repository);

  @override
  Future<Either<Failure, VendorOrder>> call(AdvanceOrderParams params) =>
      _repository.advance(params.orderId, params.status);
}

class RejectOrderParams extends Equatable {
  final String orderId;
  final RejectReason reason;
  final String? note;

  const RejectOrderParams({
    required this.orderId,
    required this.reason,
    this.note,
  });

  @override
  List<Object?> get props => [orderId, reason, note];
}

class RejectOrderUseCase
    implements UseCase<Either<Failure, VendorOrder>, RejectOrderParams> {
  final OrdersRepository _repository;

  RejectOrderUseCase(this._repository);

  @override
  Future<Either<Failure, VendorOrder>> call(RejectOrderParams params) =>
      _repository.reject(params.orderId, params.reason, note: params.note);
}
