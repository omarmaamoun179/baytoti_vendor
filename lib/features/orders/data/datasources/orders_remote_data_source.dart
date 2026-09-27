import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/utils/json_read.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/vendor_order.dart';
import '../models/order_models.dart';
import 'orders_data_source.dart';

/// The family's orders on the live API: `GET /vendor/orders`, one order,
/// and `PATCH /vendor/orders/{id}/status`.
class OrdersRemoteDataSource implements OrdersDataSource {
  /// Rows a filtered tab tries to gather before it answers, so a short
  /// screen still has something to scroll — the endpoint takes no filter,
  /// and a page of the newest orders may hold few of one kind.
  static const int _fillRows = 8;

  /// Pages one filtered read may take to gather them.
  static const int _maxPagesPerRead = 5;

  final NetworkService _networkService;

  OrdersRemoteDataSource(this._networkService);

  /// The spec documents no filter, so every tab reads the same pages and
  /// keeps its own rows ([OrderTab.holds]). The counts are worked out from
  /// the first page ([OrderListModel.countsFromApi]); a later page answers
  /// none, and the list keeps the ones it has.
  @override
  Future<Either<Failure, OrderListModel>> getOrders(OrderTab tab, int page) =>
      guardedRequest(
        'OrdersRemoteDataSource.getOrders',
        () async {
          final rows = <VendorOrderSummary>[];
          var counts = const OrderCounts();
          var next = page;
          var reads = 0;
          ApiResponse envelope;

          do {
            envelope = checkedResponse(await _networkService.get(
              ApiEndPoint.vendorOrders,
              queryParameters: {'page': next},
            ));
            final pageRows = OrderListModel.rowsFromApi(envelope);
            if (next == 1) {
              counts = OrderListModel.countsFromApi(
                pageRows,
                total: envelope.total,
              );
            }
            rows.addAll(pageRows.where((order) => tab.holds(order.status)));
            next = envelope.currentPage + 1;
            reads++;
          } while (tab != OrderTab.all &&
              rows.length < _fillRows &&
              envelope.currentPage < envelope.lastPage &&
              reads < _maxPagesPerRead);

          return OrderListModel(
            page: Paged<VendorOrderSummary>(
              items: rows,
              // Where the reading stopped, so the next page follows on.
              currentPage: envelope.currentPage,
              lastPage: envelope.lastPage,
              perPage: envelope.perPage,
              total: tab == OrderTab.all ? envelope.total : counts.of(tab),
            ),
            counts: counts,
          );
        },
        fallbackMessage: 'orders_failed',
      );

  @override
  Future<Either<Failure, VendorOrderModel>> getOrder(String id) =>
      guardedRequest(
        'OrdersRemoteDataSource.getOrder',
        () async => _read(id),
        fallbackMessage: 'order_failed',
        messageForStatus: const {404: 'order_not_found'},
      );

  @override
  Future<Either<Failure, VendorOrderModel>> advance(
    String id,
    OrderStatus status,
  ) =>
      guardedRequest(
        'OrdersRemoteDataSource.advance',
        () async {
          final wire = orderStatusToApi(status);
          if (wire == null) {
            throw const RequestException(
              'order_transition_invalid',
              statusCode: 422,
            );
          }
          return _move(id, wire);
        },
        fallbackMessage: 'order_status_failed',
        messageForStatus: const {404: 'order_not_found'},
      );

  /// Turning an order down is cancelling it. The API takes no reason, so
  /// the one the family chose stays with the app.
  @override
  Future<Either<Failure, VendorOrderModel>> reject(
    String id,
    RejectReason reason, {
    String? note,
  }) =>
      guardedRequest(
        'OrdersRemoteDataSource.reject',
        () async => _move(id, orderStatusToApi(OrderStatus.cancelled)!),
        fallbackMessage: 'order_reject_failed',
        messageForStatus: const {404: 'order_not_found'},
      );

  /// Sends [wire] and answers with the order as the server now has it —
  /// the one the answer carries, or, for a bare confirmation, read back.
  Future<VendorOrderModel> _move(String id, String wire) async {
    final envelope = checkedResponse(await _networkService.patch(
      ApiEndPoint.vendorOrderStatus(id),
      data: {'status': wire},
    ));

    final order = VendorOrderModel.orderMapOf(envelope);
    return asString(order['id']) == null
        ? _read(id)
        : VendorOrderModel.fromApi(order);
  }

  Future<VendorOrderModel> _read(String id) async =>
      VendorOrderModel.fromResponse(checkedResponse(
        await _networkService.get(ApiEndPoint.vendorOrder(id)),
      ));
}
