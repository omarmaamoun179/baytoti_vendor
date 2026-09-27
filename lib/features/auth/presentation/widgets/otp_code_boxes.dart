import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';

/// One box per digit of the code, left to right in both languages. The box
/// the next digit goes into is ringed in the accent.
class OtpCodeBoxes extends StatelessWidget {
  final String code;
  final int length;

  const OtpCodeBoxes({super.key, required this.code, required this.length});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          for (var i = 0; i < length; i++) ...[
            if (i > 0) SizedBox(width: 9.w),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 60.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.surf,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: i == code.length ? p.accent : p.line,
                    width: 2,
                  ),
                ),
                child: Text(
                  i < code.length ? code[i] : '',
                  style: AppStrings.text24w800Flat.c(p.fg),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
