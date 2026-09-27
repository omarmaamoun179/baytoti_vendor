import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/pill_chip.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/vendor_order.dart';
import 'order_status_style.dart';

/// The lifecycle tabs — "All · 12", "New · 2" — as a scrolling row of
/// pills, each with the count the server sent.
class OrderTabsStrip extends StatelessWidget {
  final OrderTab selected;
  final OrderCounts counts;
  final ValueChanged<OrderTab> onSelected;

  const OrderTabsStrip({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      child: Row(
        children: [
          for (final tab in OrderTab.values) ...[
            if (tab != OrderTab.values.first) SizedBox(width: 7.w),
            PillChip(
              label: '${tab.labelKey.tr()} · ${counts.of(tab)}',
              selected: tab == selected,
              onPressed: () => onSelected(tab),
            ),
          ],
        ],
      ),
    );
  }
}
