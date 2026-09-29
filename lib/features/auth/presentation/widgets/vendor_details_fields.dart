import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/validators/validator_messages.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/caps_label.dart';
import '../../../../core/widgets/phone_text_form_field.dart';
import '../../../../core/widgets/section_header.dart';
import '../../domain/entities/auth_params.dart';

/// The sign-up tab's business and store sections — everything
/// `POST /auth/vendor/register` takes beyond the account itself. Only the
/// business name and the store name are required.
///
/// Owns its controllers and reports the whole [VendorDetails] through
/// [onChanged] on every edit, so the form keeps only the latest value. The
/// inputs validate with the enclosing `Form`, and each also shows the
/// server's refusal of its field ([serverError], by the API's field name)
/// until it is edited ([onEdited]).
class VendorDetailsFields extends StatefulWidget {
  /// What to start from — the form's last value, so switching to the sign-in
  /// tab and back does not wipe the sections. The business phone starts
  /// empty: the field takes a national number, not the E.164 kept here.
  final VendorDetails initial;

  /// The business name's node, so the field above can hand focus down.
  final FocusNode focusNode;

  final ValueChanged<VendorDetails> onChanged;

  /// The server's message for an API field (`business_email`), if any.
  final String? Function(String field) serverError;

  /// Told which API field was edited, so its server message goes.
  final ValueChanged<String> onEdited;

  /// The API fields drawn here, whose server messages show under them.
  static const Set<String> fields = {
    'business_name',
    'business_phone',
    'business_email',
    'commercial_license',
    'civil_id',
    'bank_account',
    'iban',
    'address',
    'store_name',
    'store_description',
  };

  const VendorDetailsFields({
    super.key,
    required this.focusNode,
    required this.onChanged,
    required this.serverError,
    required this.onEdited,
    this.initial = const VendorDetails(),
  });

  @override
  State<VendorDetailsFields> createState() => _VendorDetailsFieldsState();
}

class _VendorDetailsFieldsState extends State<VendorDetailsFields> {
  late final _businessName =
      TextEditingController(text: widget.initial.businessName);
  final _businessPhone = TextEditingController();
  late final _businessEmail =
      TextEditingController(text: widget.initial.businessEmail);
  late final _commercialLicense =
      TextEditingController(text: widget.initial.commercialLicense);
  late final _civilId = TextEditingController(text: widget.initial.civilId);
  late final _bankAccount =
      TextEditingController(text: widget.initial.bankAccount);
  late final _iban = TextEditingController(text: widget.initial.iban);
  late final _address = TextEditingController(text: widget.initial.address);
  late final _storeName =
      TextEditingController(text: widget.initial.storeName);
  late final _storeDescription =
      TextEditingController(text: widget.initial.storeDescription);

  /// One node per field after the business name, in the order drawn —
  /// business phone, email, licence, civil ID, bank account, IBAN, address,
  /// store name, store description. Walked explicitly rather than by
  /// traversal: the phone field's country picker is focusable and would
  /// otherwise take a `next`.
  late final List<FocusNode> _nodes = List.generate(9, (_) => FocusNode());

  /// The phone field's reading, dial code included — the controller holds
  /// the national part only.
  PhoneNumber? _businessPhoneNumber;

  List<TextEditingController> get _controllers => [
        _businessName,
        _businessPhone,
        _businessEmail,
        _commercialLicense,
        _civilId,
        _bankAccount,
        _iban,
        _address,
        _storeName,
        _storeDescription,
      ];

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_report);
    }
    // The phone did not carry over, so the form must stop holding it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _report();
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _report() => widget.onChanged(VendorDetails(
        businessName: _businessName.text,
        // Blank stays blank: the picker reports a bare dial code for an
        // empty field.
        businessPhone: _businessPhone.text.trim().isEmpty
            ? ''
            : _businessPhoneNumber?.phoneNumber ?? _businessPhone.text,
        businessEmail: _businessEmail.text,
        commercialLicense: _commercialLicense.text,
        civilId: _civilId.text,
        bankAccount: _bankAccount.text,
        iban: _iban.text,
        address: _address.text,
        storeName: _storeName.text,
        storeDescription: _storeDescription.text,
      ));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: 'auth_section_business'.tr()),
        AppTextField(
          label: 'auth_family_name'.tr(),
          hintText: 'auth_family_name_hint'.tr(),
          controller: _businessName,
          focusNode: widget.focusNode,
          fillColor: p.surf,
          maxLength: VendorDetails.businessNameMaxLength,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.organizationName],
          onChanged: (_) => widget.onEdited('business_name'),
          onSubmitted: (_) => _nodes[0].requestFocus(),
          validator: (value) =>
              validateTextLength(
                value,
                isRequired: true,
                minLength: VendorDetails.businessNameMinLength,
                maxLength: VendorDetails.businessNameMaxLength,
              ) ??
              widget.serverError('business_name'),
        ),
        SizedBox(height: 16.h),
        CapsLabel(_optional('auth_business_phone')),
        SizedBox(height: 8.h),
        // Optional: without a required message an empty field passes, and a
        // number that is typed is still checked for its country.
        PhoneTextFormField(
          controller: _businessPhone,
          focusNode: _nodes[0],
          hintText: '2266 1100',
          height: 48.h,
          radius: 12.r,
          invalidMessage: 'invalid_phone'.tr(),
          lengthMessage: (digits) => 'phone_length'.tr(args: ['$digits']),
          // Runs after the field's own checks.
          validator: (_) => widget.serverError('business_phone'),
          onInputChanged: (number) {
            // Also called when the field regroups the same number.
            if (number.phoneNumber != _businessPhoneNumber?.phoneNumber) {
              widget.onEdited('business_phone');
            }
            _businessPhoneNumber = number;
            _report();
          },
          onSubmitted: (_) => _nodes[1].requestFocus(),
        ),
        SizedBox(height: 16.h),
        _buildOptional(
          p,
          label: 'auth_business_email',
          field: 'business_email',
          controller: _businessEmail,
          index: 1,
          maxLength: VendorDetails.businessEmailMaxLength,
          keyboardType: TextInputType.emailAddress,
          validator: validateOptionalEmail,
        ),
        _buildOptional(
          p,
          label: 'auth_commercial_license',
          field: 'commercial_license',
          controller: _commercialLicense,
          index: 2,
          maxLength: VendorDetails.commercialLicenseMaxLength,
        ),
        _buildOptional(
          p,
          label: 'auth_civil_id',
          field: 'civil_id',
          controller: _civilId,
          index: 3,
          maxLength: VendorDetails.civilIdMaxLength,
          keyboardType: TextInputType.number,
        ),
        _buildOptional(
          p,
          label: 'auth_bank_account',
          field: 'bank_account',
          controller: _bankAccount,
          index: 4,
          maxLength: VendorDetails.bankAccountMaxLength,
        ),
        _buildOptional(
          p,
          label: 'auth_iban',
          field: 'iban',
          hintText: 'auth_iban_hint'.tr(),
          controller: _iban,
          index: 5,
          maxLength: VendorDetails.ibanMaxLength,
        ),
        _buildOptional(
          p,
          label: 'auth_address',
          field: 'address',
          controller: _address,
          index: 6,
          maxLength: VendorDetails.addressMaxLength,
          multiline: true,
        ),
        SectionHeader(title: 'auth_section_store'.tr()),
        AppTextField(
          label: 'auth_store_name'.tr(),
          hintText: 'auth_store_name_hint'.tr(),
          controller: _storeName,
          focusNode: _nodes[7],
          fillColor: p.surf,
          maxLength: VendorDetails.storeNameMaxLength,
          textInputAction: TextInputAction.next,
          onChanged: (_) => widget.onEdited('store_name'),
          onSubmitted: (_) => _nodes[8].requestFocus(),
          validator: (value) =>
              validateTextLength(
                value,
                isRequired: true,
                minLength: VendorDetails.storeNameMinLength,
                maxLength: VendorDetails.storeNameMaxLength,
              ) ??
              widget.serverError('store_name'),
        ),
        SizedBox(height: 16.h),
        _buildOptional(
          p,
          label: 'auth_store_description',
          field: 'store_description',
          hintText: 'store_story_placeholder'.tr(),
          controller: _storeDescription,
          index: 8,
          maxLength: VendorDetails.storeDescriptionMaxLength,
          multiline: true,
          last: true,
        ),
      ],
    );
  }

  String _optional(String key) => 'field_optional'.tr(args: [key.tr()]);

  /// A field that may be left blank, followed by its gap. [field] is its
  /// API name and [index] its node; `next` hands focus to the one after,
  /// except from a multiline field, where the key starts a new line.
  Widget _buildOptional(
    AppPalette p, {
    required String label,
    required String field,
    required TextEditingController controller,
    required int index,
    required int maxLength,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool multiline = false,
    bool last = false,
  }) =>
      Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 16.h),
        child: AppTextField(
          label: _optional(label),
          hintText: hintText,
          controller: controller,
          focusNode: _nodes[index],
          fillColor: p.surf,
          maxLength: maxLength,
          multiline: multiline,
          minLines: 3,
          keyboardType: keyboardType,
          textInputAction:
              multiline ? TextInputAction.newline : TextInputAction.next,
          onChanged: (_) => widget.onEdited(field),
          onSubmitted:
              multiline ? null : (_) => _nodes[index + 1].requestFocus(),
          // Only length is checked beyond the email's form: the API states
          // no format for a licence, civil ID, account or IBAN.
          validator: (value) =>
              (validator?.call(value) ??
                  validateTextLength(value, maxLength: maxLength)) ??
              widget.serverError(field),
        ),
      );
}
