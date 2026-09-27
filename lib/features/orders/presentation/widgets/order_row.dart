import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/vendor_order.dart';
import 'order_status_style.dart';

/// An order as a row inside a card — the dashboard's "orders needing
/// action": the customer over the reference and item count, then status
/// and total. Rows carry their own divider; the last one leaves it off.
class OrderRow extends StatelessWidget {
  final VendorOrderSummary order;
  final VoidCallback onTap;
  final bool showDivider;

  const OrderRow({
    super.key,
    required this.order,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: p.line))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStrings.text125w600.c(p.fg),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${order.reference} · ${itemCountLabel(order.itemCount)}',
                    style: AppStrings.text105w400.c(p.fg3),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            OrderStatusPill(status: order.status),
            SizedBox(width: 10.w),
            Text(
              Money.display(order.totalFils),
              style: AppStrings.text12w800.c(p.fg),
            ),
          ],
        ),
      ),
    );
  }
}
