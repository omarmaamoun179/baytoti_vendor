import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'app_icon.dart';
import 'primary_button.dart';
import 'secondary_button.dart';
import 'sheet_handle.dart';

/// The sheet a consequential action passes through — ending an offer,
/// signing out — so its effect is explained before it happens.
///
/// Resolves true only when the confirm button is tapped. Dismissing, dragging
/// down and "back" all resolve false, so a caller writes
/// `if (!await showConfirmSheet(…)) return;`.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String icon,
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => ConfirmSheet(
      icon: icon,
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      destructive: destructive,
    ),
  );
  return confirmed ?? false;
}

class ConfirmSheet extends StatelessWidget {
  final String icon;
  final String title;
  final String body;
  final String confirmLabel;

  /// Paints the icon and the confirm button in `bad` rather than the accent.
  final bool destructive;

  const ConfirmSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 22.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            Container(
              width: 52.r,
              height: 52.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: destructive ? p.badBg : p.accentSoft,
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                icon,
                size: 22.r,
                color: destructive ? p.bad : p.accent,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppStrings.text17w800.c(p.fg),
            ),
            SizedBox(height: 8.h),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppStrings.text125w400.c(p.fg2),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'go_back'.tr(),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: PrimaryButton(
                    label: confirmLabel,
                    color: destructive ? p.bad : null,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
