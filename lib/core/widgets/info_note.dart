import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'app_icon.dart';

/// The amber note that states a rule — "a product is not purchasable until
/// it passes review" — on `--bt-amber-bg`, in `--bt-amber-ink`.
///
/// With [title] it becomes the onboarding's status banner: the icon in an
/// amber tile, a bold line over the explanation.
class InfoNote extends StatelessWidget {
  final String message;
  final String? title;

  /// Defaults to the info circle; the review banner passes the clock.
  final String? icon;

  const InfoNote({
    super.key,
    required this.message,
    this.title,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: EdgeInsets.all(title == null ? 13.r : 14.r),
      decoration: BoxDecoration(
        color: p.amberBg,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: title == null ? _buildRule(context) : _buildBanner(context),
    );
  }

  Widget _buildRule(BuildContext context) {
    final p = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: AppIcon(icon ?? AppIcons.info, size: 16.r, color: p.amberInk),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(message, style: AppStrings.text115w400Loose.c(p.amberInk)),
        ),
      ],
    );
  }

  Widget _buildBanner(BuildContext context) {
    final p = context.palette;

    return Row(
      children: [
        Container(
          width: 38.r,
          height: 38.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.amber,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: AppIcon(icon ?? AppIcons.info, size: 18.r, color: p.onAccent),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title!, style: AppStrings.text13w800.c(p.amberInk)),
              SizedBox(height: 3.h),
              Text(
                message,
                style: AppStrings.text11w400
                    .c(p.amberInk.withValues(alpha: .85)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
