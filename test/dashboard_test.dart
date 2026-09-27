import 'package:baytoti_vendor/features/dashboard/data/models/vendor_dashboard_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = {
    'period': {'key': 'today'},
    'sales': {
      'amount': '38.750',
      'change_percentage': 18,
      'chart': [
        {'label': '8 AM', 'value': 4.2},
      ],
    },
    'stats': {
      'new_orders': 2,
      'orders_today': 7,
      'out_of_stock_products': 1,
    },
    'recent_orders': [
      {'id': 1, 'order_number': 'A', 'status': 'delivered'},
      {'id': 2, 'order_number': 'B', 'status': 'processing'},
      {'id': 3, 'order_number': 'C', 'status': 'pending'},
    ],
  };

  group('the live dashboard', () {
    test('reads the day and the indicators', () {
      final dashboard = VendorDashboardModel.fromApi(today);

      expect(dashboard.salesTodayFils, 38750);
      expect(dashboard.salesChange, isNotNull);
      expect(dashboard.kpis.newOrders, 2);
      expect(dashboard.kpis.ordersToday, 7);
      expect(dashboard.kpis.unavailableCount, 1);
    });

    test('lists open orders only, the new ones first', () {
      final dashboard = VendorDashboardModel.fromApi(today);

      expect(dashboard.recentOrders.map((o) => o.reference), ['C', 'B']);
    });

    test('draws a week only when the answer says it is one', () {
      final ignored = VendorDashboardModel.fromApi(today, week: today);
      expect(ignored.week, isEmpty);

      final week = VendorDashboardModel.fromApi(today, week: {
        'period': {'key': 'week'},
        'sales': {
          'amount': '214.400',
          'chart': [
            {'label': 'Sun', 'value': 30},
            {'label': 'Mon', 'value': 40.5},
          ],
        },
      });
      expect(week.week.map((d) => d.totalFils), [30000, 40500]);
      expect(week.weekTotalFils, 214400);
    });

    test('asks the orders list when the answer leaves the orders out', () {
      expect(VendorDashboardModel.needsOrders(today), isFalse);
      expect(
        VendorDashboardModel.needsOrders({'stats': {}, 'recent_orders': []}),
        isTrue,
      );
    });
  });
}
