import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../orders/domain/entities/vendor_order.dart';
import '../../../orders/presentation/widgets/order_row.dart';

/// The orders needing action, as rows in one card.
class RecentOrdersCard extends StatelessWidget {
  final List<VendorOrderSummary> orders;
  final ValueChanged<String> onOpen;

  const RecentOrdersCard({
    super.key,
    required this.orders,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: orders.isEmpty
          ? EmptyState(message: 'dashboard_no_open_orders'.tr())
          : Column(
              children: [
                for (var i = 0; i < orders.length; i++)
                  OrderRow(
                    order: orders[i],
                    showDivider: i < orders.length - 1,
                    onTap: () => onOpen(orders[i].id),
                  ),
              ],
            ),
    );
  }
}
