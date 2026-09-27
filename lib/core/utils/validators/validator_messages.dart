import 'package:easy_localization/easy_localization.dart';

import 'validator_logic.dart';

/// Presence only. For inputs whose real rule lives on the server — the
/// sign-in identifier, or a password that predates the current strength rule.
String? validateRequired(String? value) =>
    (value == null || value.trim().isEmpty) ? 'field_required'.tr() : null;

/// A text against the API's length limits, once trimmed as the request trims
/// it. Empty passes unless [isRequired].
///
/// Counted in code points, as Laravel's `min`/`max` count a string. A field's
/// `maxLength` counts what the eye sees instead, so an emoji built from
/// several code points gets past it and is caught here, before the server
/// refuses it.
String? validateTextLength(
  String? value, {
  required int maxLength,
  int minLength = 0,
  bool isRequired = false,
}) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return isRequired ? 'field_required'.tr() : null;

  final length = text.runes.length;
  if (length < minLength) return 'text_too_short'.tr(args: ['$minLength']);
  if (length > maxLength) return 'text_too_long'.tr(args: ['$maxLength']);
  return null;
}

String? validateName(String? value) => switch (checkName(value)) {
      null => null,
      NameError.empty => 'name_required'.tr(),
      NameError.tooShort => 'name_too_short'.tr(),
      NameError.tooLong => 'name_too_long'.tr(),
    };

String? validatePhone(String? value) => switch (checkPhone(value)) {
      null => null,
      PhoneError.empty => 'phone_required'.tr(),
      PhoneError.invalid => 'invalid_phone'.tr(),
    };

String? validateEmail(String? value) => switch (checkEmail(value)) {
      null => null,
      EmailError.empty => 'email_required'.tr(),
      EmailError.invalid => 'invalid_email'.tr(),
    };

/// Same as [validateEmail] but treats empty/null as valid (optional fields).
String? validateOptionalEmail(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return checkEmail(value) == EmailError.invalid ? 'invalid_email'.tr() : null;
}

String? validatePassword(String? value) => switch (checkPassword(value)) {
      null => null,
      PasswordError.empty => 'add_password_to_continue'.tr(),
      PasswordError.weak => 'please_create_strong_password'.tr()
    };

String? validatePasswordConfirmation(String? value, String? password) =>
    switch (checkPasswordConfirmation(value, password)) {
      null => null,
      PasswordConfirmationError.empty => 'confirm_password_required'.tr(),
      PasswordConfirmationError.mismatch => 'passwords_do_not_match'.tr(),
    };
