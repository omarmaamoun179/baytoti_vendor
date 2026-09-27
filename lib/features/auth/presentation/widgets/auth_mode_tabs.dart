import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/auth_params.dart';

/// The words each tab of the sign-in screen uses.
extension AuthModeLabels on AuthMode {
  String get tabKey => switch (this) {
        AuthMode.login => 'auth_tab_login',
        AuthMode.signup => 'auth_tab_signup',
      };

  String get ctaKey => switch (this) {
        AuthMode.login => 'auth_cta_login',
        AuthMode.signup => 'auth_cta_signup',
      };
}

/// Sign in / new family, as a segmented control: a `neutral-200` track with
/// the chosen half raised on a white card.
class AuthModeTabs extends StatelessWidget {
  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  const AuthModeTabs({super.key, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: p.surf2,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          for (final option in AuthMode.values) ...[
            if (option != AuthMode.values.first) SizedBox(width: 4.w),
            Expanded(child: _buildTab(context, option)),
          ],
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, AuthMode option) {
    final p = context.palette;
    final selected = option == mode;
    final radius = BorderRadius.circular(9.r);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 42.h,
      decoration: BoxDecoration(
        color: selected ? p.surf : Colors.transparent,
        borderRadius: radius,
        boxShadow: selected ? p.cardShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(option),
          borderRadius: radius,
          child: Center(
            child: Text(
              option.tabKey.tr(),
              style: AppStrings.text125w800Flat.c(selected ? p.fg : p.fg2),
            ),
          ),
        ),
      ),
    );
  }
}
