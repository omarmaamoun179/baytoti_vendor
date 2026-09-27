import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/primary_button.dart';

/// The catalogue's search box with "+ Add" beside it.
class ProductSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;

  const ProductSearchBar({
    super.key,
    required this.onChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: p.line),
    );

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44.h,
            child: TextField(
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppStrings.text125w600.c(p.fg),
              cursorColor: p.accent,
              decoration: InputDecoration(
                filled: true,
                fillColor: p.surf,
                isDense: true,
                hintText: 'products_search_hint'.tr(),
                hintStyle: AppStrings.text12w400Flat.c(p.fg3),
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                prefixIcon: Padding(
                  padding: EdgeInsetsDirectional.only(start: 13.w, end: 9.w),
                  child: AppIcon(AppIcons.search, size: 14.r, color: p.fg3),
                ),
                prefixIconConstraints: const BoxConstraints(),
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: BorderSide(color: p.accent),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        PrimaryButton(
          label: '+ ${'add'.tr()}',
          height: 44.h,
          labelStyle: AppStrings.text12w800,
          onPressed: onAdd,
        ),
      ],
    );
  }
}
