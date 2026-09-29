import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'app_icon.dart';
import 'caps_label.dart';

/// The design's input: a 46px field on the page background, hairline border,
/// 12px corners, `600 14px` text — with an optional tracked [label] above.
///
/// [multiline] turns it into the design's text area (`400 12.5px/1.6`,
/// `11px 13px` padding), which grows between [minLines] and [maxLines].
///
/// A validator's message is drawn under the field in the theme's
/// `errorStyle`; the enclosing `Form`'s `autovalidateMode` decides when.
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;

  final bool multiline;
  final int minLines;
  final int maxLines;
  final int? maxLength;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;

  /// Defaults to the page background; sign-in's fields sit on white.
  final Color? fillColor;

  final bool enabled;

  /// Hides what is typed, for a password, with an eye at the end that shows
  /// it. Suggestions and autocorrect stay off either way — a keyboard must
  /// not learn a password.
  final bool obscureText;

  /// Hints the platform's autofill — `AutofillHints.email`, `.newPassword`.
  final Iterable<String>? autofillHints;

  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.multiline = false,
    this.minLines = 3,
    this.maxLines = 6,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.style,
    this.fillColor,
    this.enabled = true,
    this.obscureText = false,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  /// Whether a password is hidden; the eye flips it.
  late bool _hidden = widget.obscureText;

  bool get _isPassword => widget.obscureText && !widget.multiline;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final multiline = widget.multiline;
    final textStyle = widget.style ??
        (multiline ? AppStrings.text125w400 : AppStrings.text14w600);

    final field = TextFormField(
      controller: widget.controller,
      initialValue: widget.initialValue,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      minLines: multiline ? widget.minLines : 1,
      maxLines: multiline ? widget.maxLines : 1,
      maxLength: widget.maxLength,
      keyboardType: multiline ? TextInputType.multiline : widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _isPassword && _hidden,
      autocorrect: !widget.obscureText,
      enableSuggestions: !widget.obscureText,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      style: textStyle.c(p.fg),
      cursorColor: p.accent,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: textStyle.c(p.fg3),
        // The design's fields carry no counter; the limit still holds.
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: widget.fillColor ?? p.bg,
        contentPadding: multiline
            ? EdgeInsets.symmetric(horizontal: 13.w, vertical: 11.h)
            : EdgeInsets.symmetric(horizontal: 13.w, vertical: 15.h),
        border: _border(p.line),
        enabledBorder: _border(p.line),
        disabledBorder: _border(p.line),
        focusedBorder: _border(p.accent),
        errorBorder: _border(p.bad),
        focusedErrorBorder: _border(p.bad),
        suffixIcon: _isPassword ? _buildEye(p) : null,
        suffixIconConstraints: _isPassword
            ? BoxConstraints.tightFor(width: 44.w, height: 40.h)
            : null,
      ),
    );

    final label = widget.label;
    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CapsLabel(label),
        SizedBox(height: 8.h),
        field,
      ],
    );
  }

  /// Shows the password while [_hidden] is off. Sized to the field, so the
  /// field keeps the design's height.
  Widget _buildEye(AppPalette p) => IconButton(
        onPressed: () => setState(() => _hidden = !_hidden),
        tooltip: (_hidden ? 'password_show' : 'password_hide').tr(),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(width: 44.w, height: 40.h),
        icon: AppIcon(
          _hidden ? AppIcons.eye : AppIcons.eyeOff,
          size: 18.r,
          color: p.fg3,
        ),
      );

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: color),
      );
}
