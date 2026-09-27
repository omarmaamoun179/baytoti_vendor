import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'app_icon.dart';

/// A refusal shown inside a bottom sheet.
///
/// Everywhere else an error is a toast, but the toast belongs to the page
/// underneath and would sit behind an open sheet — so a sheet that talks to
/// the server says it here, above its buttons.
class SheetErrorNote extends StatelessWidget {
  final String message;

  const SheetErrorNote({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: p.badBg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(AppIcons.info, size: 16.r, color: p.bad),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(message, style: AppStrings.text115w400.c(p.bad)),
          ),
        ],
      ),
    );
  }
}
