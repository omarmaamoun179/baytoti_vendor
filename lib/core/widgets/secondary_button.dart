import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';

/// The quieter action beside a [PrimaryButton] — "Draft", "Reject",
/// "Create offer": no fill, a hairline border, text in the ink color.
///
/// Hugs its label unless placed in an `Expanded`; the design sizes it by
/// its padding (`0 18px`).
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  /// Defaults to 50px.
  final double? height;

  final Color? foreground;
  final Color? background;
  final bool loading;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height,
    this.foreground,
    this.background,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(12.r);
    final ink = foreground ?? p.fg;

    return SizedBox(
      height: height ?? 50.h,
      child: Material(
        color: background ?? Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: p.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: loading ? null : onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: Center(
              widthFactor: 1,
              child: loading
                  ? SizedBox.square(
                      dimension: 18.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ink,
                      ),
                    )
                  : Text(
                      label,
                      maxLines: 1,
                      style: AppStrings.text12w800.c(ink),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
