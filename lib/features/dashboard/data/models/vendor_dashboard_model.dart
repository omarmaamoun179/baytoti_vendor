import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/json_read.dart';
import '../../../orders/data/models/order_models.dart';
import '../../../orders/domain/entities/order_status.dart';
import '../../../orders/domain/entities/vendor_order.dart';
import '../../domain/entities/vendor_dashboard.dart';

/// The dashboard. The fixtures answer in the design contract's
/// `GET /vendor/dashboard` shape, read by [VendorDashboardModel.fromJson]:
///
/// ```json
/// {"sales_today": {"total_fils": 38750, "total_display": "38.750 د.ك",
///                  "change_display": "+١٨٪ مقارنة بالأمس · ٧ طلبات"},
///  "kpis": {"new_orders": 2, "orders_today": 7, "rating": 4.9,
///           "unavailable_count": 1},
///  "sales_last_7_days": [{"date": "2026-09-15", "day_label": "أحد",
///                         "total_fils": 4200}],
///  "week_total_display": "214.400 د.ك",
///  "recent_orders": [ …vendor order summary… ]}
/// ```
///
/// The contract gives the week's total only as display text; it is read as
/// `week_total_fils` when sent and summed from the days otherwise. The live
/// API is read by [VendorDashboardModel.fromApi].
class VendorDashboardModel extends VendorDashboard {
  const VendorDashboardModel({
    required super.salesTodayFils,
    super.salesChange,
    required super.kpis,
    super.week,
    required super.weekTotalFils,
    super.recentOrders,
  });

  factory VendorDashboardModel.fromJson(Map<String, dynamic> json) {
    final sales = asMap(json['sales_today']);
    final kpis = asMap(json['kpis']);
    final week = [
      for (final day in asMapList(json['sales_last_7_days']))
        DailySales(
          date: asDate(day['date']),
          dayLabel: asString(day['day_label']) ?? '',
          totalFils: asInt(day['total_fils']) ?? 0,
        ),
    ];

    return VendorDashboardModel(
      salesTodayFils: asInt(sales['total_fils']) ?? 0,
      salesChange: asString(sales['change_display']),
      kpis: DashboardKpis(
        newOrders: asInt(kpis['new_orders']) ?? 0,
        ordersToday: asInt(kpis['orders_today']) ?? 0,
        rating: asDouble(kpis['rating']),
        unavailableCount: asInt(kpis['unavailable_count']) ?? 0,
      ),
      week: week,
      weekTotalFils: asInt(json['week_total_fils']) ??
          week.fold<int>(0, (sum, day) => sum + day.totalFils),
      recentOrders: [
        for (final row in asMapList(json['recent_orders']))
          VendorOrderSummaryModel.fromJson(row),
      ],
    );
  }

  /// Orders the section under the week shows.
  static const int recentCount = 3;

  /// The live `GET /vendor/home`, as the backend family answers it:
  ///
  /// ```json
  /// {"vendor": {…}, "store": {…},
  ///  "period": {"key": "today", "ar": "اليوم", "en": "Today"},
  ///  "sales": {"amount": "0.000", "currency": "KWD",
  ///            "change_percentage": null,
  ///            "chart": [{"label": "8 AM", "value": 0}, …]},
  ///  "stats": {"new_orders": 0, "processing_orders": 0,
  ///            "low_stock_products": 0, "out_of_stock_products": 0},
  ///  "alerts": [], "recent_orders": []}
  /// ```
  ///
  /// [home] is the day's answer. [week] is the answer to `?period=week`,
  /// drawn only when its own `period.key` says it is one — the server has
  /// answered every period with today's figures before, and today's hourly
  /// buckets under "last seven days" would mislead. [newestOrders] is the
  /// first page of the orders list, read when the answer leaves out the
  /// orders it should carry: `recent_orders` empty, or no count of today's.
  ///
  /// "Not available" is `out_of_stock_products` — for food, the products
  /// switched off. `vendor`, `store` and `alerts` are not read.
  factory VendorDashboardModel.fromApi(
    Map<String, dynamic> home, {
    Map<String, dynamic>? week,
    List<VendorOrderSummary> newestOrders = const [],
  }) {
    final sales = asMap(home['sales']);
    final stats = asMap(home['stats']);
    final change = asDouble(sales['change_percentage']);
    final recent = [
      for (final row in asMapList(home['recent_orders']))
        if (asString(row['id']) != null) VendorOrderSummaryModel.fromApi(row),
    ];
    final orders = recent.isEmpty ? newestOrders : recent;

    final weekSales = asMap(week?['sales']);
    final isWeek =
        asString(asMap(week?['period'])['key'])?.toLowerCase() == 'week';
    final days = [
      if (isWeek)
        for (final bucket in asMapList(weekSales['chart']))
          DailySales(
            date: asDate(bucket['date']) ?? asDate(bucket['label']),
            dayLabel: asString(bucket['label']) ?? '',
            totalFils: _filsOf(bucket['value']),
          ),
    ];

    return VendorDashboardModel(
      salesTodayFils: _filsOf(sales['amount']),
      salesChange: change == null
          ? null
          : 'dashboard_change_vs_previous'.tr(args: [_percent(change)]),
      kpis: DashboardKpis(
        newOrders: asInt(stats['new_orders']) ??
            orders.where((o) => o.status == OrderStatus.placed).length,
        ordersToday: asInt(stats['orders_today']) ??
            asInt(stats['today_orders']) ??
            orders.where((o) => _isToday(o.placedAt)).length,
        rating: asDouble(stats['rating']) ?? asDouble(stats['average_rating']),
        unavailableCount: asInt(stats['out_of_stock_products']) ??
            asInt(stats['unavailable_products']) ??
            0,
      ),
      week: days,
      weekTotalFils: weekSales['amount'] == null
          ? days.fold<int>(0, (sum, day) => sum + day.totalFils)
          : _filsOf(weekSales['amount']),
      recentOrders: _needingAction(orders),
    );
  }

  /// Whether [home] lacks what [VendorDashboardModel.fromApi] would read
  /// from the orders list instead.
  static bool needsOrders(Map<String, dynamic> home) {
    final stats = asMap(home['stats']);
    return asMapList(home['recent_orders']).isEmpty ||
        (stats['orders_today'] == null && stats['today_orders'] == null);
  }

  /// Open orders, the ones waiting on the family first, newest first within
  /// each — as the fixtures order them.
  static List<VendorOrderSummary> _needingAction(
    List<VendorOrderSummary> orders,
  ) {
    DateTime placed(VendorOrderSummary o) => o.placedAt ?? DateTime(0);

    final open = [
      for (final order in orders)
        if (!order.status.isClosed && order.status != OrderStatus.unknown)
          order,
    ]..sort((a, b) {
        final aNew = a.status == OrderStatus.placed ? 0 : 1;
        final bNew = b.status == OrderStatus.placed ? 0 : 1;
        return aNew != bNew ? aNew - bNew : placed(b).compareTo(placed(a));
      });
    return open.take(recentCount).toList();
  }

  static int _filsOf(Object? value) => ((asDouble(value) ?? 0) * 1000).round();

  static bool _isToday(DateTime? time) {
    if (time == null) return false;
    final now = DateTime.now();
    return time.year == now.year &&
        time.month == now.month &&
        time.day == now.day;
  }

  /// `18.0` → `+18%`, `-5.5` → `−5.5%` — isolated left to right, so the
  /// sign stays with the figure inside Arabic.
  static String _percent(double value) {
    final figure = value.abs() == value.abs().roundToDouble()
        ? value.abs().toStringAsFixed(0)
        : value.abs().toStringAsFixed(1);
    final sign = value < 0 ? '−' : '+';
    return '\u2066${'percent_value'.tr(args: ['$sign$figure'])}\u2069';
  }
}
