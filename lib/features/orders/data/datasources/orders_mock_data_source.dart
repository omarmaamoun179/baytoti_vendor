import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/mock/mock_locale.dart';
import '../../../../core/network/guarded_request.dart';
import '../../domain/entities/order_status.dart';
import '../models/order_models.dart';
import 'order_fixtures.dart';
import 'orders_data_source.dart';

/// [OrderFixtures] behind the same contract as the API.
///
/// Answers in the shapes the contract gives — JSON through the same models
/// a remote source will use — in the app's language ([MockLocale]). It
/// refuses a move the order does not allow, the way the server does, so
/// the fixtures cannot show a flow the API would reject.
class OrdersMockDataSource implements OrdersDataSource {
  static const int _perPage = 10;

  static const Localized _payoutNote = Localized(
    'المبلغ قبل خصم عمولة المنصة. نموذج العمولة بانتظار اعتماد صاحب المشروع.',
    'Amount before platform commission. The commission model is pending '
        'the owner’s approval.',
  );

  final OrderFixtures _fixtures;
  final MockLocale _locale;

  OrdersMockDataSource(this._fixtures, this._locale);

  @override
  Future<Either<Failure, OrderListModel>> getOrders(OrderTab tab, int page) =>
      guardedRequest(
        'OrdersMockDataSource.getOrders',
        () async {
          await Future<void>.delayed(mockLatency);
          final ar = await _locale.isArabic();

          final all = [..._fixtures.orders]
            ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
          final matching = all.where((o) => tab.holds(o.status)).toList();
          final lastPage = (matching.length / _perPage).ceil().clamp(1, 1000);
          final rows = matching.skip((page - 1) * _perPage).take(_perPage);

          return OrderListModel.fromJson({
            'counts': {
              for (final t in OrderTab.values)
                t.wire: all.where((o) => t.holds(o.status)).length,
            },
            'items': [for (final order in rows) summaryJson(order, ar)],
            'meta': {
              'current_page': page,
              'last_page': lastPage,
              'per_page': _perPage,
              'total': matching.length,
            },
          });
        },
        fallbackMessage: 'orders_failed',
      );

  @override
  Future<Either<Failure, VendorOrderModel>> getOrder(String id) =>
      guardedRequest(
        'OrdersMockDataSource.getOrder',
        () async {
          await Future<void>.delayed(mockLatency);
          return VendorOrderModel.fromJson(
            _detailJson(_find(id), await _locale.isArabic()),
          );
        },
        fallbackMessage: 'order_failed',
      );

  @override
  Future<Either<Failure, VendorOrderModel>> advance(
    String id,
    OrderStatus status,
  ) =>
      guardedRequest(
        'OrdersMockDataSource.advance',
        () async {
          await Future<void>.delayed(mockLatency);

          final order = _find(id);
          if (order.nextStatus != status) {
            throw const RequestException(
              'order_transition_invalid',
              statusCode: 422,
            );
          }
          order.status = status;
          return VendorOrderModel.fromJson(
            _detailJson(order, await _locale.isArabic()),
          );
        },
        fallbackMessage: 'order_status_failed',
      );

  @override
  Future<Either<Failure, VendorOrderModel>> reject(
    String id,
    RejectReason reason, {
    String? note,
  }) =>
      guardedRequest(
        'OrdersMockDataSource.reject',
        () async {
          await Future<void>.delayed(mockLatency);

          final order = _find(id);
          if (!order.canReject) {
            throw const RequestException(
              'order_reject_not_allowed',
              statusCode: 422,
            );
          }
          order
            ..status = OrderStatus.rejected
            ..rejectReason = reason.wire;
          return VendorOrderModel.fromJson(
            _detailJson(order, await _locale.isArabic()),
          );
        },
        fallbackMessage: 'order_reject_failed',
      );

  OrderRecord _find(String id) => _fixtures.orders.firstWhere(
        (order) => order.id == id,
        orElse: () => throw const RequestException(
          'order_not_found',
          statusCode: 404,
        ),
      );

  /// A row as the list endpoint sends it — also what the dashboard fixture
  /// lists under `recent_orders`.
  static Map<String, dynamic> summaryJson(OrderRecord order, bool ar) => {
        'id': order.id,
        'reference': order.reference,
        'status': order.status.wire,
        'customer_name': order.customer.pick(ar),
        'item_count': order.itemCount,
        'total_fils': order.totalFils,
        'fulfilment_method': order.fulfilment.wire,
        'placed_at': order.placedAt.toUtc().toIso8601String(),
      };

  Map<String, dynamic> _detailJson(OrderRecord order, bool ar) => {
        ...summaryJson(order, ar),
        'customer': {
          'name': order.customer.pick(ar),
          'phone_masked': '•••• ${order.phoneLast4}',
          'call_token': 'ct_${order.id}',
          'address': order.address?.pick(ar),
        },
        'items': [
          for (final line in order.lines)
            {
              'product_id': line.productId,
              'name': line.name.pick(ar),
              'quantity': line.quantity,
              'line_total_fils': line.lineTotalFils,
            },
        ],
        'payout': {
          'gross_fils': order.totalFils,
          'commission_fils': null,
          'note': _payoutNote.pick(ar),
        },
        'next_status': order.nextStatus?.wire,
        'can_reject': order.canReject,
      };
}
