import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/bottom_action_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/vendor_order.dart';
import 'order_status_style.dart';

/// The order's one move forward — accept, start preparing, mark ready, mark
/// delivered — with "reject" beside it while the order is still new. Once
/// there is nowhere left to go the button stays, greyed, saying why.
class OrderActionBar extends StatelessWidget {
  final VendorOrder order;
  final bool advancing;
  final bool rejecting;
  final VoidCallback onAdvance;
  final VoidCallback onReject;

  const OrderActionBar({
    super.key,
    required this.order,
    required this.advancing,
    required this.rejecting,
    required this.onAdvance,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final next = order.nextStatus;
    final busy = advancing || rejecting;

    return BottomActionBar(
      child: Row(
        children: [
          if (order.canReject) ...[
            SecondaryButton(
              label: 'order_reject'.tr(),
              loading: rejecting,
              onPressed: busy ? null : onReject,
            ),
            SizedBox(width: 10.w),
          ],
          Expanded(
            child: PrimaryButton(
              label: next == null ? _closedLabel() : next.advanceKey.tr(),
              enabled: next != null && !rejecting,
              loading: advancing,
              trailingChevron: next != null,
              onPressed: onAdvance,
            ),
          ),
        ],
      ),
    );
  }

  String _closedLabel() => switch (order.status) {
        OrderStatus.rejected => 'order_closed_rejected'.tr(),
        OrderStatus.cancelled => 'order_closed_cancelled'.tr(),
        _ => 'order_complete'.tr(),
      };
}
