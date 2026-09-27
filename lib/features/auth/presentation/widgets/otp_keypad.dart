import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';

/// The design's on-screen keypad: 1–9, then a blank, 0 and delete, in three
/// columns. Laid out left to right in both languages, like a phone's.
class OtpKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  const OtpKeypad({super.key, required this.onDigit, required this.onDelete});

  static const List<String?> _keys = [
    '1', '2', '3', //
    '4', '5', '6', //
    '7', '8', '9', //
    null, '0', 'del',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          for (var row = 0; row < 4; row++) ...[
            if (row > 0) SizedBox(height: 8.h),
            Row(
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) SizedBox(width: 8.w),
                  Expanded(child: _buildKey(context, _keys[row * 3 + col])),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKey(BuildContext context, String? key) {
    final p = context.palette;
    if (key == null) return SizedBox(height: 54.h);

    final radius = BorderRadius.circular(12.r);
    final isDelete = key == 'del';

    return SizedBox(
      height: 54.h,
      child: Material(
        color: p.surf,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: p.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDelete ? onDelete : () => onDigit(key),
          child: Center(
            child: isDelete
                ? Icon(Icons.backspace_outlined, size: 20.r, color: p.fg)
                : Text(key, style: AppStrings.text20w800.c(p.fg)),
          ),
        ),
      ),
    );
  }
}
