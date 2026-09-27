import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// The unit [AppDateUtils.relativeSpan] measured a past time in.
enum RelativeSpan { justNow, minutes, hours, yesterday, date }

/// Single home for all date handling in the app: month-name tables,
/// formatting, ISO parsing, and age math.
///
/// Named [AppDateUtils] to avoid collision with Flutter's own [DateUtils].
class AppDateUtils {
  AppDateUtils._();

  // ── Month-name tables ──────────────────────────────────────────────

  /// Arabic month names paired with **Western digits** — matches the Figma
  /// renders (e.g. "30 يونيو 2026"). intl's Arabic locale emits Arabic-Indic
  /// digits (٣٠), so display formatters that need Western digits read these
  /// tables directly instead of going through [DateFormat].
  static const List<String> arabicMonthNames = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static const List<String> englishMonthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // ── Formatting ─────────────────────────────────────────────────────

  /// Cairo-timezone formatter (default `dd MMM yyyy, hh:mm a`). Use for
  /// timestamps that must be shown in Egypt local time (orders, payments,
  /// transactions).
  static String formatDateFunction(
      [DateTime? dateTime, String? languageCode, String? formatDate]) {
    final cairo = tz.getLocation('Africa/Cairo');
    final cairoTime = tz.TZDateTime.from(
      dateTime?.toUtc() ?? DateTime.now().toUtc(),
      cairo,
    );
    return DateFormat(
            formatDate ?? 'dd MMM yyyy, hh:mm a', languageCode ?? 'en')
        .format(cairoTime);
  }

  /// Null/empty-safe ISO parse to a local [DateTime]. Returns null on blank or
  /// unparseable input.
  static DateTime? parseLocalDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  /// "30 يونيو 2026" / "30 June 2026" — day, localized month name,
  /// Western-digit year. Arabic when [isAr], English otherwise. No timezone
  /// shift: reads the date's own day/month/year, so it's safe for date-only
  /// values (admission windows, birth dates) where [formatDateFunction]'s
  /// Cairo conversion could roll the day.
  static String formatDayMonthYear(DateTime date, {required bool isAr}) {
    final month = (isAr ? arabicMonthNames : englishMonthNames)[date.month - 1];
    return '${date.day} $month ${date.year}';
  }

  /// "start — end" range built from [formatDayMonthYear]. Falls back to the
  /// single non-null bound when one side is missing, or '' when both are null.
  static String formatDayMonthYearRange(DateTime? start, DateTime? end,
      {required bool isAr}) {
    if (start != null && end != null) {
      return '${formatDayMonthYear(start, isAr: isAr)} — '
          '${formatDayMonthYear(end, isAr: isAr)}';
    }
    final single = start ?? end;
    return single == null ? '' : formatDayMonthYear(single, isAr: isAr);
  }

  /// Formats a raw ISO date string to `yyyy/MM/dd`.
  /// Returns an empty string if [rawDate] is null, or the raw value if it
  /// cannot be parsed.
  static String formatShortDate(String? rawDate) {
    if (rawDate == null) return '';
    final dt = DateTime.tryParse(rawDate);
    if (dt == null) return rawDate;
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  // ── Relative time ──────────────────────────────────────────────────

  /// How long ago [date] was, as a span and a count ("5 minutes", "3 hours",
  /// "yesterday"). The words are left to the caller, so this stays free of a
  /// localization dependency.
  ///
  /// Minutes and hours are measured, but "yesterday" and older go by calendar
  /// day — the same rule a today/earlier grouping uses, so a row never says
  /// "20 hours ago" under an "earlier" heading. A time in the future (a clock
  /// ahead of this device's) reads as just now.
  static ({RelativeSpan span, int count}) relativeSpan(
    DateTime date, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final elapsed = current.difference(date);

    if (elapsed.inMinutes < 1) return (span: RelativeSpan.justNow, count: 0);
    if (elapsed.inMinutes < 60) {
      return (span: RelativeSpan.minutes, count: elapsed.inMinutes);
    }

    final today = DateTime(current.year, current.month, current.day);
    final day = DateTime(date.year, date.month, date.day);

    if (day == today) {
      return (span: RelativeSpan.hours, count: elapsed.inHours);
    }
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return (span: RelativeSpan.yesterday, count: 1);
    }
    return (span: RelativeSpan.date, count: today.difference(day).inDays);
  }

  // ── Age math ───────────────────────────────────────────────────────
  //
  // Admission age is measured at the upcoming October-1 cutoff (the start of
  // the school year), so a child's grade-matching age can differ from their
  // age today. Both the Step-2 grade filtering and the `AgeInOctoberChip` go
  // through [ageAtNextOctoberFirst] so the displayed age and the matched
  // grades always agree.

  /// Calculates age in years from an ISO date string (e.g. `"2019-03-15"`).
  /// Returns `0` if [rawBirthDate] is null or cannot be parsed.
  static int calculateAgeInYears(String? rawBirthDate) {
    if (rawBirthDate == null) return 0;
    final birthDate = DateTime.tryParse(rawBirthDate);
    if (birthDate == null) return 0;
    return calculateAgeFromDateTime(birthDate);
  }

  /// Whole-year age between [birthDate] and now.
  static int calculateAgeFromDateTime(DateTime birthDate) =>
      ageAt(birthDate, DateTime.now());

  /// The next October-1 on or after [now] (defaults to today).
  static DateTime nextOctoberFirst([DateTime? now]) {
    final today = now ?? DateTime.now();
    final thisYearOct = DateTime(today.year, 10, 1);
    return today.isAfter(thisYearOct)
        ? DateTime(today.year + 1, 10, 1)
        : thisYearOct;
  }

  /// Whole years between [birth] and [at]. Clamps negatives to 0.
  static int ageAt(DateTime birth, DateTime at) {
    var age = at.year - birth.year;
    final hadBirthday = (at.month > birth.month) ||
        (at.month == birth.month && at.day >= birth.day);
    if (!hadBirthday) age--;
    return age < 0 ? 0 : age;
  }

  /// A child's whole-year age at the upcoming October-1 admission cutoff.
  static int ageAtNextOctoberFirst(DateTime birth, [DateTime? now]) =>
      ageAt(birth, nextOctoberFirst(now));
}
