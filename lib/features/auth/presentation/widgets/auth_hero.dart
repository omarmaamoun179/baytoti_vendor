import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';

/// The top of sign-in: the Arabic wordmark, the Latin name small and
/// tracked, and one line on what the app is for — all in the accent green,
/// straight on the page background.
class AuthHero extends StatelessWidget {
  const AuthHero({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 30.h, 20.w, 10.h),
      child: Column(
        children: [
          Text(
            'brand_wordmark'.tr(),
            style: AppStrings.text30w800.c(p.accent).tracked(-.02),
          ),
          SizedBox(height: 8.h),
          Text(
            'BAYTOUTI · VENDOR',
            style: AppStrings.text9w800
                .c(p.accent.withValues(alpha: .72))
                .tracked(.24),
          ),
          SizedBox(height: 12.h),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 280.w),
            child: Text(
              'auth_intro'.tr(),
              textAlign: TextAlign.center,
              style: AppStrings.text125w400.c(p.accent.withValues(alpha: .88)),
            ),
          ),
        ],
      ),
    );
  }
}
