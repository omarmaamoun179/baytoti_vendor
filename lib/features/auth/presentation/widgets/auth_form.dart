import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/photo_picker.dart';
import '../../../../core/utils/validators/validator_messages.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/caps_label.dart';
import '../../../../core/widgets/phone_text_form_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../../domain/entities/auth_params.dart';
import 'auth_mode_tabs.dart';
import 'avatar_picker.dart';
import 'vendor_details_fields.dart';

/// Sign in and sign up in one form under the segmented control. Sign-up is
/// the whole `POST /auth/vendor/register`: the account (an optional photo,
/// name, email, phone, password), the family's business
/// ([VendorDetailsFields]) and its store. Both tabs end in a code sent to
/// the phone.
///
/// Holds its own fields and validates each as it is typed in, the message
/// under the field; what it hands up is a finished [RequestOtpParams]
/// through [onSubmit]. The server's refusals ([fieldErrors], by the API's
/// field names) show under their fields too, until the field is edited.
class AuthForm extends StatefulWidget {
  final bool loading;
  final ValueChanged<RequestOtpParams> onSubmit;

  /// The last refusal's messages by API field; those in [showsField] are
  /// drawn under their fields.
  final Map<String, String> fieldErrors;

  /// Told when the vendor switches tab, so a stale error does not follow.
  final VoidCallback? onModeChanged;

  const AuthForm({
    super.key,
    required this.loading,
    required this.onSubmit,
    this.fieldErrors = const {},
    this.onModeChanged,
  });

  /// The account's API fields, drawn above the business and store ones.
  static const Set<String> accountFields = {
    'avatar',
    'name',
    'email',
    'phone',
    'password',
    'password_confirmation',
  };

  /// Whether a server message for [field] is drawn under a field here —
  /// what is not, the page says in a toast.
  static bool showsField(String field) =>
      accountFields.contains(field) ||
      VendorDetailsFields.fields.contains(field);

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

  /// The profile photo on the device, or null for none.
  String? _avatar;

  /// The server's refusals still standing, by API field — each is dropped
  /// when its field is edited, and all of them on the next submit.
  Map<String, String> _serverErrors = {};

  AuthMode _mode = AuthMode.login;

  @override
  void didUpdateWidget(AuthForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final errors = widget.fieldErrors;
    if (identical(errors, oldWidget.fieldErrors)) return;

    final shown = {
      for (final MapEntry(:key, :value) in errors.entries)
        if (AuthForm.showsField(key) && value.trim().isNotEmpty) key: value,
    };
    if (shown.isEmpty) return;
    _serverErrors = shown;
    // After this build: validating marks every field, which must not
    // happen while they are being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !(_formKey.currentState?.validate() ?? true)) {
        _revealFirstError();
      }
    });
  }

  /// Scrolls the topmost field with a message into view — on a sign-up the
  /// button sits far below the email a refusal is usually about.
  void _revealFirstError() {
    Element? first;
    void visit(Element element) {
      if (first != null) return;
      if (element case StatefulElement(:final FormFieldState<Object?> state)
          when state.hasError) {
        first = element;
        return;
      }
      element.visitChildren(visit);
    }

    _formKey.currentContext?.visitChildElements(visit);
    final field = first;
    if (field == null) return;
    Scrollable.ensureVisible(
      field,
      alignment: .2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

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

  String? _serverError(String field) => _serverErrors[field];

  /// Drops [field]'s server message. Called from the field's own change,
  /// before it validates again.
  void _edited(String field) => _serverErrors.remove(field);

  Future<void> _pickAvatar() async {
    final picked = await pickGalleryPhotos(context, multiple: false);
    if (!mounted || picked.isEmpty) return;
    _edited('avatar');
    setState(() => _avatar = picked.first);
  }

  void _removeAvatar() {
    _edited('avatar');
    setState(() => _avatar = null);
  }

  void _setMode(AuthMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _serverErrors = {};
    });
    _formKey.currentState?.reset();
    widget.onModeChanged?.call();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    // A new attempt: the server judges it afresh, so only the local checks
    // may hold it back.
    setState(() => _serverErrors = {});
    if (!(_formKey.currentState?.validate() ?? false)) {
      _revealFirstError();
      return;
    }

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
              avatarPath: _avatar,
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
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
              // Runs after the field's own checks.
              validator: (_) => _serverError('phone'),
              onInputChanged: (number) {
                // Also called when the field regroups the same number.
                if (number.phoneNumber != _number?.phoneNumber) {
                  _edited('phone');
                }
                _number = number;
              },
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
                serverError: _serverError,
                onEdited: _edited,
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

  /// The account's photo, and its holder's name and email, above the number.
  List<Widget> _buildAccountFields(AppPalette p) => [
        SectionHeader(title: 'auth_section_account'.tr()),
        AvatarPicker(
          path: _avatar,
          error: _serverError('avatar'),
          onPick: widget.loading ? null : _pickAvatar,
          onRemove: widget.loading ? null : _removeAvatar,
        ),
        SizedBox(height: 16.h),
        AppTextField(
          label: 'auth_name'.tr(),
          hintText: 'auth_name_hint'.tr(),
          controller: _name,
          focusNode: _nameFocus,
          fillColor: p.surf,
          maxLength: SignupDetails.nameMaxLength,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: (_) => _edited('name'),
          onSubmitted: (_) => _emailFocus.requestFocus(),
          validator: (value) =>
              validateTextLength(
                value,
                minLength: SignupDetails.nameMinLength,
                maxLength: SignupDetails.nameMaxLength,
                isRequired: true,
              ) ??
              _serverError('name'),
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
          onChanged: (_) => _edited('email'),
          onSubmitted: (_) => _phoneFocus.requestFocus(),
          validator: (value) =>
              validateEmail(value?.trim()) ?? _serverError('email'),
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
          onChanged: (_) => _edited('password'),
          onSubmitted: (_) => _confirmationFocus.requestFocus(),
          validator: (value) =>
              validatePassword(value) ?? _serverError('password'),
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
          onChanged: (_) => _edited('password_confirmation'),
          onSubmitted: (_) => _vendorFocus.requestFocus(),
          validator: (value) =>
              validatePasswordConfirmation(value, _password.text) ??
              _serverError('password_confirmation'),
        ),
      ];
}
