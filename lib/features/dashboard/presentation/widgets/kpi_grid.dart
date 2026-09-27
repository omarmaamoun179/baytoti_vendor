import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/vendor_dashboard.dart';

/// The four indicators under the sales card: new orders in amber, today's
/// orders, the family's rating in the accent, products running low. New
/// orders and low stock open the list they count.
class KpiGrid extends StatelessWidget {
  final DashboardKpis kpis;
  final VoidCallback onNewOrders;
  final VoidCallback onLowStock;

  const KpiGrid({
    super.key,
    required this.kpis,
    required this.onNewOrders,
    required this.onLowStock,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rating = kpis.rating;

    return Column(
      children: [
        Row(
          children: [
            _buildKpi(
              context,
              value: '${kpis.newOrders}',
              label: 'dashboard_kpi_new_orders'.tr(),
              color: p.amber,
              onTap: onNewOrders,
            ),
            SizedBox(width: 10.w),
            _buildKpi(
              context,
              value: '${kpis.ordersToday}',
              label: 'dashboard_kpi_orders_today'.tr(),
              color: p.fg,
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            _buildKpi(
              context,
              value: rating == null ? '—' : rating.toStringAsFixed(1),
              label: 'dashboard_kpi_rating'.tr(),
              color: p.accent,
            ),
            SizedBox(width: 10.w),
            _buildKpi(
              context,
              value: '${kpis.lowStockCount}',
              label: 'dashboard_kpi_low_stock'.tr(),
              color: p.fg,
              onTap: onLowStock,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpi(
    BuildContext context, {
    required String value,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final p = context.palette;

    return Expanded(
      child: AppCard(
        radius: 14.r,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppStrings.text22w800.c(color)),
            SizedBox(height: 7.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStrings.text105w400.c(p.fg2).copyWith(height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
