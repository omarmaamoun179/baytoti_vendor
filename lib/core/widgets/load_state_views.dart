import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'app_icon.dart';
import 'empty_state.dart';
import 'secondary_button.dart';

/// A screen's first read, with nothing to show yet.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.r),
        child: SizedBox.square(
          dimension: 24.r,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: context.palette.accent,
          ),
        ),
      ),
    );
  }
}

/// A first read that failed: what went wrong, and a way to ask again.
///
/// Only for a screen with nothing on it — a refresh or a next page that
/// fails over content already shown is a toast, never this.
class LoadErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  /// A second way out under "try again" — the onboarding gate's sign-out,
  /// for an account whose reads keep failing.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const LoadErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Center(
      child: EmptyState(
        icon: AppIcons.info,
        message: message,
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SecondaryButton(
              label: 'try_again'.tr(),
              height: 44.h,
              onPressed: onRetry,
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              SizedBox(height: 8.h),
              TextButton(
                onPressed: onSecondary,
                child: Text(
                  secondaryLabel!,
                  style: AppStrings.text12w800.c(p.fg2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
