import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';

/// A selectable chip — order tabs, categories, cities, preparation time.
///
/// Selected, it fills with the accent; otherwise it sits on the page
/// background with a hairline border. By default a pill that hugs its
/// label; [expand] makes it take an equal share of a row with the design's
/// 12px corners, as the preparation-time options do.
///
/// [enabled] false fades it and ignores taps — for a choice the design shows
/// that cannot be made right now.
class PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final bool expand;
  final bool enabled;

  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    this.onPressed,
    this.expand = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(expand ? 12.r : 999);

    final chip = Material(
      color: selected ? p.accent : p.bg,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: selected ? p.accent : p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: expand
              ? EdgeInsets.symmetric(horizontal: 6.w, vertical: 12.h)
              : EdgeInsets.symmetric(horizontal: 13.w, vertical: 9.h),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStrings.text115w600.c(selected ? p.onAccent : p.fg),
          ),
        ),
      ),
    );

    final shown = enabled ? chip : Opacity(opacity: .45, child: chip);
    return expand ? Expanded(child: shown) : shown;
  }
}
