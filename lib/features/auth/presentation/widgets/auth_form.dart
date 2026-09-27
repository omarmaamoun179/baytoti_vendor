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
import '../../../../core/widgets/section_header.dart';
import '../../domain/entities/auth_params.dart';
import 'auth_mode_tabs.dart';
import 'terms_check.dart';
import 'vendor_details_fields.dart';

/// Sign in and sign up in one form under the segmented control. Sign-up is
/// the whole `POST /auth/vendor/register`: the account (name, email, phone,
/// password), the family's business ([VendorDetailsFields]) and its store,
/// then the terms. Both tabs end in a code sent to the phone.
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

  // Walked explicitly: the phone field's country picker is focusable and
  // would otherwise take a `next`. The phone's node also lets the field
  // regroup the number when it is left.
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmationFocus = FocusNode();
  final _vendorFocus = FocusNode();

  /// What the phone field last reported: the number in E.164 with the
  /// country it was typed for. The controller holds only the national digits
  /// — which country they belong to is not recoverable from them.
  PhoneNumber? _number;

  /// The business and store sections' latest value, kept across a tab
  /// switch.
  VendorDetails _vendor = const VendorDetails();

  AuthMode _mode = AuthMode.login;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _password,
      _confirmation,
      _phone,
    ]) {
      controller.dispose();
    }
    for (final node in [
      _nameFocus,
      _emailFocus,
      _phoneFocus,
      _passwordFocus,
      _confirmationFocus,
      _vendorFocus,
    ]) {
      node.dispose();
    }
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
              name: _name.text.trim(),
              email: _email.text.trim(),
              password: _password.text,
              passwordConfirmation: _confirmation.text,
              vendor: _vendor,
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
            SizedBox(height: signup ? 0 : 20.h),
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
                if (signup) {
                  _passwordFocus.requestFocus();
                } else {
                  _submit();
                }
              },
            ),
            if (signup) ...[
              SizedBox(height: 16.h),
              ..._buildPasswordFields(p),
              VendorDetailsFields(
                initial: _vendor,
                focusNode: _vendorFocus,
                onChanged: (details) => _vendor = details,
              ),
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

  /// The account holder's name and email, above the number.
  List<Widget> _buildAccountFields(AppPalette p) => [
        SectionHeader(title: 'auth_section_account'.tr()),
        AppTextField(
          label: 'auth_name'.tr(),
          hintText: 'auth_name_hint'.tr(),
          controller: _name,
          focusNode: _nameFocus,
          fillColor: p.surf,
          maxLength: SignupDetails.nameMaxLength,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onSubmitted: (_) => _emailFocus.requestFocus(),
          validator: (value) => validateTextLength(
            value,
            minLength: SignupDetails.nameMinLength,
            maxLength: SignupDetails.nameMaxLength,
            isRequired: true,
          ),
        ),
        SizedBox(height: 16.h),
        AppTextField(
          label: 'auth_email'.tr(),
          hintText: 'auth_email_hint'.tr(),
          controller: _email,
          focusNode: _emailFocus,
          fillColor: p.surf,
          maxLength: SignupDetails.emailMaxLength,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _phoneFocus.requestFocus(),
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
          focusNode: _passwordFocus,
          fillColor: p.surf,
          obscureText: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          onSubmitted: (_) => _confirmationFocus.requestFocus(),
          validator: validatePassword,
        ),
        SizedBox(height: 16.h),
        AppTextField(
          label: 'auth_password_confirm'.tr(),
          controller: _confirmation,
          focusNode: _confirmationFocus,
          fillColor: p.surf,
          obscureText: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          onSubmitted: (_) => _vendorFocus.requestFocus(),
          validator: (value) =>
              validatePasswordConfirmation(value, _password.text),
        ),
      ];
}
