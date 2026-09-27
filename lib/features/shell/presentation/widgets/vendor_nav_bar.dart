import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../orders/presentation/cubit/orders_badge_cubit.dart';

/// The design's tab bar: home, orders (with the new-order count on amber),
/// products, offers, store — the design's own stroke icons, the chosen one
/// in the accent.
class VendorNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const VendorNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final newOrders = context.select(
      (OrdersBadgeCubit cubit) => cubit.state.count,
    );
    final inset = MediaQuery.viewPaddingOf(context).bottom;

    final tabs = [
      (AppIcons.navDashboard, 'nav_home'),
      (AppIcons.navOrders, 'nav_orders'),
      (AppIcons.navProducts, 'nav_products'),
      (AppIcons.navOffers, 'nav_offers'),
      (AppIcons.navStore, 'nav_store'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surf,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: inset > 0 ? inset : 8.h),
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: _buildTab(
                  context,
                  icon: tabs[i].$1,
                  label: tabs[i].$2.tr(),
                  badge: i == 1 && newOrders > 0 ? newOrders : null,
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context, {
    required String icon,
    required String label,
    required int? badge,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final p = context.palette;
    final color = selected ? p.accent : p.fg3;

    return Semantics(
      selected: selected,
      button: true,
      label: badge == null ? label : '$label, $badge',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 44.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(4.w, 10.h, 4.w, 8.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AppIcon(icon, size: 19.r, color: color),
                    if (badge != null)
                      PositionedDirectional(
                        top: -6.r,
                        end: -14.r,
                        child: _buildBadge(context, badge),
                      ),
                  ],
                ),
                SizedBox(height: 5.h),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStrings.text95w600.c(color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, int count) {
    final p = context.palette;

    return Container(
      constraints: BoxConstraints(minWidth: 17.r),
      height: 17.r,
      padding: EdgeInsets.symmetric(horizontal: 4.r),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.amber,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AppStrings.text9w800.c(p.onAccent),
      ),
    );
  }
}
