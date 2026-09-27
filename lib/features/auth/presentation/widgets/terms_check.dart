import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';

/// "I agree to the terms of use…" — the design's 20px rounded checkbox,
/// filled with the accent when ticked. A form field, so a sign-up without it
/// is stopped with the reason under the line.
class TermsCheck extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const TermsCheck({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: value,
      validator: (_) => value ? null : 'terms_required'.tr(),
      builder: (field) {
        final p = context.palette;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                onChanged(!value);
                field.didChange(!value);
              },
              borderRadius: BorderRadius.circular(6.r),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBox(context, error: field.hasError),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'auth_terms'.tr(),
                      style: AppStrings.text115w400.c(p.fg2),
                    ),
                  ),
                ],
              ),
            ),
            if (field.errorText != null) ...[
              SizedBox(height: 6.h),
              Text(field.errorText!, style: AppStrings.text105w400.c(p.bad)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBox(BuildContext context, {required bool error}) {
    final p = context.palette;
    final border = value ? p.accent : (error ? p.bad : p.line2);

    return Container(
      width: 20.r,
      height: 20.r,
      margin: EdgeInsets.only(top: 1.h),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: value ? p.accent : p.surf,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: border, width: 2),
      ),
      child: value
          ? AppIcon(AppIcons.check, size: 11.r, color: p.onAccent)
          : null,
    );
  }
}
