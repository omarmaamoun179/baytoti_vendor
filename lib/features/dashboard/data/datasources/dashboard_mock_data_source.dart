import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/mock/mock_locale.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../orders/data/datasources/order_fixtures.dart';
import '../../../orders/data/datasources/orders_mock_data_source.dart';
import '../../../orders/domain/entities/order_status.dart';
import '../../../products/data/datasources/product_fixtures.dart';
import '../models/vendor_dashboard_model.dart';
import 'dashboard_data_source.dart';

/// The dashboard on fixtures, worked out from the order and product
/// fixtures the other tabs show — so a new order accepted on the orders tab
/// leaves the dashboard's count, and the badge, one lower.
///
/// Only the six days before today are fixed figures: the order fixtures do
/// not reach back far enough to draw a week.
class DashboardMockDataSource implements DashboardDataSource {
  /// Sales on each of the six days before today, oldest first.
  static const List<int> _pastDaysFils = [
    42250, 61000, 35500, 78750, 54000, 34250,
  ];

  /// Short day names by `DateTime.weekday` (1 is Monday), as the server
  /// would send them.
  static const List<Localized> _days = [
    Localized('اثن', 'M'),
    Localized('ثلا', 'T'),
    Localized('أرب', 'W'),
    Localized('خمي', 'T'),
    Localized('جمع', 'F'),
    Localized('سبت', 'S'),
    Localized('أحد', 'S'),
  ];

  static const double _rating = 4.9;
  static const int _recentCount = 3;

  final OrderFixtures _orders;
  final ProductFixtures _products;
  final MockLocale _locale;

  DashboardMockDataSource(this._orders, this._products, this._locale);

  @override
  Future<Either<Failure, VendorDashboardModel>> getDashboard() =>
      guardedRequest(
        'DashboardMockDataSource.getDashboard',
        () async {
          await Future<void>.delayed(mockLatency);
          final ar = await _locale.isArabic();
          final now = DateTime.now();

          final today = [
            for (final order in _orders.orders)
              if (_sameDay(order.placedAt, now) &&
                  order.status != OrderStatus.rejected &&
                  order.status != OrderStatus.cancelled)
                order,
          ];
          final todayFils =
              today.fold<int>(0, (sum, order) => sum + order.totalFils);

          return VendorDashboardModel.fromJson({
            'sales_today': {
              'total_fils': todayFils,
              'change_display': _change(todayFils, today.length, ar),
            },
            'kpis': {
              'new_orders': _orders.orders
                  .where((order) => order.status == OrderStatus.placed)
                  .length,
              'orders_today': today.length,
              'rating': _rating,
              'low_stock_count': _products.products
                  .where((p) => p.stock <= ProductFixtures.lowStockThreshold)
                  .length,
            },
            'sales_last_7_days': [
              for (var i = 0; i < _pastDaysFils.length; i++)
                _day(now.subtract(Duration(days: 6 - i)), _pastDaysFils[i], ar),
              _day(now, todayFils, ar),
            ],
            'recent_orders': [
              for (final order in _needingAction().take(_recentCount))
                OrdersMockDataSource.summaryJson(order, ar),
            ],
          });
        },
        fallbackMessage: 'dashboard_failed',
      );

  /// Open orders, the ones waiting on the family first, newest first within
  /// each.
  List<OrderRecord> _needingAction() {
    final open = [
      for (final order in _orders.orders)
        if (!order.status.isClosed) order,
    ]..sort((a, b) {
        final aNew = a.status == OrderStatus.placed ? 0 : 1;
        final bNew = b.status == OrderStatus.placed ? 0 : 1;
        return aNew != bNew ? aNew - bNew : b.placedAt.compareTo(a.placedAt);
      });
    return open;
  }

  /// "+18% vs yesterday · 7 orders".
  String _change(int todayFils, int count, bool ar) {
    final yesterday = _pastDaysFils.last;
    final percent = ((todayFils - yesterday) * 100 / yesterday).round();
    final sign = percent >= 0 ? '+' : '−';
    final orders = ar ? '$count طلبات' : '$count orders';

    // The sign and figure isolated left to right, so Arabic keeps "+18٪".
    return ar
        ? '\u2066$sign${percent.abs()}٪\u2069 مقارنة بالأمس · $orders'
        : '$sign${percent.abs()}% vs yesterday · $orders';
  }

  Map<String, dynamic> _day(DateTime date, int fils, bool ar) => {
        'date': date.toIso8601String().substring(0, 10),
        'day_label': _days[date.weekday - 1].pick(ar),
        'total_fils': fils,
      };

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
