/// Helpers for the 14-digit Egyptian national ID.
///
/// The ID encodes the holder's birth date and gender, so a single valid number
/// yields both — used to auto-fill the gender, derive the birth date, and cross
/// check a manually-picked birth date against the ID.
///
/// Layout (positions are 0-based):
///   [0]      century digit — 2 ⇒ 1900s, 3 ⇒ 2000s
///   [1..2]   year (within the century)
///   [3..4]   month
///   [5..6]   day
///   [7..8]   governorate code
///   [9..11]  serial
///   [12]     gender digit — odd ⇒ male, even ⇒ female
///   [13]     checksum
library;

class NationalIdInfo {
  /// The encoded birth date (date-only — time is midnight).
  final DateTime birthDate;

  /// `'male'` or `'female'`, derived from the gender digit.
  final String gender;

  const NationalIdInfo({required this.birthDate, required this.gender});

  /// Whether [date]'s calendar day matches the encoded birth date, ignoring
  /// any time component.
  bool matchesDate(DateTime date) =>
      date.year == birthDate.year &&
      date.month == birthDate.month &&
      date.day == birthDate.day;
}

/// Parses [raw] as an Egyptian national ID, returning the encoded birth date
/// and gender, or `null` when the ID is not a valid 14-digit number (wrong
/// length, non-digits, unsupported century digit, or an impossible date).
NationalIdInfo? parseEgyptianNationalId(String raw) {
  final id = raw.trim();
  if (!RegExp(r'^\d{14}$').hasMatch(id)) return null;

  final centuryDigit = int.parse(id[0]);
  final int yearPrefix;
  if (centuryDigit == 2) {
    yearPrefix = 1900;
  } else if (centuryDigit == 3) {
    yearPrefix = 2000;
  } else {
    return null;
  }

  final year = yearPrefix + int.parse(id.substring(1, 3));
  final month = int.parse(id.substring(3, 5));
  final day = int.parse(id.substring(5, 7));
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;

  final date = DateTime(year, month, day);
  // Reject overflow (e.g. month 02 day 31 rolls into March).
  if (date.year != year || date.month != month || date.day != day) return null;

  final genderDigit = int.parse(id[12]);
  return NationalIdInfo(
    birthDate: date,
    gender: genderDigit.isOdd ? 'male' : 'female',
  );
}
