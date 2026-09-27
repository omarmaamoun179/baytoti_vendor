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
/// adds the family's name and the terms; both end in a code sent to the
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
      fullName: _mode == AuthMode.signup ? _name.text.trim() : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final signup = _mode == AuthMode.signup;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthModeTabs(mode: _mode, onChanged: _setMode),
          SizedBox(height: 20.h),
          if (signup) ...[
            AppTextField(
              label: 'auth_family_name'.tr(),
              hintText: 'auth_family_name_hint'.tr(),
              controller: _name,
              fillColor: p.surf,
              maxLength: FamilyName.maxLength,
              textInputAction: TextInputAction.next,
              validator: (value) => validateTextLength(
                value,
                minLength: FamilyName.minLength,
                maxLength: FamilyName.maxLength,
                isRequired: true,
              ),
            ),
            SizedBox(height: 16.h),
          ],
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
            textInputAction: TextInputAction.done,
            onInputChanged: (number) => _number = number,
            onSubmitted: (_) => _submit(),
          ),
          if (signup) ...[
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
    );
  }
}
