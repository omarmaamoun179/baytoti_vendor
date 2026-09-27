import '../../../../core/utils/json_read.dart';
import '../../../orders/data/models/order_models.dart';
import '../../domain/entities/vendor_dashboard.dart';

/// `GET /vendor/dashboard`:
///
/// ```json
/// {"sales_today": {"total_fils": 38750, "total_display": "38.750 د.ك",
///                  "change_display": "+١٨٪ مقارنة بالأمس · ٧ طلبات"},
///  "kpis": {"new_orders": 2, "orders_today": 7, "rating": 4.9,
///           "low_stock_count": 3},
///  "sales_last_7_days": [{"date": "2026-09-15", "day_label": "أحد",
///                         "total_fils": 4200}],
///  "week_total_display": "214.400 د.ك",
///  "recent_orders": [ …vendor order summary… ]}
/// ```
///
/// The contract gives the week's total only as display text; it is read as
/// `week_total_fils` when sent and summed from the days otherwise.
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
        lowStockCount: asInt(kpis['low_stock_count']) ?? 0,
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
}
