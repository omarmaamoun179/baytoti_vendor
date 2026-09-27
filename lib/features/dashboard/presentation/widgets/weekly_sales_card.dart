import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/vendor_dashboard.dart';

/// The last seven days as bars, today's in the accent and the rest in the
/// soft green, with the week's total at the head.
class WeeklySalesCard extends StatelessWidget {
  final List<DailySales> week;
  final int totalFils;

  const WeeklySalesCard({
    super.key,
    required this.week,
    required this.totalFils,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'dashboard_last_seven_days'.tr(),
                  style: AppStrings.text12w800.c(p.fg),
                ),
              ),
              Text(
                Money.display(totalFils),
                style: AppStrings.text11w400Flat.c(p.fg3),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          SizedBox(height: 98.h, child: _buildBars(context)),
        ],
      ),
    );
  }

  Widget _buildBars(BuildContext context) {
    final p = context.palette;
    final peak = week.fold<int>(1, (max, day) => math.max(max, day.totalFils));

    return Semantics(
      label: 'dashboard_last_seven_days'.tr(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < week.length; i++) ...[
            if (i > 0) SizedBox(width: 7.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        // A day with no sales still shows a sliver.
                        heightFactor:
                            math.max(.04, week[i].totalFils / peak),
                        child: Container(
                          decoration: BoxDecoration(
                            color: i == week.length - 1
                                ? p.accent
                                : p.accentSoft2,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 7.h),
                  Text(
                    week[i].dayLabel,
                    maxLines: 1,
                    style: AppStrings.text9w600.c(p.fg3),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
