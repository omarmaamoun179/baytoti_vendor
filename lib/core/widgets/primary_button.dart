import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'app_icon.dart';

/// The call to action: a flat accent fill, 12px radius, an 800-weight label.
///
/// With [enabled] false it drops to the design's `neutral-500` fill — the
/// treatment for "Verify" before four digits are in, or an order that has
/// nowhere left to go. [trailingChevron] adds the forward chevron the
/// design puts on "advance" buttons, mirrored in RTL.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  /// Swaps the label for a spinner and refuses taps while a request is in
  /// flight, so a slow network cannot turn one tap into two submissions.
  final bool loading;

  final bool trailingChevron;

  /// Defaults to 50px.
  final double? height;

  /// Overrides the accent fill.
  final Color? color;

  final TextStyle? labelStyle;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.trailingChevron = false,
    this.height,
    this.color,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(12.r);
    // A spinning button keeps its fill — it is working, not disabled.
    final active = enabled || loading;
    final tappable = enabled && !loading && onPressed != null;

    return SizedBox(
      height: height ?? 50.h,
      child: Material(
        color: active ? (color ?? p.accent) : p.disabled,
        borderRadius: radius,
        child: InkWell(
          onTap: tappable ? onPressed : null,
          borderRadius: radius,
          child: Center(child: _buildContent(context)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final p = context.palette;

    if (loading) {
      return SizedBox.square(
        dimension: 20.r,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: p.onAccent),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (labelStyle ?? AppStrings.text13w800Flat).c(p.onAccent),
            ),
          ),
          if (trailingChevron) ...[
            SizedBox(width: 8.w),
            AppIcon(
              AppIcons.chevronForward,
              size: 16.r,
              color: p.onAccent,
              mirrorInRtl: true,
            ),
          ],
        ],
      ),
    );
  }
}
