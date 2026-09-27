import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/caps_label.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../domain/entities/vendor_order.dart';

/// What was ordered, and what the family is owed for it — the gross, with
/// the note on the commission still to come off it.
class OrderItemsCard extends StatelessWidget {
  final VendorOrder order;

  const OrderItemsCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsLabel('order_items_title'.tr()),
          SizedBox(height: 6.h),
          for (final line in order.lines) _buildLine(context, line),
          Padding(
            padding: EdgeInsets.only(top: 13.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'order_payout'.tr(),
                    style: AppStrings.text14w800.c(p.fg),
                  ),
                ),
                Text(
                  Money.display(order.payout.grossFils),
                  style: AppStrings.text14w800.c(p.accent),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            order.payout.note ?? 'order_commission_note'.tr(),
            style: AppStrings.text105w400Loose.c(p.fg3),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(BuildContext context, OrderLine line) {
    final p = context.palette;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 11.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11.r),
            child: SizedBox.square(
              dimension: 44.r,
              child: NetworkPhoto(source: line.imageUrl, iconSize: 15.r),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name, style: AppStrings.text125w600.c(p.fg)),
                SizedBox(height: 4.h),
                Text(
                  '× ${line.quantity}',
                  style: AppStrings.text105w400.c(p.fg3),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            Money.display(line.lineTotalFils),
            style: AppStrings.text12w800.c(p.fg),
          ),
        ],
      ),
    );
  }
}
