/// Pure validation logic — no Flutter, no localization.
///
/// Every `check*` function returns either `null` (valid) or a small error
/// enum. The matching `validate*` wrapper in `validator_messages.dart`
/// maps the enum onto a localized string for use with form fields.
library;

/// Strips every non-digit. Phone fields are entered with spaces and a dial
/// code, while the API wants an unbroken run of digits.
String digitsOnly(String? value) => (value ?? '').replaceAll(RegExp(r'\D'), '');

enum NameError { empty, tooShort, tooLong }

/// Bounds mirror the API's `RegisterRequest`: 3–100 characters.
NameError? checkName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return NameError.empty;
  if (name.length < 3) return NameError.tooShort;
  if (name.length > 100) return NameError.tooLong;
  return null;
}

enum PhoneError { empty, invalid }

/// A subscriber number of [localLength] digits, the dial code excluded.
///
/// Not what the auth forms use: their field carries a country picker, so
/// libphonenumber judges the number for whichever country is chosen — which
/// is the only way to be right about a length that differs per country. This
/// stays for a field that only ever takes a local number, and says which
/// length it is checking rather than implying every number has one.
PhoneError? checkPhone(String? value, {int localLength = 8}) {
  final digits = digitsOnly(value);
  if (digits.isEmpty) return PhoneError.empty;
  return digits.length == localLength ? null : PhoneError.invalid;
}

enum EmailError { empty, invalid }

EmailError? checkEmail(String? value) {
  if (value == null || value.isEmpty) return EmailError.empty;
  final isValid = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
      .hasMatch(value);
  return isValid ? null : EmailError.invalid;
}

enum PasswordError { empty, weak }

PasswordError? checkPassword(String? value) {
  if (value == null || value.isEmpty) return PasswordError.empty;

  final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
  final hasDigit = RegExp(r'\d').hasMatch(value);
  final hasMinLength = value.length >= 8;

  if (!hasLowercase || !hasDigit || !hasMinLength) {
    return PasswordError.weak;
  }

  return null;
}

enum PasswordConfirmationError { empty, mismatch }

/// Checked client-side so the mismatch shows under the field instead of
/// costing a round trip and coming back as a 422 on `password`.
PasswordConfirmationError? checkPasswordConfirmation(
  String? value,
  String? password,
) {
  if (value == null || value.isEmpty) return PasswordConfirmationError.empty;
  return value == password ? null : PasswordConfirmationError.mismatch;
}
