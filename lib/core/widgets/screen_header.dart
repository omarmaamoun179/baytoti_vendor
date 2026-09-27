import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'caps_label.dart';
import 'header_icon_button.dart';

/// The header every screen of the design opens with: a white bar under the
/// status bar, a small tracked kicker over an 800-weight title, back at the
/// start when the screen was pushed, and actions (the bell) at the end.
///
/// The kicker is the screen's name in the *other* language — "Dashboard"
/// over لوحة الأسرة, اللوحة over "Family dashboard" — which is how the
/// translations carry it.
class ScreenHeader extends StatelessWidget {
  final String kicker;
  final String title;

  /// Draws the back button. A tab root has none: navigation starts there.
  final bool showBack;

  /// Replaces the default pop, for a screen that has to ask first.
  final VoidCallback? onBack;

  final List<Widget> actions;

  const ScreenHeader({
    super.key,
    required this.kicker,
    required this.title,
    this.showBack = false,
    this.onBack,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surf,
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 44.h),
            child: Row(
              children: [
                if (showBack) ...[
                  AppBackButton(onPressed: onBack),
                  SizedBox(width: 10.w),
                ],
                Expanded(child: _buildTitles(context)),
                for (final action in actions) ...[
                  SizedBox(width: 10.w),
                  action,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitles(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CapsLabel(
          kicker,
          style: AppStrings.text9w800,
          color: p.accent,
          tracking: .18,
        ),
        SizedBox(height: 4.h),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppStrings.text19w800.c(p.fg).tracked(-.01),
        ),
      ],
    );
  }
}
