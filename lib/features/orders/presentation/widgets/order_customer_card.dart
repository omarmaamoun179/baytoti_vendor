import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/caps_label.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/vendor_order.dart';

/// Who the order is for and where it goes, with the call button.
///
/// The family never sees the customer's number — the contract sends it
/// masked with a `call_token` for a proxied call, and the call endpoint is
/// not specified yet — so the button says calling is on its way rather than
/// dialling anything.
class OrderCustomerCard extends StatelessWidget {
  final VendorOrder order;

  const OrderCustomerCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final customer = order.customer;
    final where = order.fulfilment == FulfilmentMethod.pickup
        ? 'order_pickup_from_family'.tr()
        : customer.address ?? '';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CapsLabel('order_customer'.tr()),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                width: 42.r,
                height: 42.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.muted,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  customer.name.characters.firstOrNull ?? '',
                  style: AppStrings.text15w800.c(p.fg2),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: AppStrings.text13w800.c(p.fg)),
                    SizedBox(height: 4.h),
                    Text(
                      [
                        where,
                        // Isolated, so the dots stay before the digits in
                        // Arabic.
                        if (customer.phoneMasked case final phone?)
                          '\u2066$phone\u2069',
                      ].where((part) => part.isNotEmpty).join(' · '),
                      style: AppStrings.text11w400.c(p.fg2),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              _buildCallButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton(BuildContext context) {
    final p = context.palette;

    return SizedBox.square(
      dimension: 38.r,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
          side: BorderSide(color: p.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showAppToast(context, 'order_call_unavailable'.tr()),
          child: Center(
            child: AppIcon(AppIcons.phone, size: 15.r, color: p.accent),
          ),
        ),
      ),
    );
  }
}
