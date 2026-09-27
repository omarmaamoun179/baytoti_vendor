import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'app_icon.dart';

/// A list with nothing in it — the design's centred `600 13px` line in
/// `neutral-600` ("No orders in this state."), with an optional glyph above
/// and an [action] below.
class EmptyState extends StatelessWidget {
  final String message;
  final String? icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.message,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 56.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon(icon!, size: 30.r, color: p.line2),
            SizedBox(height: 14.h),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppStrings.text13w600.c(p.fg3),
          ),
          if (action != null) ...[
            SizedBox(height: 18.h),
            action!,
          ],
        ],
      ),
    );
  }
}
