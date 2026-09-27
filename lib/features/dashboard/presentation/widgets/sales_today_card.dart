import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/caps_label.dart';

/// Today's sales first — the accent card that opens the dashboard, with the
/// server's line on how today compares.
class SalesTodayCard extends StatelessWidget {
  final int totalFils;
  final String? change;

  const SalesTodayCard({super.key, required this.totalFils, this.change});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: p.accent,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CapsLabel(
            'dashboard_sales_today'.tr(),
            style: AppStrings.text9w800,
            color: p.onAccent.withValues(alpha: .7),
            tracking: .18,
          ),
          SizedBox(height: 10.h),
          Text(
            Money.display(totalFils),
            style: AppStrings.text34w800.c(p.onAccent),
          ),
          if (change != null) ...[
            SizedBox(height: 8.h),
            Text(
              change!,
              style: AppStrings.text12w400.c(p.onAccent.withValues(alpha: .85)),
            ),
          ],
        ],
      ),
    );
  }
}
