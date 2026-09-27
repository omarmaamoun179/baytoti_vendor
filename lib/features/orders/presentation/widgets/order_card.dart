import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/vendor_order.dart';
import 'order_status_style.dart';

/// An order in the orders list: reference and status, the customer, what
/// and when; the total and how it leaves at the end. The whole card opens
/// the order.
class OrderCard extends StatelessWidget {
  final VendorOrderSummary order;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final time = orderTimeLabel(context, order.placedAt);

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.reference,
                      style: AppStrings.text115w800.c(p.fg3),
                    ),
                    SizedBox(width: 8.w),
                    OrderStatusPill(status: order.status),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  order.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStrings.text135w600.c(p.fg),
                ),
                SizedBox(height: 4.h),
                Text(
                  [itemCountLabel(order.itemCount), if (time.isNotEmpty) time]
                      .join(' · '),
                  style: AppStrings.text11w400.c(p.fg2),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Money.display(order.totalFils),
                style: AppStrings.text14w800.c(p.fg),
              ),
              SizedBox(height: 7.h),
              Text(
                order.fulfilment.labelKey.tr(),
                style: AppStrings.text10w400.c(p.fg3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
