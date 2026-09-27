import 'package:equatable/equatable.dart';

import '../../../orders/domain/entities/vendor_order.dart';

/// One bar of the week chart.
class DailySales extends Equatable {
  final DateTime? date;

  /// The server's short day name ("أحد", "S"), shown as sent.
  final String dayLabel;

  final int totalFils;

  const DailySales({this.date, required this.dayLabel, required this.totalFils});

  @override
  List<Object?> get props => [date, dayLabel, totalFils];
}

class DashboardKpis extends Equatable {
  final int newOrders;
  final int ordersToday;

  /// The family's rating; null before the first review.
  final double? rating;

  /// Products nobody can order right now (`is_available` off) — what the
  /// API keeps for food in place of stock running low.
  final int unavailableCount;

  const DashboardKpis({
    this.newOrders = 0,
    this.ordersToday = 0,
    this.rating,
    this.unavailableCount = 0,
  });

  @override
  List<Object?> get props =>
      [newOrders, ordersToday, rating, unavailableCount];
}

/// The whole home screen: today's sales first, then the indicators, the
/// week, and the orders needing action. The dashboard opens on a decision,
/// not a report.
class VendorDashboard extends Equatable {
  final int salesTodayFils;

  /// "+18% vs yesterday · 7 orders" — the server's own line, in the app's
  /// language. Null hides it.
  final String? salesChange;

  final DashboardKpis kpis;

  /// Oldest first; the last bar is today. Empty when the server would not
  /// answer for a week, and the card is then left out.
  final List<DailySales> week;

  final int weekTotalFils;
  final List<VendorOrderSummary> recentOrders;

  const VendorDashboard({
    required this.salesTodayFils,
    this.salesChange,
    required this.kpis,
    this.week = const [],
    required this.weekTotalFils,
    this.recentOrders = const [],
  });

  @override
  List<Object?> get props =>
      [salesTodayFils, salesChange, kpis, week, weekTotalFils, recentOrders];
}
