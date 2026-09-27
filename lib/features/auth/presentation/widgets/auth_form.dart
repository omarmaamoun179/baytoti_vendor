import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/validators/validator_messages.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/caps_label.dart';
import '../../../../core/widgets/phone_text_form_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/auth_params.dart';
import 'auth_mode_tabs.dart';
import 'terms_check.dart';

/// Sign in and sign up in one form under the segmented control. Sign-up
/// adds what `POST /auth/vendor/register` requires — the family's name, an
/// email and a password — and the terms; both end in a code sent to the
/// phone.
///
/// Holds its own fields and validates them locally; what it hands up is a
/// finished [RequestOtpParams] through [onSubmit].
class AuthForm extends StatefulWidget {
  final bool loading;
  final ValueChanged<RequestOtpParams> onSubmit;

  /// Told when the vendor switches tab, so a stale error does not follow.
  final VoidCallback? onModeChanged;

  const AuthForm({
    super.key,
    required this.loading,
    required this.onSubmit,
    this.onModeChanged,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _phone = TextEditingController();

  /// Owned here so the phone field can regroup the number when it is left.
  final _phoneFocus = FocusNode();

  /// What the phone field last reported: the number in E.164 with the
  /// country it was typed for. The controller holds only the national digits
  /// — which country they belong to is not recoverable from them.
  PhoneNumber? _number;

  AuthMode _mode = AuthMode.login;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    _phone.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _setMode(AuthMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    _formKey.currentState?.reset();
    widget.onModeChanged?.call();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onSubmit(RequestOtpParams(
      // Validated above, so the field has reported a number.
      phone: _number?.phoneNumber ?? '',
      mode: _mode,
      signup: _mode == AuthMode.signup
          ? SignupDetails(
              familyName: _name.text.trim(),
              email: _email.text.trim(),
              password: _password.text,
              passwordConfirmation: _confirmation.text,
            )
          : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final signup = _mode == AuthMode.signup;

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthModeTabs(mode: _mode, onChanged: _setMode),
            SizedBox(height: 20.h),
            if (signup) ..._buildAccountFields(p),
            // The design's small caps label rather than the field's own.
            CapsLabel('auth_phone'.tr()),
            SizedBox(height: 8.h),
            PhoneTextFormField(
              controller: _phone,
              focusNode: _phoneFocus,
              hintText: '5150 2244',
              height: 48.h,
              radius: 12.r,
              requiredMessage: 'phone_required'.tr(),
              invalidMessage: 'invalid_phone'.tr(),
              lengthMessage: (digits) =>
                  'phone_length'.tr(args: ['$digits']),
              textInputAction:
                  signup ? TextInputAction.next : TextInputAction.done,
              onInputChanged: (number) => _number = number,
              onSubmitted: (_) {
                // Sign-up goes on to the password; sign-in is done here.
                if (!signup) _submit();
              },
            ),
            if (signup) ...[
              SizedBox(height: 16.h),
              ..._buildPasswordFields(p),
              SizedBox(height: 16.h),
              TermsCheck(
                value: _acceptedTerms,
                onChanged: (value) => setState(() => _acceptedTerms = value),
              ),
            ],
            SizedBox(height: 16.h),
            PrimaryButton(
              label: _mode.ctaKey.tr(),
              height: 52.h,
              labelStyle: AppStrings.text14w800,
              trailingChevron: true,
              loading: widget.loading,
              onPressed: _submit,
            ),
            SizedBox(height: 16.h),
            Text(
              'auth_hint'.tr(),
              textAlign: TextAlign.center,
              style: AppStrings.text11w400Loose.c(p.fg3),
            ),
          ],
        ),
      ),
    );
  }

  /// The family's name and the account's email, above the number.
  List<Widget> _buildAccountFields(AppPalette p) => [
        AppTextField(
          label: 'auth_family_name'.tr(),
          hintText: 'auth_family_name_hint'.tr(),
          controller: _name,
          fillColor: p.surf,
          maxLength: FamilyName.maxLength,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.organizationName],
          validator: (value) => validateTextLength(
            value,
            minLength: FamilyName.minLength,
            maxLength: FamilyName.maxLength,
            isRequired: true,
          ),
        ),
        SizedBox(height: 16.h),
        AppTextField(
          label: 'auth_email'.tr(),
          hintText: 'auth_email_hint'.tr(),
          controller: _email,
          fillColor: p.surf,
          maxLength: SignupDetails.emailMaxLength,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: (value) => validateEmail(value?.trim()),
        ),
        SizedBox(height: 16.h),
      ];

  /// The password the account is created with, twice. The app signs in by
  /// code; the password is the API's requirement, for the account itself.
  List<Widget> _buildPasswordFields(AppPalette p) => [
        AppTextField(
          label: 'auth_password'.tr(),
          hintText: 'auth_password_hint'.tr(),
          controller: _password,
          fillColor: p.surf,
          obscureText: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          validator: validatePassword,
        ),
        SizedBox(height: 16.h),
        AppTextField(
          label: 'auth_password_confirm'.tr(),
          controller: _confirmation,
          fillColor: p.surf,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          validator: (value) =>
              validatePasswordConfirmation(value, _password.text),
          onSubmitted: (_) => _submit(),
        ),
      ];
}
