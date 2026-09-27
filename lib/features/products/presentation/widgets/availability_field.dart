import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../../../core/widgets/caps_label.dart';

/// Whether the product can be ordered now — the API's `is_available`, which
/// is all it keeps for food in place of a stock count. Drawn beside the
/// price in the stepper's own box, so the row keeps its rhythm.
class AvailabilityField extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AvailabilityField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CapsLabel('product_availability'.tr()),
        SizedBox(height: 8.h),
        InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            height: 46.h,
            padding: EdgeInsetsDirectional.only(start: 12.w, end: 8.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: p.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value
                        ? 'product_available_to_order'.tr()
                        : 'product_out_of_stock'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStrings.text12w600.c(value ? p.fg : p.amberInk),
                  ),
                ),
                AppSwitch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
