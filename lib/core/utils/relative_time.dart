import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import 'app_date_utils.dart';

/// "4 minutes ago", "yesterday", or the date for anything older.
String relativeTimeLabel(BuildContext context, DateTime date) {
  final relative = AppDateUtils.relativeSpan(date);

  return switch (relative.span) {
    RelativeSpan.justNow => 'time_just_now'.tr(),
    RelativeSpan.minutes =>
      'time_minutes_ago'.tr(args: ['${relative.count}']),
    RelativeSpan.hours => 'time_hours_ago'.tr(args: ['${relative.count}']),
    RelativeSpan.yesterday => 'time_yesterday'.tr(),
    RelativeSpan.date => AppDateUtils.formatDayMonthYear(
        date,
        isAr: context.locale.languageCode == 'ar',
      ),
  };
}

/// "12 May 2026 · 1:04 PM" — Western digits, month name in the app's
/// language.
String dateTimeLabel(BuildContext context, DateTime date) {
  final isAr = context.locale.languageCode == 'ar';
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = (date.hour < 12 ? 'time_am' : 'time_pm').tr();

  return '${AppDateUtils.formatDayMonthYear(date, isAr: isAr)} · '
      '$hour:$minute $period';
}
