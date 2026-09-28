import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/caps_label.dart';
import '../../../location/presentation/widgets/location_row.dart';

/// The app's language, the account's location and signing out. Not in the
/// design, which switches language outside the phone and never signs out;
/// they sit at the foot of the store tab, the family's own corner of the
/// app. The language control is the design canvas's عربي | ENGLISH toggle.
class AccountCard extends StatelessWidget {
  final VoidCallback onSignOut;

  const AccountCard({super.key, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsLabel('account_title'.tr()),
          SizedBox(height: 12.h),
          Row(
            children: [
              AppIcon(AppIcons.globe, size: 16.r, color: p.fg2),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'account_language'.tr(),
                  style: AppStrings.text12w600.c(p.fg),
                ),
              ),
              _buildLanguageToggle(context),
            ],
          ),
          _buildDivider(context),
          const LocationRow(),
          _buildDivider(context),
          InkWell(
            onTap: onSignOut,
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                children: [
                  AppIcon(AppIcons.logout, size: 16.r, color: p.bad),
                  SizedBox(width: 10.w),
                  Text(
                    'sign_out'.tr(),
                    style: AppStrings.text12w600.c(p.bad),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Divider(color: context.palette.line, height: 1),
      );

  Widget _buildLanguageToggle(BuildContext context) {
    final p = context.palette;
    final current = context.locale.languageCode;

    Widget option(String code, String label) {
      final selected = code == current;
      return InkWell(
        onTap: selected ? null : () => context.setLocale(Locale(code)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          color: selected ? p.accent : Colors.transparent,
          child: Text(
            label,
            style: AppStrings.text115w800.c(selected ? p.onAccent : p.fg),
          ),
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surf,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: p.line),
      ),
      // The two names keep their order in either language.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [option('ar', 'عربي'), option('en', 'ENGLISH')],
        ),
      ),
    );
  }
}
