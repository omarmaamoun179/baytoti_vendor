import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/app_strings.dart';

/// A status pill — an order's state, a product's review state.
///
/// Colours come from the caller so one shape covers every tone; the mapping
/// from a status to its pair lives with the status. [large] is the order
/// details header's bigger pill (`800 11px`, `7px 10px`).
class StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final bool large;

  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: large
          ? EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h)
          : EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(large ? 8.r : 7.r),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: (large ? AppStrings.text11w800 : AppStrings.text10w800)
            .c(foreground),
      ),
    );
  }
}
