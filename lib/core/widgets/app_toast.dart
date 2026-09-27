import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'app_icon.dart';

/// The app's toast: an ink-colored bar that floats above the tab bar, or
/// above a screen's bottom action bar, for a few seconds.
///
/// Built on [ScaffoldMessenger] rather than a hand-rolled overlay so it
/// queues, dismisses on navigation, and needs no manual timer. The floating
/// bar rises above the nearest root [Scaffold]'s bottom bar on its own.
///
/// [isError] only swaps the leading glyph — a failure reads as the same
/// component rather than a second kind of banner.
///
/// [actionLabel] with [onAction] adds an action at the end and keeps the bar
/// up long enough to reach it.
void showAppToast(
  BuildContext context,
  String message, {
  bool isError = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final p = context.palette;
  final action = actionLabel == null || onAction == null
      ? null
      : SnackBarAction(
          label: actionLabel,
          textColor: p.accentSoft2,
          onPressed: onAction,
        );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.fg,
        elevation: 0,
        action: action,
        // A bar with an action otherwise stays until someone closes it.
        persist: false,
        duration: action == null ? _readingTime(message) : _actionTime,
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        content: Row(
          children: [
            AppIcon(
              isError ? AppIcons.info : AppIcons.check,
              size: isError ? 18.r : 16.r,
              color: isError ? p.amber : p.accentSoft2,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                message,
                style: AppStrings.text125w600.c(p.surf).copyWith(height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Long enough to read the bar and reach for its action.
const Duration _actionTime = Duration(seconds: 5);

/// Long enough to read what is in the bar — a validation toast lists every
/// field the server refused, one per line.
Duration _readingTime(String message) {
  const base = Duration(milliseconds: 2400);
  const perLine = Duration(milliseconds: 900);
  const cap = Duration(seconds: 8);

  // Counted in lines rather than characters: the extra lines are what the bar
  // grows by, and a single long line still wraps into the same width.
  final extraLines = message.split('\n').length - 1;
  if (extraLines <= 0) return base;

  final total = base + perLine * extraLines;
  return total > cap ? cap : total;
}
