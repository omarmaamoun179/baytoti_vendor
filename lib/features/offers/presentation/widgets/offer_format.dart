import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/utils/app_date_utils.dart';

/// "20٪" in Arabic, "20%" in English.
String percentLabel(int percent) => 'percent_value'.tr(args: ['$percent']);

/// "30 September" / "30 سبتمبر" — Western digits, month in the app's
/// language.
String dayMonthLabel(BuildContext context, DateTime date) {
  final isAr = context.locale.languageCode == 'ar';
  final months = isAr
      ? AppDateUtils.arabicMonthNames
      : AppDateUtils.englishMonthNames;
  return '${date.day} ${months[date.month - 1]}';
}
