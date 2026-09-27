import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/vendor_order.dart';
import 'order_status_style.dart';

/// The top of an order: its reference, when and how, the status pill, and
/// the design's five-segment bar of how far along it is.
class OrderHeaderCard extends StatelessWidget {
  final VendorOrder order;

  const OrderHeaderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final time = orderTimeLabel(context, order.placedAt);

    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.reference, style: AppStrings.text22w800.c(p.fg)),
                    SizedBox(height: 7.h),
                    Text(
                      [if (time.isNotEmpty) time, order.fulfilment.labelKey.tr()]
                          .join(' · '),
                      style: AppStrings.text115w400Meta.c(p.fg2),
                    ),
                  ],
                ),
              ),
              OrderStatusPill(status: order.status, large: true),
            ],
          ),
          SizedBox(height: 16.h),
          _buildProgress(context),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    final p = context.palette;
    // A rejected or cancelled order left the path: every segment goes quiet.
    final reached = order.status.step ?? -1;

    return Row(
      children: [
        for (var i = 0; i < OrderStatus.stepCount; i++) ...[
          if (i > 0) SizedBox(width: 5.w),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 6.h,
              decoration: BoxDecoration(
                color: i <= reached ? p.accent : p.muted,
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
