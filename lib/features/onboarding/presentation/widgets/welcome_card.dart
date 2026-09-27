import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';

/// The accent card that opens onboarding: a greeting to the family by name
/// and what approval unlocks.
class WelcomeCard extends StatelessWidget {
  final String title;
  final String message;

  const WelcomeCard({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 22.h),
      decoration: BoxDecoration(
        color: p.accent,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStrings.text26w800.c(p.onAccent).tracked(-.02),
          ),
          SizedBox(height: 10.h),
          Text(
            message,
            style: AppStrings.text13w400.c(p.onAccent.withValues(alpha: .88)),
          ),
        ],
      ),
    );
  }
}
